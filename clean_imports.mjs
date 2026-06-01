import fs from 'fs';
import path from 'path';

const file = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
let content = fs.readFileSync(file, 'utf-8');

content = content.replace("import 'dart:math';\n", "");
content = content.replace("import 'dart:ui';\n", "");
content = content.replace("import 'package:flutter/foundation.dart';\n", "");

fs.writeFileSync(file, content);
console.log('Imports cleaned');
