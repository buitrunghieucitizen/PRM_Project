import 'dart:io';

void main() {
  final dir = Directory('lib/screens');
  final replacements = {
    r'Theme\.of\(context\)\.scaffoldBackgroundColor': r'const Color(0xFFF0F4F8)',
    r'Theme\.of\(context\)\.cardColor': r'Colors.white',
    r'Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color': r'const Color(0xFF0F172A)',
  };

  for (var file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart') && !file.path.contains('profile_screen.dart')) {
      var content = file.readAsStringSync();
      var origContent = content;
      
      replacements.forEach((pat, repl) {
        content = content.replaceAll(RegExp(pat), repl);
      });
      
      if (content != origContent) {
        file.writeAsStringSync(content);
        print('Reverted ${file.path}');
      }
    }
  }
}
