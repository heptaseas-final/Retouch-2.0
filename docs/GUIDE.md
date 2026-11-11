# Panduan Repo Retouch (TOLONG DIBACA)

> **WAJIB setiap kali mulai chat baru Claude: (PENTINGGGGG)**
>
> 1. Attach **`SPEC.md` terbaru** sebagai konteks. (bisa didownload di sini: [**Agent Skills & Spec**](https://www.dropbox.com/scl/fo/5diw7gwkih5gkqf2orbdq/APQSa6HRDgNgEkk1QC3RsTs?rlkey=w6eeo89j0ui9c053wl4n144s1&st=2q55uvsr&dl=0))
> 2. Selalu pastiin skills kalian dalam versi terbaru.
> 3. Lampirkan file yang mau diubah (Swift/zip), lalu minta **rencana dulu** sebelum kode.
>
> JANGAN LUPA, nanti conflict hehehehehe

Aturan lengkapnya ada di `retouch-spec/engineering.md`. Kalau ada yang beda, ikuti `engineering.md`.

---

## 1. Setup pertama kali

1. `git pull` branch `development`.
2. Jalankan `xcodegen generate`
3. Pasang skill JANGAN LUPA (bagian 2).

## 2. Install skill di Claude

### File Skill yang wajib di download (install ulang karena ada update): [Agent Skills & Spec](https://www.dropbox.com/scl/fo/5diw7gwkih5gkqf2orbdq/APQSa6HRDgNgEkk1QC3RsTs?rlkey=w6eeo89j0ui9c053wl4n144s1&st=luo884ow&dl=0)

### Langkah install

1. Settings > Capabilities > aktifkan **Code execution and file creation** (skill butuh ini).
2. Customize > Skills > **+** > **Upload a skill** > pilih zip. Ulangi untuk **kelima** skill: `retouch-spec`, `karpathy-guidelines`, `antislop`, `swift-architecture`, `swift-agents`.
3. Aktifkan toggle kelimanya.
4. Buka chat baru, ketik `/retouch-spec`. Kalau skill-nya muncul, berarti berhasil.

Catatan:
- Skill **gak update sendiri, harus upload manual**. Kalau version di `engineering.md` beda, upload ulang zip-nya. AI juga akan mengingatkan kalau skill kalian kedaluwarsa. (Kasih tau Davin kalau ada yang expired.)
- Kalau menu Skills tidak ada di akun kalian, tempel isi `retouch-spec/engineering.md` di awal chat.

Kalau tidak pakai claude.ai:

| Alat | Yang dilakukan |
|---|---|
| Cursor, Codex, Copilot (membaca repo) | Tidak perlu apa-apa, `AGENTS.md` terbaca otomatis setelah `git pull` |
| Claude Code | Buat `CLAUDE.md` berisi satu baris `Read AGENTS.md first.` |
| AI chat lain | Paste isi `engineering.md` di awal chat |

## 3. Cara memakai AI untuk tiap task (PENTINGGGGG)

1. **Baiknya satu task, satu chat baru, satu branch (tapi terserah kalian)**
2. Ketik `/retouch-spec`, lalu lampirkan `SPEC.md` terbaru.
3. Sertakan AC dari `SPEC.md` kalau ada. Jadi jangan lupa upload `SPEC.md`
4. Lampirkan file yang akan diubah (Swift/ZIP file).
5. **Minta plan dulu.** AI akan kirim daftar file, asumsi, dan pertanyaan. Baca, koreksi, baru setujui.
6. Setelah dapat kodenya: build, jalankan tes, dan coba di iPhone untuk hal yang menyangkut kamera, gesture, dan brightness.

Contoh prompt:

> /retouch-spec task: tambah tombol Lock zoom di layar Mirror (AC10). File terlampir: SPEC.md, MirrorView.swift, MirrorViewModel.swift, ZoomService.swift. Kirim rencananya dulu.

Contoh untuk AI yang membaca repo:

> Ikuti AGENTS.md. task: tambah tombol lock zoom di layar Mirror sesuai AC10 di SPEC.md. Kirim rencana dulu sebelum mengubah file.

Kalau AI melanggar aturan (folder baru, service dibuat di View, ada komentar), tolak dan suruh ia baca ulang `engineering.md`.

## 4. Branching (PENTINGGGGG)

| Branch | Aturan |
|---|---|
| `main` | Versi rilis. Hanya menerima PR dari `development`, tidak boleh push langsung. Yang boleh push **HANYA TECH LEAD** |
| `development` | ini branch staging. di branch ini code harus bisa dibuild, team bisa request PR ke branch ini. Di-review, approve, dan merge **HANYA OLEH TECH LEAD** |
| `feature/<nama-singkat>` | Satu task. Dibuat dari `development`, dihapus setelah merge. Pastiin sebelum dihapus semua tasknya udah complete. |

Alur:
1. `git checkout development`, lalu `git pull`.
2. `git checkout -b feature/<nama-task-kalian>`.
3. Commit kecil dengan format conventional commit (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`,`perf:`, dkk).
4. Push ke branch `feature/` kalian, lalu buka PR ke `development`. Merge setelah test Jenkins hijau dan ada minimal satu reviewer (TECH LEAD).
5. Kalau conflict kabarin ya hehehe. Nanti tech lead akan resolve conflict kecuali ada beberapa urusan.
6. Rilis: merge PR dari `development` ke `main`.

Aktifkan branch protection untuk `main` dan `development`, dan jangan biarkan branch `feature/` hidup lebih dari beberapa hari.

## 5. Checklist sebelum PR (PENTINGGGGG)

1. Build ga error, semua testcase lulus (CTRL + U).
2. File baru ada di folder yang benar (lihat bagian 6 dan 10).
3. Satu file di bawah 300 baris.
4. Comment seperlunya saja yah.
5. Hanya file yang perlu yang diubah, tanpa ubah kode orang lain.
6. Di deskripsi PR, tulis apa yang sudah dan belum dicek manual di iPhone.

## 6. Mengubah aturan _(infokan ke Tech Lead kalau ada yang mau diubah)_ (PENTINGGGGG)

1. Ubah `retouch-spec/` lewat PR, naikkan nomor versi di `SKILL.md` dan `engineering.md`.
2. Setelah merge, umumkan di channel tim.
3. Pengguna claude.ai: compress ulang folder lalu upload ulang. Pengguna AI berbasis repo: cukup `git pull`.

## 7. Menambah fitur, service, atau komponen

AI sudah tahu playbook yang harus dibuka. Ringkasnya:

| Mau menambah | Yang disentuh |
|---|---|
| Layar atau alur baru | Folder fitur sendiri, 1 baris di `AppContainer`, 1 route di `ContentView` |
| Service baru | `Services/<Domain>/`, 1 baris di `AppContainer`, 1 fake di `RetouchTests/Fakes/` |
| Komponen UI | Folder fitur (dipakai 1 fitur) atau `Components/` (dipakai 2 fitur atau lebih) |
| Mengubah file lama | Hanya baris yang perlu diubah |

Playbook dan template (View, ViewModel, Service) ada di `retouch-spec/`.

## 8. File rawan konflik (PENTINGGGGGG)

Ubah seminimal mungkin dan kabari tim dulu:

- `AppContainer.swift`, `ContentView.swift`: hanya tambah baris di bawah, jangan ubah urutan.
- `MirrorViewModel.swift`: kalau lewat 300 baris, usulkan dipecah.
- `ZoomService.swift` dan `ZoomService+*.swift`: perilaku baru masuk ke file sendiri.
- `LightingConfig.swift`, `ZoomTuning.swift`: tulis di PR nilai lama, nilai baru, dan AC yang terpengaruh.
- `project.yml` dan build settings: **jangan diubah!**

## 9. Kesalahan yang sering terjadi

| Kesalahan | Yang benar |
|---|---|
| Lupa `/retouch-spec` atau tidak melampirkan `SPEC.md` | Selalu di awal chat baru |
| Tidak melampirkan file yang diubah | Lampirkan versi terbaru dari repo |
| Langsung minta kode tanpa rencana | Minta rencana dulu |
| Membuat service di View atau ViewModel | Buat di `AppContainer` |
| Membuat folder baru (`Helpers`, `Utils`) | Tanya tech lead dulu |
| Satu PR besar untuk banyak hal | Satu task, satu PR kecil |
| Lupa upload ulang skill setelah versi naik | Upload ulang tiap versi naik |
| Hanya memasang sebagian skill (kurang dari 5) | Pasang dan aktifkan kelimanya |

---

## 10. Apa yang berubah dari Repo?

| Hal | Sebelum | Sesudah |
|---|---|---|
| Jumlah file Swift | 86 | 74 |
| Cara memanggil | 3 jalur berbeda | 1 jalur: View, ViewModel, Service |
| Yang membuat service | `MirrorSession`, `AutoLightDetector`, sebagian View | Hanya `AppContainer` |
| Kamera dan lighting | Satu kelas `AutoLightDetector` | `CameraService` dan `LightingService` |
| Zoom | `ZoomGestureService` 922 baris | `ZoomService` dipecah ke 5 file, masing-masing di bawah 300 baris |
| ViewModel Mirror | `MirrorViewModel` dan `LightingViewModel` | Satu `MirrorViewModel` |
| Debug overlay dan log zoom | Ada | Dihapus |
| Komentar | Bebas | Tidak boleh, kecuali header Xcode |
| Aturan untuk AI | Tidak ada | `retouch-spec/` dan `AGENTS.md` |

Tidak berubah: algoritma zoom, lighting, rendering Metal, tampilan, dan semua fitur. Detail per file ada di `MOVE_MAP.md`.

## 11. Directory Repo

| Lokasi | Isi |
|---|---|
| `SPEC.md` | Spec Retouch product |
| `retouch-spec/` | Aturan engineering untuk manusia dan AI (cara membangunnya) |
| `AGENTS.md` | Penunjuk ke `retouch-spec/` untuk AI yang membaca repo |
| `Retouch/App/` | `RetouchApp`, `AppContainer`, `ContentView` |
| `Retouch/Features/<Fitur>/` | `Views/`, `ViewModels/`, `Components/` milik fitur itu |
| `Retouch/Components/` | Komponen UI yang dipakai 2 fitur atau lebih |
| `Retouch/Models/` | Tipe data biasa |
| `Retouch/Services/` | `Camera/`, `Lighting/`, `Output/`, `ZoomGesture/` |
| `RetouchTests/` | Mengikuti struktur `Retouch/`, plus `Fakes/` |

## 12. Alur pemanggilan

```
View -> ViewModel -> Service -> Model
```

1. View hanya menampilkan dan memanggil method ViewModel.
2. ViewModel menyimpan state layar dan memanggil service.
3. Service mengerjakan kamera, lighting, zoom, dan render.
4. Semua service dibuat di `AppContainer`, lalu dioper ke ViewModel lewat `init`.

Hasil zoom kembali ke layar lewat `ZoomStore`.

## 13. Kenapa dirombak

1. `MirrorSession` dipegang semua orang, jadi hampir tiap PR konflik.
2. Ada 3 cara memanggil service. Tiap anggota cara manggilnya beda-beda
3. Ada file raksasa (`ZoomGestureService` 922 baris, lima tanggung jawab).
4. Kode debug bercampur dengan kode produksi.
5. Belum ada aturan tertulis untuk penempatan file, penamaan, dan cara AI bekerja.