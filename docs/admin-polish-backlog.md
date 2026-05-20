# Admin console — design polish backlog

## Status

The admin console (`admin/`) is functionally complete and live in production
on Render. It uses pure Bootstrap 5 defaults from the .NET Blazor scaffold
with no custom branding. Looks like a competent internal tool, not a
polished product. Acceptable for the pilot where the admin team is
the only audience. Worth investing in if/when the admin is shown to
external stakeholders (partners, regulators, investors) or evolved into
a customer-facing retailer portal.

This is a tracker of polish items, ordered by impact/effort ratio.

## Quick wins (~2 hours total)

### 1. Bootstrap Icons aren't actually loaded

The scaffold's `NavMenu.razor` references icon classes like
`bi-house-door-fill-nav-menu` that don't render because Bootstrap Icons
CSS is never imported. The nav currently shows no icons.

Fix: add `<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" />`
to `admin/Components/App.razor`, or vendor the package locally. Then
swap the placeholder `bi-house-door-fill-nav-menu` etc. for real
icons like `bi-speedometer2` (Dashboard), `bi-people` (Retailers),
`bi-tag` (Brands), `bi-box-seam` (Stock), `bi-person-gear` (Users).

### 2. Brand color + logo

Pick a brand palette suited to LPG/cooking-gas — orange flame or deep
teal both work. Define as CSS variables in `wwwroot/app.css`:

```css
:root {
  --gasfinder-primary: #E85D04; /* example flame orange */
  --gasfinder-primary-dark: #C44604;
  --bs-primary: var(--gasfinder-primary);
}
```

Replace the text "GasFinder.Admin" in `NavMenu.razor` with a small
inline SVG logo + text. Update favicon at `wwwroot/favicon.png`.

### 3. Loading states

Replace `<p>Loading...</p>` placeholders with Bootstrap placeholder
skeletons (rows of `.placeholder-glow` boxes the same shape as the
real content). Affected files:
- `admin/Components/Pages/Dashboard.razor`
- `admin/Components/Pages/Retailers.razor`
- `admin/Components/Pages/Brands.razor`
- `admin/Components/Pages/Stock.razor`
- `admin/Components/Pages/Users.razor`

## Medium effort (~3 hours total)

### 4. Toast notifications for actions

All feedback is inline `alert-danger` boxes today. Successful actions
silently refresh. Add a `ToastService` (scoped DI) and a `<ToastHost />`
component in `MainLayout.razor`. Trigger on:
- Successful brand create/update/delete
- Successful retailer status change ("Approved Test LPG Depot")
- Successful PIN reset / role change
- Failed actions (replace inline alerts)

### 5. Empty states

When a list is empty, show an illustration (or icon) plus a helpful
next step. e.g. "No retailers waiting for approval" with a small
checkmark icon, not just a grey paragraph.

### 6. Microcopy + helper text

Every form field could benefit from a placeholder example and a
`form-text` helper:
- Brand logo URL: placeholder `https://cdn.example.com/totalgas.png`,
  helper "Square logos look best (recommended 256×256)"
- Retailer rejection reason: helper "Be specific — the retailer sees
  this in their app if rejected"
- PIN reset: helper "Tell the user the new PIN via SMS or phone call"

### 7. Confirmation toasts after destructive actions

Brand delete and retailer suspend currently just refresh silently.
Toast confirming the action ("Test LPG Depot suspended") gives users
a reversibility cue and a chance to spot mistakes.

## Larger investments

### 8. Dark mode

Bootstrap 5.3+ ships built-in dark mode via `data-bs-theme="dark"`.
Add a toggle in the navbar that persists via localStorage. Most pages
will work out of the box; check badge contrast and the activity-feed
tables.

### 9. Accessibility audit

Run Lighthouse / axe on every page. Likely finds:
- Color contrast on warning badges (`bg-warning text-dark` is borderline)
- Missing `aria-label` on icon-only buttons
- Focus rings hidden by Bootstrap's default styles in some places
- Modal focus-trap may not be set up for our custom modals (not using
  Bootstrap JS — pure Razor)

### 10. Customer-facing retailer portal split

Long term, if retailers ever sign in to a web portal (vs. only the
Flutter retailer app), the current admin console isn't the right
shape. A retailer would want their own dashboard, not an admin queue.
Worth a separate Blazor project if that need materializes.

## Acceptance criteria for "production-polished"

- A new user opening the admin without context recognizes it as a
  designed product, not a scaffold
- Every action gives explicit feedback (toast)
- Every empty/loading state is intentional, not blank
- Brand identity is consistent across nav, favicon, login card, footer
- Lighthouse score ≥ 90 in Accessibility and Best Practices
