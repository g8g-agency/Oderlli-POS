# POS Deployment Scan & Test Scenarios
**Scanned:** June 12, 2026  
**Test Suite:** 28/28 ✅  
**Verdict:** ⚠️ CONDITIONAL GO — deploy with 1 blocker acknowledged, run all scenarios below before first real shift

---

## Deployment Verdict

```
┌─────────────────────────────────────────────────────────────────┐
│  ⚠️  CONDITIONAL GO FOR PILOT                                   │
│                                                                  │
│  The POS is functionally operational for a supervised pilot.     │
│  ONE gap must be understood before go-live:                      │
│                                                                  │
│  Payment records are stored in-memory only. They are NOT         │
│  sent to the backend. Restart the app = all payment records      │
│  for that session are gone. Reconcile cash drawer manually       │
│  until the payment API call is wired.                            │
│                                                                  │
│  Everything else — auth, ordering, cart, checkout, receipt,      │
│  split billing, floor plan, KDS flow, session lock — works.      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Full Screen-by-Screen Scan Results

### ✅ App Boot & Orientation
- Forces landscape, hides system UI (immersiveSticky) — correct for tablet POS
- `ProviderScope` → `InactivityScope` → `MaterialApp.router` — correctly wrapped
- Text scaling clamped 0.85–1.10 — safe for various Windows DPI settings
- **Status: READY**

---

### ✅ Step 1 — Organization Login (`/login`)
- Email + password form with regex validation
- `POST /auth/login` → stores `access_token`, `refresh_token`, `device_session_id` in `FlutterSecureStorage`
- Demo account buttons auto-fill credentials — **remove before prod or label clearly**
- Error shown as red SnackBar
- Loading spinner during request
- **Status: READY** ⚠️ Demo buttons visible on login screen — flag for pilot staff

---

### ✅ Step 2 — Branch Selection (`/select-branch`)
- Fetches `GET /tenants/current`, filters by `tenantId`
- Card grid with animated selection feedback
- "Switch Organization" back-button logs out cleanly
- Shows spinner if loading, error state with "Try Again" button
- **Status: READY**

---

### ✅ Step 3 — Employee PIN Login (`/employee-login`)
- Fetches staff list `GET /tenants/:id/staff?branchId=...` — keyed by tenantId+branchId, not on every auth tick (efficient)
- PIN keypad works with physical keyboard (digits, backspace, Enter, Escape) — important for desktop/tablet with keyboard
- Shake animation on wrong PIN with 1.2s error recovery
- Lock mode: shows locked user, allows same-user unlock OR manager override
- Manager override: tries the manager's staff profile from the staff list — **this uses the first manager in the list, not a specific manager PIN; may surprise staff if multiple managers exist**
- "LOGOUT ORGANIZATION" button visible — correct emergency exit
- **Status: READY** ⚠️ Manager override picks `firstWhere(manager)` — acceptable for pilot with 1 manager

---

### ✅ Dashboard (`/dashboard`)
- Shows today's revenue (served/completed orders only — correct)
- Avg order value, occupied tables, active orders
- Role-filtered: Server sees only assigned orders; Cashier sees billing queue; Manager sees all + quick actions
- Order cards pull from live `ordersProvider` (fetches on init, after checkout, and every 30s on floor)
- **Status: READY**

---

### ✅ Floor Plan (`/floor`)
- `liveTableStatusProvider` enriches table cards with live `billTotal` + `occupiedSince` from active orders
- Auto-refreshes tables + orders every 30 seconds
- Manual refresh button in top bar
- Section filter chips with horizontal scroll (no overflow)
- "COUNTER / WALK-IN" button → sentinel table ID `00000000-0000-0000-0000-000000000001`
- Backend `runtimeState` mapped: `FREE → available`, `ACTIVE_GUESTS → occupied`, `ORDERING → preparing`, `PAYMENT_PENDING → paymentPending`, `ASSISTANCE_REQUESTED → ready`
- Seat Guests, Manage Order Items, Request Bill, Proceed to Checkout, Vacate Table — all wired
- Server role blocked from "REQUEST BILL" and checkout paths — correct
- **Status: READY**

---

### ✅ Menu / New Order (`/menu`, `/pos/menu`)
- Fetches categories + menu items from backend (`/api/tenants/:tenantId/menu/branch/:branchId`)
- Category chips filter; search bar debounced
- Menu item cards show qty-in-cart badge, tap to add
- Right panel: `OrderCartPanel` shows live cart with totals
- Counter order header displays "Counter / Walk-in" correctly
- Hardcoded "Sarah Jenkins" and "Terminal 1" in `POSSidebar` footer — **these should come from `authProvider`, fix before multi-user scenarios**
- **Status: READY** ⚠️ Sidebar profile hardcoded to "Sarah Jenkins" — cosmetic, not functional

---

### ✅ Cart (`/cart`)
- OCC: `expectedCartRevision` sent with every mutation — 409 triggers auto-refresh + clear error
- Schema mismatch error caught and shown with retry button
- Modifiers toggle via delete+re-add pattern (backend limitation handled correctly)
- Table dropdown pre-fills from `activeTableIdProvider`
- "SEND TO KITCHEN" → `POST /api/v1/orders/checkout` with staff JWT — confirmed correct
- After checkout: clears cart, refreshes tables + orders, routes to `/floor`
- **Status: READY**

---

### ✅ Orders Screen (`/orders`)
- Tab-filtered view: All / Pending / Preparing / Ready / Served
- Count badges on tabs
- Order rows show table number, items list, total, elapsed time, waiter name
- No action buttons — passive display only (correct for cashier/server view)
- **Status: READY**

---

### ✅ Checkout Shell + Billing (`/checkout`)
- Left panel: receipt summary (items, subtotal, discount, tax, service charge, total)
- Billing screen: settlement status banner with progress bar
- Service charge presets: 0%, 10%, 15%
- Discount presets: 0%, 10%, 20%
- Discounts > 20% trigger `ManagerOverrideDialog` with PIN `1111` — confirmed correct
- Override logged to shift activity
- "PROCEED TO PAY" → `/checkout/payment`
- "COMPLETE SESSION" (after full payment) → prints receipt, clears table, routes to `/floor`
- **Status: READY**

---

### ✅ Payments Screen (`/checkout/payment`)
- Cash keypad with quick helpers (Exact Cash, ₹200, ₹500)
- Card tab: simulates terminal response (fake 1.2s delay) — **no real PX terminal integration; both card and UPI are simulated**
- UPI tab: shows QR placeholder
- Mixed payment: allocate Cash + Card + UPI portions
- Change due calculation shown in settlement preview
- `billNotifier.addPayment()` records locally and updates shift drawer
- ⚠️ **NO backend API call for payment — this is in-memory only**
- **Status: FUNCTIONAL BUT DATA NOT PERSISTED**

---

### ✅ Split Billing (`/checkout/split-billing`)
- Equal split: integer paise math with remainder on last guest — tested ✅
- By Items: assign items to guests, tax/service/discount applied proportionally
- Custom split: free-form amount entry with unallocated balance tracker
- Each guest has a Pay button → routes to `/checkout/payment?amount=X`
- **Status: READY**

---

### ✅ Refunds Screen (`/checkout/refund`)
- Manager-only access (server blocked at router level)
- Cashier requires manager override PIN
- Search by receipt ID → shows mock result (hardcoded ₹4230 VISA transaction)
- ⚠️ **Refund result is purely UI — no backend call, no real transaction reversal**
- Acceptable for pilot if refunds are manually processed and logged
- **Status: UI ONLY — manual process required**

---

### ✅ Session Lock / Inactivity
- 5-minute inactivity → locks terminal, clears cart, routes to employee login
- Pause/resume on app lifecycle (background → foreground resets timer)
- Avatar click in dashboard top bar also locks immediately
- "LOCK TERMINAL" in sidebar works
- **Status: READY**

---

### ✅ Token Refresh
- 401 → auto-refresh `POST /auth/refresh` with single-flight lock (no duplicate requests)
- Refresh fail → `_triggerSessionExpired()` → clears storage, forces re-login
- **Status: READY**

---

## Known Gaps Summary

| # | Gap | Severity | Workaround for Pilot |
|---|---|---|---|
| 1 | Payment records not sent to backend | 🔴 Blocking (data loss on app restart) | Don't restart app mid-shift; reconcile drawer manually |
| 2 | Card / UPI payment is simulated | 🟡 Operational | Accept cash only OR record card/UPI externally |
| 3 | Refund screen is UI-only | 🟡 Operational | Process all refunds via admin panel |
| 4 | Menu sidebar shows "Sarah Jenkins" hardcoded | 🟢 Cosmetic | Ignore for pilot |
| 5 | GSTIN / FSSAI null on receipts | 🟡 Compliance | Print receipts contain all other fields; add GSTIN manually if required |
| 6 | Kitchen screen route disabled | 🟡 Feature gap | Use separate KDS device (Staff App / table_os) |
| 7 | Demo account buttons on login screen | 🟢 Cosmetic | Brief pilot staff not to use them |

---

## Pre-Deployment Checklist

- [ ] Backend is running and reachable at `https://api.orderlyy.com`
- [ ] Database migrations applied (check for `relation does not exist` errors on first load)
- [ ] At least one staff account with PIN set up in the system
- [ ] Tables configured in the admin panel for the branch
- [ ] Menu items published for the branch
- [ ] Tablet is in landscape orientation lock
- [ ] App deployed in release mode (not debug) — `allowMockFallbackInDebug = false` confirmed
- [ ] Shift opened by manager before staff begin taking orders

---

## Test Scenarios

Run all scenarios in order before the first real shift. Each scenario lists the steps, what to check, and the expected result.

---

### 🔐 AUTH-01 — Full Login Flow (Happy Path)
**Pre-condition:** Backend running, valid org credentials available

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open app on tablet in landscape | Splash screen, then redirects to `/login` |
| 2 | Enter org email + password, tap Sign In | Loading spinner, then redirects to Branch Selection |
| 3 | Select the correct branch | "Initializing branch context..." → redirects to Employee Login |
| 4 | Select staff profile (e.g. Manager) | Profile highlighted with role color |
| 5 | Enter correct 4-digit PIN, tap SIGN IN | "Welcome back, [Name]!" → redirects to Dashboard |
| 6 | Verify dashboard shows branch name in header | Branch name appears in red next to "Dashboard" |

---

### 🔐 AUTH-02 — Wrong PIN
| Step | Action | Expected Result |
|---|---|---|
| 1 | On employee login, select any staff profile | Profile selected |
| 2 | Enter wrong 4-digit PIN | PIN dots turn red, shake animation plays, error text appears |
| 3 | After 1.2 seconds | PIN cleared, error text clears, ready for retry |

---

### 🔐 AUTH-03 — Session Lock & Unlock
| Step | Action | Expected Result |
|---|---|---|
| 1 | Login fully as cashier | Reach Dashboard |
| 2 | Click the avatar in top-right of dashboard | Terminal locks, redirects to Employee Login |
| 3 | Staff profile is pre-selected (locked user shown) | "Terminal Locked" header visible |
| 4 | Enter correct PIN | Unlocks, returns to Dashboard |

---

### 🔐 AUTH-04 — Inactivity Timeout
| Step | Action | Expected Result |
|---|---|---|
| 1 | Login fully, navigate to Floor Plan | Floor plan visible |
| 2 | Leave tablet untouched for 5 minutes | Terminal auto-locks, cart cleared, redirected to Employee Login |
| 3 | Enter PIN to unlock | Returns to Dashboard (not Floor Plan — correct behaviour) |

---

### 🍽️ ORDER-01 — Dine-In Table Order (Full Flow)
| Step | Action | Expected Result |
|---|---|---|
| 1 | Go to Floor Plan | Tables loaded from backend, statuses visible |
| 2 | Tap an Available table | Quick Actions panel opens on right |
| 3 | Tap "SEAT GUESTS" | Table status changes to Occupied |
| 4 | Tap "OPEN MENU BOOK" | Menu screen opens, table number shown in header |
| 5 | Tap 3–4 items to add to cart | Cart panel on right shows items and running total |
| 6 | Tap cart icon or "VIEW CART" | Cart screen opens with item list |
| 7 | Adjust modifier on one item (e.g. Extra Cheese) | Modifier toggles — item deleted and re-added in backend |
| 8 | Add a kitchen note "No onion" | Note saved on item |
| 9 | Tap "SEND TO KITCHEN" | Loading overlay, success SnackBar "Order dispatched to KDS" |
| 10 | Check Floor Plan | Table now shows Occupied/Ordering status and bill total |
| 11 | Check Orders screen | New order appears in Pending tab |

---

### 🛒 ORDER-02 — Counter / Walk-in Order
| Step | Action | Expected Result |
|---|---|---|
| 1 | Go to Floor Plan | Floor plan visible |
| 2 | Tap "COUNTER / WALK-IN" button | Menu screen opens, header shows "Counter / Walk-in" |
| 3 | Add 2 items, go to Cart | Cart shows correct items |
| 4 | Verify table dropdown shows "Counter" or sentinel ID | Counter order recognised |
| 5 | Tap "SEND TO KITCHEN" | Order dispatched, success SnackBar |

---

### 💳 CHECKOUT-01 — Cash Payment (Full Checkout)
| Step | Action | Expected Result |
|---|---|---|
| 1 | From Floor Plan, tap an Occupied table | Quick Actions panel opens |
| 2 | Tap "MANAGE ORDER ITEMS" → "SEND TO KITCHEN" (if not done) OR tap "REQUEST BILL / CHECKOUT" | Table status becomes Payment Pending |
| 3 | Tap "PROCEED TO CHECKOUT" | Checkout Shell opens with receipt on left |
| 4 | Review receipt items and total — verify amounts correct | Subtotal + 5% tax + 10% service charge = Total |
| 5 | Tap "PROCEED TO PAY" | Payment screen opens |
| 6 | On Cash tab, tap "Exact Cash" | Cash tendered fills to exact total |
| 7 | Tap "COMPLETE PAYMENT" | Success SnackBar, routes back to Billing |
| 8 | Billing screen shows "SETTLED" in green | Status bar is green, remaining = ₹0 |
| 9 | Tap "COMPLETE SESSION" | Receipt print dialog (mock), SnackBar "Session settled!", routes to Floor Plan |
| 10 | Check Floor Plan | Table is now Available |

---

### 💳 CHECKOUT-02 — Partial Cash + Remaining Cash (Two Payments)
| Step | Action | Expected Result |
|---|---|---|
| 1 | Go to Checkout for an occupied table | Checkout shell opens |
| 2 | Proceed to Pay → enter ₹100 cash | Change due shows correctly if total < ₹100 |
| 3 | Tap "COMPLETE PAYMENT" | Billing shows "PARTIALLY PAID", progress bar partially filled |
| 4 | Tap "PROCEED TO PAY" again | Remaining balance pre-filled |
| 5 | Complete remaining payment | "SETTLED" status |

---

### 💳 CHECKOUT-03 — Discount with Manager Override
| Step | Action | Expected Result |
|---|---|---|
| 1 | Go to Billing screen for any table | Billing screen visible |
| 2 | In discount section, tap "20%" | Discount applied immediately (≤ 20%, no dialog) |
| 3 | There is no "30%" preset, so test via: tap "20%" twice to check it toggles | Tap 0% to clear, verify |
| 4 | Manually test: to trigger override dialog, modify billing_screen.dart threshold to 10% temporarily OR note it triggers only on custom % > 20 (presets max at 20%) | ManagerOverrideDialog should appear |
| 5 | In dialog, enter PIN "1111" | Discount applied, override logged in shift |
| 6 | Enter wrong PIN in dialog | Dialog shows error, discount NOT applied |

> **Note for pilot:** Default presets are 0%, 10%, 20%. Manager override only triggers if custom percentages above 20% are added. Confirm with manager that 20% maximum is acceptable for pilot.

---

### 🔀 CHECKOUT-04 — Split Bill (Equal Split)
| Step | Action | Expected Result |
|---|---|---|
| 1 | Go to Billing screen | Billing screen visible |
| 2 | Tap "SPLIT BILL" | Split Billing screen opens |
| 3 | Keep Equal Split mode, set 3 guests | Three rows appear |
| 4 | Verify amounts sum exactly to total (check for ₹0.01 remainder on last guest) | Amounts sum correctly |
| 5 | Tap Pay button on Guest 1 | Redirects to payment screen with Guest 1's amount pre-filled |
| 6 | Complete cash payment for Guest 1 | Returns to Billing showing partial payment |
| 7 | Repeat for Guests 2 and 3 | All settled, table cleared |

---

### 📋 FLOOR-01 — Floor Plan Live Refresh
| Step | Action | Expected Result |
|---|---|---|
| 1 | Open Floor Plan on POS | Tables loaded |
| 2 | From another device (admin panel or Staff App), change a table's status | Wait up to 30 seconds |
| 3 | Observe Floor Plan without touching refresh | Table status updates automatically |
| 4 | Tap manual refresh button (↺ in top bar) | Immediate refresh, table states reload |

---

### 🔒 SECURITY-01 — Role Access Control
| Step | Action | Expected Result |
|---|---|---|
| 1 | Login as Server role | Dashboard shows "My Assigned Orders" only |
| 2 | Sidebar should NOT show "Shifts" | Shifts menu item hidden for server |
| 3 | Try navigating to `/checkout` directly | Redirected to Dashboard (server blocked) |
| 4 | Try navigating to `/settings` directly | Redirected to Dashboard |
| 5 | Login as Cashier | Can access checkout, cannot access Shifts/Settings |
| 6 | Login as Manager | All routes accessible |

---

### 💾 STABILITY-01 — App Restart Behaviour (Know Your Risk)
| Step | Action | Expected Result |
|---|---|---|
| 1 | Login fully, open an order, add items | Cart loaded |
| 2 | Force-close the app | App closes |
| 3 | Reopen app | Should restore session (auth tokens in FlutterSecureStorage persist) |
| 4 | Check if cart items are still visible | Cart reloads from backend via `loadCart()` on provider init |
| 5 | Complete a payment, then force-close app | ⚠️ Payment record is LOST (in-memory only) |
| 6 | Reopen — check Billing screen | Payment history is empty — table may still show as occupied |
| **Mitigation** | Do NOT restart app mid-payment | Complete the session fully before any restart |

---

### 🧾 RECEIPT-01 — Receipt Content Verification
| Step | Action | Expected Result |
|---|---|---|
| 1 | Complete a full checkout with a discount | Ready to print |
| 2 | Tap "COMPLETE SESSION" | Receipt print triggered |
| 3 | Review printed/previewed receipt for: restaurant name, branch, date/time, order number, cashier name, all items with quantities, subtotal, discount line, tax (5%), total, payment method, amount paid, change | All fields present |
| 4 | Verify GSTIN/FSSAI fields | Currently null — will be blank on receipt. Note for operator |

---

### ⚡ EDGE-01 — Backend Offline Behaviour
| Step | Action | Expected Result |
|---|---|---|
| 1 | Disconnect tablet from network | Network lost |
| 2 | Attempt to load Floor Plan | Error state shown: "Connection Error" with error message |
| 3 | Attempt to add a cart item | Error SnackBar: "Server is offline" (OfflineCartException) |
| 4 | Reconnect network | Tap refresh — data loads normally |
| 5 | `allowMockFallbackInDebug = false` confirmed | No mock data shown in production |

---

### ⚡ EDGE-02 — OCC Conflict (Two Terminals on Same Table)
| Step | Action | Expected Result |
|---|---|---|
| 1 | Open same table cart on two POS terminals simultaneously | Both show cart |
| 2 | Terminal A adds an item | Cart version bumps to v2 on backend |
| 3 | Terminal B (still on v1) tries to add an item | 409 Conflict received |
| 4 | Terminal B auto-refreshes cart | Shows OCC conflict message: "Cart updated by another terminal. Reloaded." |
| 5 | Terminal B retries adding the item | Succeeds on refreshed cart |

---

## Pilot Go/No-Go Sign-Off

| Check | Owner | Status |
|---|---|---|
| Backend deployed and `/health` returns 200 | Backend team | ☐ |
| Database migrations applied (no `relation does not exist` errors) | Backend team | ☐ |
| Staff PINs configured for all pilot employees | Admin | ☐ |
| Tables and menu published for pilot branch | Admin | ☐ |
| All 10 test scenarios above executed and passing | QA / Lead | ☐ |
| Payment reconciliation process documented (manual for pilot) | Manager | ☐ |
| App running in release mode on pilot tablet | Dev | ☐ |
| Manager on-site for first shift to handle edge cases | Operations | ☐ |

---

*Scan performed: June 12, 2026 — Orderlyy POS v1.0 Pilot Build*
