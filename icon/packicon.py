import os
from PIL import Image

def create_ico(image_path, output_path):
    img = Image.open(image_path)
    icon_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    img.save(output_path, sizes=icon_sizes)

def create_icns(image_path, output_path):
    os.system(f"sips -s format png {image_path} --out tmp.png")

def main():
    # Ensure output directories exist
    os.makedirs("./win", exist_ok=True)

    # Path to your source image
    source_image = "raw/PluginScanner.png"  # Replace with your image path

    # Generate .ico file
    create_ico(source_image, "./win/PluginScanner.ico")

    print("Icon pack generated successfully!")

if __name__ == "__main__":
    main()
