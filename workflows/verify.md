# Ralph Verification Workflow

## Quick Reference

```bash
# Fast check (during development)
pnpm verify:fast

# Full check (before commit/PR)
pnpm verify:full

# Individual commands
pnpm safety:check      # Check for prod credentials
pnpm typecheck         # TypeScript check
pnpm test:e2e          # Run all E2E tests
pnpm test:e2e:ui       # Playwright UI mode (for debugging)
```

---

## What Each Command Does

### `pnpm verify:fast`
1. **Safety tripwire** - Blocks if prod Stripe/Supabase detected
2. **TypeScript check** - Catches type errors
3. **Playwright E2E (Chromium)** - Basic smoke tests

### `pnpm verify:full`
1. All of `verify:fast` +
2. **Production build** - Ensures it builds for deployment

---

## Safety Tripwires

The `scripts/safety-check.js` script will **FAIL** if:

| Check | Fail Condition |
|-------|----------------|
| Stripe Secret Key | Starts with `sk_live_` |
| Stripe Publishable Key | Starts with `pk_live_` |
| Supabase URL | Points to known production project |

### Adding Production Project Ref

Edit `scripts/safety-check.js` and add your prod project ref:

```javascript
const PROD_PROJECT_REFS = [
  'your-prod-project-ref-here'  // Add this
];
```

---

## E2E Tests Location

```
apps/web/e2e/
├── smoke.spec.ts       # Basic page load tests
├── topup.spec.ts       # Payment flow tests (add later)
└── cockpit.spec.ts     # Creator cockpit tests (add later)
```

---

## For AI Agents (Ralph Loop)

### Mission Template

```markdown
MISSION: [Your feature description]

NON-NEGOTIABLE SAFETY RULES
1) Never use production Supabase/Stripe/Twilio
2) Run everything against local Supabase (resettable)
3) Do not print secrets in logs

RALPH LOOP BEHAVIOR
After EVERY code change, run: pnpm verify:fast
- If it fails, fix and repeat
- If it passes, run: pnpm verify:full
Only when both pass, you are allowed to finish.

COMPLETION PROMISE
Print exactly: ALL_TESTS_PASSING
Only after pnpm verify:full is green.
```

---

## Troubleshooting

### "Cannot find module '@playwright/test'"
```bash
pnpm install
pnpm exec playwright install chromium
```

### "Port 3000 in use"
```bash
lsof -ti:3000 | xargs kill -9
pnpm dev:web
```

### Playwright tests failing on CI
```bash
# Install browsers for CI
pnpm exec playwright install --with-deps chromium
```
