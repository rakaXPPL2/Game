# DECISIONS.md — Kota Megastruktur Brutalis

Dokumen ini mencatat semua keputusan teknis yang diambil selama pengerjaan proyek.

---

## Fase 0 — Setup & Tooling

**Tanggal:** 2026-11-02

### Keputusan

| Keputusan | Nilai | Alasan |
|---|---|---|
| Godot binary | `D:\Game\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` | Binary console resmi untuk CLI & automation |
| Renderer | Forward Plus | Wajib untuk volumetric fog, SDFGI, SSIL, SSAO |
| Physics engine | Jolt Physics | Bawaan proyek, stabil dan performan |
| GPU API | D3D12 | Default Windows Forward+, optimal di GPU Intel UHD |
| `@export_tool_button` | Tersedia | Godot 4.7 > 4.4, fitur ini ada |
| Shadow atlas directional | 4096 | Sesuai brief §6 Fase 0, Medium preset |
| MSAA 3D | 2x (value=1) | Brief §6 Fase 0 |
| Screen space AA | FXAA (value=1) | Brief §6 Fase 0 |
| Occlusion culling | aktif | Brief §6 Fase 0 |
| Main scene | `res://scenes/main.tscn` | Sesuai struktur brief §5 |

### InputMap
13 aksi terdaftar: `move_forward`, `move_back`, `move_left`, `move_right`, `sprint` (Shift),
`jump` (Space), `toggle_fly` (F), `photo_mode` (P), `screenshot` (F2),
`debug_overlay` (F3), `preset_1` (1), `preset_2` (2), `preset_3` (3).

### Catatan
- `reference/skyline_ref.png` disalin dari gambar referensi pengguna.
- Pipeline screenshot otomatis `screenshot_runner.gd` terverifikasi via CLI `--shot=test_phase0`.

---

## Fase 1 — Blockout Atmosfer

**Tanggal:** 2026-11-02

### Keputusan & Kalibrasi
- **Sky Shader (`shaders/sky_storm.gdshader`):**
  - FBM awan badai di kubah langit dengan gradasi cepat dari haze cakrawala (`#B9B5A8`) ke awan badai gelap pekat (`#3E434C` / `#2E323A`).
  - Sun break terisolasi di sekitar arah matahari.
- **Environment (`environment/city_environment.tres`):**
  - `tonemap_mode` = 3 (ACES), exposure = 0.95, white = 5.0.
  - `adjustment_enabled` = true, contrast = 1.18, saturation = 0.80 (mood desaturasi sinematik).
  - `fog_sky_affect` = 0.08 (agar awan badai gelap atas tidak terbilas kabut).
  - `volumetric_fog_density` = 0.0008, length = 2200.0, anisotropy = 0.3.
  - `ssao_enabled` = true, radius = 4.0, intensity = 2.0.
  - `glow_enabled` = true (bloom 0.1, HDR threshold 1.0).
- **Tata Cahaya (`DirectionalLight3D` Sun):**
  - Rotasi `(-32°, 195°, 0°)`: matahari di depan-kiri atas, menghasilkan pencahayaan backlit dramatis.
  - Energi 2.0, volumetric fog energy 1.6.
- **Komposisi Blockout (`scenes/main.tscn`):**
  - `RefCam` di `(0, 230, 0)`, rotasi pitch -3°, FOV 62°.
  - 10 menara blockout terdistribusi dari jarak 70m hingga 1950m membuktikan 4 lapis kedalaman visual.
- **Hasil:** `screenshots/phase1.png` lolos verifikasi komposisi, kedalaman, dan atmosfer.

---

## Fase 2 — Material Fasad dan Menara Hero

**Tanggal:** 2026-11-02

### Keputusan & Implementasi
- **Shader Fasad (`shaders/facade.gdshader`):**
  - Koordinat dunia (`MODEL_MATRIX * VERTEX`), anti-moire fade `smoothstep(120, 850, dist)`.
  - 3 varian material: `facade_tower.tres`, `facade_sprawl.tres`, `facade_far.tres`.
- **Menara Hero (`scripts/hero_tower.gd`):**
  - Prosedural bertingkat (setback 2–3 tier), pita mekanikal gelap, rusuk vertikal, mahkota, antena, dan lampu aviation merah.
- **Papan Neon (`scripts/neon_sign.gd`):**
  - Teks vertikal bertumpuk, nilai emisi HDR (multiplier 4.5–5.0).
  - Teks orisinal: `KARANG`, `SENJA`, `LUMEN`, `TERAS`, `BLOK-9`.
- **Hasil:** `screenshots/phase2.png` membuktikan fasad beton brutalis realistis, grid jendela menyala tajam di foreground, memudar halus di midground, dan pendar neon tajam.

---

## Fase 3 — Kota (Sprawl + Mid-Tower)

**Tanggal:** 2026-11-02

### Keputusan & Implementasi
- **Generator Kota (`scripts/city_generator.gd`):**
  - Grid blok prosedural dengan pembagian 2–4 lot per blok.
  - `FastNoiseLite` (frekuensi 0.0015) memodulasi tinggi bangunan dan sebaran menara mid.
  - Guard zones: radius 240m di sekitar `RefCam` dan footprint semua menara hero.
  - MultiMesh chunking per 256m (`Vector2i`) untuk culling efisien.
  - Sprawl: `cast_shadow = OFF` untuk menjaga performa rendering tetap tinggi.
  - Mid-tower: `cast_shadow = ON` (terpisah) untuk bayangan dramatis di atap sprawl.
  - Detail atap: tangki/antena dengan `visibility_range_end = 900.0`.
  - Cincin Siluet Horizon: 850 instance siluet jauh pada radius 3000–6200m sudut ±100° dengan `facade_far.tres`.
  - Hasil hitungan instance: 4.845 sprawl + 246 mid-tower (memenuhi target 4.000–12.000 sprawl & 100–300 mid-tower).
- **Ground Shader (`shaders/ground.gdshader`):**
  - Aspal gelap `#15171B` dengan garis jalan prosedural dan titik pendar lampu jalan oranye di persimpangan.
- **Scene Terpisah (`scenes/world/city.tscn`):**
  - Menggabungkan `CityGenerator` dan `Ground` secara modular.
- **Hasil:** `screenshots/phase3.png` membuktikan kepadatan kota brutalis yang penuh hingga horizon tanpa lubang kosong.

---

## Fase 4 — Foreground

**Tanggal:** 2026-11-02

### Keputusan & Implementasi
- **Balkon & Collision (`scenes/world/balcony.tscn`):**
  - Platform menjorok ukuran 55m x 24m x 5m tebal, menembus menara kiri pada ketinggian y = 217.5m.
  - Pagar solid setinggi 1.2m di sisi depan dan samping kanan.
  - Dinding pengaman tak terlihat (`CollisionShape3D` setinggi 4m) agar pemain aman menjelajah balkon tanpa resiko jatuh tak sengaja.
  - Strip pendar hangat di bagian bawah platform (`Mat_Warm_Underside`, emisi 3.5).
  - 8 siluet figur manusia statis (`CapsuleMesh`, radius 0.28m, tinggi 1.78m) berbaris di tepi pagar menikmati panorama kota.
- **Occlusion Culling:**
  - Ditambahkan `OccluderInstance3D` dengan `BoxOccluder3D` pada `H_FG_Left` dan `H_FG_Right`.
- **Hasil:** `screenshots/phase4.png` membuktikan komposisi presisi tepi kiri (0–11%), balkon (0–18%, y 57–66%), dan menara kanan (81–100%) dengan siluet manusia yang hidup.

---

## Fase 5 — God Rays, Awan, Polish

**Tanggal:** 2026-11-02

### Keputusan & Implementasi
- **Berkas Cahaya Diagonal (`scripts/cloud_canopy.gd`):**
  - Mengimplementasikan sistem berkas cahaya volumetrik diagonal terarah (Rencana B/hybrid terkalibrasi) tanpa artefak bayangan kasar, menghasilkan berkas sinar matahari menembus kabut ke arah kota kanan-tengah (x 52–72%, y 25–55%).
  - Spot attenuation halus (1.4–1.8), spot angle 24°–32°, range 2600–2800m dengan warna hangat keemasan (`Color(1.0, 0.90, 0.74)`).
  - Energi volumetrik 4.8–5.5 menghasilkan pendar atmosfer dramatis.
- **Polish & Detil:**
  - Lampu aviation merah berkedip di seluruh menara hero.
  - Kontras visual dan gradasi ACES menjaga kontras neon terhadap kabut tebal.
- **Hasil:** `screenshots/phase5.png` membuktikan berkas cahaya diagonal yang anggun menyinari lembah kota brutalis.

---

## Fase 6 — Pemain dan Mode Foto

**Tanggal:** 2026-11-02

### Keputusan & Implementasi
- **Pemain First-Person (`scripts/player.gd` & `scenes/player/player.tscn`):**
  - `CharacterBody3D` dengan kapsul kolisi, gravitasi 9.8 m/s², jalan kaki 3.5 m/s, sprint 7.0 m/s (Shift), lompat 4.5 m/s (Space).
  - Spawn di atas balkon di `(-45.0, 220.5, -68.0)` menghadap pemandangan kota.
  - Mouse look dengan penangkap kursor (ESC untuk buka/tutup kursor).
- **Mode Kamera Bebas (Free Cam / Noclip):**
  - Tombol `F`: toggle terbang bebas menembus ruang tanpa tabrakan.
  - Kecepatan terbang diatur via scroll wheel mouse: 50 m/s, 200 m/s, dan 800 m/s.
  - Kontrol vertikal: E (naik) dan Q (turun).
- **Mode Foto Sinematik (`scripts/photo_mode.gd`):**
  - Tombol `P`: toggle sembunyikan semua UI / HUD.
- **Diagnostik & Debug Overlay (`scripts/debug_overlay.gd`):**
  - Tombol `F3`: overlay panel menampilkan FPS, frame time (ms), total Draw Calls, jumlah objek, primitives, dan nama preset grafis aktif.
- **Preset Kualitas Runtime (`scripts/quality_presets.gd`):**
  - Tombol `1` (Low), `2` (Medium), `3` (High).
- **Tangkapan Layar Pemain (`screenshot_runner.gd`):**
  - Tombol `F2`: simpan langsung tangkapan layar beresolusi penuh ke `user://shots/`.
- **Hasil:** `screenshots/phase6.png` memverifikasi kesiapan kontrol dan penjelajahan level secara lancar.

---
