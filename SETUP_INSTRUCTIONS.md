# App Logo Replacement - Complete Setup Instructions

## Status

✓ Code changes completed
✓ Asset structure created
✓ Icon generation script ready
⏳ Waiting for logo image file

## Required Action: Save the Logo Image

The Attendance University logo has been provided in the chat. You now need to save it to the correct location:

### Quick Setup (Recommended)

1. **Save the logo image**
   - Right-click on the Attendance University logo image from the chat
   - Select "Save image as..." or similar option
   - Save as: **`attendance_logo.png`**
   - Location: **`c:\Users\lenovo\Documents\memoir\assets\images\`**
   - Format: PNG (high resolution, 512x512 or larger recommended)

2. **Generate all icons automatically**
   - Open PowerShell in the project directory
   - Run these commands:

   ```powershell
   # Navigate to project
   cd c:\Users\lenovo\Documents\memoir

   # Install Python image library (if needed)
   pip install Pillow

   # Generate all icons
   python generate_app_icons.py
   ```

3. **Handle Windows icon**
   - After the script completes, open https://convertio.co/png-ico/
   - Upload: `assets/images/attendance_logo.png`
   - Download the `.ico` file
   - Save to: `windows/runner/resources/app_icon.ico`

4. **Test the changes**
   ```powershell
   flutter pub get
   flutter run
   ```

## What Changed in the Code

### 1. pubspec.yaml

```yaml
flutter:
  assets:
    - assets/images/
```

### 2. lib/main.dart - Login Screen Logo

**Before:**

```dart
child: CustomPaint(painter: _HodooriLogoPainter()),
```

**After:**

```dart
child: Image.asset(
  'assets/images/attendance_logo.png',
  fit: BoxFit.contain,
),
```

### 3. Removed Code

- Deleted `_HodooriLogoPainter` class (165+ lines of custom painting code)

## Verification Checklist

After setup, verify:

- [ ] Logo image saved to `assets/images/attendance_logo.png`
- [ ] Python script executed successfully
- [ ] Icons generated in Android directories
- [ ] Icons generated in Web directory
- [ ] Icons generated in macOS directory
- [ ] Windows ICO file saved
- [ ] `flutter pub get` ran without errors
- [ ] App launches and shows new logo on login screen
- [ ] Logo is centered and properly aligned
- [ ] Logo appears in system/app drawer correctly
- [ ] No "Image not found" errors in console

## File Structure After Setup

```
memoir/
├── assets/
│   └── images/
│       └── attendance_logo.png ✓ New
├── android/app/src/main/res/
│   ├── mipmap-mdpi/ic_launcher.png ✓ Updated
│   ├── mipmap-hdpi/ic_launcher.png ✓ Updated
│   ├── mipmap-xhdpi/ic_launcher.png ✓ Updated
│   ├── mipmap-xxhdpi/ic_launcher.png ✓ Updated
│   └── mipmap-xxxhdpi/ic_launcher.png ✓ Updated
├── web/
│   ├── icons/
│   │   ├── Icon-192.png ✓ Updated
│   │   ├── Icon-512.png ✓ Updated
│   │   ├── Icon-maskable-192.png ✓ Updated
│   │   └── Icon-maskable-512.png ✓ Updated
│   └── favicon.png ✓ Updated
├── windows/runner/resources/
│   └── app_icon.ico ✓ Update manually
├── macos/Runner/Assets.xcassets/AppIcon.appiconset/
│   ├── app_icon_16.png ✓ Updated
│   ├── app_icon_32.png ✓ Updated
│   ├── app_icon_64.png ✓ Updated
│   ├── app_icon_128.png ✓ Updated
│   ├── app_icon_256.png ✓ Updated
│   ├── app_icon_512.png ✓ Updated
│   └── app_icon_1024.png ✓ Updated
├── lib/main.dart ✓ Updated
├── pubspec.yaml ✓ Updated
├── LOGO_REPLACEMENT_GUIDE.md ✓ New
└── generate_app_icons.py ✓ New

```

## Troubleshooting

### Issue: Python script says "Source logo not found"

**Solution:**

- Verify file is at: `c:\Users\lenovo\Documents\memoir\assets\images\attendance_logo.png`
- Check filename spelling (case-sensitive on some systems)
- Ensure file is PNG format

### Issue: "Image not found" error when running app

**Solution:**

- Run `flutter clean && flutter pub get`
- Verify `pubspec.yaml` has `assets: - assets/images/`
- Restart IDE if using VS Code

### Issue: Logo quality looks poor

**Solution:**

- Use higher resolution source image (512x512 minimum)
- Run script again to regenerate icons
- The LANCZOS resampling in the script provides high quality

### Issue: Different logos on different platforms

**Solution:**

- Ensure all icon files were generated from same source
- Run `python generate_app_icons.py` again
- Verify all target directories have files

## Platform Specific Notes

### Android

- Uses `ic_launcher.png` in mipmap folders
- Different DPI densities: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi
- Automatically selected based on device density

### iOS

- Icons are optional since script only generates PNG
- Can manually add to Xcode if needed
- App will use default icon if not in Assets.xcassets

### macOS

- Requires all 7 sizes (16, 32, 64, 128, 256, 512, 1024)
- Script generates all of them automatically

### Web

- Uses two main sizes: 192x192 and 512x512
- Maskable versions for adaptive icons
- Favicon.png for browser tab

### Windows

- Requires ICO format (not PNG)
- Must be converted manually or with converter tool
- Use online converter or ImageMagick if available

## Additional Features Available

The login screen logo now has:

- ✓ Scale animation (zoom in effect)
- ✓ Fade animation (appears gradually)
- ✓ Proper centering and alignment
- ✓ High quality rendering at 200x200
- ✓ Support for light and dark backgrounds
- ✓ Maintains aspect ratio

## Support

If you encounter issues:

1. Check the file paths are exactly as specified
2. Verify PNG format and image quality
3. Run `flutter clean` and `flutter pub get`
4. Check console output for specific error messages
5. Refer to `LOGO_REPLACEMENT_GUIDE.md` for detailed platform info
