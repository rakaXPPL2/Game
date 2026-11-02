# DECISIONS.md — Kota Megastruktur Brutalis

Dokumen ini mencatat semua keputusan teknis yang diambil selama pengerjaan proyek.

---

## Fase 0 — Setup & Tooling

**Tanggal:** 2026-11-02

### Keputusan

| Keputusan | Nilai | Alasan |
|---|---|---|
| Godot binary | `D:\Game\Godot_v4.7.2-stable_win64.exe` | Ditemukan via scan drive D |
| Renderer | Forward Plus | Wajib untuk volumetric fog, SDFGI, SSIL, SSAO |
| Physics engine | Jolt Physics | Sudah ada di project.godot sebelumnya |
| GPU API | D3D12 | Default Windows, performa lebih baik dari Vulkan di beberapa GPU |
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
- `kotak.tscn` dari eksperimen sebelumnya dibiarkan di root; tidak dihapus agar tidak mengganggu editor state.
- Reference image disalin dari lampiran chat ke `reference/skyline_ref.png`.

---
