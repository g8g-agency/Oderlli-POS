from PIL import Image

img_path = r"C:\Users\PRAKHAR\.gemini\antigravity-ide\brain\989c4c2d-f753-4819-99ab-9d94b475ce82\menu_page_with_items_1781521127635.png"
img = Image.open(img_path)
w, h = img.size
print(f"Image dimensions: {w}x{h}")

# Search for LightPOSColors.primary: RGB(255, 122, 0)
# We look in the right panel: x > 1000
orange_pixels = []
for y in range(500, h - 10):
    for x in range(1000, w - 10):
        r, g, b, *a = img.getpixel((x, y))
        # Orange/primary color: R in [240, 255], G in [100, 140], B in [0, 20]
        if r > 240 and 100 < g < 140 and b < 20:
            orange_pixels.append((x, y))

if orange_pixels:
    xs = [p[0] for p in orange_pixels]
    ys = [p[1] for p in orange_pixels]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    bw = max_x - min_x + 1
    bh = max_y - min_y + 1
    cx = min_x + bw // 2
    cy = min_y + bh // 2
    print(f"Found orange button: screen_center=({cx}, {cy}), viewport_center=({cx/1.25:.1f}, {cy/1.25:.1f}), size={bw}x{bh}")
else:
    print("No orange pixels found in right panel")

# Let's also print colors at X=1300 for Y between 750 and 850
print("\nVertical profile at X=1300 (Y from 750 to 860):")
last_rgb = None
for y in range(750, 860):
    r, g, b, *a = img.getpixel((1300, y))
    if last_rgb is None or abs(r - last_rgb[0]) > 5 or abs(g - last_rgb[1]) > 5 or abs(b - last_rgb[2]) > 5:
        print(f"Y={y}: RGB=({r}, {g}, {b})")
    last_rgb = (r, g, b)
