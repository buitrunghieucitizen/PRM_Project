import 'dart:io';

void main() {
  var errors = [
    'lib/screens/dashboard.dart:378', 'lib/screens/dashboard.dart:512', 'lib/screens/dashboard.dart:606', 'lib/screens/dashboard.dart:639',
    'lib/screens/goals.dart:111', 'lib/screens/goals.dart:128', 'lib/screens/goals.dart:142', 'lib/screens/goals.dart:175', 'lib/screens/goals.dart:223', 'lib/screens/goals.dart:290', 'lib/screens/goals.dart:349', 'lib/screens/goals.dart:382', 'lib/screens/goals.dart:436', 'lib/screens/goals.dart:446',
    'lib/screens/journal.dart:111', 'lib/screens/journal.dart:142', 'lib/screens/journal.dart:206', 'lib/screens/journal.dart:240', 'lib/screens/journal.dart:290', 'lib/screens/journal.dart:380', 'lib/screens/journal.dart:390',
    'lib/screens/login_page.dart:107', 'lib/screens/login_page.dart:113', 'lib/screens/login_page.dart:139', 'lib/screens/login_page.dart:151', 'lib/screens/login_page.dart:285',
    'lib/screens/monthly_plan.dart:102', 'lib/screens/monthly_plan.dart:119', 'lib/screens/monthly_plan.dart:133', 'lib/screens/monthly_plan.dart:179', 'lib/screens/monthly_plan.dart:189', 'lib/screens/monthly_plan.dart:232', 'lib/screens/monthly_plan.dart:287', 'lib/screens/monthly_plan.dart:350', 'lib/screens/monthly_plan.dart:360',
    'lib/screens/onboarding_screen.dart:69', 'lib/screens/onboarding_screen.dart:106',
    'lib/screens/reports.dart:174', 'lib/screens/reports.dart:248', 'lib/screens/reports.dart:370', 'lib/screens/reports.dart:410', 'lib/screens/reports.dart:435', 'lib/screens/reports.dart:503',
    'lib/screens/welcome_screen.dart:58', 'lib/screens/welcome_screen.dart:91'
  ];

  for (var e in errors) {
    var parts = e.split(':');
    var file = File(parts[0]);
    if (file.existsSync()) {
      var lines = file.readAsLinesSync();
      var lineIdx = int.parse(parts[1]) - 1;
      
      // search up to 10 lines backwards for 'const '
      for(int i = 0; i < 15; i++) {
         if (lineIdx - i >= 0) {
           var L = lines[lineIdx - i];
           if (L.contains('const [')) { lines[lineIdx - i] = L.replaceFirst('const [', '['); break;}
           if (L.contains('const Row(')) { lines[lineIdx - i] = L.replaceFirst('const Row(', 'Row('); break;}
           if (L.contains('const Column(')) { lines[lineIdx - i] = L.replaceFirst('const Column(', 'Column('); break;}
           if (L.contains('const EdgeInsets')) { lines[lineIdx - i] = L.replaceFirst('const EdgeInsets', 'EdgeInsets'); break;}
           if (L.contains('const Text(')) { lines[lineIdx - i] = L.replaceFirst('const Text(', 'Text('); break;}
           if (L.contains('const Icon(')) { lines[lineIdx - i] = L.replaceFirst('const Icon(', 'Icon('); break;}
           if (L.contains('const BoxDecoration(')) { lines[lineIdx - i] = L.replaceFirst('const BoxDecoration(', 'BoxDecoration('); break;}
           if (L.contains('const SizedBox(')) { lines[lineIdx - i] = L.replaceFirst('const SizedBox(', 'SizedBox('); break;}
           if (L.contains('const Padding(')) { lines[lineIdx - i] = L.replaceFirst('const Padding(', 'Padding('); break;}
           if (L.contains('const TextStyle(')) { lines[lineIdx - i] = L.replaceFirst('const TextStyle(', 'TextStyle('); break;}
         }
      }
      file.writeAsStringSync(lines.join('\\n'));
    }
  }
}
