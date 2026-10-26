from pathlib import Path
import json, urllib.request, urllib.parse, concurrent.futures, hashlib
ROOT=Path(__file__).resolve().parent
tree=json.loads((ROOT/'sample-tree.json').read_text())
revision=tree['sha']
paths=[]
for item in tree['tree']:
    p=item['path']
    if (p.startswith('Strings/Harp/') and any('_'+n+'_' in p for n in ['D2','A2','C3','E3','G3','B3','D4','F4','A4','C5','E5','G5'])) or (p.startswith('Percussion/Marimba/') and any('_'+n+'_' in p for n in ['C2','G2','F3','C4','G4','B4'])) or (p.startswith('Woodwinds/Flute/susNV/') and '_v1_1.wav' in p and any('_'+n+'_' in p for n in ['A3','C4','E4','A4','C5'])) or (p.startswith('Strings/Solo Contrabass/Pizz/') and '_v1_rr1.wav' in p and any('_'+n+'_' in p for n in ['D1','G0','A1','C1','E1'])) or (p.startswith('Keys/Upright Piano/Player_dyn1_') and any('_'+n+'.wav' in p for n in ['014','018','022','026','030'])):
        paths.append(p)
paths+=['LICENSE','README.md']
def download(p):
    target=ROOT/'samples'/p
    target.parent.mkdir(parents=True,exist_ok=True)
    url='https://raw.githubusercontent.com/sgossner/VSCO-2-CE/'+revision+'/'+urllib.parse.quote(p)
    if not target.exists():target.write_bytes(urllib.request.urlopen(url,timeout=60).read())
    return {'path':p,'url':url,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'bytes':target.stat().st_size}
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
    manifest=list(pool.map(download,paths))
(ROOT/'samples-manifest.json').write_text(json.dumps({'repository':'https://github.com/sgossner/VSCO-2-CE','revision':revision,'license':'CC0-1.0','files':manifest},indent=2))
print('Downloaded',len(manifest),'files;',round(sum(x['bytes'] for x in manifest)/1048576,2),'MiB')
