# Ralph Template

A customizable verification and safety system for AI-assisted development.

## Quick Install

### Option 1: Clone into your project
```bash
cd your-project
git clone https://github.com/YOUR_USERNAME/ralph-template .ralph-temp
cp -r .ralph-temp/templates/* .
cp -r .ralph-temp/scripts ./scripts
rm -rf .ralph-temp
```

### Option 2: Use setup script
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/ralph-template/main/install.sh | bash
```

## What You Get

```
your-project/
├── PROMPT.md           # Ralph loop instructions
├── @fix_plan.md        # Task tracking
├── @AGENT.md           # Build/run commands
├── status.json         # Status tracking
├── scripts/
│   └── safety-check.js # Production safety tripwire
├── .agent/workflows/
│   ├── feature.md      # /feature command
│   └── verify.md       # /verify command
└── playwright.config.ts # E2E test config
```

## Usage

### Start a Feature
```
/feature I want to add [your 10-30 sentence description]
```

Ralph will:
1. Ask clarifying questions
2. Create @fix_plan.md with tasks
3. Wait for approval
4. Loop: Implement → Verify → Update → Repeat
5. Exit when all tasks complete

### Verify Commands
```bash
pnpm safety:check   # Check for prod credentials
pnpm verify:fast    # Safety + TypeCheck + E2E
pnpm verify:full    # verify:fast + Build
```

## Customization

### Safety Tripwires
Edit `scripts/safety-check.js` to add your production project refs:

```javascript
const PROD_PROJECT_REFS = [
  'your-prod-supabase-ref'
];
```

### package.json Scripts
Add these to your project's package.json:

```json
{
  "scripts": {
    "safety:check": "node scripts/safety-check.js",
    "typecheck": "tsc --noEmit",
    "test:e2e": "playwright test",
    "verify:fast": "pnpm safety:check && pnpm typecheck && pnpm test:e2e",
    "verify:full": "pnpm verify:fast && pnpm build"
  }
}
```

## License

MIT
