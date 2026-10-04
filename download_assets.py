import urllib.request
import zipfile
import os
import shutil

urls = {
    'nature': 'https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip',
    'city': 'https://kenney.nl/media/pages/assets/tiny-town/a415fbeb49-1735736916/kenney_tiny-town.zip'
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
        
    # Find Models/OBJ format folder inside temp_name
    models_dir = None
    for root, dirs, files in os.walk(f"temp_{name}"):
        if "Models" in dirs and "OBJ format" in os.path.join(root, "Models"):
            pass # sometimes it's flat
        if "OBJ format" in root:
            models_dir = root
            break
            
    if not models_dir:
        # Check if there is an OBJ folder
        for root, dirs, files in os.walk(f"temp_{name}"):
            if "OBJ" in root:
                models_dir = root
                break
                
    if models_dir:
        dest_dir = os.path.join(base_dir, name)
        os.makedirs(dest_dir, exist_ok=True)
        # copy all .obj, .mtl, .png
        for f in os.listdir(models_dir):
            if f.endswith(('.obj', '.mtl', '.png')):
                shutil.copy2(os.path.join(models_dir, f), dest_dir)
        print(f"Copied models to {dest_dir}")
        
        # We also need textures! Usually Kenney puts them in a Textures folder.
        # But for OBJ, the .mtl references .png directly if they are together.
    
    print(f"Done {name}.")
