import json
import os
import subprocess

icon_source = "/Users/wavesmanagement/scripts/Productibot Loyalty Scan/logo 2.png"
appiconset_dir = "/Users/wavesmanagement/scripts/Productibot Loyalty Scan/Sources/Assets.xcassets/AppIcon.appiconset"

sizes = [
    (20, 1, "ipad"), (20, 2, "ipad"), (20, 2, "iphone"), (20, 3, "iphone"),
    (29, 1, "ipad"), (29, 2, "ipad"), (29, 2, "iphone"), (29, 3, "iphone"),
    (40, 1, "ipad"), (40, 2, "ipad"), (40, 2, "iphone"), (40, 3, "iphone"),
    (60, 2, "iphone"), (60, 3, "iphone"),
    (76, 1, "ipad"), (76, 2, "ipad"),
    (83.5, 2, "ipad"),
    (1024, 1, "ios-marketing")
]

images = []

for size, scale, idiom in sizes:
    pixel_size = int(size * scale)
    filename = f"Icon-{size}x{size}@{scale}x-{idiom}.png"
    filepath = os.path.join(appiconset_dir, filename)
    subprocess.run(["sips", "-z", str(pixel_size), str(pixel_size), icon_source, "--out", filepath], stdout=subprocess.DEVNULL)
    
    if size == int(size):
        size_str = f"{int(size)}x{int(size)}"
    else:
        size_str = f"{size}x{size}"
        
    images.append({
        "size": size_str,
        "idiom": idiom,
        "filename": filename,
        "scale": f"{scale}x"
    })

contents = {
    "images": images,
    "info": {
        "version": 1,
        "author": "xcode"
    }
}

with open(os.path.join(appiconset_dir, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)

print("Icons generated successfully.")
