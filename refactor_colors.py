import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Mappings
    # 5. Color(0xFFE5E5E5) -> Theme.of(context).dividerColor
    content = content.replace('Color(0xFFE5E5E5)', 'Theme.of(context).dividerColor')
    
    # 4b. Color(0xFFF5F5F5) -> Theme.of(context).colorScheme.surface
    content = content.replace('Color(0xFFF5F5F5)', 'Theme.of(context).colorScheme.surface')
    
    # 6a. Color(0xFF666666) -> Theme.of(context).textTheme.bodySmall?.color
    content = content.replace('Color(0xFF666666)', 'Theme.of(context).textTheme.bodySmall?.color')
    
    # 6b. Color(0xFF999999) -> Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)
    content = content.replace('Color(0xFF999999)', 'Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)')

    # Text Colors.black
    content = re.sub(r'TextStyle\(([^)]*)color:\s*Colors\.black([^)]*)\)', 
                     r'TextStyle(\1color: Theme.of(context).textTheme.bodyLarge?.color\2)', content)
    
    # Text Colors.white
    content = re.sub(r'TextStyle\(([^)]*)color:\s*Colors\.white([^)]*)\)', 
                     r'TextStyle(\1color: Theme.of(context).scaffoldBackgroundColor\2)', content)

    # For BoxDecoration, we can just replace 'color: Colors.white' with 'color: Theme.of(context).cardColor'
    # if it is inside a BoxDecoration. A simple heuristic is: if 'color: Colors.white' is followed by 'borderRadius' or 'shape'
    # or preceded by 'BoxDecoration('... actually, let's just do an iterative approach.
    
    # Split by BoxDecoration
    parts = content.split('BoxDecoration(')
    for i in range(1, len(parts)):
        # Find the matching closing parenthesis
        depth = 1
        j = 0
        while j < len(parts[i]) and depth > 0:
            if parts[i][j] == '(':
                depth += 1
            elif parts[i][j] == ')':
                depth -= 1
            j += 1
        
        box_dec = parts[i][:j]
        rest = parts[i][j:]
        box_dec = box_dec.replace('Colors.white', 'Theme.of(context).cardColor')
        parts[i] = box_dec + rest
        
    content = 'BoxDecoration('.join(parts)

    # Now replace the remaining Colors.white
    content = content.replace('Colors.white', 'Theme.of(context).scaffoldBackgroundColor')

    # Colors.black -> Theme.of(context).primaryColor for remaining
    content = content.replace('Colors.black', 'Theme.of(context).primaryColor')
    
    # Fix Color(0xFF333333) -> we don't have mapping for it, let's map it to bodyLarge?.color or primaryColor
    content = content.replace('Color(0xFF333333)', 'Theme.of(context).textTheme.bodyLarge?.color')

    # Also Color(0xFFCCCCCC) in reports.dart
    content = content.replace('Color(0xFFCCCCCC)', 'Theme.of(context).dividerColor')
    
    # Remove alpha issues if any
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

files = [
    'lib/screens/login_page.dart',
    'lib/screens/register_page.dart',
    'lib/screens/welcome_screen.dart',
    'lib/screens/onboarding_screen.dart',
    'lib/widgets/bottom_nav.dart',
    'lib/screens/ai_advisor.dart',
    'lib/screens/profile_screen.dart',
    'lib/screens/reports.dart'
]

for f in files:
    try:
        process_file(f)
        print(f"Processed {f}")
    except Exception as e:
        print(f"Failed {f}: {e}")
