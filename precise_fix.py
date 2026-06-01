import re

with open('lib/screens/login/login_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add import
code = code.replace("import '../../providers/auth_provider.dart';", "import '../../providers/auth_provider.dart';\nimport 'welcome_splash_layout.dart';")

# 2. Remove unused imports
code = code.replace("import 'dart:math';\n", "")
code = code.replace("import 'dart:ui';\n", "")

# 3. Remove variables
code = re.sub(r'  late final AnimationController _splashController;\n  late final AnimationController _floatController;\n  late final Animation<double> _logoAnim;\n  late final Animation<double> _headlineAnim;\n  late final Animation<double> _subtitleAnim;\n  late final Animation<double> _mockupAnim;\n  late final Animation<double> _featuresAnim;\n  late final Animation<double> _taglineAnim;\n  late final Animation<double> _buttonAnim;\n  late final Animation<double> _footerAnim;\n', '', code)

# 4. Remove initState block
code = re.sub(r'    // Splash and float animation controllers\n    _splashController = AnimationController\([\s\S]*?    _floatController\.repeat\(reverse: true\);\n', '', code)

# 5. Remove dispose
code = code.replace("    _splashController.dispose();\n    _floatController.dispose();\n", "")

# 6. Replace the entire block from "// ── Background Blobs" to the end of the file, because we know all the old methods are at the end, except we don't want to delete `_buildPasscodeLayout`!
# Wait, `_buildPasscodeLayout` is ABOVE `_buildBgBlobs`!
# Line 1110 is `_buildPasscodeLayout`.
# Line 1153 is `// ── Background Blobs ────────────────────────────────────────────────────────`
# All the unused methods and the old splash screen layout are below line 1153.
# Let's verify that nothing important comes after them. We can just regex replace from `  // ── Background Blobs` to the end of the class.

new_splash = """  Widget _buildSplashLayout(BuildContext context) {
    return WelcomeSplashLayout(
      onLoginPressed: () {
        setState(() {
          _showPasscode = true;
        });
      },
    );
  }
}
"""

code = re.sub(r'  // ── Background Blobs ──[\s\S]*\Z', new_splash, code)

with open('lib/screens/login/login_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Done")
