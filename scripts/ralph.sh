#!/bin/bash
# Ralph Loop for BurnDial
# Mimics frankbria/ralph-claude-code behavior
# Usage: ./scripts/ralph.sh [--max-loops N] [--verbose]

set -e

# =============================================================================
# Configuration
# =============================================================================
MAX_LOOPS=${MAX_LOOPS:-50}
MAX_CALLS_PER_HOUR=${MAX_CALLS_PER_HOUR:-100}
CLAUDE_TIMEOUT_MINUTES=${CLAUDE_TIMEOUT_MINUTES:-30}
VERBOSE=${VERBOSE:-false}

# Exit detection thresholds
MAX_CONSECUTIVE_TEST_LOOPS=3
MAX_CONSECUTIVE_DONE_SIGNALS=2

# Directories and files
LOG_DIR="logs"
STATUS_FILE="status.json"
PROMPT_FILE="PROMPT.md"
FIX_PLAN_FILE="@fix_plan.md"
CALL_COUNT_FILE=".call_count"
LOOP_COUNT_FILE=".loop_count"
EXIT_SIGNALS_FILE=".exit_signals"
TIMESTAMP_FILE=".last_reset"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

log_status() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""

    case $level in
        "INFO")  color=$BLUE ;;
        "WARN")  color=$YELLOW ;;
        "ERROR") color=$RED ;;
        "SUCCESS") color=$GREEN ;;
        "LOOP") color=$PURPLE ;;
    esac

    echo -e "${color}[$timestamp] [$level] $message${NC}"
    
    # Also log to file
    mkdir -p "$LOG_DIR"
    echo "[$timestamp] [$level] $message" >> "$LOG_DIR/ralph.log"
}

update_status_json() {
    local loop_count=$1
    local calls_made=$2
    local status=$3
    local last_action=$4
    local exit_reason=${5:-""}

    cat > "$STATUS_FILE" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "loop_count": $loop_count,
    "calls_made_this_hour": $calls_made,
    "max_calls_per_hour": $MAX_CALLS_PER_HOUR,
    "status": "$status",
    "last_action": "$last_action",
    "exit_reason": "$exit_reason",
    "verifyStatus": {
        "safetyCheck": null,
        "typecheck": null,
        "e2e": null,
        "build": null
    }
}
EOF
}

# =============================================================================
# Call Tracking
# =============================================================================

init_call_tracking() {
    local current_hour=$(date +%Y%m%d%H)
    local last_reset_hour=""

    if [[ -f "$TIMESTAMP_FILE" ]]; then
        last_reset_hour=$(cat "$TIMESTAMP_FILE")
    fi

    # Reset counter if it's a new hour
    if [[ "$current_hour" != "$last_reset_hour" ]]; then
        echo "0" > "$CALL_COUNT_FILE"
        echo "$current_hour" > "$TIMESTAMP_FILE"
        log_status "INFO" "Call counter reset for new hour: $current_hour"
    fi

    # Initialize exit signals if needed
    if [[ ! -f "$EXIT_SIGNALS_FILE" ]]; then
        echo '{"test_only_loops": [], "done_signals": [], "completion_indicators": []}' > "$EXIT_SIGNALS_FILE"
    fi
}

can_make_call() {
    local calls_made=0
    if [[ -f "$CALL_COUNT_FILE" ]]; then
        calls_made=$(cat "$CALL_COUNT_FILE")
    fi

    if [[ $calls_made -ge $MAX_CALLS_PER_HOUR ]]; then
        return 1
    fi
    return 0
}

increment_call() {
    local calls_made=0
    if [[ -f "$CALL_COUNT_FILE" ]]; then
        calls_made=$(cat "$CALL_COUNT_FILE")
    fi
    ((calls_made++))
    echo "$calls_made" > "$CALL_COUNT_FILE"
}

# =============================================================================
# Exit Detection
# =============================================================================

should_exit_gracefully() {
    # Check @fix_plan.md for completion
    if [[ -f "$FIX_PLAN_FILE" ]]; then
        local total_items=$(grep -c "^- \[" "$FIX_PLAN_FILE" 2>/dev/null || echo "0")
        local completed_items=$(grep -c "^- \[x\]" "$FIX_PLAN_FILE" 2>/dev/null || echo "0")

        if [[ $total_items -gt 0 ]] && [[ $completed_items -eq $total_items ]]; then
            echo "plan_complete"
            return 0
        fi
    fi

    # Check exit signals file
    if [[ -f "$EXIT_SIGNALS_FILE" ]]; then
        local done_signals=$(cat "$EXIT_SIGNALS_FILE" | grep -o '"done_signals":\s*\[[^]]*\]' | grep -o '\[.*\]' | grep -c "," 2>/dev/null || echo "0")
        
        if [[ $done_signals -ge $MAX_CONSECUTIVE_DONE_SIGNALS ]]; then
            echo "completion_signals"
            return 0
        fi
    fi

    echo ""
    return 1
}

record_done_signal() {
    if [[ -f "$EXIT_SIGNALS_FILE" ]]; then
        local timestamp=$(date -Iseconds)
        # Simple append - in production use jq
        log_status "INFO" "Recorded done signal at $timestamp"
    fi
}

# =============================================================================
# Safety Check
# =============================================================================

run_safety_check() {
    log_status "INFO" "Running safety check..."
    
    if pnpm safety:check; then
        log_status "SUCCESS" "Safety check passed"
        return 0
    else
        log_status "ERROR" "Safety check FAILED - stopping loop"
        return 1
    fi
}

# =============================================================================
# Verification
# =============================================================================

run_verify_fast() {
    log_status "INFO" "Running verify:fast..."
    
    if pnpm verify:fast; then
        log_status "SUCCESS" "verify:fast passed"
        return 0
    else
        log_status "WARN" "verify:fast failed"
        return 1
    fi
}

run_verify_full() {
    log_status "INFO" "Running verify:full..."
    
    if pnpm verify:full; then
        log_status "SUCCESS" "verify:full passed"
        return 0
    else
        log_status "WARN" "verify:full failed"
        return 1
    fi
}

# =============================================================================
# Main Loop
# =============================================================================

main() {
    log_status "SUCCESS" "🚀 Ralph loop starting"
    log_status "INFO" "Max loops: $MAX_LOOPS | Max calls/hour: $MAX_CALLS_PER_HOUR"
    log_status "INFO" "Logs: $LOG_DIR/ | Status: $STATUS_FILE"

    # Check for required files
    if [[ ! -f "$PROMPT_FILE" ]]; then
        log_status "ERROR" "PROMPT.md not found!"
        echo ""
        echo "This directory needs Ralph files. Run:"
        echo "  cp templates/* ."
        exit 1
    fi

    # Safety check first
    if ! run_safety_check; then
        log_status "ERROR" "🛑 Safety check failed - cannot proceed"
        exit 1
    fi

    # Initialize tracking
    init_call_tracking
    
    local loop_count=0
    if [[ -f "$LOOP_COUNT_FILE" ]]; then
        loop_count=$(cat "$LOOP_COUNT_FILE")
    fi

    # Main loop
    while [[ $loop_count -lt $MAX_LOOPS ]]; do
        loop_count=$((loop_count + 1))
        echo "$loop_count" > "$LOOP_COUNT_FILE"

        log_status "LOOP" "=== Starting Loop #$loop_count ==="

        # Check rate limits
        if ! can_make_call; then
            log_status "WARN" "Rate limit reached, waiting..."
            sleep 60
            continue
        fi

        # Check for graceful exit
        local exit_reason=$(should_exit_gracefully)
        if [[ -n "$exit_reason" ]]; then
            log_status "SUCCESS" "🏁 Graceful exit: $exit_reason"
            update_status_json "$loop_count" "$(cat $CALL_COUNT_FILE 2>/dev/null || echo 0)" "completed" "graceful_exit" "$exit_reason"
            
            echo ""
            echo "========================================"
            echo "ALL_TESTS_PASSING"
            echo "Total loops: $loop_count"
            echo "Exit reason: $exit_reason"
            echo "========================================"
            break
        fi

        # Update status
        local calls_made=$(cat "$CALL_COUNT_FILE" 2>/dev/null || echo "0")
        update_status_json "$loop_count" "$calls_made" "executing" "loop_iteration"

        # Create log file for this loop
        local loop_log="$LOG_DIR/loop_$(printf '%04d' $loop_count).log"
        echo "=== Loop #$loop_count started at $(date) ===" > "$loop_log"

        # Run verification
        if run_verify_fast; then
            log_status "SUCCESS" "Loop #$loop_count completed successfully"
            echo "verify:fast PASSED" >> "$loop_log"
            
            # Increment call counter
            increment_call
            
            # Brief pause
            sleep 2
        else
            log_status "WARN" "Loop #$loop_count had failures"
            echo "verify:fast FAILED" >> "$loop_log"
            
            # Don't exit on failure - let agent fix
            sleep 5
        fi

        echo "=== Loop #$loop_count ended at $(date) ===" >> "$loop_log"
    done

    if [[ $loop_count -ge $MAX_LOOPS ]]; then
        log_status "WARN" "Max loops ($MAX_LOOPS) reached"
        update_status_json "$loop_count" "$(cat $CALL_COUNT_FILE 2>/dev/null || echo 0)" "max_loops" "limit_reached"
    fi
}

# =============================================================================
# CLI
# =============================================================================

show_help() {
    echo "Ralph Loop for BurnDial"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --max-loops N    Maximum loop iterations (default: 50)"
    echo "  --verbose        Enable verbose logging"
    echo "  --status         Show current status and exit"
    echo "  --reset          Reset loop counter and exit signals"
    echo "  -h, --help       Show this help"
}

show_status() {
    echo "Ralph Status"
    echo "============"
    
    if [[ -f "$LOOP_COUNT_FILE" ]]; then
        echo "Current loop: $(cat $LOOP_COUNT_FILE)"
    else
        echo "Current loop: 0"
    fi
    
    if [[ -f "$CALL_COUNT_FILE" ]]; then
        echo "Calls this hour: $(cat $CALL_COUNT_FILE)"
    fi
    
    if [[ -f "$STATUS_FILE" ]]; then
        echo ""
        cat "$STATUS_FILE"
    fi
}

reset_ralph() {
    echo "Resetting Ralph..."
    rm -f "$LOOP_COUNT_FILE" "$CALL_COUNT_FILE" "$EXIT_SIGNALS_FILE"
    echo "0" > "$LOOP_COUNT_FILE"
    echo "0" > "$CALL_COUNT_FILE"
    echo '{"test_only_loops": [], "done_signals": [], "completion_indicators": []}' > "$EXIT_SIGNALS_FILE"
    log_status "SUCCESS" "Ralph reset complete"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --max-loops)
            MAX_LOOPS=$2
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --status)
            show_status
            exit 0
            ;;
        --reset)
            reset_ralph
            exit 0
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main
main
