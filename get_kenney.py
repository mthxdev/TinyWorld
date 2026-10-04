import urllib.request
import re

url = 'https://kenney.nl/assets/nature-kit'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    html = urllib.request.urlopen(req).read().decode('utf-8')
    links = re.findall(r'href=[\'"]?(https?://[^\'" >]+)', html)
    print([l for l in links if 'download' in l.lower() or 'dl' in l.lower() or '.zip' in l.lower()])
    
    # Also find any form actions
    actions = re.findall(r'action=[\'"]?(https?://[^\'" >]+)', html)
    print("Actions:", actions)
    
    # Just print the first 20 lines to see where the download button points
    import bs4
except Exception as e:
    print(e)
