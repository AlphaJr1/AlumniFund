# Quick Guide: Start & Stop Flutter Server

## 🛑 STOP Server

### Option 1: Di Terminal Flutter (Recommended)
Tekan: **`q`** (quit)

### Option 2: Force Stop
Tekan: **`Ctrl + C`** di terminal

### Option 3: Close Terminal
Langsung close terminal window

---

## ▶️ START Server

### Cara 1: Full Path (Selalu Works)
```powershell
cd d:\Projects\DompetAlumni
C:\src\flutter_windows_3.38.5-stable\flutter\bin\flutter.bat run -d chrome
```

### Cara 2: Jika PATH Sudah Di-Set
```powershell
cd d:\Projects\DompetAlumni
flutter run -d chrome
```

### Cara 3: Dengan Port Spesifik
```powershell
cd d:\Projects\DompetAlumni
C:\src\flutter_windows_3.38.5-stable\flutter\bin\flutter.bat run -d chrome --web-port=8080
```

---

## ⚡ Hot Reload (Tanpa Restart)

Saat server running, di terminal:
- **`r`** - Hot reload (refresh cepat)
- **`R`** - Hot restart (restart penuh)
- **`h`** - Help (lihat semua commands)

---

## 📝 Quick Commands

| Command | Action |
|---------|--------|
| `q` | Quit/Stop server |
| `r` | Hot reload |
| `R` | Hot restart |
| `c` | Clear console |
| `h` | Show help |

---

## 🎯 Typical Workflow

1. **Start:**
   ```powershell
   cd d:\Projects\DompetAlumni
   C:\src\flutter_windows_3.38.5-stable\flutter\bin\flutter.bat run -d chrome
   ```

2. **Edit code** (auto hot reload)

3. **Manual reload:** Tekan `r`

4. **Stop:** Tekan `q`

---

**That's it! Super simple! 🚀**
