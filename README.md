# Kota Megastruktur Brutalis

Level 3D di Godot 4.7 — pemandangan kota brutalis dari balkon menara.

## Cara Menjalankan

```
# Buka editor
D:\Game\Godot_v4.7.2-stable_win64.exe --path .

# Jalankan headless (verifikasi)
D:\Game\Godot_v4.7.2-stable_win64.exe --headless --path . --quit-after 5

# Screenshot fase
D:\Game\Godot_v4.7.2-stable_win64.exe --path . --resolution 1920x1080 -- --shot=phase1 --preset=medium
```

## Kontrol

| Tombol | Aksi |
|---|---|
| WASD | Jalan |
| Shift | Sprint |
| Space | Lompat |
| F | Toggle free cam (noclip) |
| P | Photo mode |
| F2 | Screenshot |
| F3 | Debug overlay (FPS, draw call) |
| 1 / 2 / 3 | Preset Low / Medium / High |

## Struktur Proyek

```
scenes/     — scene utama, city, balkon, player
scripts/    — GDScript semua sistem
shaders/    — facade, ground, sky
environment/— WorldEnvironment resource
reference/  — gambar referensi skyline
screenshots/— hasil verifikasi tiap fase
docs/       — brief dan decisions
```

## Kredit

Semua aset prosedural. Tidak ada aset pihak ketiga.
