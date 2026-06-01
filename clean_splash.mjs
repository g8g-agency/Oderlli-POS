import fs from 'fs';
import path from 'path';

const loginFile = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
let content = fs.readFileSync(loginFile, 'utf-8');

// 1. Add import
if (!content.includes("import 'welcome_splash_layout.dart';")) {
  content = content.replace("import '../../providers/auth_provider.dart';", "import '../../providers/auth_provider.dart';\nimport 'welcome_splash_layout.dart';");
}

const splashStart = content.indexOf('  // ── Background Blobs');
const posLogo = content.indexOf('// _PosLogo');
const endOfClass = content.lastIndexOf('}', posLogo);

if (splashStart !== -1 && posLogo !== -1) {
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
`;

    content = content.substring(0, splashStart) + newSplash + content.substring(endOfClass);
    
    // Clean animations
    content = content.replace(/_splashController = AnimationController\([\s\S]*?\);\n/g, '');
    content = content.replace(/_logoAnim = Tween[\s\S]*?\);\n/g, '');
    content = content.replace(/_headlineAnim = Tween[\s\S]*?\);\n/g, '');
    content = content.replace(/_subtitleAnim = Tween[\s\S]*?\);\n/g, '');
    content = content.replace(/_mockupAnim = Tween[\s\S]*?\);\n/g, '');
    content = content.replace(/_featuresAnim = Tween[\s\S]*?\);\n/g, '');
    content = content.replace(/_taglineAnim = Tween[\s\S]*?\);\n/g, '');
    content = content.replace(/_buttonAnim = Tween[\s\S]*?\);\n/g, '');
    content = content.replace(/_footerAnim = Tween[\s\S]*?\);\n/g, '');
    content = content.replace(/_floatController = AnimationController\([\s\S]*?\n\s+..repeat\(reverse: true\);\n/g, '');
    content = content.replace(/_splashController.forward\(\);\n/g, '');
    content = content.replace(/_floatController.dispose\(\);\n/g, '');
    content = content.replace(/_splashController.dispose\(\);\n/g, '');

    const animDeclarations = [
      '  late final AnimationController _splashController;\n',
      '  late final Animation<double> _logoAnim;\n',
      '  late final Animation<double> _headlineAnim;\n',
      '  late final Animation<double> _subtitleAnim;\n',
      '  late final Animation<double> _mockupAnim;\n',
      '  late final Animation<double> _featuresAnim;\n',
      '  late final Animation<double> _taglineAnim;\n',
      '  late final Animation<double> _buttonAnim;\n',
      '  late final Animation<double> _footerAnim;\n',
      '  late final AnimationController _floatController;\n'
    ];
    for (const d of animDeclarations) {
        content = content.replace(d, '');
    }
    
    // Replace remaining hardcoded old colors (from first task patch)
    content = content.replace(/Color\(0xFFFFF8F3\)/g, 'Color(0xFFFEF2F2)'); 
    content = content.replace(/Color\(0xFFFFE4CC\)/g, 'Color(0xFFFECACA)'); 
    content = content.replace(/Color\(0xFFFFF0E0\)/g, 'Color(0xFFFEE2E2)'); 

    fs.writeFileSync(loginFile, content);
    console.log('Login screen fully cleaned!');
} else {
    console.log('Markers not found', {splashStart, posLogo});
}
