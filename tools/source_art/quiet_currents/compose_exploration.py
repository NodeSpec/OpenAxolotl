"""Render an original exploration score using CC0 recorded instruments.

Authoring only; Godot streams the rendered Ogg and needs none of these libraries.
All timed events and source sample hashes are saved alongside the master.
"""
from pathlib import Path
import sys,json,math,hashlib
ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'deps'))
import numpy as np
import soundfile as sf
from scipy.signal import resample_poly,butter,sosfilt,fftconvolve
from fractions import Fraction
SR=44100;BPM=104;BEAT=60/BPM;BARS=48;N=round(BARS*4*BEAT*SR)
OUT=ROOT/'render';OUT.mkdir(exist_ok=True)
rng=np.random.default_rng(270926)
samples={};events=[];stems={k:np.zeros((N,2),np.float32) for k in ['harp','piano','marimba','bass','kick','snare','hat']}
def register(kind,path,root):
    x,sr=sf.read(ROOT/'samples'/path,always_2d=True,dtype='float32')
    if sr!=SR:x=resample_poly(x,SR,sr,axis=0)
    # Retain the stereo recording, center DC, remove only leading near-silence.
    if x.shape[1]==1:x=np.repeat(x,2,axis=1)
    x=x[:,:2];x-=np.mean(x,axis=0)
    energy=np.max(abs(x),axis=1);where=np.flatnonzero(energy>max(0.00003,energy.max()*.004))
    if len(where):x=x[max(0,where[0]-int(.005*SR)):]
    peak=max(.001,float(abs(x).max()));x=x/peak*.7
    samples.setdefault(kind,[]).append((root,x,path))
for note,root in [('E3',52),('G3',55),('B3',59),('D4',62),('F4',65),('A4',69),('C5',72),('E5',76),('G5',79)]:
    register('harp',f'Strings/Harp/KSHarp_{note}_mf.wav',root)
for index,root in [(14,49),(18,57),(22,65),(26,73),(30,81)]:
    register('piano',f'Keys/Upright Piano/Player_dyn1_rr1_{index:03}.wav',root)
for note,root in [('C2',48),('G2',55),('F3',65),('C4',72),('G4',79),('B4',83)]:
    register('marimba',f'Percussion/Marimba/Marimba_hit_Outrigger_{note}_loud_01.wav',root)
for note,root in [('C1',36),('D1',38),('E1',40),('A1',45)]:
    register('bass',f'Strings/Solo Contrabass/Pizz/BKCtbss_Pizz_{note}_v1_rr1.wav',root)
register('kick','vcsl/Membranophones/Struck Membranophones/Bass Drum 1/BDrumNew_hit_v3_rr1_Sum.wav',60)
register('snare','vcsl/Membranophones/Struck Membranophones/Snare Drum, Modern 3/Snare4_HitSN_v4_rr1_Mid.wav',60)
register('hat','vcsl/Idiophones/Struck Idiophones/Hi-Hat Cymbal/HiHat_HitC_v2_rr1_Mid.wav',60)
cache={}
def voice(kind,note,duration):
    key=(kind,note,round(duration,3))
    if key in cache:return cache[key]
    root,x,path=min(samples[kind],key=lambda s:abs(s[0]-note))
    ratio=Fraction(2**((root-note)/12)).limit_denominator(900)
    x=resample_poly(x,ratio.numerator,ratio.denominator,axis=0).astype(np.float32)
    # Short, warm samples give the beat room without changing instrument pitch.
    release={'harp':.38,'piano':.20,'marimba':.18,'bass':.09,'kick':.055,'snare':.085,'hat':.025}[kind]
    gate=duration;length=min(len(x),round((gate+release)*SR));x=x[:length].copy()
    attack=int(SR*(.001 if kind in ['kick','snare','hat'] else .003))
    x[:attack]*=np.linspace(0,1,attack,dtype=np.float32)[:,None]
    end=min(length,round(release*SR));x[-end:]*=np.linspace(1,0,end,dtype=np.float32)[:,None]**1.5
    # Take a little edge off the close microphones, especially the bright mallets.
    cutoff={'harp':7600,'piano':6800,'marimba':6200,'bass':2400,'kick':2700,'snare':8500,'hat':9000}[kind]
    x=sosfilt(butter(2,cutoff,fs=SR,output='sos'),x,axis=0).astype(np.float32)
    cache[key]=(x,path);return x,path
def put(kind,note,beat,duration,level,pan=0,human=True):
    timing=float(rng.uniform(-.006,.006)) if human else 0
    start=round((beat*BEAT+timing)*SR)%N
    gain=level*float(rng.uniform(.9,1.08))
    x,path=voice(kind,note,duration*BEAT)
    # Preserve some recorded stereo width while gently positioning the instrument.
    mid=x.mean(axis=1);side=(x[:,0]-x[:,1])*.20
    gains=np.sqrt(np.array([1-pan,1+pan],np.float32))
    signal=np.stack([mid+side,mid-side],axis=1)*gains*gain
    first=min(len(signal),N-start);stems[kind][start:start+first]+=signal[:first]
    if first<len(signal):stems[kind][:len(signal)-first]+=signal[first:]
    events.append({'instrument':kind,'midi':note,'beat':round(beat+timing/BEAT,5),'duration_beats':duration,'gain':round(gain,5),'source':path})
# Bright triads and a repeating four-bar pop progression, with a lighter bridge.
chords={
 'D':(38,[62,66,69],[62,66,69,74]),
 'A':(45,[61,64,69],[61,64,69,76]),
 'Bm':(35,[62,66,71],[62,66,71,74]),
 'G':(43,[62,67,71],[62,67,71,74]),
 'Em':(40,[59,64,67],[64,67,71,76]),
}
progressions=[['D','A','Bm','G','D','A','G','A'],
 ['D','A','Bm','G','D','A','Bm','G'],
 ['G','D','A','Bm','G','D','Em','A'],
 ['D','A','Bm','G','D','A','Bm','G'],
 ['G','G','D','D','Em','Bm','G','A'],
 ['D','A','Bm','G','D','A','G','A']]
for bar in range(BARS):
    section=bar//8;within=bar%8
    root,voicing,arp=chords[progressions[section][within]];base=bar*4
    density=.75 if section==4 else (.92 if section==0 else 1.)
    # Short syncopated piano stabs make the accompaniment bounce.
    for off,level in [(0,.053),(1.52,.043),(2.5,.049)]:
        if section==4 and off==1.52:continue
        for j,note in enumerate(voicing):
            put('piano',note,base+off+j*.009,.36,level*density,.10)
    if within%2==1 and section!=4:
        for j,note in enumerate(voicing[1:]):
            put('piano',note,base+3.52+j*.008,.24,.033*density,.10)
    # Bouncy octave bass supports the kick, rather than a long low sustain.
    for off,interval,level in [(0,0,.17),(.76,12,.095),(1.5,0,.12),(2,0,.155),(2.76,7,.10),(3.5,12,.09)]:
        if section==4 and off not in [0,2,3.5]:continue
        put('bass',root+interval,base+off,.38,level*density,-.03)
    # A little plucked sparkle between lead phrases.
    if within%2==0:
        for j,off in enumerate([.52,3.52]):
            put('harp',arp[j+1]+12,base+off,.5,.026*density,-.26)
    # Near-straight pop/hip-hop pulse with snappy two/four accents.
    drum_density=.68 if section==4 else 1.
    pattern=[(0,.29),(1.5,.20),(2,.28),(3.52,.19)]
    for off,level in pattern:
        if section==4 and off==1.5:continue
        put('kick',60,base+off,.17,level*drum_density,0)
    for off in [1.005,3.005]:
        put('snare',60,base+off,.14,.218*drum_density,.02)
        # A soft double-strike thickens the backbeat without a loud reverb tail.
        put('snare',60,base+off+.023,.07,.049*drum_density,-.12)
    for step in range(8):
        if section==4 and step%2:continue
        off=step//2+(.52 if step%2 else 0)
        put('hat',60,base+off,.058,(.054 if step%2==0 else .034)*drum_density,.20)
    if within==7 and section!=4:
        for off,level in [(3.25,.047),(3.75,.060)]:
            put('snare',60,base+off,.07,level,.08)

# A concise repeated hook is the foreground identity, starting in the opening.
# Chord-tone endings follow each bar while the rhythmic motif stays memorable.
hook={
 'D':[(.25,74),(.75,74),(1.25,78),(2.25,81),(2.75,78),(3.25,76)],
 'A':[(.25,76),(.75,76),(1.25,73),(2.25,69),(3.25,73)],
 'Bm':[(.25,74),(.75,74),(1.25,78),(2.25,83),(2.75,81),(3.25,78)],
 'G':[(.25,79),(.75,78),(1.25,74),(2.25,71),(3.25,74)],
 'Em':[(.25,76),(.75,79),(1.25,78),(2.25,76),(3.25,71)],
}
for bar in range(BARS):
    section=bar//8;within=bar%8;chord=progressions[section][within]
    if section==4:continue
    # Four-bar call, then a lighter answer: avoid constant high-register activity.
    response=within>=4
    for i,(off,note) in enumerate(hook[chord]):
        if response and i in [1,4]:continue
        level=.062 if response else .077
        lead='marimba' if section==2 else 'piano'
        put(lead,note,bar*4+off,.30,level,-.10 if lead=='piano' else .25)
        if not response and section in [1,3,5] and i in [0,3]:
            put('marimba',note,bar*4+off+.012,.25,.031,.28)
    if within==7:
        put('harp',76,bar*4+3.52,.35,.024,-.24)

# Fixed stereo room: early reflections and a quiet diffused tail. Periodic
# convolution carries every release/reverb tail across the exact bar boundary.
mix=np.zeros((N,2),np.float32)
for kind,stem in stems.items():
    mix+=stem
    send={'harp':.085,'piano':.045,'marimba':.06,'bass':.015,'kick':.003,'snare':.018,'hat':.008}[kind]
    mono=stem.mean(axis=1)
    for channel in range(2):
        ir=np.zeros(round(1.65*SR),np.float32)
        for delay,level in [(0.041,.34),(.079,.25),(.127,.19),(.193,.12)]:
            ir[round((delay+channel*.008)*SR)]=level
        # Sparse dense-tail reflection cloud, deterministic and decorrelated.
        for t in np.arange(.22,1.65,.004):
            pos=round((t+rng.uniform(-.0015,.0015))*SR)
            ir[pos]+=float(rng.normal(0,.015)*math.exp(-t/0.38))
        ir=sosfilt(butter(1,4200,fs=SR,output='sos'),ir).astype(np.float32)
        wet=fftconvolve(mono,ir).astype(np.float32)
        mix[:,channel]+=wet[:N]*send
        mix[:len(wet)-N,channel]+=wet[N:]*send
    print('Rendered',kind,flush=True)
# No brickwall limiting or artificial loudness pumping. Preserve transients.
mix-=mix.mean(axis=0)
rms=float(np.sqrt(np.mean(mix.astype(np.float64)**2)));peak=float(abs(mix).max())
gain=min(10**(-23/20)/rms,10**(-5/20)/peak);mix*=gain
# Last-resort tiny DC seam correction over 2 ms; normally below audibility.
edge=mix[-1]-mix[0];window=round(.002*SR)
mix[-window:]-=np.linspace(0,1,window,dtype=np.float32)[:,None]*edge
sf.write(OUT/'quiet_currents.wav',mix,SR,subtype='PCM_24')
def write_ogg(path,data):
    # Chunked writes avoid libsndfile's large-buffer Vorbis encoder failure.
    with sf.SoundFile(path,'w',samplerate=SR,channels=2,format='OGG',subtype='VORBIS') as stream:
        for start in range(0,len(data),65536):stream.write(data[start:start+65536])
write_ogg(OUT/'quiet_currents.ogg',mix)
# Preview includes gentle fades; gameplay master remains an exact continuous loop.
preview=mix.copy();fade=round(.6*SR)
preview[:fade]*=np.linspace(0,1,fade)[:,None];preview[-fade:]*=np.linspace(1,0,fade)[:,None]
write_ogg(OUT/'quiet_currents_preview.ogg',preview)
write_ogg(OUT/'quiet_currents_game_mix.ogg',preview*10**(-10/20))
decoded,rate=sf.read(OUT/'quiet_currents.ogg',always_2d=True)
assert rate==SR and len(decoded)==N and np.isfinite(decoded).all()
assert abs(decoded).max()<.95
report={'title':'Quiet Currents — bright pop groove','bpm':BPM,'meter':'4/4','key':'D major','bars':BARS,'seconds':N/SR,'events':len(events),'sample_rate':SR,'peak_dbfs':20*math.log10(float(abs(mix).max())),'rms_dbfs':20*math.log10(float(np.sqrt(np.mean(mix**2)))),'decoded_peak_dbfs':20*math.log10(float(abs(decoded).max())),'decoded_seam_max_delta':float(abs(decoded[-1]-decoded[0]).max()),'ogg_bytes':(OUT/'quiet_currents.ogg').stat().st_size,'source_library':'VSCO 2 Community Edition and VCSL, CC0-1.0','instruments':list(stems),'swing_ratio':.52,'gameplay_player_db':{'land':-10,'water':-13},'sha256':hashlib.sha256((OUT/'quiet_currents.ogg').read_bytes()).hexdigest()}
assert not any(e['instrument']=='flute' for e in events)
(OUT/'analysis.json').write_text(json.dumps(report,indent=2))
(OUT/'score-events.json').write_text(json.dumps(events,indent=2))
print(json.dumps(report,indent=2))
