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

    // 5. Borders / Dividers: Color(0xFFE5E5E5) -> Theme.of(context).dividerColor
    content = content.replace(/const Color\(0xFFE5E5E5\)/g, 'Theme.of(context).dividerColor');
    content = content.replace(/Color\(0xFFE5E5E5\)/g, 'Theme.of(context).dividerColor');
    
    // 4b. Color(0xFFF5F5F5) -> Theme.of(context).colorScheme.surface
    content = content.replace(/const Color\(0xFFF5F5F5\)/g, 'Theme.of(context).colorScheme.surface');
    content = content.replace(/Color\(0xFFF5F5F5\)/g, 'Theme.of(context).colorScheme.surface');
    
    // 6a. Subtitles: Color(0xFF666666) -> Theme.of(context).textTheme.bodySmall?.color
    content = content.replace(/const Color\(0xFF666666\)/g, 'Theme.of(context).textTheme.bodySmall?.color');
    content = content.replace(/Color\(0xFF666666\)/g, 'Theme.of(context).textTheme.bodySmall?.color');
    
    // 6b. Color(0xFF999999) -> Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)
    content = content.replace(/const Color\(0xFF999999\)/g, 'Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)');
    content = content.replace(/Color\(0xFF999999\)/g, 'Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)');

    // Text Colors.black -> Theme.of(context).textTheme.bodyLarge?.color
    content = content.replace(/color:\s*Colors\.black\s*(?=\s*,?\s*(?:font|height|letter|size|Text|child))/g, 'color: Theme.of(context).textTheme.bodyLarge?.color');
    content = content.replace(/color:\s*Colors\.black\s*\)/g, 'color: Theme.of(context).textTheme.bodyLarge?.color)');
    
    // Text Colors.white -> Theme.of(context).scaffoldBackgroundColor
    content = content.replace(/color:\s*Colors\.white\s*(?=\s*,?\s*(?:font|height|letter|size|Text|child))/g, 'color: Theme.of(context).scaffoldBackgroundColor');
    content = content.replace(/color:\s*Colors\.white\s*\)/g, 'color: Theme.of(context).scaffoldBackgroundColor)');

    // For BoxDecoration, we split and replace 'color: Colors.white' -> 'color: Theme.of(context).cardColor'
    let parts = content.split('BoxDecoration(');
    for (let i = 1; i < parts.length; i++) {
        let depth = 1;
        let j = 0;
        while (j < parts[i].length && depth > 0) {
            if (parts[i][j] === '(') depth++;
            else if (parts[i][j] === ')') depth--;
            j++;
        }
        let boxDec = parts[i].substring(0, j);
        let rest = parts[i].substring(j);
        
        boxDec = boxDec.replace(/color:\s*Colors\.white/g, 'color: Theme.of(context).cardColor');
        parts[i] = boxDec + rest;
    }
    content = parts.join('BoxDecoration(');

    // Any remaining Colors.white -> Theme.of(context).scaffoldBackgroundColor
    content = content.replace(/Colors\.white/g, 'Theme.of(context).scaffoldBackgroundColor');

    // Any remaining Colors.black -> Theme.of(context).primaryColor
    content = content.replace(/Colors\.black/g, 'Theme.of(context).primaryColor');
    
    // Color(0xFF333333) -> textTheme.bodyLarge?.color
    content = content.replace(/const Color\(0xFF333333\)/g, 'Theme.of(context).textTheme.bodyLarge?.color');
    content = content.replace(/Color\(0xFF333333\)/g, 'Theme.of(context).textTheme.bodyLarge?.color');

    // Color(0xFFCCCCCC) -> dividerColor
    content = content.replace(/const Color\(0xFFCCCCCC\)/g, 'Theme.of(context).dividerColor');
    content = content.replace(/Color\(0xFFCCCCCC\)/g, 'Theme.of(context).dividerColor');
    
    // Fix text style on TextField for dark mode support
    content = content.replace(/(TextField\(\s*controller:[^,]+,)(?!\s*style:)/g, '$1\n      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),');

    // Clean up any "const " before widgets that now contain Theme.of
    let lines = content.split('\n');
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes('Theme.of') && lines[i].includes('const ')) {
            lines[i] = lines[i].replace(/const /g, '');
        }
    }
    content = lines.join('\n');

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
