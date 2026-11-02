# Kota Megastruktur Brutalis (Godot 4.7 Forward+)

Pemandangan kota megastruktur brutalis prosedural 3D dilihat dari balkon menara tinggi berkabut di engine **Godot 4.7** (renderer **Forward+**).

Proyek ini dibuat mengikuti panduan `docs/CITY_BRIEF.md` dengan seluruh aset (geometri bangunan, fasad jendela, material aspal, tata cahaya, kabut volumetrik, dan awan badai) dibangun secara **100% prosedural**.

---

## Cara Menjalankan

### 1. Buka di Godot Editor
```powershell
& "D:\Game\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path "D:\Project\Game Persis\game-persis"
```
Tekan **F5** di dalam editor untuk menjalankan scene utama.

### 2. Jalankan Mode Permainan Interaktif Langsung
```powershell
& "D:\Game\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path "D:\Project\Game Persis\game-persis" --resolution 1920x1080
```

### 3. Otomatisasi Verifikasi & Tangkapan Layar
```powershell
# Uji coba headless (verifikasi bebas error)
& "D:\Game\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path "D:\Project\Game Persis\game-persis" --quit-after 5

# Ambil screenshot kamera referensi RefCam dengan preset Medium
& "D:\Game\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path "D:\Project\Game Persis\game-persis" --resolution 1920x1080 -- --shot=hasil_akhir --preset=medium
```

---

## Kontrol Permainan

| Tombol / Masukan | Fungsi |
|---|---|
| **W, A, S, D** | Berjalan di balkon |
| **Shift** (Tahan) | Lari / Sprint (7 m/s) |
| **Spasi** | Melompat |
| **Mouse** | Melihat sekeliling (kursor otomatis terkunci) |
| **ESC** | Kunci / Lepas kursor mouse |
| **F** | **Mode Kamera Bebas (Free Cam / Noclip)** |
| **Scroll Wheel (Naik / Turun)** | Mengatur kecepatan Free Cam: **50 m/s**, **200 m/s**, **800 m/s** |
| **E / Q** (Saat Free Cam) | Naik / Turun secara vertikal |
| **P** | **Mode Foto** (sembunyikan seluruh UI dan HUD) |
| **F2** | Simpan tangkapan layar beresolusi penuh ke `user://shots/` |
| **F3** | **Debug Overlay** (menampilkan FPS, Draw Calls, Primitives, Preset) |
| **1** | Beralih ke preset kualitas **Low** |
| **2** | Beralih ke preset kualitas **Medium** (Default) |
| **3** | Beralih ke preset kualitas **High** (SDFGI + TAA) |

---

## Preset Grafis

| Fitur | Low (1) | Medium (2 - Default) | High (3) |
|---|---|---|---|
| **Volumetric Fog** | Nonaktif | Aktif (Kepadatan 0.0008, Panjang 2200m) | Aktif (Kepadatan 0.0012, Panjang 2500m) |
| **SSAO** | Nonaktif | Aktif (Radius 4.0m) | Aktif (Radius 6.0m) |
| **Glow & Bloom** | Aktif (ACES HDR) | Aktif (ACES HDR) | Aktif (ACES HDR) |
| **SDFGI / SSIL** | Nonaktif | Nonaktif | Aktif |
| **Directional Shadow** | Orthogonal | Parallel 4-Splits | Parallel 4-Splits |
| **Anti-Aliasing** | FXAA | MSAA 2x + FXAA | MSAA 2x + TAA |
| **Draw Calls Terukur** | ~615 | ~616 | ~620 |

---

## Struktur Proyek

```
res://
  project.godot                   # Konfigurasi engine Forward+, InputMap, D3D12, Jolt
  reference/skyline_ref.png       # Gambar referensi visual komposisi
  docs/
    CITY_BRIEF.md                 # Brief instruksi arsitektur proyek
    DECISIONS.md                  # Log keputusan teknis dari Fase 0 hingga Fase 7
  scenes/
    main.tscn                     # Scene utama (Tata cahaya, kamera, controller)
    world/
      city.tscn                   # Modular scene: Generator kota + Ground shader
      hero_tower.tscn             # Template menara monolit hero
      balcony.tscn                # Platform balkon dengan collision pagar & siluet manusia
    player/
      player.tscn                 # Karakter first-person dengan kapsul kolisi & noclip
  scripts/
    main.gd                       # Orkestrator scene & penentu kamera aktif
    city_generator.gd             # Generator MultiMesh chunking per 256m
    hero_tower.gd                 # Generator menara brutalis bertingkat prosedural
    neon_sign.gd                  # Generator papan teks vertikal pendar HDR
    cloud_canopy.gd               # Sistem berkas cahaya (God Rays) volumetrik
    quality_presets.gd            # Pengatur preset kualitas runtime (Low/Med/High)
    player.gd                     # Logika kontrol first-person & kamera noclip
    photo_mode.gd                 # Mode foto sinematik
    debug_overlay.gd              # Overlay diagnostik performa F3
    screenshot_runner.gd          # Autoload runner verifikasi screenshot
  shaders/
    facade.gdshader               # Fasad beton brutalis berbasis koordinat dunia & anti-moire
    ground.gdshader               # Aspal jalan prosedural dengan marka dan titik lampu
    sky_storm.gdshader            # Kubah awan badai FBM prosedural dengan sun break
  environment/
    city_environment.tres         # Environment Forward+: tonemap ACES, kabut, SSAO, glow
    camera_attributes.tres        # CameraAttributesPractical manual exposure
    facade_tower.tres             # Material fasad menara hero
    facade_sprawl.tres            # Material fasad hunian padat sprawl
    facade_far.tres               # Material fasad siluet menara jauh & cincin horizon
    ground_material.tres          # Material aspal kota
  screenshots/                    # Bukti verifikasi visual tiap fase (phase1 - phase6)
  tools/
    compare.py                    # Script pembanding grid 8x6 (Pillow)
```

---

## Keputusan Teknis & Orisinalitas

1. **Aset 100% Prosedural:**
   - Tidak ada aset eksternal yang diunduh.
   - Papan neon menggunakan teks vertikal orisinal: `KARANG`, `SENJA`, `LUMEN`, `TERAS`, `BLOK-9`.
2. **Optimasi Tingkat Tinggi:**
   - 4.845 bangunan sprawl menggunakan `MultiMeshInstance3D` yang di-chunk per 256 meter untuk culling otomatis.
   - Bayangan dinonaktifkan pada bangunan sprawl dan hanya diaktifkan pada menara hero dan mid-tower.
   - Total draw call terjaga di kisaran **~616**, jauh di bawah batas toleransi (1.500 draw call).
3. **Pencahayaan Volumetrik & God Rays:**
   - Menggunakan `DirectionalLight3D` sudut datang (-32°, 195°, 0°) dengan berkas cahaya volumetrik diagonal menembus kabut tebal ke arah pemukiman kota.

---

## Kredit
Dikerjakan secara pair-programming agentic menggunakan Antigravity dan Godot Engine 4.7.
