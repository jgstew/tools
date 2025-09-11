# Requires Pillow: python -m pip install --upgrade Pillow
from PIL import Image

Image_Object = Image.open("example.png")

# resize
Image_Object_Resized = Image_Object.resize((48, 48), Image.ANTIALIAS)

# save and optimize
Image_Object_Resized.save("png_resize_optimized.png", optimize=True)

# https://stackoverflow.com/questions/273946/how-do-i-resize-an-image-using-pil-and-maintain-its-aspect-ratio
# https://pillow.readthedocs.io/en/stable/reference/Image.html
# https://stackoverflow.com/questions/10607468/how-to-reduce-the-image-file-size-using-pil
