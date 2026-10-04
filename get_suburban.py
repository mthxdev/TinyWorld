import urllib.request
import re

url = 'https://kenney.nl/assets/city-kit-suburban'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    html = urllib.request.urlopen(req).read().decode('utf-8')
    links = re.findall(r'href=[\'"]?(https?://[^\'" >]+)', html)
    print([l for l in links if 'download' in l.lower() or 'dl' in l.lower() or '.zip' in l.lower()])
except Exception as e:
    print(e)
