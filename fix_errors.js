const fs = require('fs');

const files = [
    'lib/screens/login_page.dart',
    'lib/screens/register_page.dart',
    'lib/screens/welcome_screen.dart',
    'lib/screens/onboarding_screen.dart',
    'lib/widgets/bottom_nav.dart',
    'lib/screens/ai_advisor.dart',
    'lib/screens/profile_screen.dart',
    'lib/screens/reports.dart'
];

function processFile(filepath) {
    let content = fs.readFileSync(filepath, 'utf8');

    // Fix incorrect mappings from previous run
    content = content.replace(/BorderSide\(\s*color:\s*Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color\s*\)/g, 'BorderSide(color: Theme.of(context).primaryColor)');
    
    // Fix CircularProgressIndicator color
    content = content.replace(/CircularProgressIndicator\(\s*color:\s*Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color/g, 'CircularProgressIndicator(color: Theme.of(context).primaryColor');
    content = content.replace(/CircularProgressIndicator\(\s*strokeWidth:\s*2,\s*color:\s*Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color/g, 'CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor');

    // Icon colors shouldn't be bodyLarge?.color usually, but they accept Color?. Wait, Icon color is Color?. No, Icon color parameter is `Color?`. So it shouldn't cause compile error, but primaryColor is better.
    // The list element type Color? can't be assigned to Color in reports.dart
    // `List<Color> colors = [Theme.of(context).textTheme.bodyLarge?.color, ...]`
    // Let's replace the array in reports.dart
    content = content.replace(/List<Color> colors = \[[^\]]+\];/g, 
        'List<Color> colors = [Theme.of(context).primaryColor, Theme.of(context).primaryColor, Theme.of(context).textTheme.bodySmall?.color ?? Theme.of(context).primaryColor, Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6) ?? Theme.of(context).primaryColor, Theme.of(context).dividerColor, Theme.of(context).dividerColor];');

    // Remove `const` keywords that are causing "Methods can't be invoked in constant expressions"
    // Because we added `Theme.of(context)` inside previously `const` widget trees.
    // We can just remove `const ` globally for Widget constructors.
    // To be safe, remove `const ` before words starting with capital letter.
    content = content.replace(/const\s+([A-Z][a-zA-Z0-9_]*)/g, '$1');

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
