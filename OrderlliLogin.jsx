import React, { useState, useEffect } from 'react';

export default function OrderlliLogin() {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => {
      setMounted(true);
    }, 80);
    return () => clearTimeout(timer);
  }, []);

  // Mock table data for Tablet POS mockup
  const tables = [
    { num: 'T-01', amount: '₹2,840', status: 'active' },
    { num: 'T-02', amount: '₹1,250', status: 'ordering' },
    { num: 'T-03', amount: '₹4,120', status: 'billdue' },
    { num: 'T-04', amount: '₹0', status: 'open' },
    { num: 'T-05', amount: '₹1,890', status: 'active' },
    { num: 'T-06', amount: '₹0', status: 'open' },
    { num: 'T-07', amount: '₹3,034', status: 'billdue' },
    { num: 'T-08', amount: '₹950', status: 'ordering' },
    { num: 'T-09', amount: '₹3,410', status: 'active' },
    { num: 'T-10', amount: '₹0', status: 'open' },
    { num: 'T-11', amount: '₹2,150', status: 'active' },
    { num: 'T-12', amount: '₹680', status: 'ordering' }
  ];

  // Helper for table status top border color
  const getStatusColor = (status) => {
    switch (status) {
      case 'active': return '#FF7A00';
      case 'billdue': return '#EF4444';
      case 'ordering': return '#F59E0B';
      case 'open': return '#D1FAE5';
      default: return '#ECEAE4';
    }
  };

  // Mock line items for Phone bill preview mockup
  const billItems = [
    { name: 'Chicken Tikka', price: '₹760' },
    { name: 'Paneer Tikka', price: '₹320' },
    { name: 'Butter Chicken', price: '₹480' },
    { name: 'Dal Makhani', price: '₹280' },
    { name: 'Lamb Biryani', price: '₹550' }
  ];

  // Animation delay utility
  const getAnimStyle = (delayMs) => ({
    opacity: mounted ? 1 : 0,
    transform: mounted ? 'translateY(0)' : 'translateY(18px)',
    transition: 'opacity 0.55s ease, transform 0.55s ease',
    transitionDelay: `${delayMs}ms`
  });

  return (
    <div className="orderlli-wrapper">
      {/* CSS Injected Styles for Hover & Float Effects */}
      <style dangerouslySetInnerHTML={{ __html: `
        .orderlli-wrapper {
          font-family: 'Inter', -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          background-color: #F9F5F0;
          min-height: 100vh;
          width: 100%;
          display: flex;
          align-items: center;
          justify-content: center;
          position: relative;
          overflow-x: hidden;
          margin: 0;
          padding: 24px 16px;
          box-sizing: border-box;
        }

        .orderlli-blob {
          position: fixed;
          border-radius: 50%;
          pointer-events: none;
          z-index: 0;
          filter: blur(60px);
          -webkit-filter: blur(60px);
        }

        .orderlli-card {
          background-color: #FFFFFF;
          border-radius: 28px;
          max-width: 400px;
          width: 100%;
          padding: 32px;
          box-shadow: 0px 20px 40px rgba(255, 122, 0, 0.05);
          z-index: 10;
          display: flex;
          flex-direction: column;
          box-sizing: border-box;
        }

        .orderlli-logo-row {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 10px;
          margin-bottom: 24px;
        }

        .orderlli-logo-box {
          width: 42px;
          height: 42px;
          background-color: #FF7A00;
          border-radius: 11px;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0px 4px 16px rgba(255, 122, 0, 0.40);
        }

        .orderlli-logo-text {
          font-size: 24px;
          font-weight: 800;
          color: #111827;
          letter-spacing: -0.03em;
          line-height: 1;
        }

        .orderlli-logo-text-pos {
          color: #FF7A00;
        }

        .orderlli-headline {
          font-size: 20px;
          font-weight: 700;
          color: #111827;
          text-align: center;
          margin: 0 0 4px 0;
          line-height: 1.2;
        }

        .orderlli-subtitle {
          font-size: 14px;
          font-weight: 600;
          color: #FF7A00;
          text-align: center;
          margin: 0 0 28px 0;
          line-height: 1.2;
        }

        .orderlli-mockup-container {
          position: relative;
          height: 220px;
          width: 100%;
          margin-bottom: 28px;
        }

        .orderlli-tablet {
          position: absolute;
          left: 0;
          top: 10px;
          width: 72%;
          z-index: 1;
          background-color: #1A1A1E;
          border-radius: 14px;
          padding: 5px 5px 7px 5px;
          box-shadow: 0 12px 24px rgba(0,0,0,0.12);
          box-sizing: border-box;
          animation: orderlli-tablet-float 6s ease-in-out infinite;
        }

        .orderlli-tablet-screen {
          background-color: #FFFFFF;
          border-radius: 10px;
          overflow: hidden;
          display: flex;
          flex-direction: column;
          height: 142px;
          box-sizing: border-box;
        }

        .orderlli-tablet-header {
          height: 16px;
          background-color: #FFFFFF;
          border-bottom: 0.5px solid #ECEAE4;
          display: flex;
          align-items: center;
          padding: 0 6px;
          justify-content: space-between;
          box-sizing: border-box;
        }

        .orderlli-dots {
          display: flex;
          gap: 2.5px;
          align-items: center;
        }

        .orderlli-dot {
          width: 4px;
          height: 4px;
          border-radius: 50%;
        }

        .orderlli-dot.red { background-color: #EF4444; }
        .orderlli-dot.yellow { background-color: #F59E0B; }
        .orderlli-dot.green { background-color: #10B981; }

        .orderlli-tablet-title {
          font-size: 7px;
          font-weight: 700;
          color: #111827;
          display: flex;
          align-items: center;
          gap: 3px;
        }

        .orderlli-tablet-body {
          background-color: #F5F4F0;
          flex-grow: 1;
          padding: 4px;
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          grid-template-rows: repeat(3, 1fr);
          gap: 3.5px;
          box-sizing: border-box;
        }

        .orderlli-table-card {
          background-color: #FFFFFF;
          border-radius: 3px;
          padding: 2.5px;
          display: flex;
          flex-direction: column;
          justify-content: space-between;
          box-shadow: 0px 1px 2px rgba(0,0,0,0.02);
          box-sizing: border-box;
        }

        .orderlli-table-num {
          font-size: 6px;
          font-weight: 700;
          color: #111827;
          line-height: 1;
        }

        .orderlli-table-val {
          font-size: 5px;
          font-weight: 600;
          color: #6B7280;
          text-align: right;
          line-height: 1;
        }

        .orderlli-tablet-footer {
          height: 14px;
          background-color: #111827;
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 0 6px;
          box-sizing: border-box;
        }

        .orderlli-tablet-footer-left {
          font-size: 5px;
          color: #9CA3AF;
          font-weight: 500;
        }

        .orderlli-tablet-footer-right {
          display: flex;
          align-items: center;
          gap: 3px;
        }

        .orderlli-tablet-footer-val {
          font-size: 5px;
          color: #FF7A00;
          font-weight: 700;
        }

        .orderlli-tablet-footer-indicator {
          width: 3px;
          height: 3px;
          background-color: #10B981;
          border-radius: 50%;
        }

        .orderlli-phone {
          position: absolute;
          right: 0;
          top: 30px;
          width: 38%;
          z-index: 2;
          background-color: #1A1A1E;
          border-radius: 16px;
          padding: 5px;
          box-shadow: 0 16px 32px rgba(0,0,0,0.20);
          box-sizing: border-box;
          animation: orderlli-phone-float 6s ease-in-out infinite;
          animation-delay: 0.8s;
        }

        .orderlli-phone-screen {
          background-color: #FFFFFF;
          border-radius: 12px;
          overflow: hidden;
          display: flex;
          flex-direction: column;
          height: 162px;
          box-sizing: border-box;
        }

        .orderlli-phone-header {
          background-color: #FF7A00;
          height: 18px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 0 6px;
          box-sizing: border-box;
        }

        .orderlli-phone-bill {
          font-size: 6px;
          font-weight: 700;
          color: #FFFFFF;
        }

        .orderlli-phone-table {
          font-size: 5.5px;
          font-weight: 600;
          color: rgba(255,255,255,0.75);
        }

        .orderlli-phone-body {
          flex-grow: 1;
          padding: 4px 6px;
          display: flex;
          flex-direction: column;
          justify-content: space-between;
          box-sizing: border-box;
        }

        .orderlli-phone-items-list {
          display: flex;
          flex-direction: column;
        }

        .orderlli-phone-item {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 3.5px 0;
          border-bottom: 0.5px solid #F3F4F6;
          box-sizing: border-box;
        }

        .orderlli-phone-item-name {
          font-size: 5.5px;
          font-weight: 600;
          color: #111827;
        }

        .orderlli-phone-item-price {
          font-size: 5px;
          font-weight: 500;
          color: #374151;
        }

        .orderlli-phone-total-bar {
          background-color: #111827;
          height: 15px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 0 6px;
          box-sizing: border-box;
          margin-top: auto;
        }

        .orderlli-phone-total-label {
          font-size: 5.5px;
          font-weight: 700;
          color: #FFFFFF;
        }

        .orderlli-phone-total-val {
          font-size: 5.5px;
          font-weight: 700;
          color: #FF7A00;
        }

        .orderlli-phone-settle-bar {
          background-color: #FF7A00;
          height: 16px;
          display: flex;
          align-items: center;
          justify-content: center;
          box-sizing: border-box;
        }

        .orderlli-phone-settle-text {
          font-size: 5.5px;
          font-weight: 700;
          color: #FFFFFF;
        }

        .orderlli-features-row {
          display: flex;
          gap: 8px;
          width: 100%;
          margin-bottom: 24px;
          box-sizing: border-box;
        }

        .orderlli-feature-card {
          flex: 1;
          background-color: #FFF8F3;
          border: 1.5px solid #FFE4CC;
          border-radius: 12px;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          padding: 10px 4px;
          box-sizing: border-box;
          cursor: pointer;
          transition: border-color 0.2s ease, transform 0.2s ease;
        }

        .orderlli-feature-card:hover {
          border-color: #FF7A00;
          transform: translateY(-2px);
        }

        .orderlli-feature-label {
          font-size: 10px;
          font-weight: 500;
          color: #374151;
          margin-top: 6px;
          text-align: center;
          white-space: nowrap;
        }

        .orderlli-tagline {
          font-size: 13px;
          color: #6B7280;
          text-align: center;
          margin: 0 0 20px 0;
          line-height: 1.4;
        }

        .orderlli-btn {
          width: 100%;
          padding: 15px;
          background-color: #FF7A00;
          border: none;
          border-radius: 14px;
          color: #FFFFFF;
          font-size: 16px;
          font-weight: 700;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          cursor: pointer;
          box-shadow: 0 4px 20px rgba(255, 122, 0, 0.40);
          transition: opacity 0.2s ease, transform 0.2s ease;
          box-sizing: border-box;
        }

        .orderlli-btn:hover {
          opacity: 0.92;
          transform: translateY(-1px);
        }

        .orderlli-btn:active {
          transform: translateY(1px);
        }

        .orderlli-footer {
          font-size: 12px;
          color: #9CA3AF;
          text-align: center;
          margin-top: 14px;
          line-height: 1.2;
        }

        @keyframes orderlli-tablet-float {
          0%, 100% { transform: translateY(0px) rotate(-1deg); }
          50% { transform: translateY(-8px) rotate(-0.5deg); }
        }

        @keyframes orderlli-phone-float {
          0%, 100% { transform: translateY(0px) rotate(1deg); }
          50% { transform: translateY(-10px) rotate(2deg); }
        }
      ` }} />

      {/* Background Depth Blobs */}
      <div className="orderlli-blob" style={{
        left: '-50px',
        top: '-50px',
        width: '340px',
        height: '340px',
        backgroundColor: 'rgba(255, 122, 0, 0.10)',
        filter: 'blur(60px)'
      }} />
      <div className="orderlli-blob" style={{
        right: '-50px',
        top: '-30px',
        width: '220px',
        height: '220px',
        backgroundColor: 'rgba(255, 180, 120, 0.12)',
        filter: 'blur(50px)'
      }} />
      <div className="orderlli-blob" style={{
        right: '-60px',
        bottom: '-50px',
        width: '280px',
        height: '280px',
        backgroundColor: 'rgba(255, 122, 0, 0.07)',
        filter: 'blur(70px)'
      }} />

      {/* Card Content wrapper */}
      <div className="orderlli-card">
        {/* LOGO ROW */}
        <div className="orderlli-logo-row" style={getAnimStyle(0)}>
          <div className="orderlli-logo-box">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M18 6L6 18" />
              <path d="M16 4l4 4" />
              <path d="M6 6L18 18" />
              <path d="M4 8l4-4" />
            </svg>
          </div>
          <div className="orderlli-logo-text">
            Orderlli<span className="orderlli-logo-text-pos"> POS</span>
          </div>
        </div>

        {/* HEADLINES */}
        <h1 className="orderlli-headline" style={getAnimStyle(80)}>
          Welcome to Orderlli POS
        </h1>
        <p className="orderlli-subtitle" style={getAnimStyle(130)}>
          Your Restaurant Command Center
        </p>

        {/* MOCKUP VISUALIZATION */}
        <div className="orderlli-mockup-container" style={getAnimStyle(200)}>
          {/* Tablet Frame Mockup */}
          <div className="orderlli-tablet">
            <div className="orderlli-tablet-screen">
              {/* Header Bar */}
              <div className="orderlli-tablet-header">
                <div className="orderlli-dots">
                  <div className="orderlli-dot red" />
                  <div className="orderlli-dot yellow" />
                  <div className="orderlli-dot green" />
                </div>
                <div className="orderlli-tablet-title">
                  <svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="#FF7A00" strokeWidth="2.5">
                    <circle cx="12" cy="12" r="10" />
                  </svg>
                  Floor Management
                </div>
                <div style={{ width: 14 }} />
              </div>

              {/* Grid Area */}
              <div className="orderlli-tablet-body">
                {tables.map((t, idx) => (
                  <div
                    key={idx}
                    className="orderlli-table-card"
                    style={{ borderTop: `1.5px solid ${getStatusColor(t.status)}` }}
                  >
                    <span className="orderlli-table-num">{t.num}</span>
                    <span className="orderlli-table-val">{t.amount}</span>
                  </div>
                ))}
              </div>

              {/* Dark Footer Bar */}
              <div className="orderlli-tablet-footer">
                <div className="orderlli-tablet-footer-left">14/18 Tables</div>
                <div className="orderlli-tablet-footer-right">
                  <span className="orderlli-tablet-footer-val">₹48.2K Today</span>
                  <div className="orderlli-tablet-footer-indicator" />
                </div>
              </div>
            </div>
          </div>

          {/* Overlapping Phone Frame Mockup */}
          <div className="orderlli-phone">
            <div className="orderlli-phone-screen">
              {/* Header Bar */}
              <div className="orderlli-phone-header">
                <span className="orderlli-phone-bill">Bill #2847</span>
                <span className="orderlli-phone-table">T-07</span>
              </div>

              {/* Order list and Bill content */}
              <div className="orderlli-phone-body">
                <div className="orderlli-phone-items-list">
                  {billItems.map((item, idx) => (
                    <div className="orderlli-phone-item" key={idx}>
                      <span className="orderlli-phone-item-name">{item.name}</span>
                      <span className="orderlli-phone-item-price">{item.price}</span>
                    </div>
                  ))}
                </div>

                {/* Dark Total Strip */}
                <div className="orderlli-phone-total-bar">
                  <span className="orderlli-phone-total-label">Total</span>
                  <span className="orderlli-phone-total-val">₹3,034</span>
                </div>

                {/* Bottom Settle Button Mockup */}
                <div className="orderlli-phone-settle-bar">
                  <span className="orderlli-phone-settle-text">Settle Payment</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* FEATURE CARDS ROW */}
        <div className="orderlli-features-row" style={getAnimStyle(300)}>
          {/* Card 1: Floor Map */}
          <div className="orderlli-feature-card">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#FF7A00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <polygon points="3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21" />
              <line x1="9" y1="3" x2="9" y2="18" />
              <line x1="15" y1="6" x2="15" y2="21" />
            </svg>
            <span className="orderlli-feature-label">Floor Map</span>
          </div>

          {/* Card 2: New Orders */}
          <div className="orderlli-feature-card">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#FF7A00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="9" cy="21" r="1" />
              <circle cx="20" cy="21" r="1" />
              <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6" />
              <line x1="12" y1="9" x2="18" y2="9" />
              <line x1="15" y1="6" x2="15" y2="12" />
            </svg>
            <span className="orderlli-feature-label">New Orders</span>
          </div>

          {/* Card 3: Billing */}
          <div className="orderlli-feature-card">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#FF7A00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <rect x="2" y="5" width="20" height="14" rx="2" ry="2" />
              <line x1="2" y1="10" x2="22" y2="10" />
            </svg>
            <span className="orderlli-feature-label">Billing</span>
          </div>

          {/* Card 4: Kitchen */}
          <div className="orderlli-feature-card">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#FF7A00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M6 18V20a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V18" />
              <path d="M12 2A7 7 0 0 0 5.07 9.1A4.5 4.5 0 0 0 7.5 17h9a4.5 4.5 0 0 0 2.43-7.9A7 7 0 0 0 12 2z" />
            </svg>
            <span className="orderlli-feature-label">Kitchen</span>
          </div>

          {/* Card 5: Live Sync */}
          <div className="orderlli-feature-card">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#FF7A00" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l.73-.73" />
            </svg>
            <span className="orderlli-feature-label">Live Sync</span>
          </div>
        </div>

        {/* TAGLINE */}
        <p className="orderlli-tagline" style={getAnimStyle(370)}>
          Manage tables, orders, and settlements in real-time.
        </p>

        {/* CTA BUTTON */}
        <button
          className="orderlli-btn"
          style={getAnimStyle(430)}
          onClick={() => {
            alert('Orderlli POS: Auth Flow Triggered');
          }}
        >
          Login / Sign Up
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <line x1="5" y1="12" x2="19" y2="12" />
            <polyline points="12 5 19 12 12 19" />
          </svg>
        </button>

        {/* FOOTER */}
        <div className="orderlli-footer" style={getAnimStyle(500)}>
          One app for all your restaurant operations.
        </div>
      </div>
    </div>
  );
}
