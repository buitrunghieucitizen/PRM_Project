import 'dart:io';

void main() {
  var errors = [
    'lib/screens/dashboard.dart',
    'lib/screens/goals.dart',
    'lib/screens/journal.dart',
    'lib/screens/login_page.dart',
    'lib/screens/monthly_plan.dart',
    'lib/screens/onboarding_screen.dart',
    'lib/screens/reports.dart',
    'lib/screens/welcome_screen.dart'
  ];

  for (var path in errors) {
    var file = File(path);
    if (file.existsSync()) {
      var content = file.readAsStringSync();
      if (content.contains(r'\n')) {
        content = content.replaceAll(r'\n', '\n');
        file.writeAsStringSync(content);
        print('Fixed \$path');
      }
    }
  }
}
