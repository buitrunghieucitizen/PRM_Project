const fs = require('fs');
const glob = require('fs').readdirSync;

const files = [
    'lib/screens/login_page.dart',
    'lib/screens/register_page.dart',
    'lib/screens/welcome_screen.dart',
    'lib/screens/onboarding_screen.dart',
    'lib/widgets/bottom_nav.dart',
    'lib/screens/ai_advisor.dart',
    'lib/screens/profile_screen.dart',
    'lib/screens/reports.dart',
    'lib/main.dart',
    'lib/screens/monthly_plan.dart'
];

function processFile(filepath) {
    if (!fs.existsSync(filepath)) return;
    let content = fs.readFileSync(filepath, 'utf8');

    // 1. Fix `children: const [`
    content = content.replace(/children:\s*const\s*\[/g, 'children: [');
    
    // 2. Fix `style = TextStyle` in reports.dart
    content = content.replace(/style = TextStyle\(/g, 'var style = TextStyle(');

    // 3. Fix `error - The constructor being called isn't a const constructor`
    // Add `const` back to constructors that I broke
    content = content.replace(/^(\s*)([A-Z][a-zA-Z0-9_]*)\(\{super\.key(.*)\}\);/gm, '$1const $2({super.key$3});');

    // Fix main.dart `const Reports()` if it's there
    content = content.replace(/const Reports\(\)/g, 'Reports()');
    content = content.replace(/const MonthlyPlanScreen\(\)/g, 'MonthlyPlanScreen()'); // if we broke MonthlyPlanScreen... wait, I didn't touch monthly_plan.dart! But main.dart calls it.
    
    fs.writeFileSync(filepath, content, 'utf8');
}

files.forEach(f => {
    try {
        processFile(f);
        console.log(`Processed ${f}`);
    } catch (e) {
        console.error(`Failed ${f}: ${e.message}`);
    }
});
