import fs from 'fs';
import path from 'path';

// Fix welcome_splash_layout.dart width string issue
const welcomeFile = path.join(process.cwd(), 'lib/screens/login/welcome_splash_layout.dart');
let welcome = fs.readFileSync(welcomeFile, 'utf-8');
welcome = welcome.replace(/width: '70%'/g, 'width: 80.w');
welcome = welcome.replace(/width: '40%'/g, 'width: 40.w');
fs.writeFileSync(welcomeFile, welcome);

// Fix login_screen.dart
const loginFile = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
let login = fs.readFileSync(loginFile, 'utf-8');

// 1. Add import
if (!login.includes("import 'welcome_splash_layout.dart';")) {
  login = login.replace("import '../../providers/auth_provider.dart';", "import '../../providers/auth_provider.dart';\nimport 'welcome_splash_layout.dart';");
}

// 2. Remove all animations from login_screen.dart
const toRemoveAnims = [
  '  late final AnimationController _splashController;',
  '  late final Animation<double> _logoAnim;',
  '  late final Animation<double> _headlineAnim;',
  '  late final Animation<double> _subtitleAnim;',
  '  late final Animation<double> _mockupAnim;',
  '  late final Animation<double> _featuresAnim;',
  '  late final Animation<double> _taglineAnim;',
  '  late final Animation<double> _buttonAnim;',
  '  late final Animation<double> _footerAnim;',
  '  late final AnimationController _floatController;'
];
for (const str of toRemoveAnims) {
  login = login.replace(str + '\n', '');
}

// 3. Clean initState
login = login.replace(/_splashController = AnimationController\([\s\S]*?\);\n/g, '');
login = login.replace(/_logoAnim = Tween[\s\S]*?\);\n/g, '');
login = login.replace(/_headlineAnim = Tween[\s\S]*?\);\n/g, '');
login = login.replace(/_subtitleAnim = Tween[\s\S]*?\);\n/g, '');
login = login.replace(/_mockupAnim = Tween[\s\S]*?\);\n/g, '');
login = login.replace(/_featuresAnim = Tween[\s\S]*?\);\n/g, '');
login = login.replace(/_taglineAnim = Tween[\s\S]*?\);\n/g, '');
login = login.replace(/_buttonAnim = Tween[\s\S]*?\);\n/g, '');
login = login.replace(/_footerAnim = Tween[\s\S]*?\);\n/g, '');
login = login.replace(/_floatController = AnimationController\([\s\S]*?\n\s+..repeat\(reverse: true\);\n/g, '');
login = login.replace(/_splashController.forward\(\);\n/g, '');
login = login.replace(/_floatController.dispose\(\);\n/g, '');
login = login.replace(/_splashController.dispose\(\);\n/g, '');

// 4. Replace _buildBgBlobs up to _buildSplashLayout with just _buildSplashLayout
const cutStart = login.indexOf('  // ── Background & Abstract Blobs ───────────────────────────────────────────');
const cutEnd = login.indexOf('  // ── Phone Interface Mockup ──────────────────────────────────────────────────');

if (cutStart !== -1 && cutEnd !== -1) {
    // Find the end of _buildFeatureCards which is just before _PosLogo
    const posLogoIndex = login.indexOf('// ── _PosLogo');
    
    // We want to delete from cutStart up to posLogoIndex, EXCEPT the last closing brace before it.
    // Wait, the easier way is to just find the markers.
    const startOfPosLogo = login.lastIndexOf('// ───', posLogoIndex);
    
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
    
    // Replace all of it
    login = login.substring(0, cutStart) + newSplash + login.substring(startOfPosLogo !== -1 ? startOfPosLogo : posLogoIndex - 80);
}

// 5. Apply the secondary colors patch from task 1 since we checked out the file
login = login.replace(/Color\(0xFFFFF8F3\)/g, 'Color(0xFFFEF2F2)'); 
login = login.replace(/Color\(0xFFFFE4CC\)/g, 'Color(0xFFFECACA)'); 
login = login.replace(/Color\(0xFFFFF0E0\)/g, 'Color(0xFFFEE2E2)'); 

fs.writeFileSync(loginFile, login);
console.log('Final fix applied successfully.');
