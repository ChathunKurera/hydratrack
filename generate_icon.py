#!/usr/bin/env python3

from PIL import Image, ImageDraw, ImageFont
import math
import os

def create_water_bottle_icon(size):
    """Create water bottle icon at given size"""
    img = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(img, 'RGBA')

    scale = size / 1024.0

    # Background gradient (simplified as solid colors)
    # Top part
    draw.rectangle([(0, 0), (size, size * 0.3)], fill=(26, 128, 230))
    # Bottom part
    draw.rectangle([(0, size * 0.3), (size, size)], fill=(0, 179, 255))

    # Bottle cap
    cap_width = int(180 * scale)
    cap_height = int(80 * scale)
    cap_x = (size - cap_width) // 2
    cap_y = int(150 * scale)
    draw.rounded_rectangle(
        [(cap_x, cap_y), (cap_x + cap_width, cap_y + cap_height)],
        radius=int(15 * scale),
        fill=(255, 255, 255, 77)  # white with alpha
    )

    # Bottle neck
    neck_width = int(150 * scale)
    neck_height = int(60 * scale)
    neck_x = (size - neck_width) // 2
    neck_y = cap_y + cap_height
    draw.rectangle(
        [(neck_x, neck_y), (neck_x + neck_width, neck_y + neck_height)],
        fill=(255, 255, 255, 64)
    )

    # Main bottle body
    bottle_width = int(400 * scale)
    bottle_height = int(650 * scale)
    bottle_x = (size - bottle_width) // 2
    bottle_y = neck_y + neck_height
    draw.rounded_rectangle(
        [(bottle_x, bottle_y), (bottle_x + bottle_width, bottle_y + bottle_height)],
        radius=int(60 * scale),
        fill=(255, 255, 255, 51)
    )

    # Water fill (70% of bottle)
    water_width = int(360 * scale)
    water_height = int(455 * scale)
    water_x = (size - water_width) // 2
    water_y = bottle_y + bottle_height - water_height - int(15 * scale)
    draw.rounded_rectangle(
        [(water_x, water_y), (water_x + water_width, water_y + water_height)],
        radius=int(50 * scale),
        fill=(77, 217, 255, 217)
    )

    # Highlight on bottle
    highlight_width = int(120 * scale)
    highlight_height = int(300 * scale)
    highlight_x = bottle_x + int(50 * scale)
    highlight_y = water_y + int(50 * scale)
    draw.rounded_rectangle(
        [(highlight_x, highlight_y), (highlight_x + highlight_width, highlight_y + highlight_height)],
        radius=int(20 * scale),
        fill=(255, 255, 255, 77)
    )

    # Water surface wave (simplified)
    wave_y = water_y + int(5 * scale)
    wave_points = []
    for x in range(int(water_x), int(water_x + water_width), max(1, int(5 * scale))):
        relative_x = (x - water_x) / (50 * scale)
        sine_value = math.sin(relative_x * math.pi)
        y = wave_y + int(sine_value * 8 * scale)
        wave_points.append((x, y))

    # Draw wave as polygon
    if len(wave_points) > 2:
        wave_polygon = wave_points + [(water_x + water_width, water_y + int(50 * scale)), (water_x, water_y + int(50 * scale))]
        draw.polygon(wave_polygon, fill=(128, 255, 255, 102))

    # Draw "70%" text
    try:
        # Try to use a nice bold font
        font_size = int(140 * scale)
        try:
            # macOS system fonts
            font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", font_size)
        except:
            try:
                font = ImageFont.truetype("/Library/Fonts/Arial Bold.ttf", font_size)
            except:
                # Fallback to default
                font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()

    text = "70%"

    # Get text bounding box
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    text_x = (size - text_width) // 2
    text_y = (size - text_height) // 2 + int(50 * scale)

    # Draw text with shadow
    shadow_offset = max(1, int(3 * scale))
    draw.text((text_x + shadow_offset, text_y + shadow_offset), text, font=font, fill=(0, 0, 0, 77))
    draw.text((text_x, text_y), text, font=font, fill=(255, 255, 255, 255))

    return img

# Icon sizes needed
icon_configs = [
    ("icon_20x20.png", 20),
    ("icon_29x29.png", 29),
    ("icon_40x40.png", 40),
    ("icon_58x58.png", 58),
    ("icon_60x60.png", 60),
    ("icon_76x76.png", 76),
    ("icon_80x80.png", 80),
    ("icon_87x87.png", 87),
    ("icon_120x120.png", 120),
    ("icon_152x152.png", 152),
    ("icon_167x167.png", 167),
    ("icon_180x180.png", 180),
    ("icon_1024x1024.png", 1024),
]

output_dir = "/Users/chathunkurera/HydraTrack/HydraTrack/Assets.xcassets/AppIcon.appiconset"

print("Generating HydraTrack water bottle icons...")
print(f"Output directory: {output_dir}\n")

for filename, size in icon_configs:
    icon = create_water_bottle_icon(size)
    filepath = os.path.join(output_dir, filename)
    icon.save(filepath, "PNG")
    print(f"✓ Created: {filename}")

print(f"\n✅ All {len(icon_configs)} icons generated successfully!")
print(f"Icons saved to: {output_dir}")
