import urllib.request
import re

url = 'https://kenney.nl/assets/category:3D?sort=update'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    html = urllib.request.urlopen(req).read().decode('utf-8')
    links = re.findall(r'href=[\'"]?(https?://kenney\.nl/assets/[^\'" >]+)', html)
    print(set([l for l in links if 'character' in l.lower() or 'people' in l.lower() or 'village' in l.lower()]))
except Exception as e:
    print(e)
