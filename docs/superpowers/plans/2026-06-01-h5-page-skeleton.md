# H5 Page Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first maintainable low-fidelity H5 page skeleton for MeuMall without rendering the native bottom Tab inside H5.

**Architecture:** Shared placeholder and layout components live under `hybird-meumall/src/components/commerce`. Page routes under `hybird-meumall/src/app` consume those components and use local mock data. Native owns the first-level Tab; H5 owns only content pages and internal secondary pages.

**Tech Stack:** Next.js App Router, React, TypeScript, Tailwind CSS v3, CSS variables.

---

## File Structure

- Modify `hybird-meumall/src/components/commerce/PageShell.tsx`: replace the old shell with `H5PageShell` semantics and remove bottom navigation.
- Modify `hybird-meumall/src/components/commerce/IconBlock.tsx`: keep compatibility, add placeholder-friendly naming.
- Create `hybird-meumall/src/components/commerce/PlaceholderMedia.tsx`: image/banner/avatar/QR placeholders.
- Create `hybird-meumall/src/components/commerce/SectionHeader.tsx`: reusable section title row.
- Create `hybird-meumall/src/components/commerce/ActionGrid.tsx`: reusable entry grid.
- Create `hybird-meumall/src/components/commerce/MetricCard.tsx`: reusable metric card.
- Create `hybird-meumall/src/components/commerce/LowFiPage.tsx`: shared low-fidelity page frame.
- Modify `hybird-meumall/src/components/commerce/ProductCard.tsx`: use placeholder media and support commission/action labels.
- Modify `hybird-meumall/src/lib/commerce/mock-data.ts`: update nav and mock data to match MeuMall, removing cart semantics.
- Modify or create route files under `hybird-meumall/src/app/**/page.tsx` for home, promotion, mine, agent placeholder, and secondary skeleton pages.
- Update H5 project AI state docs after implementation.

## Task 1: Shared Skeleton Components

**Files:**
- Modify: `hybird-meumall/src/components/commerce/PageShell.tsx`
- Modify: `hybird-meumall/src/components/commerce/IconBlock.tsx`
- Modify: `hybird-meumall/src/components/commerce/ProductCard.tsx`
- Create: `hybird-meumall/src/components/commerce/PlaceholderMedia.tsx`
- Create: `hybird-meumall/src/components/commerce/SectionHeader.tsx`
- Create: `hybird-meumall/src/components/commerce/ActionGrid.tsx`
- Create: `hybird-meumall/src/components/commerce/MetricCard.tsx`
- Create: `hybird-meumall/src/components/commerce/LowFiPage.tsx`

- [ ] Implement placeholder and shell components.
- [ ] Confirm no component renders a bottom Tab.
- [ ] Run `pnpm typecheck`.

## Task 2: Mock Data

**Files:**
- Modify: `hybird-meumall/src/lib/commerce/mock-data.ts`
- Test: `hybird-meumall/src/lib/commerce/mock-data.test.ts`

- [ ] Replace generic cart-era mock data with MeuMall page, product, promotion, member and order skeleton data.
- [ ] Update tests to assert no cart nav item exists.
- [ ] Run `pnpm test -- src/lib/commerce/mock-data.test.ts`.

## Task 3: Home And Commerce Pages

**Files:**
- Modify: `hybird-meumall/src/app/page.tsx`
- Modify: `hybird-meumall/src/app/category/page.tsx`
- Modify: `hybird-meumall/src/app/product/[id]/page.tsx`
- Create: `hybird-meumall/src/app/order-confirm/page.tsx`
- Create: `hybird-meumall/src/app/seckill/page.tsx`
- Create: `hybird-meumall/src/app/messages/page.tsx`
- Create: `hybird-meumall/src/app/consult/page.tsx`

- [ ] Build homepage content skeleton and commerce secondary skeletons.
- [ ] Ensure product detail links to order confirmation and consult placeholder.
- [ ] Ensure no Figma images or downloaded icons are used.

## Task 4: Promotion Pages

**Files:**
- Create: `hybird-meumall/src/app/promotion/page.tsx`
- Create: `hybird-meumall/src/app/promotion/products/page.tsx`
- Create: `hybird-meumall/src/app/promotion/commission/page.tsx`
- Create: `hybird-meumall/src/app/promotion/card/page.tsx`
- Create: `hybird-meumall/src/app/promotion/level/page.tsx`
- Create: `hybird-meumall/src/app/promotion/benefits/page.tsx`
- Create: `hybird-meumall/src/app/promotion/ranking/page.tsx`

- [ ] Build promotion first-level content skeleton.
- [ ] Build low-fidelity promotion secondary skeletons.
- [ ] Ensure commission text uses N+1 language and no realtime finality promise.

## Task 5: Mine And Account Pages

**Files:**
- Create: `hybird-meumall/src/app/mine/page.tsx`
- Modify: `hybird-meumall/src/app/profile/page.tsx`
- Create: `hybird-meumall/src/app/favorites/products/page.tsx`
- Create: `hybird-meumall/src/app/favorites/shops/page.tsx`
- Create: `hybird-meumall/src/app/member/page.tsx`
- Create: `hybird-meumall/src/app/orders/page.tsx`
- Create: `hybird-meumall/src/app/agent-placeholder/page.tsx`

- [ ] Build mine first-level content skeleton.
- [ ] Build low-fidelity favorites, member, orders and agent placeholder pages.
- [ ] Keep settings/account as low-fidelity or legacy-compatible content, not a first-level Tab.

## Task 6: Validation And Documentation

**Files:**
- Modify: `hybird-meumall/.ai/PROJECT_STATE.md`
- Modify: `hybird-meumall/.ai/CHANGE_SUMMARY.md`
- Modify: `hybird-meumall/.ai/TODO.md`
- Modify: `hybird-meumall/docs/08_CHANGELOG.md`
- Modify: `hybird-meumall/docs/09_DECISIONS.md`
- Create: `hybird-meumall/.ai/test-reports/2026-06-01-h5-page-skeleton.md`

- [ ] Run `pnpm typecheck`.
- [ ] Run `pnpm lint`.
- [ ] Run `pnpm test`.
- [ ] Run `pnpm build`.
- [ ] Run `pnpm run ai:check-workflow`.
- [ ] Record validation results in the test report.
