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
  - Menara kiri gelap, menara kanan terang dengan lengan menjorok, balkon kiri dengan siluet ledge, menara mid-left dengan strip neon teal bersinar, menara kaca hitam di kanan-tengah.
- **Hasil:** `screenshots/phase1.png` lolos verifikasi komposisi, kedalaman, dan atmosfer.

---
