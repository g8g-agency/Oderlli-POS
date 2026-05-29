import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeSplashLayout extends StatelessWidget {
  final VoidCallback onLoginPressed;

  const WelcomeSplashLayout({super.key, required this.onLoginPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const brandRed = Color(0xFFBA0013); // POS red

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF191C1D) : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 384,
              height: 384,
              decoration: BoxDecoration(
                color: brandRed.withOpacity(0.05),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: brandRed.withOpacity(0.05),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900), // wider for tablet POS
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    children: [
                      // Header Section
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.point_of_sale_rounded, color: brandRed, size: 36),
                              const SizedBox(width: 12),
                              Text(
                                'Orderlyy ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: isDark ? Colors.white : const Color(0xFF191C1D),
                                ),
                              ),
                              Text(
                                'POS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: brandRed,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome to Orderlyy POS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF191C1D),
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Smart Billing Companion',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: brandRed,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Hero Mockup Section - Using BoxFit.contain so it is NOT zoomed
                      Expanded(
                        flex: 6,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: 1.25,
                              child: Image.asset(
                                'assets/images/pos_welcome.png',
                                fit: BoxFit.contain, // Prevents zooming and cropping
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Features Grid
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildFeatureCard(Icons.bolt_rounded, 'Fast\nBilling', isDark, brandRed),
                          _buildFeatureCard(Icons.splitscreen_rounded, 'Split\nPayments', isDark, brandRed),
                          _buildFeatureCard(Icons.sync_rounded, 'Live\nKitchen Sync', isDark, brandRed),
                          _buildFeatureCard(Icons.table_restaurant_rounded, 'Table\nManagement', isDark, brandRed),
                          _buildFeatureCard(Icons.receipt_long_rounded, 'Real-time\nOrders', isDark, brandRed),
                        ],
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Footer Action Section (CTA)
                      Column(
                        children: [
                          Text(
                            'Serve faster, bill smarter, and manage effortlessly.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF636467),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 320, // max width for button so it doesn't stretch too far on tablet
                            height: 60,
                            child: FilledButton(
                              onPressed: onLoginPressed,
                              style: FilledButton.styleFrom(
                                backgroundColor: brandRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                shadowColor: brandRed.withOpacity(0.4),
                              ),
                              child: Text(
                                'Login / Sign In',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'One POS system for your complete restaurant operations.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white54 : const Color(0xFF636467),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String label, bool isDark, Color brandRed) {
    return Container(
      width: 110,
      height: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E3132) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE1E3E4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF191C1D) : const Color(0xFFF3F4F5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: brandRed, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: isDark ? Colors.white : const Color(0xFF191C1D),
            ),
          ),
        ],
      ),
    );
  }
}
