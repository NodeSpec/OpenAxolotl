"""Original, deterministic synthesized score and foley. No sampled recordings."""
from pathlib import Path
import math, wave, json
import numpy as np
OUT=Path(__file__).resolve().parents[1]/'assets/audio/cascade'
OUT.mkdir(exist_ok=True)
SR=44100
rng=np.random.default_rng(19427)
report={}
def hz(m):return 440*2**((m-69)/12)
def write(name,x,loop=False):
    if x.ndim==1:x=np.stack([x,x],axis=1)
    peak=float(np.max(np.abs(x)))
    if peak>.83:x=x*(.83/peak)
    if not loop:
        n=min(len(x)//2,441);x[:n]*=np.linspace(0,1,n)[:,None];x[-n:]*=np.linspace(1,0,n)[:,None]
    with wave.open(str(OUT/(name+'.wav')),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes((x*32767).astype('<i2').tobytes())
    report[name]={'seconds':round(len(x)/SR,4),'peak':round(float(abs(x).max()),4),'rms':round(float(np.sqrt(np.mean(x*x))),4),'loop':loop}
def tone(m,d,kind='keys'):
    t=np.arange(round(d*SR))/SR;f=hz(m)
    if kind=='bass':
        x=(np.sin(2*np.pi*f*t)+.24*np.sin(4*np.pi*f*t)+.09*np.sin(6*np.pi*f*t))*np.exp(-t*3)
        x*=np.minimum(t/.006,1)*np.minimum((d-t)/.035,1)
    elif kind=='pad':
        x=(np.sin(2*np.pi*f*t)+.22*np.sin(2*np.pi*f*1.002*t)+.16*np.sin(4*np.pi*f*t))
        x*=np.minimum(t/.18,1)*np.minimum((d-t)/.28,1)*.55
    elif kind=='pluck':
        x=(np.sin(2*np.pi*f*t+.85*np.sin(2*np.pi*f*2*t)*np.exp(-t*18))+.15*np.sin(2*np.pi*f*3*t))*np.exp(-t*7)
        x*=np.minimum(t/.004,1)
    else:
        x=(np.sin(2*np.pi*f*t+1.5*np.sin(2*np.pi*f*2*t)*np.exp(-t*10))+.08*np.sin(2*np.pi*f*4*t))*np.exp(-t*3.3)
        x*=np.minimum(t/.004,1)*np.minimum((d-t)/.03,1)
    return x
def drum(kind):
    d={'kick':.3,'snare':.20,'hat':.055,'clap':.15,'rim':.075}[kind]
    t=np.arange(round(d*SR))/SR;n=rng.normal(0,1,len(t))
    hi=n-np.convolve(n,np.ones(9)/9,mode='same')
    if kind=='kick':return np.sin(2*np.pi*(46*t+50*.027*(1-np.exp(-t/.027))))*np.exp(-t*17)+hi*.02*np.exp(-t*120)
    if kind=='snare':return (hi*.4+np.sin(2*np.pi*185*t)*.22)*np.exp(-t*26)*np.minimum(t/.002,1)
    if kind=='hat':return hi*.15*np.exp(-t*85)*np.minimum(t/.001,1)
    if kind=='clap':return hi*.24*(np.exp(-t*40)+np.where(t>.012,np.exp(-np.maximum(t-.012,0)*55),0)+np.where(t>.023,np.exp(-np.maximum(t-.023,0)*45),0))
    return (np.sin(2*np.pi*820*t)+.6*np.sin(2*np.pi*1430*t))*np.exp(-t*95)*.4
def mix_score(name,bpm,bars,groove=False):
    beat=60/bpm;duration=bars*4*beat;count=round(duration*SR);x=np.zeros((count,2))
    def put(signal,b,level=.1,pan=0):
        start=round(b*beat*SR);idx=(np.arange(len(signal))+start)%count
        gains=np.sqrt([(1-pan)/2,(1+pan)/2]);np.add.at(x,idx,signal[:,None]*gains*level)
    roots=[50,55,48,53] # Dm9 - G13 - Cmaj9 - Fmaj9
    chords=[[62,65,69,72,76],[59,65,69,74],[60,64,67,71,74],[57,64,67,72]]
    melody=[74,76,77,81,79,77,76,72,74,77,76,69,72,74,69,67]
    for bar in range(bars):
        c=(bar//2)%4;root=roots[c];b=bar*4
        if groove:
            for off in [0,1.5,2.75]:put(drum('kick'),b+off,.45)
            for off in [1,3]:put(drum('snare'),b+off,.28);put(drum('clap'),b+off+.008,.12, .12)
            for j in range(8):put(drum('hat'),b+j*.5+(.035 if j%2 else 0),.45 if j%2==0 else .28,(-1)**j*.35)
            for off,interval in [(0,0),(.75,12),(1.5,7),(2,0),(2.75,10),(3.5,12)]:put(tone(root-12+interval,.26,'bass'),b+off,.29,-.06)
            for off in [.5,1.75,2.5,3.5]:
                for note in chords[c]:put(tone(note,.35,'keys'),b+off,.062,-.25)
            for j in range(4):
                note=melody[(bar*2+j)%len(melody)]
                put(tone(note,.28,'pluck'),b+j+.25,.075,.4)
        else:
            for note in chords[c]:put(tone(note,beat*4.1,'pad'),b,.055, (note%3-1)*.45)
            for off in [0,2.5]:put(tone(root-12,.65,'bass'),b+off,.18)
            for off in [1,3]:put(drum('rim'),b+off,.13,.3)
            for off in [0,2]:put(drum('kick'),b+off,.14)
            for j in range(8):put(drum('hat'),b+j*.5,.13 if j%2 else .18,(-1)**j*.4)
            for j,off in enumerate([.5,1.25,2.5,3.25]):
                note=melody[(bar*2+j+(8 if bar>=8 else 0))%len(melody)]
                if bar%4==3 and j>1:continue
                put(tone(note,.8,'keys'),b+off,.15,math.sin(bar+j)*.3)
    # Subtle stereo room echoes wrap into loop head, preserving exact bar length.
    wet=x.copy()
    for delay,gain in [(.137,.11),(.239,.065),(.383,.04)]:x+=np.roll(wet,round(delay*SR),axis=0)[:,::-1]*gain
    x=np.tanh(x*1.1)*.85
    write(name,x,not groove)
mix_score('cascade_exploration',96,16)
mix_score('crayfish_groove',112,8,True)
def chime(notes,spacing=.09):
    n=round((len(notes)*spacing+.8)*SR);x=np.zeros(n)
    for i,m in enumerate(notes):
        v=tone(m,.8,'keys')*.22;a=round(i*spacing*SR);x[a:a+len(v)]+=v[:len(x)-a]
    return x
for name,notes in {'crayfish_pickup':[81,86,90],'dance_unlocked':[74,77,81,86,89],'checkpoint':[67,74,79],'net_escape':[74,81,86],'net_caught':[62,57,50]}.items():write(name,chime(notes))
for name,kind in [('tail_whack','whack'),('spin_charge','spin'),('slide','slide'),('movement_swim_stroke','swim'),('movement_dive','dive'),('movement_waddle_step','step'),('movement_hop','hop'),('landing','land')]:
    d={'whack':.25,'spin':.55,'slide':.42,'swim':.22,'dive':.4,'step':.085,'hop':.17,'land':.14}[kind]
    t=np.arange(round(d*SR))/SR;n=rng.normal(0,1,len(t));smooth=np.convolve(n,np.ones(35)/35,mode='same')
    if kind in ['swim','dive','spin']:
        v=smooth*.38*np.sin(np.pi*t/d)**2+np.sin(2*np.pi*(240*t+150*t*t))*np.exp(-t*17)*.04
    elif kind=='hop':v=np.sin(2*np.pi*(240*t+800*t*t))*np.sin(np.pi*t/d)**2*.11
    elif kind=='whack':v=smooth*.6*np.sin(np.pi*t/d)**1.3+np.sin(2*np.pi*(110*t-60*t*t))*np.exp(-t*22)*.07
    else:v=smooth*.40*np.exp(-t*(16 if kind=='slide' else 45))
    write(name,v)
# Distinct required bank events, all original synthesized motifs.
for i,part in enumerate(['tail','gill','leg']):
    write('capability_lost_'+part,chime([65+i*3,60+i*3,55+i*3]))
    write('capability_regrown_'+part,chime([62+i*3,69+i*3,74+i*3]))
for name,notes in [('bubble',[79,84,88]),('jet',[62,74,86]),('glow',[81,85,88,93])]:write('gill_mod_'+name+'_activated',chime(notes,.07))
# Low ambience beds use periodic synthesis to avoid loop clicks.
for k,name in enumerate(['grammar_land','grammar_water','region_barren','region_resourced','region_restored']):
    d=8.;t=np.arange(round(d*SR))/SR
    if k<2:
        noise=rng.normal(0,1,len(t));spec=np.fft.rfft(noise);f=np.fft.rfftfreq(len(t),1/SR)
        spec*=np.exp(-(f/(900 if k==0 else 260))**2);v=np.fft.irfft(spec,n=len(t));v=v/max(abs(v))*.055
        v*=.8+.2*np.sin(2*np.pi*t/d)
    else:
        v=np.zeros(len(t))
        for m in [50,57,62+(k-2)*2]:
            f=round(hz(m)*d)/d;v+=np.sin(2*np.pi*f*t)*.012*(.8+.2*np.sin(2*np.pi*t/d))
    write(name,v,True)
(Path(__file__).resolve().parent/'source_art'/'cascade_audio_analysis.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(Path(__file__).resolve().parent/'source_art'/'cascade_audio_build_details.json').write_text(json.dumps({'author':'OpenAxolotl project; original procedural synthesis authored in Codex','generationMethod':'ai-generated','tool':'Python and NumPy, deterministic oscillator and noise synthesis','licenseTerms':'Original generated composition and waveforms; no third-party recordings or sampled music. Project Apache-2.0 licence.','description':'96 BPM D-minor exploration loop; 112 BPM funk dance cue; synthesized movement, pickup and restoration sounds.','source':'tools/make_cascade_audio.py'},indent=2),encoding='utf-8')
print('Generated',len(report),'original stereo WAVs',json.dumps({k:v for k,v in report.items() if k in ['cascade_exploration','crayfish_groove']}))
