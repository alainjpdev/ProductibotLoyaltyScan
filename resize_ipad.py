import os
from PIL import Image
import glob

# Rutas
input_dir = os.path.expanduser("~/scripts/Productibot Loyalty Scan")
output_dir = os.path.expanduser("~/Desktop/AppStore_Screenshots_iPad")
os.makedirs(output_dir, exist_ok=True)

# Dimensiones exactas de iPad Pro 12.9" para App Store
TARGET_WIDTH = 2048
TARGET_HEIGHT = 2732

# Encontrar los archivos PNG con nombres de UUID
png_files = [f for f in glob.glob(os.path.join(input_dir, "*.PNG")) if "-" in os.path.basename(f)]

for idx, img_path in enumerate(png_files):
    img = Image.open(img_path).convert("RGB")
    original_width, original_height = img.size
    
    # Calcular ratio para Aspect Fill (llenar la pantalla completa recortando el exceso)
    ratio_w = TARGET_WIDTH / original_width
    ratio_h = TARGET_HEIGHT / original_height
    ratio = max(ratio_w, ratio_h)
    
    new_width = int(original_width * ratio)
    new_height = int(original_height * ratio)
    
    # Redimensionar
    img_resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # Recortar el centro exacto
    left = (new_width - TARGET_WIDTH) / 2
    top = (new_height - TARGET_HEIGHT) / 2
    right = (new_width + TARGET_WIDTH) / 2
    bottom = (new_height + TARGET_HEIGHT) / 2
    
    img_cropped = img_resized.crop((left, top, right, bottom))
    
    # Guardar
    output_filename = f"iPad_Screenshot_{idx + 1}.png"
    output_path = os.path.join(output_dir, output_filename)
    img_cropped.save(output_path, "PNG")
    print(f"Generado iPad: {output_path}")

print("¡Proceso de iPad terminado!")
