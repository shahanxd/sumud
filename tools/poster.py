# Builds docs/marketing/sumud-poster-16x9 from an in-engine render of d1_beach at dusk:
#   xvfb-run -a -s "-screen 0 1920x1080x24" bin/Godot_v4.7.2-stable_linux.x86_64 --path game --rendering-method gl_compatibility --resolution 1920x1080 res://tests/shot_scene.tscn -- --scene=res://scenes/d1_beach.tscn --out=$PWD/.cache/poster/hd_dusk_600.png --frames=600 --phase=dusk --kite --no-hud
#   python3 tools/poster.py
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np
im=Image.open('.cache/poster/hd_dusk_600.png').convert('RGB')
a=np.array(im).astype(np.float32); H,W=a.shape[:2]
# Paint out the crowd's eye-lights only at the heads (F-05 is undecided); the held kites keep their colours.
heads=[(1128,585,1150,600),(1174,606,1194,628),(1374,606,1394,628),(1532,585,1554,600),(1576,606,1598,628),(1798,606,1818,628)]
for x0_,y0_,x1_,y1_ in heads:
    b_=a[y0_:y1_,x0_:x1_]
    m=(b_[...,0]>50)&(b_[...,0]>=b_[...,2]-8)
    b_[m]=[22,18,24]
y=np.linspace(0,1,H)[:,None]
shade=(np.clip((y-0.62)/0.38,0,1)**1.2*0.72)[...,None]
a=a*(1-shade)+np.array([12,8,10])*shade
top=(np.clip((0.12-y)/0.12,0,1)*0.35)[...,None]
a=a*(1-top)+np.array([14,12,30])*top
im=Image.fromarray(a.clip(0,255).astype(np.uint8)); d=ImageDraw.Draw(im)
F='game/assets/fonts/amiri/'
title=ImageFont.truetype(F+'Amiri-Bold.ttf',150); ar=ImageFont.truetype(F+'Amiri-Bold.ttf',96)
tag=ImageFont.truetype(F+'Amiri-Regular.ttf',38); small=ImageFont.truetype(F+'Amiri-Regular.ttf',27)
cream=(244,232,212); rose=(232,150,110)
def sw(t,f,s): return sum(d.textlength(c,font=f) for c in t)+s*(len(t)-1)
def spaced(t,f,x,y,s,fill):
    for c in t: d.text((x,y),c,font=f,fill=fill); x+=d.textlength(c,font=f)+s
    return x
x0=120; ty=742
glow=Image.new('L',im.size,0); ImageDraw.Draw(glow).rectangle([x0-40,ty+40,x0+sw('SUMUD',title,28)+340,ty+400],fill=110)
glow=glow.filter(ImageFilter.GaussianBlur(70)).point(lambda v:int(v*0.55))
im=Image.composite(Image.new('RGB',im.size,(8,6,8)),im,glow); d=ImageDraw.Draw(im)
xe=spaced('SUMUD',title,x0,ty,24,cream)
d.text((xe+44,ty+36),'صمود',font=ar,fill=rose,direction='rtl',language='ar')
d.line([(x0+6,ty+192),(x0+420,ty+192)],fill=(178,32,40),width=4)
d.text((x0+4,ty+204),'Ten days. One family. One street in Gaza City.',font=tag,fill=cream)
d.text((x0+4,ty+252),'A game about holding on.',font=tag,fill=(214,196,176))
s='A 2D narrative adventure  ·  No combat  ·  A score of human voices'
d.text((W-120-d.textlength(s,font=small),ty+262),s,font=small,fill=(200,184,166))
im.save('docs/marketing/sumud-poster-16x9.png',optimize=True)
im.save('docs/marketing/sumud-poster-16x9.jpg',quality=92)
print(im.size)
