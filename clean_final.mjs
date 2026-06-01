import fs from 'fs';
import path from 'path';

const file = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
const lines = fs.readFileSync(file, 'utf-8').split('\n');

// Arrays are 0-indexed. Line N in 1-indexed is lines[N-1].
// - Import: Add `import 'welcome_splash_layout.dart';` after line 16.
// - Lines 46 to 55: delete
// - Lines 84 to 142: delete
// - Lines 158 to 159: delete
// - Lines 1155 to 1865: replace with new _buildSplashLayout
// - Lines 1868 to 2082: delete

const newLines = [];

for (let i = 0; i < lines.length; i++) {
    const lineNum = i + 1; // 1-indexed

    if (lineNum >= 46 && lineNum <= 55) continue;
    if (lineNum >= 84 && lineNum <= 142) continue;
    if (lineNum >= 158 && lineNum <= 159) continue;
    
    if (lineNum === 1155) {
        newLines.push(`  // ── Splash Screen Layout ─────────────────────────────────────────────────────
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
  }`);
        continue;
    }
    
    if (lineNum > 1155 && lineNum <= 1865) continue;
    
    if (lineNum >= 1868 && lineNum <= 2082) continue;

    let line = lines[i];

    // Apply color replacements
    line = line.replace(/Color\(0xFFFFF8F3\)/g, 'Color(0xFFFEF2F2)'); 
    line = line.replace(/Color\(0xFFFFE4CC\)/g, 'Color(0xFFFECACA)'); 
    line = line.replace(/Color\(0xFFFFF0E0\)/g, 'Color(0xFFFEE2E2)'); 

    newLines.push(line);

    if (line.includes("import '../../providers/auth_provider.dart';")) {
        newLines.push("import 'welcome_splash_layout.dart';");
    }
}

fs.writeFileSync(file, newLines.join('\n'));
console.log('Fixed precisely using line numbers!');
