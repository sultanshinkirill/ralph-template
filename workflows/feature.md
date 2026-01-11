---
description: Start a new feature with brainstorming and implementation
---

# /feature - Ralph Feature Development

## How to Use

```
/feature I want to add [your feature description in 10-30 sentences]
```

---

## Phase 1: Brainstorm (BEFORE any code)

Read the user's feature description.

**You MUST:**
1. Ask 5+ clarifying questions about edge cases, UX, and integration
2. Check existing code for conflicts
3. Propose 2-3 alternative approaches
4. Create @fix_plan.md with task breakdown
5. **Wait for user approval before coding**

---

## Phase 2: Ralph Loop (AFTER approval)

### Loop Structure

```
┌─────────────────────────────────────┐
│  1. Read @fix_plan.md               │
│     Find next uncompleted task      │
│                                     │
│  2. Implement                       │
│     Make targeted code changes      │
│                                     │
│  3. Verify                          │
│     Run: pnpm verify:fast           │
│                                     │
│  4. Update                          │
│     Mark task [x] or note blocker   │
│                                     │
│  5. Repeat until all [x]            │
└─────────────────────────────────────┘
```

### Verification Commands

// turbo
After EVERY code change:
```bash
pnpm safety:check    # MUST pass first
pnpm verify:fast     # safety + typecheck + e2e
```

// turbo
When all tasks complete:
```bash
pnpm verify:full     # Final verification + build
```

### Exit Conditions

Exit the loop when:
- All items in @fix_plan.md marked `[x]`
- `pnpm verify:full` passes
- Print: `ALL_TESTS_PASSING`

### Error Handling

If stuck on same error 3+ times:
1. Update @fix_plan.md with blocker
2. Ask human for input
3. Stop making the failing change

---

## Deliverables Checklist

- [ ] @fix_plan.md updated with tasks
- [ ] Database migrations (if needed)
- [ ] API routes (if needed)
- [ ] UI components
- [ ] Types in `lib/types.ts`
- [ ] Translations in `messages/fi.json`
- [ ] E2E test in `apps/web/e2e/[feature].spec.ts`
- [ ] Screenshots of new UI

---

## Completion Signal

```
========================================
ALL_TESTS_PASSING
Feature: [Feature Name]
Tests: X passed
Build: Success
========================================
```
