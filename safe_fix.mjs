import fs from 'fs';
import path from 'path';

const file = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
let content = fs.readFileSync(file, 'utf-8');

// 1. Add import
if (!content.includes("import 'welcome_splash_layout.dart';")) {
  content = content.replace("import '../../providers/auth_provider.dart';", "import '../../providers/auth_provider.dart';\nimport 'welcome_splash_layout.dart';");
}

// 2. Remove fields
const toRemoveAnims = [
  '  late final AnimationController _splashController;\n',
  '  late final AnimationController _floatController;\n',
  '  late final Animation<double> _logoAnim;\n',
  '  late final Animation<double> _headlineAnim;\n',
  '  late final Animation<double> _subtitleAnim;\n',
  '  late final Animation<double> _mockupAnim;\n',
  '  late final Animation<double> _featuresAnim;\n',
  '  late final Animation<double> _taglineAnim;\n',
  '  late final Animation<double> _buttonAnim;\n',
  '  late final Animation<double> _footerAnim;\n'
];
for (const str of toRemoveAnims) {
  content = content.replace(str, '');
}

// 3. Clean initState chunk
const initBlockOriginal = `    // Splash and float animation controllers
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (kIsWeb) {
      _floatController.repeat();
    } else {
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        _floatController.repeat();
      }
    }

    _logoAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _headlineAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.08, 0.63, curve: Curves.easeOut),
    );
    _subtitleAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.13, 0.68, curve: Curves.easeOut),
    );
    _mockupAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.20, 0.75, curve: Curves.easeOut),
    );
    _featuresAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.30, 0.85, curve: Curves.easeOut),
    );
    _taglineAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.37, 0.92, curve: Curves.easeOut),
    );
    _buttonAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.43, 0.98, curve: Curves.easeOut),
    );
    _footerAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_showPasscode) {
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) {
            _splashController.forward();
          }
        });
      }
    });`;

content = content.replace(initBlockOriginal, '');

// 4. Remove dispose lines
content = content.replace('    _splashController.dispose();\n', '');
content = content.replace('    _floatController.dispose();\n', '');

// 5. Remove _splashController.forward(from: 0);
content = content.replace('                          _splashController.forward(from: 0);\n', '');
content = content.replace('                          _splashController.forward(from: 0);\n', ''); // if multiple
content = content.replace('_splashController.forward(from: 0);', '');

// 6. Replace _buildBgBlobs ... _buildFeatureCards
const cutStart = content.indexOf('  // ── Background Blobs ────────────────────────────────────────────────────────');
const posLogo = content.indexOf('// _PosLogo');
const endOfClass = content.lastIndexOf('}', posLogo);

if (cutStart !== -1 && posLogo !== -1) {
    const newSplash = `  // ── Splash Screen Layout ─────────────────────────────────────────────────────
  Widget _buildSplashLayout(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('splash'),
      child: WelcomeSplashLayout(
        onLoginPressed: () {
          setState(() {
            _showPasscode = true;
          });
        },
      ),
    );
  }
}
`;
    content = content.substring(0, cutStart) + newSplash + content.substring(endOfClass + 1); // skip old '}'
} else {
    console.log("Could not find boundaries for widget replacement");
}

// 7. Apply color patches to remaining components (LeftPanel, Passcode, StaffCard)
content = content.replace(/Color\(0xFFFFF8F3\)/g, 'Color(0xFFFEF2F2)'); 
content = content.replace(/Color\(0xFFFFE4CC\)/g, 'Color(0xFFFECACA)'); 
content = content.replace(/Color\(0xFFFFF0E0\)/g, 'Color(0xFFFEE2E2)'); 

fs.writeFileSync(file, content);
console.log('Safe patch applied');
