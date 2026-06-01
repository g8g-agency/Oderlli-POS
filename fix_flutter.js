const fs = require('fs');
let code = fs.readFileSync('lib/screens/login/login_screen.dart', 'utf8');

if (!code.includes('welcome_splash_layout.dart')) {
    code = code.replace(
        "import '../../providers/auth_provider.dart';", 
        "import '../../providers/auth_provider.dart';\nimport 'welcome_splash_layout.dart';"
    );
}

const match = code.match(/  Widget _buildSplashLayout\(BuildContext context\) \{[\s\S]*?  \/\/ ── Overlapping Devices Layout/);

if (match) {
    const newSplash = `  Widget _buildSplashLayout(BuildContext context) {
    return WelcomeSplashLayout(
      onLoginPressed: () {
        setState(() {
          _showPasscode = true;
        });
      },
    );
  }

  // ── Overlapping Devices Layout`;
    code = code.replace(match[0], newSplash);
    fs.writeFileSync('lib/screens/login/login_screen.dart', code);
    console.log('Successfully hooked up WelcomeSplashLayout!');
} else {
    console.log('Failed to find _buildSplashLayout block');
}
