# Flutter Installation Guide for Windows

## 🎯 Quick Start

Flutter SDK belum terinstall di sistem Anda. Ikuti langkah berikut untuk install Flutter.

## 📥 Download Flutter SDK

### Option 1: Download Langsung (Recommended)

1. **Download Flutter SDK**
   - Kunjungi: https://docs.flutter.dev/get-started/install/windows
   - Atau download langsung: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip
   - File size: ~1.5 GB

2. **Extract ZIP**
   - Extract ke lokasi yang mudah diakses (contoh: `C:\src\flutter`)
   - **JANGAN** extract ke folder yang memerlukan elevated privileges (seperti `C:\Program Files`)

3. **Add to PATH**
   
   **Cara 1: Via GUI**
   - Buka "Edit environment variables for your account"
   - Di "User variables", cari variable `Path`
   - Click "Edit"
   - Click "New"
   - Tambahkan: `C:\src\flutter\bin` (sesuaikan dengan lokasi extract Anda)
   - Click "OK" pada semua dialog
   
   **Cara 2: Via PowerShell (Admin)**
   ```powershell
   # Ganti path sesuai lokasi extract Anda
   [System.Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\src\flutter\bin', [System.EnvironmentVariableTarget]::User)
   ```

4. **Restart Terminal/PowerShell**
   - Close semua terminal yang terbuka
   - Buka PowerShell baru

5. **Verify Installation**
   ```powershell
   flutter --version
   flutter doctor
   ```

### Option 2: Using Git (Alternative)

```powershell
# Clone Flutter repository
cd C:\src
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH (sama seperti Option 1)
```

## 🔧 Flutter Doctor

Setelah install, jalankan:

```powershell
flutter doctor
```

**Expected Output:**
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.x.x, on Microsoft Windows...)
[✓] Windows Version (Installed version of Windows is version 10 or higher)
[✓] Chrome - develop for the web
[!] Android toolchain - develop for Android devices (optional untuk web)
[!] Visual Studio - develop Windows apps (optional untuk web)
[✓] VS Code (optional)
```

**Untuk Flutter Web, yang penting:**
- ✅ Flutter SDK
- ✅ Chrome browser

Android toolchain dan Visual Studio **TIDAK** diperlukan untuk Flutter Web.

## 🌐 Enable Flutter Web

```powershell
flutter config --enable-web
```

## ✅ Verification

Test bahwa Flutter sudah siap:

```powershell
# Check Flutter version
flutter --version

# Check devices (should show Chrome)
flutter devices

# Should show something like:
# Chrome (web) • chrome • web-javascript • Google Chrome 120.x.x
```

## 🚀 Next Steps After Installation

Setelah Flutter terinstall, kembali ke project dan jalankan:

```powershell
cd d:\Projects\DompetAlumni

# Install dependencies
flutter pub get

# Run app
flutter run -d chrome
```

## 🐛 Troubleshooting

### Issue: "flutter: command not found" setelah add to PATH

**Solution:**
- Restart terminal/PowerShell
- Atau restart komputer
- Verify PATH dengan: `$env:Path -split ';' | Select-String flutter`

### Issue: Flutter doctor shows errors

**For Web Development, you only need:**
- Flutter SDK ✅
- Chrome browser ✅

**You can ignore:**
- Android toolchain ❌ (not needed for web)
- Visual Studio ❌ (not needed for web)
- Xcode ❌ (not needed for web)

### Issue: Chrome not detected

**Solution:**
```powershell
# Set Chrome executable path
flutter config --chrome-executable="C:\Program Files\Google\Chrome\Application\chrome.exe"
```

## 📚 Additional Resources

- [Official Flutter Installation Guide](https://docs.flutter.dev/get-started/install/windows)
- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [Flutter Doctor Documentation](https://docs.flutter.dev/get-started/install/windows#run-flutter-doctor)

## ⏱️ Installation Time

- Download: 5-15 minutes (tergantung internet)
- Extract: 1-2 minutes
- Setup PATH: 1 minute
- Total: ~10-20 minutes

---

**Setelah Flutter terinstall, kembali ke sini dan kita lanjutkan setup project! 🚀**
