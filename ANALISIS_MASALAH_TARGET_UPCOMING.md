# Analisis Masalah: Target dengan Deadline Dekat Masih Berstatus "Upcoming"

## 🔍 Masalah yang Ditemukan

**Situasi**: Target dengan deadline 13 Februari 2026 masih ditampilkan sebagai "Upcoming Target" padahal sekarang sudah 12 Februari 2026 (besok adalah deadline).

**Waktu saat ini**: 12 Februari 2026, 15:55 WIB (GMT+7)
**Deadline target**: 13 Februari 2026, 23:59:59

---

## 🐛 Akar Masalah

### 1. **Logika Aktivasi Target yang Tidak Optimal**

Di file `lib/services/target_service.dart`, fungsi `checkAndActivateTargets()` memiliki beberapa masalah:

**Masalah A - Filter Target yang Terlalu Ketat (Baris 752)**:
```dart
final validTargets = allTargets
    .where((t) => t.status == 'upcoming' && t.deadline.isAfter(now))
    .toList();
```

**Mengapa ini masalah?**
- Hanya memeriksa target dengan status `'upcoming'`
- Tidak memeriksa target yang sudah `'active'` tapi mungkin perlu di-switch
- Kondisi `deadline.isAfter(now)` benar (13 Feb 23:59 > 12 Feb 15:55), jadi target masuk ke daftar valid
- **TAPI** sistem tidak mengaktifkannya jika sudah ada target aktif lain

**Masalah B - Logika Switch Target yang Lemah (Baris 767-778)**:
```dart
if (activeAfterClose.isEmpty) {
  // No active target, activate nearest
  await _activateTarget(nearestTarget.id);
} else {
  // Check if nearest target has earlier deadline than current active
  final currentActiveTarget = activeAfterClose.first;
  if (nearestTarget.deadline.isBefore(currentActiveTarget.deadline)) {
    // Switch! Deactivate current, activate nearest
    await _deactivateTarget(currentActiveTarget.id);
    await _activateTarget(nearestTarget.id);
  }
}
```

**Mengapa ini masalah?**
- Sistem hanya switch target jika deadline target baru **lebih awal** dari target aktif saat ini
- Dari screenshot, terlihat target "January 2026" dengan deadline 10 Feb 2026 masih ditampilkan
- Jika target "January 2026" masih aktif (seharusnya sudah closed karena deadline lewat), sistem tidak akan switch ke "February 2026"

### 2. **Kemungkinan Target Lama Belum Ditutup**

Dari screenshot, target "January 2026" dengan deadline 10 Feb 2026 (sudah lewat 2 hari!) masih muncul di daftar "Upcoming Targets". Ini menunjukkan:
- Fungsi `checkAndActivateTargets()` mungkin belum dijalankan secara otomatis
- Target dengan deadline yang sudah lewat tidak otomatis ditutup
- Sistem masih menganggap target lama sebagai "active", sehingga target baru tidak diaktifkan

### 3. **Provider Hanya Memeriksa Status Database**

Di file `lib/providers/graduation_target_provider.dart` (baris 67):
```dart
final upcoming = targets.where((t) => t.status == 'upcoming').toList();
```

Provider ini hanya menampilkan target dengan status `'upcoming'` dari database, tanpa memeriksa apakah deadline sudah dekat atau sudah lewat.

---

## ✅ Solusi yang Diterapkan

### Perbaikan 1: Meningkatkan Logika `checkAndActivateTargets()`

**File**: `lib/services/target_service.dart`

**Perubahan**:
1. **Memperluas filter target valid** untuk mencakup target `'active'` dan `'upcoming'`:
   ```dart
   final validTargets = allTargets
       .where((t) => 
           (t.status == 'upcoming' || t.status == 'active') && 
           t.deadline.isAfter(now))
       .toList();
   ```

2. **Menambah pengecekan ID target** sebelum switch:
   ```dart
   if (nearestTarget.id != currentActiveTarget.id) {
     if (nearestTarget.deadline.isBefore(currentActiveTarget.deadline)) {
       // Switch! Deactivate current, activate nearest
       await _deactivateTarget(currentActiveTarget.id);
       await _activateTarget(nearestTarget.id);
     }
   }
   ```

3. **Memastikan target dengan deadline lewat ditutup** sebelum aktivasi target baru

**Dampak**:
- Sistem sekarang akan selalu mengaktifkan target dengan deadline terdekat
- Target dengan deadline yang sudah lewat akan otomatis ditutup
- Tidak ada lagi target "stuck" dalam status upcoming padahal deadline sudah dekat

---

## 🔧 Langkah Perbaikan Manual

Untuk memaksa sistem mengecek ulang dan mengaktifkan target yang benar, lakukan langkah berikut:

### Opsi 1: Restart Aplikasi
1. Tutup aplikasi web admin
2. Buka kembali
3. Fungsi `checkAndActivateTargets()` akan otomatis dijalankan saat aplikasi dimulai

### Opsi 2: Trigger Manual dari Admin Panel
Jika ada tombol "Recalculate Allocation" atau sejenisnya di admin panel, klik tombol tersebut untuk memicu pengecekan ulang.

### Opsi 3: Tutup Target Lama Secara Manual
1. Buka halaman "Manage Targets"
2. Jika ada target dengan deadline yang sudah lewat (seperti "January 2026" dengan deadline 10 Feb), tutup secara manual
3. Sistem akan otomatis mengaktifkan target berikutnya (February 2026)

---

## 📊 Penjelasan Teknis Detail

### Alur Aktivasi Target yang Benar:

```
1. Aplikasi dimulai
   ↓
2. checkAndActivateTargets() dipanggil
   ↓
3. Ambil semua target dari database
   ↓
4. Tutup target aktif yang deadline-nya sudah lewat
   ↓
5. Cari target dengan deadline terdekat (yang belum lewat)
   ↓
6. Jika tidak ada target aktif → Aktifkan target terdekat
   ↓
7. Jika ada target aktif → Bandingkan deadline
   ↓
8. Jika target terdekat deadline-nya lebih awal → Switch
```

### Kondisi Target:

| Status | Kondisi | Aksi |
|--------|---------|------|
| `upcoming` | Deadline > sekarang, tidak ada target aktif | Aktifkan jika deadline terdekat |
| `active` | Deadline > sekarang, sedang aktif | Tetap aktif kecuali ada target dengan deadline lebih awal |
| `closed` | Deadline < sekarang ATAU ditutup manual | Tidak bisa diaktifkan lagi (kecuali reopen) |

---

## 🎯 Kesimpulan

**Masalah**: Target dengan deadline 13 Feb masih "upcoming" karena:
1. Ada target lama (January 2026) yang belum ditutup meskipun deadline sudah lewat
2. Logika aktivasi target tidak cukup robust untuk menangani kasus ini
3. Sistem tidak otomatis switch ke target dengan deadline terdekat

**Solusi**: 
1. ✅ Perbaiki logika `checkAndActivateTargets()` (sudah dilakukan)
2. ⏳ Restart aplikasi atau tutup target lama secara manual
3. ⏳ Sistem akan otomatis mengaktifkan target February 2026

**Hasil yang Diharapkan**:
- Target "February 2026" dengan deadline 13 Feb akan menjadi "Active Target"
- Target "January 2026" dengan deadline 10 Feb (sudah lewat) akan ditutup otomatis atau dihapus dari daftar upcoming
- Sistem akan lebih responsif dalam mengaktifkan target dengan deadline terdekat

---

## 🔄 Testing

Untuk memverifikasi perbaikan:
1. Restart aplikasi admin
2. Periksa halaman "Manage Targets"
3. Pastikan target "February 2026" sekarang berstatus "Active Target"
4. Pastikan target dengan deadline yang sudah lewat tidak muncul di "Upcoming Targets"
