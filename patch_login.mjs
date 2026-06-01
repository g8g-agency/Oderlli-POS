import fs from 'fs';
import path from 'path';

const file = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
let content = fs.readFileSync(file, 'utf-8');

// 1. Remove _floatController init
content = content.replace(/_floatController = AnimationController\([\s\S]*?\);\n/g, '');
content = content.replace(/if \(kIsWeb\) \{[\s\S]*?\} else \{[\s\S]*?_floatController\.repeat\(\);\n      \}\n    \}/g, '');
content = content.replace(/_floatController\.dispose\(\);\n/g, '');

// 2. Replace _buildMockups content
const mockupsOriginal = `  Widget _buildMockups() {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Tablet Mockup with Float animation
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatVal = 6 * sin(_floatController.value * 2 * pi);
              return Positioned(
                left: 0,
                top: 10 + floatVal,
                width: 236,
                child: child!,
              );
            },
            child: _buildTabletMockup(),
          ),
          // Phone Mockup with Float animation (offset phase)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatVal = 8 * sin((_floatController.value * 2 * pi) + 0.8);
              return Positioned(
                right: 0,
                top: 30 + floatVal,
                width: 128,
                child: child!,
              );
            },
            child: _buildPhoneMockup(),
          ),
        ],
      ),
    );
  }`;

const mockupsNew = `  Widget _buildMockups() {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 10,
            width: 236,
            child: _buildTabletMockup(),
          ),
          Positioned(
            right: 0,
            top: 30,
            width: 128,
            child: _buildPhoneMockup(),
          ),
        ],
      ),
    );
  }`;

content = content.replace(mockupsOriginal, mockupsNew);

// 3. Update the hardcoded colors in login_screen.dart
content = content.replace(/Color\(0xFFFF7A00\)/g, 'Color(0xFFE31E24)');
content = content.replace(/Color\(0xFFFFB478\)/g, 'Color(0xFFE31E24)');

// 4. Remove the white card constraint in _buildSplashLayout
const splashLayoutOriginal = `    return KeyedSubtree(
      key: const ValueKey('splash'),
      child: Stack(
        children: [
          _buildBgBlobs(),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400.w),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 30.r,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(32.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [`;

const splashLayoutNew = `    return KeyedSubtree(
      key: const ValueKey('splash'),
      child: Stack(
        children: [
          _buildBgBlobs(),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 800.w),
                  child: Container(
                    padding: EdgeInsets.all(32.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [`;

content = content.replace(splashLayoutOriginal, splashLayoutNew);

fs.writeFileSync(file, content);
console.log('Login screen patched successfully');
