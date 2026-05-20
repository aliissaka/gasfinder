# Admin console — mobile responsiveness plan

## Status

The admin (Blazor Server, `admin/`) is built on Bootstrap 5 from the default
.NET scaffold. It is **usable** on phones (no broken layouts) but is **not
designed** for them: data-dense tables require horizontal scrolling, and the
filter rows on Stock/Users dominate vertical space on narrow screens.

This document captures the work needed to make the admin phone-first
without breaking the current desktop/tablet experience.

## What works today

- `admin/Components/Pages/Dashboard.razor` — tiles stack 1-up on `xs`, 3-up
  on `md`, 4-up on `lg`. Good as-is.
- `admin/Components/Pages/Login.razor` — narrow card, works on any width.
- All modals (add brand, reset PIN, change role, suspend retailer with
  reason, etc.) — Bootstrap modals are responsive by default.
- Sidebar nav (`admin/Components/Layout/NavMenu.razor`) — collapses into
  a hamburger toggle on small screens via the existing
  `.navbar-toggler` + `.nav-scrollable` pattern in `MainLayout.razor.css`.

## What needs work

### 1. Replace wide tables with card layouts on `xs`

Affected:
- `admin/Components/Pages/Retailers.razor`
- `admin/Components/Pages/Brands.razor`
- `admin/Components/Pages/Stock.razor`
- `admin/Components/Pages/Users.razor`

Each has 6-8 columns with a wide actions cell. `.table-responsive` adds
horizontal scrolling on mobile, which works but is fiddly (swipe sideways
to find the Approve button).

Approach: dual-render the row content. At `md` and up, keep the table.
At `xs/sm`, render each row as a Bootstrap card with:
- Title row: primary identifier (shop name / brand name / phone) + status badge
- Body: 2-3 lines of key metadata (phone, address, last update)
- Footer: action buttons stretched full width, or collapsed into a
  three-dot menu (`<details>` element or Bootstrap dropdown)

Bootstrap utility classes that help: `d-md-none` / `d-none d-md-block`
to switch between card and table renderings.

### 2. Filter row collapsing

Affected:
- `admin/Components/Pages/Stock.razor` (4 selects in `col-md-3`)
- `admin/Components/Pages/Users.razor` (role tabs + search input)

On `xs` these stack to 3-4 full-width rows, taking ~40% of the viewport
before any data shows.

Approach: wrap the filters in a collapsible Bootstrap accordion or a
`<details>` element labeled "Filters" with a count badge of active
filters. Default closed on `xs`, open on `md+`.

### 3. Per-row action overflow

Affected: same four list pages.

The Retailers row has 3 buttons (Approve / Reject / Move to Pending) plus
an expand chevron. At `xs` these wrap and consume two card-rows.

Approach: on `xs`, render only the primary action (e.g. Approve) inline,
and move the rest into a "More" dropdown. On `md+`, show all buttons as
today.

### 4. Modal sizing on `xs`

Affected: all modals.

Bootstrap modals default to centered with `max-width: 500px`. On phones
this is fine, but the Reason textarea on the Reject modal feels cramped.

Approach: add `.modal-dialog-scrollable` to long-content modals, and
ensure form controls use `inputmode` attributes where appropriate
(`tel` for phone fields, `numeric` for PIN — already done on PIN).

### 5. Touch targets

The Approve / Reject / chevron buttons use `btn-sm`. Bootstrap's small
buttons are ~28px tall — below the 44px recommended touch target.

Approach: on `xs`, drop `btn-sm` so buttons revert to default 38px+
height. Acceptable trade-off: slightly larger buttons on small screens.

## Suggested ordering

1. Retailers page (highest-frequency admin task — approve queue)
2. Users page (next most-used)
3. Stock page (data-dense, biggest improvement from cards)
4. Brands page (lowest frequency, smallest table)
5. Filter-row collapsing (cross-cutting, do last)

## Estimate

~1-2 hours of focused work to convert all four list pages. No backend
changes required — pure Razor + CSS.

## Acceptance criteria

- On iPhone SE (375px wide) viewport in DevTools, every page renders
  without horizontal scroll
- Every primary action (Approve / Reset PIN / etc.) is reachable
  within one tap from the relevant row's card
- Filter panels don't push the data below the fold on `xs`
- All existing desktop behavior unchanged (regression-test the table
  views at `>= md`)
