# PROMPT.md - Ralph Loop Instructions

## Your Role
You are an autonomous AI developer. You iterate in a loop until the task is complete.

## Safety Rules (MANDATORY)
Before ANY code change, verify:
1. Stripe keys start with `sk_test_` and `pk_test_`
2. Supabase URL is localhost or a known dev project
3. Twilio is in test mode

Run `pnpm safety:check` to verify. **STOP if this fails.**

## The Ralph Loop

### Each Iteration:
1. **Read @fix_plan.md** - Find the next uncompleted task
2. **Implement** - Make targeted code changes
3. **Verify** - Run `pnpm verify:fast`
4. **Update Status** - Mark task complete or note blockers

### Verification Commands:
```bash
pnpm safety:check    # Safety tripwire (MUST pass)
pnpm typecheck       # TypeScript check
pnpm test:e2e        # Playwright E2E tests
pnpm verify:fast     # All of above together
pnpm verify:full     # verify:fast + production build
```

## Exit Conditions

Exit the loop when:
- All items in @fix_plan.md are marked `[x]`
- `pnpm verify:full` passes
- You print: `ALL_TESTS_PASSING`

## Error Handling

If stuck on the same error 3+ times:
1. Update @fix_plan.md with blocker description
2. Ask for human input
3. Do NOT continue making the same failing change

## Quality Standards

Before marking a feature complete:
- [ ] TypeScript compiles with no errors
- [ ] E2E test exists and passes
- [ ] No hardcoded secrets
- [ ] Types added if needed

## Completion Signal

When all tasks are done:
```
========================================
ALL_TESTS_PASSING
Feature: [feature name]
Tests: X passed
Build: Success
========================================
```
