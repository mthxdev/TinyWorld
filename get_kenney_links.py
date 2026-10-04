import urllib.request
import re

urls = [
    'https://kenney.nl/assets/tiny-town',
    'https://kenney.nl/assets/mini-characters-1',
    'https://kenney.nl/assets/nature-kit'
]

for url in urls:
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        html = urllib.request.urlopen(req).read().decode('utf-8')
        links = re.findall(r'href=[\'"]?(https?://[^\'" >]+)', html)
        downloads = [l for l in links if 'download' in l.lower() or 'dl' in l.lower() or '.zip' in l.lower()]
        print(f"{url}:")
        for d in downloads:
            print("  -", d)
    except Exception as e:
        print(f"Error on {url}: {e}")
