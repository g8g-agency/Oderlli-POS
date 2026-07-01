async function test() {
  try {
    const loginRes = await fetch('http://localhost:3001/api/v1/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'testcafe.owner@test.com',
        password: 'Test@123456',
        device_fingerprint: 'pos-test-device-fingerprint',
      })
    });
    const loginData = await loginRes.json();
    const token = loginData.data.access_token;
    const branchId = '35817bed-f14f-4cff-b510-247a8a740beb';
    const tableId = '00000000-0000-0000-0000-000000000001';

    const qrRes = await fetch('http://localhost:3001/api/v1/admin/qr/codes', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        branch_id: branchId,
        table_id: tableId,
      })
    });
    const qrData = await qrRes.json();
    const signedPayload = qrData.data.signed_payload;
    console.log('Signed Payload:', signedPayload);

    const resolveRes = await fetch('http://localhost:3001/api/v1/qr/resolve', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        signed_payload: signedPayload,
        nonce: 'pos-test-nonce-' + Date.now(),
        device_fingerprint: 'pos-test-fingerprint-id',
      })
    });
    console.log('Resolve Status:', resolveRes.status);
    const resolveData = await resolveRes.json();
    console.log('Resolve Data:', resolveData);
  } catch (err) {
    console.error(err);
  }
}

test();
