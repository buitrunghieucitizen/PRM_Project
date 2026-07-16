import 'dart:io';

void main() {
  final dir = Directory('lib/screens');
  final replacements = {
    r'color:\s*const\s*Color\(0xFFF0F4F8\)': r'color: Theme.of(context).scaffoldBackgroundColor',
    r'color:\s*Colors\.white': r'color: Theme.of(context).cardColor',
    r'color:\s*const\s*Color\(0xFF0F172A\)': r'color: Theme.of(context).textTheme.bodyLarge?.color',
    r'color:\s*Color\(0xFF0F172A\)': r'color: Theme.of(context).textTheme.bodyLarge?.color',
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
        print('Updated ${file.path}');
      }
    }
  }
}
