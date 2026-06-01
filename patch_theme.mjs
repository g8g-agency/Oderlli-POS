import fs from 'fs';
import path from 'path';

const colorsFile = path.join(process.cwd(), 'lib/theme/app_colors.dart');
let content = fs.readFileSync(colorsFile, 'utf-8');

// Primary colors
content = content.replace(/Color\(0xFF994700\)/g, 'Color(0xFFE31E24)');
content = content.replace(/Color\(0xFFFF7A00\)/g, 'Color(0xFFE31E24)');
content = content.replace(/Color\(0xFF753400\)/g, 'Color(0xFFB0121A)');

// Text colors
content = content.replace(/Color\(0xFF151C25\)/g, 'Color(0xFF1A1C1E)'); // textPrimary
content = content.replace(/Color\(0xFF584235\)/g, 'Color(0xFF1A1C1E)'); // textSecondary
content = content.replace(/Color\(0xFF6B7280\)/g, 'Color(0xFF6C757D)'); // textTertiary

// Surface variants (orange hints to neutral)
content = content.replace(/Color\(0xFFFFDBC8\)/g, 'Color(0xFFFEE8E9)'); // sidebarActiveBg

fs.writeFileSync(colorsFile, content);

// Now apply Google Fonts to app_typography.dart
const typoFile = path.join(process.cwd(), 'lib/theme/app_typography.dart');
let typo = fs.readFileSync(typoFile, 'utf-8');

if (!typo.includes('google_fonts.dart')) {
    typo = "import 'package:google_fonts/google_fonts.dart';\n" + typo;
    // Replace the default text theme mapping with Google Fonts
    // Currently it might be just defining styles with a font family.
    // I'll replace any fontFamily: 'something' with google fonts or just wrap the textTheme.
    typo = typo.replace(/fontFamily: ['"].+?['"]/g, "fontFamily: GoogleFonts.plusJakartaSans().fontFamily");
    
    // Also inject google fonts text theme
    typo = typo.replace(/static const TextTheme textTheme = TextTheme\(/g, "static final TextTheme textTheme = GoogleFonts.plusJakartaSansTextTheme(const TextTheme(");
    typo = typo.replace(/  \);\n}/g, "  ));\n}");
}

fs.writeFileSync(typoFile, typo);

console.log('Colors and Typography patched successfully');
