import os
from PIL import Image, ImageOps, ImageDraw, ImageFont

workspace = "/Users/wavesmanagement/scripts/Productibot Loyalty Scan"
src_qr = os.path.join(workspace, "productibot_qr.png")
src_logo = os.path.join(workspace, "logo 2.png")
output_dir = os.path.join(workspace, "PlayStore_Assets")
os.makedirs(output_dir, exist_ok=True)

# 1. Generar Ícono de Google Play Store (512 x 512 px)
icon_size = 512
icon = Image.new("RGBA", (icon_size, icon_size), (255, 255, 255, 255))

if os.path.exists(src_qr):
    img = Image.open(src_qr).convert("RGB")
    inv = ImageOps.invert(img)
    bbox = inv.getbbox()
    qr_crop = img.crop(bbox)
    qr_scaled = qr_crop.resize((360, 360), Image.Resampling.LANCZOS)
    offset = ((icon_size - 360) // 2, (icon_size - 360) // 2)
    icon.paste(qr_scaled, offset)
else:
    print("No se encontró productibot_qr.png")

icon_path = os.path.join(output_dir, "icon_512x512.png")
icon.save(icon_path, "PNG")
print(f"✓ Ícono generado para Google Play: {icon_path}")

# 2. Generar Gráfico de Funciones / Feature Graphic (1024 x 500 px)
fg_width, fg_height = 1024, 500
feature_graphic = Image.new("RGB", (fg_width, fg_height), (15, 20, 30))
draw = ImageDraw.Draw(feature_graphic)

# Dibujar degradado oscuro estilizado
for y in range(fg_height):
    ratio = y / fg_height
    r = int(18 * (1 - ratio) + 10 * ratio)
    g = int(23 * (1 - ratio) + 13 * ratio)
    b = int(36 * (1 - ratio) + 20 * ratio)
    draw.line([(0, y), (fg_width, y)], fill=(r, g, b))

# Agregar logotipo o ícono centrado/lateral si existe
if os.path.exists(src_logo):
    logo = Image.open(src_logo).convert("RGBA")
    logo.thumbnail((260, 260), Image.Resampling.LANCZOS)
    # Centrar verticalmente a la izquierda
    feature_graphic.paste(logo, (80, (fg_height - logo.height) // 2), logo)
elif os.path.exists(src_qr):
    qr_mini = icon.resize((240, 240), Image.Resampling.LANCZOS)
    feature_graphic.paste(qr_mini, (80, (fg_height - 240) // 2), qr_mini)

# Renderizar textos en el banner
try:
    font_title = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 46)
    font_sub = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 24)
except Exception:
    font_title = ImageFont.load_default()
    font_sub = ImageFont.load_default()

draw.text((380, 190), "Productibot QR SCAN", fill=(255, 255, 255), font=font_title)
draw.text((380, 260), "Terminal de Escaneo para Personal", fill=(0, 210, 255), font=font_sub)
draw.text((380, 305), "Lealtad, Visitas y Canje de Premios", fill=(180, 190, 210), font=font_sub)

fg_path = os.path.join(output_dir, "feature_graphic_1024x500.png")
feature_graphic.save(fg_path, "PNG")
print(f"✓ Feature Graphic generado para Google Play: {fg_path}")

print("Todos los activos para Google Play Store generados exitosamente.")
