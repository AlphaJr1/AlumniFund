# Firebase Setup Guide

Panduan lengkap untuk setup Firebase project untuk Dompet Alumni.

## 📋 Prerequisites

- Google account
- Node.js installed (untuk Firebase CLI)
- Flutter SDK installed

## 🔥 Step 1: Create Firebase Project

1. **Buka Firebase Console**
   - Navigate ke https://console.firebase.google.com/
   - Click "Add project" atau "Create a project"

2. **Configure Project**
   - **Project name**: `dompet-alumni` (atau nama lain sesuai keinginan)
   - **Google Analytics**: Optional (bisa disable untuk MVP)
   - Click "Create project"
   - Tunggu sampai project selesai dibuat

## 🔐 Step 2: Enable Authentication

1. **Navigate to Authentication**
   - Di sidebar kiri, click "Authentication"
   - Click "Get started"

2. **Enable Email/Password**
   - Tab "Sign-in method"
   - Click "Email/Password"
   - Enable "Email/Password" (toggle ON)
   - Click "Save"

3. **Create Admin User**
   - Tab "Users"
   - Click "Add user"
   - **Email**: `admin@example.com` (ganti dengan email Anda)
   - **Password**: Buat password yang kuat (min 6 karakter)
   - Click "Add user"
   
   > ⚠️ **PENTING**: Simpan credentials ini dengan aman!

## 📊 Step 3: Create Firestore Database

1. **Navigate to Firestore Database**
   - Di sidebar kiri, click "Firestore Database"
   - Click "Create database"

2. **Security Rules**
   - Select "Start in **production mode**"
   - Click "Next"

3. **Location**
   - Pilih location terdekat (contoh: `asia-southeast1` untuk Indonesia)
   - Click "Enable"
   - Tunggu database selesai dibuat

4. **Deploy Security Rules** (nanti setelah setup selesai)

## 💾 Step 4: Enable Cloud Storage

1. **Navigate to Storage**
   - Di sidebar kiri, click "Storage"
   - Click "Get started"

2. **Security Rules**
   - Select "Start in **production mode**"
   - Click "Next"

3. **Location**
   - Gunakan location yang sama dengan Firestore
   - Click "Done"

## 🌐 Step 5: Setup Firebase Hosting

1. **Navigate to Hosting**
   - Di sidebar kiri, click "Hosting"
   - Click "Get started"
   - Follow wizard (kita akan deploy via CLI nanti)

## 🛠️ Step 6: Install Firebase CLI

1. **Install Firebase Tools**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**
   ```bash
   firebase login
   ```
   - Browser akan terbuka
   - Login dengan Google account yang sama

3. **Verify Installation**
   ```bash
   firebase --version
   ```

## 🔧 Step 7: Install FlutterFire CLI

1. **Install FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Verify Installation**
   ```bash
   flutterfire --version
   ```

## ⚙️ Step 8: Configure Flutter App

1. **Navigate to Project Directory**
   ```bash
   cd d:\Projects\DompetAlumni
   ```

2. **Run FlutterFire Configure**
   ```bash
   flutterfire configure
   ```
   
   - Select Firebase project yang sudah dibuat
   - Select platforms: **Web** (pilih dengan spacebar, enter untuk confirm)
   - FlutterFire akan generate `lib/firebase_options.dart`

3. **Verify Configuration**
   - Check bahwa file `lib/firebase_options.dart` sudah ter-generate
   - File ini berisi Firebase configuration untuk app Anda

## 🔒 Step 9: Deploy Security Rules

1. **Initialize Firebase in Project**
   ```bash
   firebase init
   ```
   
   - Select:
     - ✅ Firestore
     - ✅ Storage
     - ✅ Hosting
   - Use existing project: Select project Anda
   - **Firestore rules**: `firestore.rules` (sudah ada)
   - **Firestore indexes**: `firestore.indexes.json` (enter untuk default)
   - **Storage rules**: `storage.rules` (sudah ada)
   - **Hosting public directory**: `build/web`
   - **Configure as SPA**: Yes
   - **Setup automatic builds**: No

2. **Deploy Rules**
   ```bash
   firebase deploy --only firestore:rules,storage:rules
   ```

## 📝 Step 10: Initialize Default Settings

1. **Run Flutter App Locally**
   ```bash
   flutter run -d chrome
   ```
   
   - App akan auto-create default settings di Firestore
   - Check di Firebase Console > Firestore Database
   - Collection `settings` dengan document `default` harus sudah ada

2. **Update Settings via Admin Panel**
   - Login ke admin panel (`/admin/login`)
   - Navigate ke Settings
   - Update informasi rekening dan target dana

## ✅ Verification Checklist

Pastikan semua sudah setup dengan benar:

- [ ] Firebase project created
- [ ] Authentication enabled (Email/Password)
- [ ] Admin user created
- [ ] Firestore database created
- [ ] Cloud Storage enabled
- [ ] Firebase Hosting setup
- [ ] Firebase CLI installed & logged in
- [ ] FlutterFire CLI installed
- [ ] `firebase_options.dart` generated
- [ ] Security rules deployed
- [ ] Default settings initialized
- [ ] App running locally

## 🚀 Next Steps

### Local Development

```bash
# Run app
flutter run -d chrome

# Hot reload works automatically
```

### Production Deployment

```bash
# Build for production
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Your app will be live at:
# https://your-project.web.app
```

## 🔧 Troubleshooting

### Issue: FlutterFire command not found

**Solution:**
```bash
# Add to PATH (Windows)
# Add this to your environment variables:
%LOCALAPPDATA%\Pub\Cache\bin

# Or use full path:
dart pub global run flutterfire_cli:flutterfire configure
```

### Issue: Firebase login fails

**Solution:**
```bash
# Logout and login again
firebase logout
firebase login --reauth
```

### Issue: Permission denied on Firestore

**Solution:**
- Check security rules di Firebase Console
- Pastikan rules sudah di-deploy:
  ```bash
  firebase deploy --only firestore:rules
  ```

### Issue: Image upload fails

**Solution:**
- Check storage rules di Firebase Console
- Pastikan file size < 5MB
- Pastikan file type adalah image

## 📚 Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)

## 💡 Tips

1. **Free Tier Limits**
   - Firestore: 50K reads, 20K writes per day
   - Storage: 5GB storage, 1GB download per day
   - Hosting: 10GB storage, 360MB per day
   - Cukup untuk komunitas kecil (25 orang)

2. **Security Best Practices**
   - Jangan share admin credentials
   - Enable 2FA untuk Firebase account
   - Regularly backup Firestore data
   - Monitor usage di Firebase Console

3. **Performance**
   - Enable caching untuk images
   - Optimize image sizes sebelum upload
   - Use indexes untuk complex queries (jika diperlukan)

---

**Selamat! Firebase project Anda sudah siap digunakan! 🎉**
