"""tools/compare.py — Bandingkan grid 8x6 warna & luminans antara skyline_ref.png dan screenshot."""

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow tidak terpasang. Jalankan: pip install pillow")
    sys.exit(0)

def compare_images(ref_path: str, shot_path: str, grid_cols: int = 8, grid_rows: int = 6):
    ref_file = Path(ref_path)
    shot_file = Path(shot_path)

    if not ref_file.exists():
        print(f"File referensi tidak ditemukan: {ref_path}")
        return
    if not shot_file.exists():
        print(f"File screenshot tidak ditemukan: {shot_path}")
        return

    ref_img = Image.open(ref_file).convert("RGB").resize((1920, 1080))
    shot_img = Image.open(shot_file).convert("RGB").resize((1920, 1080))

    cell_w = 1920 // grid_cols
    cell_h = 1080 // grid_rows

    total_diff = 0.0
    cell_count = grid_cols * grid_rows

    print(f"\n=== Perbandingan Grid {grid_cols}x{grid_rows} ===")
    print(f"Ref: {ref_file.name} vs Shot: {shot_file.name}\n")

    for r in range(grid_rows):
        row_str = []
        for c in range(grid_cols):
            box = (c * cell_w, r * cell_h, (c + 1) * cell_w, (r + 1) * cell_h)
            ref_crop = ref_img.crop(box)
            shot_crop = shot_img.crop(box)

            ref_stat = ref_crop.resize((1, 1)).getpixel((0, 0))
            shot_stat = shot_crop.resize((1, 1)).getpixel((0, 0))

            diff = sum(abs(ref_stat[i] - shot_stat[i]) for i in range(3)) / 3.0
            total_diff += diff
            row_str.append(f"{diff:4.1f}")
        print(f"Row {r}: " + " | ".join(row_str))

    avg_diff = total_diff / cell_count
    print(f"\nRata-rata deviasi warna per sel: {avg_diff:.2f} / 255 ({(avg_diff / 255.0) * 100:.1f}%)")

if __name__ == "__main__":
    ref = sys.argv[1] if len(sys.argv) > 1 else "reference/skyline_ref.png"
    shot = sys.argv[2] if len(sys.argv) > 2 else "screenshots/phase6.png"
    compare_images(ref, shot)
