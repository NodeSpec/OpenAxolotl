from pathlib import Path
import json,urllib.request,urllib.parse,hashlib,concurrent.futures
ROOT=Path(__file__).resolve().parent
tree=json.loads((ROOT/'drum-tree.json').read_text());revision=tree['sha']
paths=['Membranophones/Struck Membranophones/Bass Drum 1/BDrumNew_hit_v3_rr1_Sum.wav',
 'Membranophones/Struck Membranophones/Snare Drum, Modern 3/Snare4_HitSN_v4_rr1_Mid.wav',
 'Idiophones/Struck Idiophones/Hi-Hat Cymbal/HiHat_HitC_v2_rr1_Mid.wav','LICENSE','README.md']
def fetch(path):
    url=f'https://raw.githubusercontent.com/sgossner/VCSL/{revision}/'+urllib.parse.quote(path)
    p=ROOT/'samples/vcsl'/path;p.parent.mkdir(parents=True,exist_ok=True)
    if not p.exists():p.write_bytes(urllib.request.urlopen(url,timeout=60).read())
    return {'path':path,'url':url,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:files=list(pool.map(fetch,paths))
(ROOT/'drum-manifest.json').write_text(json.dumps({'repository':'https://github.com/sgossner/VCSL','revision':revision,'license':'CC0-1.0','files':files},indent=2))
print('Downloaded recorded kit and CC0 license:',sum(f['bytes'] for f in files),'bytes')
