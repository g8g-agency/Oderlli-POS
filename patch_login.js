const fs = require('fs');
const path = require('path');

const file = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
let lines = fs.readFileSync(file, 'utf8').split('\n');

let newLines = [];
let skipMode = false;
let braceCount = 0;

for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Remove old splash fields
    if (line.includes('late final AnimationController _splashController;')) continue;
    if (line.includes('late final AnimationController _floatController;')) continue;
    if (line.includes('late final Animation<double> _logoAnim;')) continue;
    if (line.includes('late final Animation<double> _headlineAnim;')) continue;
    if (line.includes('late final Animation<double> _subtitleAnim;')) continue;
    if (line.includes('late final Animation<double> _mockupAnim;')) continue;
    if (line.includes('late final Animation<double> _featuresAnim;')) continue;
    if (line.includes('late final Animation<double> _taglineAnim;')) continue;
    if (line.includes('late final Animation<double> _buttonAnim;')) continue;
    if (line.includes('late final Animation<double> _footerAnim;')) continue;

    // Remove initialization in initState
    if (line.includes('// Splash and float animation controllers')) {
        skipMode = true;
    }
    if (skipMode && line.includes('    _floatController.repeat(reverse: true);')) {
        skipMode = false;
        continue; // skip this line too
    }
    if (skipMode) continue;

    // Remove dispose
    if (line.includes('_splashController.dispose();')) continue;
    if (line.includes('_floatController.dispose();')) continue;

    // Replace _buildBgBlobs
    if (line.includes('Widget _buildBgBlobs() {')) {
        skipMode = 'method';
        braceCount = 0;
    }
    
    // Replace _buildFadeSlide
    if (line.includes('Widget _buildFadeSlide({')) {
        skipMode = 'method';
        braceCount = 0;
    }

    // Replace _buildSplashLayout
    if (line.includes('Widget _buildSplashLayout(BuildContext context) {')) {
        newLines.push('  Widget _buildSplashLayout(BuildContext context) {');
        newLines.push('    return WelcomeSplashLayout(');
        newLines.push('      onLoginPressed: () {');
        newLines.push('        setState(() {');
        newLines.push('          _showPasscode = true;');
        newLines.push('        });');
        newLines.push('      },');
        newLines.push('    );');
        newLines.push('  }');
        
        skipMode = 'method';
        braceCount = 0;
    }

    if (skipMode === 'method') {
        if (line.includes('{')) braceCount += (line.match(/\{/g) || []).length;
        if (line.includes('}')) braceCount -= (line.match(/\}/g) || []).length;
        
        if (braceCount === 0) {
            skipMode = false;
        }
        continue;
    }

    newLines.push(line);
}

fs.writeFileSync(file, newLines.join('\n'));
console.log('Patch complete.');
