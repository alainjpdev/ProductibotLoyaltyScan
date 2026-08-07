from PIL import Image

# Load the original image
img_path = "/Users/wavesmanagement/scripts/Productibot Loyalty Scan/logo 2.png"
out_path = "/Users/wavesmanagement/scripts/Productibot Loyalty Scan/Sources/Assets.xcassets/Logo.imageset/logo.png"

img = Image.open(img_path).convert("RGBA")
datas = img.getdata()

newData = []
for item in datas:
    # change white or near-white background to black
    if item[0] > 240 and item[1] > 240 and item[2] > 240:
        newData.append((0, 0, 0, item[3])) # Black
    else:
        newData.append(item)

img.putdata(newData)
img.save(out_path, "PNG")
print("Image background changed to black successfully.")
