import fs from 'fs';
import path from 'path';

const file = path.join(process.cwd(), 'lib/screens/login/login_screen.dart');
let content = fs.readFileSync(file, 'utf-8');

const toRemove = [
  "import 'dart:math';\n",
  "import 'dart:ui';\n",
  "import 'package:flutter/foundation.dart';\n",
  "  late final Animation<double> _logoAnim;\n",
  "  late final Animation<double> _headlineAnim;\n",
  "  late final Animation<double> _subtitleAnim;\n",
  "  late final Animation<double> _mockupAnim;\n",
  "  late final Animation<double> _featuresAnim;\n",
  "  late final Animation<double> _taglineAnim;\n",
  "  late final Animation<double> _buttonAnim;\n",
  "  late final Animation<double> _footerAnim;\n"
];

for (const s of toRemove) {
  content = content.replace(s, "");
}

fs.writeFileSync(file, content);
console.log('Final clean done');
