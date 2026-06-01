const fs = require('fs');
const path = require('path');

const file = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
let content = fs.readFileSync(file, 'utf8');

// 1. Add import for WelcomeSplashLayout
if (!content.includes("import 'welcome_splash_layout.dart';")) {
    content = content.replace(
        "import '../../providers/auth_provider.dart';", 
        "import '../../providers/auth_provider.dart';\nimport 'welcome_splash_layout.dart';"
    );
}

// 2. Remove unused imports
content = content.replace("import 'dart:math';\n", "");
content = content.replace("import 'dart:ui';\n", "");

// 3. Remove fields
content = content.replace(/  late final AnimationController _splashController;\n  late final AnimationController _floatController;\n  late final Animation<double> _logoAnim;\n  late final Animation<double> _headlineAnim;\n  late final Animation<double> _subtitleAnim;\n  late final Animation<double> _mockupAnim;\n  late final Animation<double> _featuresAnim;\n  late final Animation<double> _taglineAnim;\n  late final Animation<double> _buttonAnim;\n  late final Animation<double> _footerAnim;\n/g, '');

// 4. Remove initState block for splash
content = content.replace(/    \/\/ Splash and float animation controllers[\s\S]*?    _floatController\.repeat\(reverse: true\);\n/g, '');

// 5. Remove dispose
content = content.replace(/    _splashController\.dispose\(\);\n    _floatController\.dispose\(\);\n/g, '');

// 6. Replace the old UI
const oldSplashBlock = `    if (!_showPasscode) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _buildBgBlobs(),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: 48.h),
                child: Column(
                  children: [
                    _buildHeader(),
                    Gap(40.h),
                    _buildHeroSection(),
                    Gap(60.h),
                    _buildFeaturesGrid(),
                    Gap(60.h),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }`;

const newSplashBlock = `    if (!_showPasscode) {
      return WelcomeSplashLayout(
        onLoginPressed: () {
          setState(() {
            _showPasscode = true;
          });
        },
      );
    }`;

content = content.replace(oldSplashBlock, newSplashBlock);

// 7. Remove the old private methods for the splash UI:
// _buildBgBlobs, _buildHeader, _buildHeroSection, _buildFeaturesGrid, _buildFooter, _buildFoodCard, _buildDot, _buildSidebarIcon, _buildCartItemPlaceholder
const methodsToRemove = [
    /_buildBgBlobs\(\) \{[\s\S]*?return Stack\([\s\S]*?\}\n  \}/g,
    /_buildHeader\(\) \{[\s\S]*?return Column\([\s\S]*?\}\n  \}/g,
    /_buildHeroSection\(\) \{[\s\S]*?return AnimatedBuilder\([\s\S]*?\}\n  \}/g,
    /_buildDot\(Color color\) \{[\s\S]*?\}\n  \}/g,
    /_buildSidebarIcon\(IconData icon, \{bool isActive = false\}\) \{[\s\S]*?\}\n  \}/g,
    /_buildFoodCard\(String imageUrl\) \{[\s\S]*?\}\n  \}/g,
    /_buildCartItemPlaceholder\(\) \{[\s\S]*?\}\n  \}/g,
    /_buildFeaturesGrid\(\) \{[\s\S]*?return SlideTransition\([\s\S]*?\}\n  \}/g,
    /_buildFooter\(\) \{[\s\S]*?return SlideTransition\([\s\S]*?\}\n  \}/g
];

// Wait, the regexes for methods might be tricky because of nested braces. 
// It's safer to not delete them if it breaks, but flutter analyze will just say they are unused methods if we leave them.
// Let's see if we can use a simpler substring match or just leave the dead methods since they won't cause compile errors, only warnings.
// Actually, I can just use a simple state machine in JS to strip methods.

fs.writeFileSync(file, content);
console.log('Cleaned login_screen.dart');
