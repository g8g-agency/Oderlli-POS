import fs from 'fs';
import path from 'path';

const file = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
let content = fs.readFileSync(file, 'utf-8');

// Add import
if (!content.includes("import 'welcome_splash_layout.dart';")) {
  content = content.replace("import '../../providers/auth_provider.dart';", "import '../../providers/auth_provider.dart';\nimport 'welcome_splash_layout.dart';");
}

// Replace _buildSplashLayout
const startMarker = '  // ── Splash Screen Layout ─────────────────────────────────────────────────────\n  Widget _buildSplashLayout(BuildContext context) {';
const endMarker = '  // ── Features Section (Bottom Grid) ──────────────────────────────────────────';

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

const startIndex = content.indexOf(startMarker);
const endIndex = content.indexOf(endMarker);

if (startIndex !== -1 && endIndex !== -1) {
  content = content.substring(0, startIndex) + newSplash + content.substring(endIndex);
}

// Remove old mockups and features methods
const toRemove = [
  '  // ── Features Section (Bottom Grid) ──────────────────────────────────────────',
  '  // ── Tagline & Footer ────────────────────────────────────────────────────────',
  '  // ── Overlapping Devices Layout ──────────────────────────────────────────────',
  '  // ── Tablet Interface Mockup ─────────────────────────────────────────────────',
  '  // ── Phone Mockup (Overlap) ──────────────────────────────────────────────────'
];

for (const marker of toRemove) {
  const s = content.indexOf(marker);
  if (s !== -1) {
    // Find the end of this method (usually the next // ── marker or end of class)
    const nextMarker = content.indexOf('  // ──', s + 10);
    const end = nextMarker !== -1 ? nextMarker : content.lastIndexOf('}');
    
    if (end !== -1) {
       content = content.substring(0, s) + content.substring(end);
    }
  }
}

fs.writeFileSync(file, content);
console.log('Patch complete.');
