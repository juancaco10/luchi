"""Genera el foreground del icono adaptativo de Android a partir de
app_logo.png, inscrito en la zona segura (66% del lienzo de 108dp) para que
ningún launcher (círculo, squircle, cuadrado redondeado...) recorte el
dibujo al aplicar su máscara.
"""
from PIL import Image
import os

SRC = "assets/images/app_logo.png"
OUT_DIR = "android/app/src/main/res"

# density -> tamaño del lienzo del foreground en px (108dp * factor de densidad)
DENSITIES = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}

SAFE_ZONE_RATIO = 0.66  # el 33% restante puede quedar recortado por la máscara

src = Image.open(SRC).convert("RGBA")

for folder, canvas_size in DENSITIES.items():
    logo_size = int(canvas_size * SAFE_ZONE_RATIO)
    logo = src.resize((logo_size, logo_size), Image.LANCZOS)

    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    offset = ((canvas_size - logo_size) // 2, (canvas_size - logo_size) // 2)
    canvas.paste(logo, offset, logo)

    out_path = os.path.join(OUT_DIR, folder, "ic_launcher_foreground.png")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    canvas.save(out_path)
    print(f"{out_path}  {canvas_size}x{canvas_size} (logo {logo_size}px)")
