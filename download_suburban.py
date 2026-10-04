import urllib.request
import zipfile
import os
import shutil

urls = {
    'suburban': 'https://kenney.nl/media/pages/assets/city-kit-suburban/2c871b7af2-1745479373/kenney_city-kit-suburban_20.zip',
}

base_dir = "TinyWorld/TinyWorld/art.scnassets"

for name, url in urls.items():
    print(f"Downloading {name}...")
    zip_path = f"{name}.zip"
    
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response, open(zip_path, 'wb') as out_file:
        shutil.copyfileobj(response, out_file)
        
    print(f"Extracting {name}...")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(f"temp_{name}")
        
    models_dir = None
    for root, dirs, files in os.walk(f"temp_{name}"):
        if "OBJ format" in root:
            models_dir = root
            break
            
    if not models_dir:
        for root, dirs, files in os.walk(f"temp_{name}"):
            if "OBJ" in root:
                models_dir = root
                break
                
    if models_dir:
        dest_dir = os.path.join(base_dir, name)
        os.makedirs(dest_dir, exist_ok=True)
        for f in os.listdir(models_dir):
            if f.endswith(('.obj', '.mtl', '.png', '.jpg')):
                shutil.copy2(os.path.join(models_dir, f), dest_dir)
        print(f"Copied models to {dest_dir}")
