# Fitur Reopen Target (Buka Kembali Target yang Sudah Di-Archive)

## Deskripsi
Fitur ini memungkinkan admin untuk membuka kembali target yang sudah masuk ke archive karena deadline-nya sudah lewat. Target yang dibuka kembali akan menjadi "upcoming" dan bisa diaktifkan kembali.

## Cara Menggunakan

### 1. Akses Archived Targets
- Buka halaman **Admin > Manage Targets**
- Scroll ke bagian bawah hingga menemukan section **"Archived Targets"**
- Klik untuk expand/collapse list

### 2. Buka Kembali Target
- Pada setiap target yang sudah di-archive, terdapat tombol **refresh icon** (🔄) di sebelah kanan
- Klik tombol tersebut untuk membuka dialog konfirmasi

### 3. Pilih Deadline Baru
Dialog akan menampilkan:
- Konfirmasi untuk membuka kembali target
- **Date picker** untuk memilih deadline baru
- Opsi untuk menggunakan deadline default (H-3 dari tanggal wisuda)

**Pilihan:**
- **Pilih tanggal manual**: Klik pada field tanggal untuk membuka calendar picker
- **Gunakan default**: Biarkan kosong, sistem akan menghitung H-3 dari tanggal wisuda terdekat

### 4. Konfirmasi
- Klik **"Buka Kembali"** untuk melanjutkan
- Klik **"Batal"** untuk membatalkan

## Perilaku Sistem

### Status Target Setelah Reopen
- Target akan berubah status dari `closed`/`archived` menjadi `upcoming`
- `open_date` dan `closed_date` akan di-reset
- `allocated_from_fund` akan di-reset ke 0
- Deadline akan diupdate sesuai pilihan

### Auto-Allocation Dana
**PENTING**: Setelah target dibuka kembali, sistem akan otomatis:
1. Reset `allocated_from_fund` ke 0
2. Memanggil `autoAllocateToTarget()` untuk mengalokasikan dana dari General Fund
3. Dana yang tersedia di General Fund akan otomatis dialokasikan ke target
4. Jika General Fund memiliki Rp 120.000 dan target membutuhkan Rp 250.000, maka:
   - `current_amount`: Rp 0 (donasi langsung)
   - `allocated_from_fund`: Rp 120.000 (dari General Fund)
   - **Total yang terlihat**: Rp 120.000

### Aktivasi Otomatis
Setelah target dibuka kembali:
- Sistem akan otomatis mengecek apakah target ini harus menjadi active
- Jika tidak ada active target lain, atau deadline-nya lebih dekat, target akan otomatis menjadi active
- Jika ada active target dengan deadline lebih dekat, target akan tetap sebagai upcoming

## Implementasi Teknis

### Service Layer
**File**: `lib/services/target_service.dart`

```dart
Future<void> reopenTarget({
  required String targetId,
  DateTime? newDeadline,
}) async
```

**Parameter:**
- `targetId`: ID target yang akan dibuka kembali
- `newDeadline`: (Optional) Deadline baru, jika null akan menggunakan default

**Validasi:**
- Hanya target dengan status `closed` atau `archived` yang bisa dibuka kembali
- Deadline harus di masa depan (validasi di UI)

### UI Layer
**File**: `lib/screens/admin/views/manage_targets_view.dart`

**Method:**
- `_reopenTarget(GraduationTarget target)`: Menampilkan dialog dan handle reopen

**UI Components:**
- Dialog konfirmasi dengan date picker
- Tombol refresh icon di setiap archived target item
- Snackbar untuk feedback sukses/error

## Contoh Use Case

### Scenario 1: Deadline Terlewat Karena Kesalahan
Target untuk wisuda Februari 2026 sudah di-archive karena deadline lewat, tapi ternyata ada kesalahan tanggal. Admin bisa:
1. Buka kembali target
2. Set deadline baru yang benar
3. Target kembali aktif dan bisa menerima donasi

### Scenario 2: Perpanjangan Waktu
Target sudah ditutup tapi belum tercapai. Admin ingin memberikan waktu tambahan:
1. Buka kembali target
2. Set deadline 1-2 minggu ke depan
3. Target kembali upcoming/active

### Scenario 3: Menggunakan Deadline Default
Target dibuka kembali tanpa perubahan deadline:
1. Buka kembali target
2. Tidak pilih tanggal (biarkan kosong)
3. Sistem akan hitung ulang H-3 dari tanggal wisuda

## Catatan Penting

⚠️ **Perhatian:**
- Target yang dibuka kembali akan masuk ke queue upcoming targets
- Jika ada active target lain, target yang dibuka kembali tidak akan langsung active
- Sistem akan otomatis memilih target dengan deadline terdekat untuk dijadikan active
- Pastikan deadline yang dipilih masuk akal (tidak terlalu dekat atau terlalu jauh)

✅ **Best Practice:**
- Pilih deadline minimal 3-7 hari ke depan untuk memberikan waktu yang cukup
- Cek dulu apakah ada target lain yang sedang active
- Pastikan target yang dibuka kembali masih relevan
