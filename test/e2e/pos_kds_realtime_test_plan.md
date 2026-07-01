═══════════════════════════════════════════════════════════════
  P1-1: POS → KDS REALTIME FLOW — TEST PLAN
═══════════════════════════════════════════════════════════════

── SETUP ──────────────────────────────────────────────────────

Prerequisites:
  - Backend running and accessible
  - Supabase realtime enabled on the orders table
  - KDS open in browser (Branch A)
  - POS tablet logged in with staff PIN (Branch A)
  - Audio not muted on KDS device
  - Browser console open on KDS tab (F12)

── TEST M1: HAPPY PATH ────────────────────────────────────────

Steps:
  1. On KDS: open browser console, run:
       window.__kdsOrderLog = [];
     This lets us capture incoming realtime events.

  2. On POS: select Table 3 → add 3 items → tap Checkout.
     Note the exact timestamp (T0) when Checkout is tapped.

  3. On KDS: note the timestamp (T1) when the new order card appears.

  4. VERIFY — all must pass:
     [ ] T1 - T0 < 2000ms (order appears within 2 seconds)
     [ ] Audio beep plays on KDS
     [ ] Order card shows "POS" badge (not "QR" or blank)
     [ ] Order card shows "Table 3" and correct item count
     [ ] Order status is "pending" or "new"

  5. On KDS: accept the order → mark it ready.
     VERIFY:
     [ ] Staff app receives a "ready" notification

── TEST M2: COUNTER ORDER ─────────────────────────────────────

  1. On POS: tap COUNTER / WALK-IN → add 2 items → Checkout.
  2. On KDS: VERIFY:
     [ ] Order appears within 2 seconds
     [ ] Order card shows "Counter" (not a table number)
     [ ] "POS" badge present
     [ ] Audio beep plays

── TEST M3: SOURCE BADGE VERIFICATION ─────────────────────────

In Supabase SQL editor, after each test order run:

  SELECT id, source, processed_by_staff_id, table_id, created_at
  FROM orders
  WHERE created_at > NOW() - INTERVAL '2 minutes'
  ORDER BY created_at DESC
  LIMIT 5;

  VERIFY:
  [ ] POS orders: source = 'pos', processed_by_staff_id IS NOT NULL
  [ ] Counter orders: table_id = '00000000-0000-0000-0000-000000000001'
  [ ] QR orders: source = 'qr_scan', processed_by_staff_id IS NULL

── TEST M4: DELIVERY RATE ─────────────────────────────────────

  1. Place 5 consecutive POS orders (table + counter mix).
  2. VERIFY:
     [ ] All 5 appear in KDS (0 lost)
     [ ] All 5 appear within 2 seconds
     [ ] All 5 play audio beep
  3. If any order is missed, see DEBUGGING section below.

── DEBUGGING: IF KDS DOES NOT RECEIVE POS ORDERS ──────────────

Step D1 — Check the Supabase realtime subscription filter.

  Find the KDS subscription in the codebase. It will look like:

    supabase
      .channel('orders')
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'orders',
        filter: `branch_id=eq.${branchId}`,  // ✅ correct
      }, callback)
      .subscribe();

  WRONG (silently drops POS orders):
    filter: `branch_id=eq.${branchId},source=eq.qr_scan`

  FIX: Remove any source= clause from the filter.
  The filter must only contain branch_id so both QR and POS
  orders are received.

Step D2 — Verify realtime is enabled on the orders table.

  In Supabase dashboard:
    Database → Replication → Tables
    Confirm "orders" table has realtime toggled ON.
  
  If not: enable it, then re-run TEST M1.

Step D3 — Check the INSERT event reaches Supabase at all.

  In Supabase dashboard → Logs → Realtime:
  After a POS checkout, look for an INSERT event on the orders
  table. If no event appears, the backend is not committing the
  order to the correct table or schema.

Step D4 — Check the KDS channel is subscribed before checkout.

  In browser console on KDS tab, run:
    supabase.getChannels().map(c => c.topic)
  
  Expect to see: 'realtime:public:orders' or similar.
  If the channel is missing, the KDS subscription is not
  initialising correctly — check component mount lifecycle.

Step D5 — Check audio beep is not silently failing.

  In KDS source, find the beep call (likely a new Audio() or
  Howler play). Wrap it in a try/catch and log errors:

    try {
      await audioPlayer.play();
    } catch (e) {
      console.error('KDS audio beep failed:', e);
    }

  Common cause: browser autoplay policy blocks audio until the
  user has interacted with the page. Fix by triggering a silent
  audio play on first user click to unlock the audio context.

── ACCEPTANCE CRITERIA (all must pass for P1-1 DONE) ──────────

  [ ] M1 passes: order in KDS < 2 seconds, beep, POS badge
  [ ] M2 passes: counter order shows correctly
  [ ] M3 passes: database source tagging correct
  [ ] M4 passes: 5/5 orders delivered, 0 lost
  [ ] No source= filter on KDS subscription
  [ ] Audio beep plays reliably (autoplay policy handled)

═══════════════════════════════════════════════════════════════
