const fs = require('fs');
const path = require('path');

const file = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
let content = fs.readFileSync(file, 'utf8');

// Match the entire block:
// if (!_showPasscode) {
//   return Scaffold( ... );
// }

const regex = /if \(!_showPasscode\) \{\s*return Scaffold\([\s\S]*?body: Stack\([\s\S]*?\}\s*\);\s*\}/g;

const newSplashBlock = `if (!_showPasscode) {
      return WelcomeSplashLayout(
        onLoginPressed: () {
          setState(() {
            _showPasscode = true;
          });
        },
      );
    }`;

content = content.replace(regex, newSplashBlock);

// Remove the unused methods completely:
content = content.replace(/  Widget _buildBgBlobs\(\) \{[\s\S]*?return Stack\([\s\S]*?\}\n  \}\n\n/g, '');
content = content.replace(/  Widget _buildHeader\(\) \{[\s\S]*?return Column\([\s\S]*?\}\n  \}\n\n/g, '');
content = content.replace(/  Widget _buildHeroSection\(\) \{[\s\S]*?return AnimatedBuilder\([\s\S]*?\}\n  \}\n\n/g, '');
content = content.replace(/  Widget _buildDot\(Color color\) \{[\s\S]*?\}\n  \}\n\n/g, '');
content = content.replace(/  Widget _buildSidebarIcon\(IconData icon, \{bool isActive = false\}\) \{[\s\S]*?\}\n  \}\n\n/g, '');
content = content.replace(/  Widget _buildFoodCard\(String imageUrl\) \{[\s\S]*?\}\n  \}\n\n/g, '');
content = content.replace(/  Widget _buildCartItemPlaceholder\(\) \{[\s\S]*?\}\n  \}\n\n/g, '');
content = content.replace(/  Widget _buildFeaturesGrid\(\) \{[\s\S]*?return SlideTransition\([\s\S]*?\}\n  \}\n\n/g, '');
content = content.replace(/  Widget _buildFooter\(\) \{[\s\S]*?return SlideTransition\([\s\S]*?\}\n  \}\n/g, '');

fs.writeFileSync(file, content);
console.log('Fixed WelcomeSplashLayout import issue');
