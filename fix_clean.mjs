import fs from 'fs';
import path from 'path';

const file = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
const lines = fs.readFileSync(file, 'utf-8').split('\n');
const newLines = [];
let skip = false;
let inInitState = false;
let inDispose = false;

for (let i = 0; i < lines.length; i++) {
    let line = lines[i];

    if (line.includes("import '../../providers/auth_provider.dart';")) {
        newLines.push(line);
        newLines.push("import 'welcome_splash_layout.dart';");
        continue;
    }

    if (line.includes('late final AnimationController _splashController;') ||
        line.includes('late final AnimationController _floatController;') ||
        (line.includes('late final Animation<double>') && line.includes('Anim;'))) {
        continue;
    }

    if (line.includes('void initState() {')) {
        inInitState = true;
    }
    if (inInitState && line.includes('}')) {
        inInitState = false;
    }

    if (inInitState) {
        if (line.includes('_splashController =') || 
            line.includes('_floatController =') ||
            line.includes('Anim = Tween')) {
            while (i < lines.length && !lines[i].includes(';')) {
                i++;
            }
            continue;
        }
        if (line.includes('..repeat(reverse: true);')) continue;
        if (line.includes('_splashController.forward();')) continue;
    }

    if (line.includes('void dispose() {')) {
        inDispose = true;
    }
    if (inDispose && line.includes('}')) {
        inDispose = false;
    }

    if (inDispose) {
        if (line.includes('_splashController.dispose();') ||
            line.includes('_floatController.dispose();')) {
            continue;
        }
    }

    if (line.includes('Widget _buildBgBlobs() {')) {
        skip = true;
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
  }
}
`);
        continue;
    }

    if (skip && line.includes('// _PosLogo')) {
        skip = false;
    }

    if (!skip) {
        line = line.replace(/Color\(0xFFFFF8F3\)/g, 'Color(0xFFFEF2F2)'); 
        line = line.replace(/Color\(0xFFFFE4CC\)/g, 'Color(0xFFFECACA)'); 
        line = line.replace(/Color\(0xFFFFF0E0\)/g, 'Color(0xFFFEE2E2)'); 
        newLines.push(line);
    }
}

fs.writeFileSync(file, newLines.join('\n'));
console.log('Processed file completely (with correct brace closing)');
