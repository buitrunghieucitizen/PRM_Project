const fs = require('fs');
const file = 'lib/services/api_service.dart';
let content = fs.readFileSync(file, 'utf8');

content = content.replace(
  '  static final Map<String, dynamic> _apiCache = {};',
  `  static final Map<String, dynamic> _apiCache = {};
  static void Function()? onUnauthorized;

  static void _handle401(http.Response response) {
    if (response.statusCode == 401) {
      logout();
      onUnauthorized?.call();
      throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
    }
  }`
);

let lines = content.split('\n');
let newLines = [];

for (let i = 0; i < lines.length; i++) {
  let line = lines[i];
  
  if (line.includes('if (response.statusCode') && !line.includes('_handle401')) {
      let isAuthMethod = true;
      for (let j = i; j >= 0; j--) {
        if (lines[j].includes('Future<')) {
          if (lines[j].includes('login(') || lines[j].includes('register(') || lines[j].includes('googleLogin(')) {
            isAuthMethod = false;
          }
          break;
        }
      }
      if (isAuthMethod) {
         let match = line.match(/^(\s*)/);
         let indent = match ? match[1] : '';
         newLines.push(indent + '_handle401(response);');
      }
  } else if (line.includes('bool ok = response.statusCode == 204 || response.statusCode == 200;')) {
      let match = line.match(/^(\s*)/);
      let indent = match ? match[1] : '';
      newLines.push(indent + '_handle401(response);');
  }
  
  newLines.push(line);
}

fs.writeFileSync(file, newLines.join('\n'));
console.log('Done fixing api_service.dart');
