"""
App Icon Generator for DiaCare Patient and Doctor Apps
Generates Material Design style icons with distinct colors for each flavor.
Includes adaptive icons and splash screen assets.
"""

import os
from pathlib import Path

# Try to import PIL, if not available provide instructions
try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Pillow is required. Install with: pip install Pillow")
    exit(1)

# Icon sizes for Android (mipmap folders)
ICON_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

# Adaptive icon foreground sizes (with padding for safe zone)
ADAPTIVE_SIZES = {
    'mipmap-mdpi': 108,
    'mipmap-hdpi': 162,
    'mipmap-xhdpi': 216,
    'mipmap-xxhdpi': 324,
    'mipmap-xxxhdpi': 432,
}

# Splash screen sizes
SPLASH_SIZES = {
    'drawable-mdpi': 480,
    'drawable-hdpi': 800,
    'drawable-xhdpi': 1280,
    'drawable-xxhdpi': 1920,
    'drawable-xxxhdpi': 2560,
}

# Color schemes
PATIENT_COLORS = {
    'primary': (0, 150, 136),      # Teal 500
    'secondary': (0, 121, 107),    # Teal 700
    'accent': (255, 255, 255),     # White
    'background': (224, 242, 241), # Teal 50
    'hex_primary': '#009688',
    'hex_background': '#E0F2F1',
}

DOCTOR_COLORS = {
    'primary': (63, 81, 181),      # Indigo 500
    'secondary': (48, 63, 159),    # Indigo 700
    'accent': (255, 255, 255),     # White
    'background': (232, 234, 246), # Indigo 50
    'hex_primary': '#3F51B5',
    'hex_background': '#E8EAF6',
}

def create_icon(size, colors, is_doctor=False):
    """Create a modern app icon with gradient-like effect"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    padding = size // 10
    corner_radius = size // 4
    
    # Draw main background
    draw.rounded_rectangle(
        [padding, padding, size - padding, size - padding],
        radius=corner_radius,
        fill=colors['primary']
    )
    
    center = size // 2
    
    if is_doctor:
        # Draw medical cross
        cross_width = size // 6
        cross_length = size // 3
        
        draw.rectangle([
            center - cross_width // 2,
            center - cross_length,
            center + cross_width // 2,
            center + cross_length
        ], fill=colors['accent'])
        
        draw.rectangle([
            center - cross_length,
            center - cross_width // 2,
            center + cross_length,
            center + cross_width // 2
        ], fill=colors['accent'])
    else:
        # Draw heart shape
        heart_size = size // 3
        left_circle = (center - heart_size // 3, center - heart_size // 6)
        right_circle = (center + heart_size // 3, center - heart_size // 6)
        radius = heart_size // 3
        
        draw.ellipse([
            left_circle[0] - radius,
            left_circle[1] - radius,
            left_circle[0] + radius,
            left_circle[1] + radius
        ], fill=colors['accent'])
        
        draw.ellipse([
            right_circle[0] - radius,
            right_circle[1] - radius,
            right_circle[0] + radius,
            right_circle[1] + radius
        ], fill=colors['accent'])
        
        draw.polygon([
            (center - heart_size // 2 - radius // 2, center - heart_size // 6),
            (center + heart_size // 2 + radius // 2, center - heart_size // 6),
            (center, center + heart_size)
        ], fill=colors['accent'])
    
    return img


def create_adaptive_foreground(size, colors, is_doctor=False):
    """Create adaptive icon foreground (symbol only, transparent background)"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    # Symbol should be in the inner 66% (safe zone)
    symbol_size = int(size * 0.33)
    
    if is_doctor:
        # Draw medical cross
        cross_width = symbol_size // 3
        cross_length = symbol_size
        
        draw.rectangle([
            center - cross_width // 2,
            center - cross_length // 2,
            center + cross_width // 2,
            center + cross_length // 2
        ], fill=colors['primary'])
        
        draw.rectangle([
            center - cross_length // 2,
            center - cross_width // 2,
            center + cross_length // 2,
            center + cross_width // 2
        ], fill=colors['primary'])
    else:
        # Draw heart shape
        heart_size = symbol_size
        left_circle = (center - heart_size // 3, center - heart_size // 6)
        right_circle = (center + heart_size // 3, center - heart_size // 6)
        radius = heart_size // 3
        
        draw.ellipse([
            left_circle[0] - radius,
            left_circle[1] - radius,
            left_circle[0] + radius,
            left_circle[1] + radius
        ], fill=colors['primary'])
        
        draw.ellipse([
            right_circle[0] - radius,
            right_circle[1] - radius,
            right_circle[0] + radius,
            right_circle[1] + radius
        ], fill=colors['primary'])
        
        draw.polygon([
            (center - heart_size // 2 - radius // 2, center - heart_size // 6),
            (center + heart_size // 2 + radius // 2, center - heart_size // 6),
            (center, center + heart_size)
        ], fill=colors['primary'])
    
    return img


def create_splash_image(width, colors, is_doctor=False):
    """Create splash screen image"""
    height = width  # Square for simplicity, will be centered
    img = Image.new('RGBA', (width, height), colors['background'])
    draw = ImageDraw.Draw(img)
    
    center_x = width // 2
    center_y = height // 2
    symbol_size = width // 4
    
    if is_doctor:
        # Draw medical cross
        cross_width = symbol_size // 3
        cross_length = symbol_size
        
        draw.rectangle([
            center_x - cross_width // 2,
            center_y - cross_length // 2,
            center_x + cross_width // 2,
            center_y + cross_length // 2
        ], fill=colors['primary'])
        
        draw.rectangle([
            center_x - cross_length // 2,
            center_y - cross_width // 2,
            center_x + cross_length // 2,
            center_y + cross_width // 2
        ], fill=colors['primary'])
    else:
        # Draw heart
        heart_size = symbol_size
        left_circle = (center_x - heart_size // 3, center_y - heart_size // 6)
        right_circle = (center_x + heart_size // 3, center_y - heart_size // 6)
        radius = heart_size // 3
        
        draw.ellipse([
            left_circle[0] - radius,
            left_circle[1] - radius,
            left_circle[0] + radius,
            left_circle[1] + radius
        ], fill=colors['primary'])
        
        draw.ellipse([
            right_circle[0] - radius,
            right_circle[1] - radius,
            right_circle[0] + radius,
            right_circle[1] + radius
        ], fill=colors['primary'])
        
        draw.polygon([
            (center_x - heart_size // 2 - radius // 2, center_y - heart_size // 6),
            (center_x + heart_size // 2 + radius // 2, center_y - heart_size // 6),
            (center_x, center_y + heart_size)
        ], fill=colors['primary'])
    
    return img


def generate_icons_for_flavor(flavor_name, colors, is_doctor, base_path):
    """Generate all icon sizes for a flavor"""
    flavor_path = base_path / 'android' / 'app' / 'src' / flavor_name / 'res'
    
    # Standard icons
    for folder_name, size in ICON_SIZES.items():
        folder_path = flavor_path / folder_name
        folder_path.mkdir(parents=True, exist_ok=True)
        
        icon = create_icon(size, colors, is_doctor)
        icon_path = folder_path / 'ic_launcher.png'
        icon.save(icon_path, 'PNG')
        print(f"  Created: {folder_name}/ic_launcher.png")
    
    # Adaptive icon foregrounds
    for folder_name, size in ADAPTIVE_SIZES.items():
        folder_path = flavor_path / folder_name
        folder_path.mkdir(parents=True, exist_ok=True)
        
        foreground = create_adaptive_foreground(size, colors, is_doctor)
        fg_path = folder_path / 'ic_launcher_foreground.png'
        foreground.save(fg_path, 'PNG')
        print(f"  Created: {folder_name}/ic_launcher_foreground.png")


def generate_splash_for_flavor(flavor_name, colors, is_doctor, base_path):
    """Generate splash screen assets for a flavor"""
    flavor_path = base_path / 'android' / 'app' / 'src' / flavor_name / 'res'
    
    for folder_name, size in SPLASH_SIZES.items():
        folder_path = flavor_path / folder_name
        folder_path.mkdir(parents=True, exist_ok=True)
        
        splash = create_splash_image(size, colors, is_doctor)
        splash_path = folder_path / 'splash_image.png'
        splash.save(splash_path, 'PNG')
        print(f"  Created: {folder_name}/splash_image.png")


def create_adaptive_icon_xml(flavor_name, colors, base_path):
    """Create adaptive icon XML configuration"""
    flavor_path = base_path / 'android' / 'app' / 'src' / flavor_name / 'res'
    
    # Create mipmap-anydpi-v26 folder for adaptive icon config
    anydpi_path = flavor_path / 'mipmap-anydpi-v26'
    anydpi_path.mkdir(parents=True, exist_ok=True)
    
    # Adaptive icon XML
    adaptive_xml = f'''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
    
    (anydpi_path / 'ic_launcher.xml').write_text(adaptive_xml)
    print(f"  Created: mipmap-anydpi-v26/ic_launcher.xml")
    
    # Background color resource
    values_path = flavor_path / 'values'
    values_path.mkdir(parents=True, exist_ok=True)
    
    colors_xml = f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{colors['hex_background']}</color>
</resources>
'''
    
    (values_path / 'colors.xml').write_text(colors_xml)
    print(f"  Created: values/colors.xml")


def create_splash_drawable_xml(flavor_name, colors, base_path):
    """Create splash screen drawable XML"""
    flavor_path = base_path / 'android' / 'app' / 'src' / flavor_name / 'res'
    
    drawable_path = flavor_path / 'drawable'
    drawable_path.mkdir(parents=True, exist_ok=True)
    
    # Launch background XML
    launch_bg_xml = f'''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_background" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_image" />
    </item>
</layer-list>
'''
    
    (drawable_path / 'launch_background.xml').write_text(launch_bg_xml)
    print(f"  Created: drawable/launch_background.xml")
    
    # Splash background color
    values_path = flavor_path / 'values'
    values_path.mkdir(parents=True, exist_ok=True)
    
    # Read existing colors.xml or create new
    colors_file = values_path / 'colors.xml'
    if colors_file.exists():
        content = colors_file.read_text()
        if 'splash_background' not in content:
            # Add splash color
            content = content.replace(
                '</resources>',
                f'    <color name="splash_background">{colors["hex_background"]}</color>\n</resources>'
            )
            colors_file.write_text(content)
    else:
        colors_xml = f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{colors['hex_background']}</color>
    <color name="splash_background">{colors['hex_background']}</color>
</resources>
'''
        colors_file.write_text(colors_xml)
    print(f"  Updated: values/colors.xml with splash_background")


def main():
    script_path = Path(__file__).resolve()
    project_root = script_path.parent.parent
    
    print("=" * 60)
    print("DiaCare App Icon & Splash Screen Generator")
    print("=" * 60)
    
    # Generate Patient assets
    print("\n📱 Generating Patient app assets (Teal)...")
    print("-" * 40)
    print("Icons:")
    generate_icons_for_flavor('patient', PATIENT_COLORS, is_doctor=False, base_path=project_root)
    print("\nAdaptive Icon Config:")
    create_adaptive_icon_xml('patient', PATIENT_COLORS, base_path=project_root)
    print("\nSplash Screen:")
    generate_splash_for_flavor('patient', PATIENT_COLORS, is_doctor=False, base_path=project_root)
    create_splash_drawable_xml('patient', PATIENT_COLORS, base_path=project_root)
    
    # Generate Doctor assets
    print("\n👨‍⚕️ Generating Doctor app assets (Indigo)...")
    print("-" * 40)
    print("Icons:")
    generate_icons_for_flavor('doctor', DOCTOR_COLORS, is_doctor=True, base_path=project_root)
    print("\nAdaptive Icon Config:")
    create_adaptive_icon_xml('doctor', DOCTOR_COLORS, base_path=project_root)
    print("\nSplash Screen:")
    generate_splash_for_flavor('doctor', DOCTOR_COLORS, is_doctor=True, base_path=project_root)
    create_splash_drawable_xml('doctor', DOCTOR_COLORS, base_path=project_root)
    
    print("\n" + "=" * 60)
    print("✅ All assets generated successfully!")
    print("=" * 60)
    print("\nRebuild your apps to see the new icons and splash screens:")
    print("  flutter build apk --flavor patient -t lib/main_patient.dart")
    print("  flutter build apk --flavor doctor -t lib/main_doctor.dart")


if __name__ == '__main__':
    main()
