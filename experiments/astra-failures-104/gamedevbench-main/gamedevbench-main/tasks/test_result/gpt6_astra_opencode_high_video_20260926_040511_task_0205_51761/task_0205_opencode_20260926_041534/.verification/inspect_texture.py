from PIL import Image
from PIL import ImageDraw

image = Image.open('/workspace/assets/sprites/tree_image.jpg')
image.crop((1370, 1250, 2420, 1510)).save('/workspace/.verification/tree_tips.png')

preview = image.resize((960, 540))
draw = ImageDraw.Draw(preview)
for x in range(0, 3841, 240):
    px = x // 4
    draw.line((px, 0, px, 540), fill=(255, 0, 0), width=1)
    draw.text((px + 2, 2), str(x), fill=(255, 0, 0))
for y in range(0, 2161, 120):
    py = y // 4
    draw.line((0, py, 960, py), fill=(255, 0, 0), width=1)
    draw.text((2, py + 2), str(y), fill=(255, 0, 0))
preview.save('/workspace/.verification/tree_grid.png')
