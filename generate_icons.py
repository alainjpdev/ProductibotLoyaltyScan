import os
import json
from PIL import Image, ImageOps

src_path = "/Users/wavesmanagement/scripts/Productibot Loyalty Scan/productibot_qr.png"
appiconset_dir = "/Users/wavesmanagement/scripts/Productibot Loyalty Scan/Sources/Assets.xcassets/AppIcon.appiconset"

img = Image.open(src_path).convert("RGB")
inv = ImageOps.invert(img)
bbox = inv.getbbox()
qr_crop = img.crop(bbox)

# Canvas 1024x1024
canvas = Image.new("RGB", (1024, 1024), (255, 255, 255))
qr_scaled = qr_crop.resize((700, 700), Image.NEAREST)
offset = ((1024 - 700) // 2, (1024 - 700) // 2)
canvas.paste(qr_scaled, offset)

sizes = [
    (20, 1, "ipad"), (20, 2, "ipad"), (20, 2, "iphone"), (20, 3, "iphone"),
    (29, 1, "ipad"), (29, 2, "ipad"), (29, 2, "iphone"), (29, 3, "iphone"),
    (40, 1, "ipad"), (40, 2, "ipad"), (40, 2, "iphone"), (40, 3, "iphone"),
    (60, 2, "iphone"), (60, 3, "iphone"),
    (76, 1, "ipad"), (76, 2, "ipad"),
    (83.5, 2, "ipad"),
    (1024, 1, "ios-marketing")
]

images_meta = []
for size, scale, idiom in sizes:
    px = int(size * scale)
    filename = f"Icon-{size}x{size}@{scale}x-{idiom}.png"
    out_path = os.path.join(appiconset_dir, filename)
    resized = canvas.resize((px, px), Image.LANCZOS)
    resized.save(out_path, "PNG")
    
    size_str = f"{int(size)}x{int(size)}" if size == int(size) else f"{size}x{size}"
    images_meta.append({
        "size": size_str,
        "idiom": idiom,
        "filename": filename,
        "scale": f"{scale}x"
    })

contents = {
    "images": images_meta,
    "info": {
        "version": 1,
        "author": "xcode"
    }
}

with open(os.path.join(appiconset_dir, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)

print("Icons generated successfully from productibot_qr.png.")
