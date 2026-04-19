#!/usr/bin/env python3
"""
Script to generate app icons from a source logo image for all Flutter platforms.
Requirements: pip install Pillow
"""

import os
from PIL import Image
import shutil

# Define the source logo and target locations
SOURCE_LOGO = "assets/images/attendance_logo.png"

# Define icon sizes and locations for each platform
ICON_CONFIGS = {
    # Android
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": (48, 48),
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": (72, 72),
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": (96, 96),
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": (144, 144),
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (192, 192),
    
    # Web
    "web/icons/Icon-192.png": (192, 192),
    "web/icons/Icon-512.png": (512, 512),
    "web/icons/Icon-maskable-192.png": (192, 192),
    "web/icons/Icon-maskable-512.png": (512, 512),
    "web/favicon.png": (32, 32),
    
    # Main asset logo
    "assets/images/attendance_logo.png": (256, 256),  # Keep or resize main logo
}

# macOS and iOS icon sizes
MACOS_IOS_SIZES = {
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png": (16, 16),
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png": (32, 32),
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png": (64, 64),
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png": (128, 128),
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png": (256, 256),
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png": (512, 512),
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png": (1024, 1024),
}

def generate_icons():
    """Generate all icon sizes from the source logo."""
    
    # Check if source logo exists
    if not os.path.exists(SOURCE_LOGO):
        print(f"ERROR: Source logo not found at {SOURCE_LOGO}")
        print("Please ensure you have saved the Attendance University logo to assets/images/attendance_logo.png")
        return False
    
    try:
        # Open the source image
        source_image = Image.open(SOURCE_LOGO).convert("RGBA")
        print(f"Source image loaded: {source_image.size}")
        
        # Generate all icon sizes
        all_configs = {**ICON_CONFIGS, **MACOS_IOS_SIZES}
        
        for output_path, (width, height) in all_configs.items():
            # Create directories if they don't exist
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            
            # Skip if it's the source file and size is the same
            if output_path == SOURCE_LOGO and source_image.size == (width, height):
                print(f"✓ Skipping {output_path} (already correct size)")
                continue
            
            # Resize the image
            # Use LANCZOS for high-quality downsampling
            resized = source_image.resize((width, height), Image.Resampling.LANCZOS)
            
            # Save the resized image
            resized.save(output_path, "PNG", quality=95)
            print(f"✓ Generated: {output_path} ({width}x{height})")
        
        print("\n✓ All icons generated successfully!")
        print("\nNext steps:")
        print("1. For Windows: Convert assets/images/attendance_logo.png to windows/runner/resources/app_icon.ico")
        print("   (You can use online tools or ImageMagick: convert attendance_logo.png app_icon.ico)")
        print("2. For iOS: Update ios/Runner/Assets.xcassets/AppIcon.appiconset/ with generated PNG files")
        print("3. Run 'flutter pub get' to update the app")
        print("4. Run 'flutter run' to test")
        
        return True
        
    except Exception as e:
        print(f"ERROR: Failed to generate icons: {e}")
        return False

if __name__ == "__main__":
    success = generate_icons()
    exit(0 if success else 1)
