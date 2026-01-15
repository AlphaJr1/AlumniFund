# Firestore Indexes Documentation

## Overview
File ini mendefinisikan composite indexes yang diperlukan untuk Cloud Functions queries.

## Indexes

### 1. graduation_targets (status + deadline)
**Purpose**: Digunakan oleh scheduled functions untuk query targets berdasarkan status dan deadline

**Used by**:
- `checkDeadlines`: Query targets dengan status 'active' atau 'closing_soon' yang deadlinenya sudah lewat
  ```javascript
  db.collection('graduation_targets')
    .where('status', 'in', ['active', 'closing_soon'])
    .where('deadline', '<', now)
  ```

- `updateClosingSoonStatus`: Query targets dengan status 'active' yang deadline <= 7 hari
  ```javascript
  db.collection('graduation_targets')
    .where('status', '==', 'active')
    .where('deadline', '<=', sevenDaysFromNow)
  ```

**Fields**:
- `status` (ASCENDING): upcoming, active, closing_soon, closed, archived
- `deadline` (ASCENDING): Timestamp

### 2. pending_submissions (status + reviewed_at)
**Purpose**: Digunakan untuk cleanup old rejected submissions

**Used by**:
- `cleanupOldSubmissions`: Query submissions yang rejected dan sudah >30 hari
  ```javascript
  db.collection('pending_submissions')
    .where('status', '==', 'rejected')
    .where('reviewed_at', '<', thirtyDaysAgo)
  ```

**Fields**:
- `status` (ASCENDING): pending, approved, rejected
- `reviewed_at` (ASCENDING): Timestamp

## Deployment

Indexes akan otomatis dibuat saat deploy:
```bash
firebase deploy --only firestore:indexes
```

Atau deploy bersamaan dengan functions:
```bash
firebase deploy
```

## Monitoring

Cek status indexes di Firebase Console:
- Firestore → Indexes tab
- Lihat status: Building / Enabled / Error

## Notes

- Indexes diperlukan untuk composite queries (multiple where clauses)
- Tanpa indexes, queries akan gagal dengan error "requires an index"
- Index creation bisa memakan waktu beberapa menit untuk collections besar
