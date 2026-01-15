# 🚀 SIMPLE SETUP - Langsung Test!

## Karena Firebase CLI install lama, kita pakai cara lebih simple:

### ✅ LANGSUNG RUN APP!

App sudah configured untuk auto-seed data saat startup.

```bash
# Langsung run!
flutter run -d chrome
```

**Yang terjadi:**
1. ✅ Firebase init otomatis
2. ✅ Auto-create settings jika belum ada
3. ✅ Auto-create general fund jika belum ada
4. ✅ App langsung bisa ditest!

---

## 📝 Manual Seed Data (Jika Perlu)

Jika auto-seed tidak jalan, bisa manual via Firestore Console:

### 1. Buka Firestore Console
https://console.firebase.google.com/project/YOUR_PROJECT/firestore

### 2. Add Collection: `settings`
Document ID: `app_config`

Click "Add field" mode atau paste JSON:
```json
{
  "payment_methods": [
    {"type": "bank", "provider": "BNI", "account_number": "1428471525", "account_name": "Adrian Alfajri", "qr_code_url": null},
    {"type": "bank", "provider": "BCA", "account_number": "3000968357", "account_name": "Adrian Alfajri", "qr_code_url": null},
    {"type": "ewallet", "provider": "OVO", "account_number": "081377707700", "account_name": "Adrian Alfajri", "qr_code_url": null},
    {"type": "ewallet", "provider": "Gopay", "account_number": "081377707700", "account_name": "Adrian Alfajri", "qr_code_url": null}
  ],
  "system_config": {"per_person_allocation": 250000, "deadline_offset_days": 3, "minimum_contribution": 10000, "auto_open_next_target": true},
  "admin_config": {"whatsapp_number": "+6281377707700", "admin_email": "adrianalfajri@gmail.com"}
}
```

### 3. Add Collection: `general_fund`
Document ID: `current`
```json
{
  "balance": 0,
  "total_income": 0,
  "total_expense": 0,
  "transaction_count": 0
}
```

### 4. (Optional) Add Sample Target
Collection: `graduation_targets`
Document ID: `mei_2026`
```json
{
  "month": 5,
  "year": 2026,
  "graduates": [
    {"name": "Budi Santoso", "date": "2026-05-15T00:00:00Z", "location": "Universitas Indonesia"},
    {"name": "Siti Rahmawati", "date": "2026-05-20T00:00:00Z", "location": "ITB"}
  ],
  "target_amount": 500000,
  "current_amount": 0,
  "deadline": "2026-05-12T00:00:00Z",
  "status": "active",
  "distribution": {"per_person": 0, "total_distributed": 0, "status": "pending"}
}
```

---

## 🎯 QUICK START

```bash
# 1. Run app
flutter run -d chrome

# 2. Jika error, check console untuk error message
# 3. Jika perlu manual seed, buka Firestore Console
```

DONE!
