import fs from 'fs';
import path from 'path';

const file = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
let content = fs.readFileSync(file, 'utf-8');

// Replace pale orange backgrounds with pale red
content = content.replace(/Color\(0xFFFFF8F3\)/g, 'Color(0xFFFEF2F2)'); 
content = content.replace(/Color\(0xFFFFE4CC\)/g, 'Color(0xFFFECACA)'); 
content = content.replace(/Color\(0xFFFFF0E0\)/g, 'Color(0xFFFEE2E2)'); 

fs.writeFileSync(file, content);
console.log('Secondary colors patched successfully');
