import os
from PIL import Image

def test_tahoe_assets():
    dark_wp = "assets/wallpapers/macOS-Tahoe-Dark.jpg"
    light_wp = "assets/wallpapers/macOS-Tahoe-Light.jpg"
    assert os.path.isfile(dark_wp), "Dark wallpaper missing"
    assert os.path.isfile(light_wp), "Light wallpaper missing"
    
    with Image.open(dark_wp) as im:
        assert im.width >= 2560 and im.height >= 1440
    with Image.open(light_wp) as im:
        assert im.width >= 2560 and im.height >= 1440

    assert os.path.isfile("assets/themes/macOS-Tahoe-Dark/gtk-3.0/gtk.css")
    assert os.path.isfile("assets/themes/macOS-Tahoe-Light/gtk-3.0/gtk.css")
    assert os.path.isfile("assets/icons/stage-manager.svg")
    print("All Tahoe assets verified!")

if __name__ == "__main__":
    test_tahoe_assets()
