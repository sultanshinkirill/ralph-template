# @AGENT.md - Build & Run Instructions

## Quick Commands

```bash
# Verification (Ralph Loop)
pnpm safety:check         # Check for prod credentials
pnpm typecheck            # TypeScript compilation check
pnpm test:e2e             # Run Playwright E2E tests
pnpm verify:fast          # safety + typecheck + e2e
pnpm verify:full          # verify:fast + production build

# Testing
pnpm test:e2e:ui          # Playwright UI mode (for debugging)
```

## Environment

Ensure your `.env.local` has test credentials:
- Stripe keys starting with `sk_test_` and `pk_test_`
- Local Supabase URL or dev project
- Twilio test credentials
