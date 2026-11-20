import math, os

SH = '''<filter id="sh" x="-40%" y="-40%" width="180%" height="190%">
<feGaussianBlur in="SourceAlpha" stdDeviation="3.2"/><feOffset dy="3.5"/>
<feComponentTransfer><feFuncA type="linear" slope="0.32"/></feComponentTransfer>
<feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<filter id="sh2" x="-40%" y="-40%" width="180%" height="190%">
<feGaussianBlur in="SourceAlpha" stdDeviation="1.6"/><feOffset dy="1.5"/>
<feComponentTransfer><feFuncA type="linear" slope="0.25"/></feComponentTransfer>
<feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>'''

def lg(id, c1, c2, x1=0,y1=0,x2=0,y2=1):
    return f'<linearGradient id="{id}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"><stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient>'

icons = {}  # name -> (bg_top, bg_bottom, defs, body)

# 1 FILES
icons['files'] = ('#5C93FA', '#2D5FD6',
  lg('fBack','#D3E0FF','#AFC4F5') + lg('fFront','#FFFFFF','#E4ECFE') + lg('fPaper','#FFFFFF','#F1F4FA'),
  '''<g filter="url(#sh)">
<path d="M28 38a5 5 0 0 1 5-5h20l7 7h35a5 5 0 0 1 5 5v47H28z" fill="url(#fBack)"/>
<g transform="rotate(-5 64 60)"><rect x="36" y="42" width="54" height="34" rx="3" fill="url(#fPaper)"/>
<path d="M44 52h30M44 58h38M44 64h22" stroke="#C9D3E6" stroke-width="2.4" stroke-linecap="round"/></g>
<rect x="25" y="56" width="78" height="42" rx="6" fill="#8FA9E4"/>
<rect x="25" y="52" width="78" height="42" rx="6" fill="url(#fFront)"/>
<path d="M31 52.8h66" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.9"/>
</g>''')

# 2 WEB (globe)
icons['web'] = ('#F4F7FD', '#D9E3F3',
  '<radialGradient id="wG" cx="0.38" cy="0.32" r="0.75"><stop offset="0" stop-color="#7CC0FF"/><stop offset="0.55" stop-color="#2F7BEA"/><stop offset="1" stop-color="#1747A8"/></radialGradient>'
  + lg('wHi','#FFFFFF','#FFFFFF') ,
  '''<g filter="url(#sh)">
<circle cx="64" cy="62" r="36" fill="url(#wG)"/>
<g fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="2">
<ellipse cx="64" cy="62" rx="15" ry="36"/><path d="M28 62h72"/><path d="M33 44h62M33 80h62"/><path d="M64 26v72"/></g>
<circle cx="64" cy="62" r="36" fill="none" stroke="#0E3784" stroke-opacity="0.35" stroke-width="1.5"/>
<ellipse cx="52" cy="42" rx="15" ry="8" fill="#FFFFFF" opacity="0.38" transform="rotate(-25 52 42)"/>
</g>''')

# 3 MAIL
icons['mail'] = ('#FF8266', '#E0453B',
  lg('mBody','#FFFFFF','#EEF1F6') + lg('mFlapIn','#D9DEE8','#C3CAD8') + lg('mPaper','#FFFFFF','#F6F8FB'),
  '''<g filter="url(#sh)">
<path d="M26 50l38-20 38 20v40H26z" fill="url(#mFlapIn)"/>
<rect x="36" y="34" width="56" height="44" rx="3" fill="url(#mPaper)"/>
<path d="M44 46h40M44 53h40M44 60h26" stroke="#CDD5E3" stroke-width="2.4" stroke-linecap="round"/>
<path d="M26 54l38 22 38-22v40a5 5 0 0 1-5 5H31a5 5 0 0 1-5-5z" fill="#B9C2D3"/>
<path d="M26 52l38 22 38-22v38a5 5 0 0 1-5 5H31a5 5 0 0 1-5-5z" fill="url(#mBody)"/>
<path d="M26.5 92l30-22M101.5 92l-30-22" stroke="#D5DBE6" stroke-width="1.6" stroke-linecap="round"/>
</g>''')

# 4 CALENDAR
icons['calendar'] = ('#FFFFFF', '#E9ECF2',
  lg('cTop','#FF6B5E','#E4372D') + lg('cPage','#FFFFFF','#F3F5F9'),
  '''<g filter="url(#sh)">
<rect x="30" y="34" width="68" height="66" rx="8" fill="#C7CDD8"/>
<rect x="30" y="31" width="68" height="66" rx="8" fill="#DDE2EA"/>
<rect x="30" y="28" width="68" height="66" rx="8" fill="url(#cPage)"/>
<path d="M30 36a8 8 0 0 1 8-8h52a8 8 0 0 1 8 8v12H30z" fill="url(#cTop)"/>
<path d="M36 29.2h56" stroke="#FFFFFF" stroke-opacity="0.5" stroke-width="1.4" stroke-linecap="round"/>
<text x="64" y="44.5" text-anchor="middle" font-family="Roboto Flex, Inter, Arial, sans-serif" font-size="10.5" font-weight="700" letter-spacing="1.2" fill="#FFFFFF">NOV</text>
<text x="64" y="84" text-anchor="middle" font-family="Roboto Flex, Inter, Arial, sans-serif" font-size="34" font-weight="500" fill="#24232A">20</text>
</g>''')

# 5 CLOCK
icons['clock'] = ('#34323D', '#16151B',
  lg('kBezel','#FAFAFC','#A9ABB6') + '<radialGradient id="kFace" cx="0.5" cy="0.4" r="0.65"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#E8E9EE"/></radialGradient>',
  None)
ticks = ''.join(
  f'<line x1="{64+27*math.sin(math.radians(a)):.2f}" y1="{62-27*math.cos(math.radians(a)):.2f}" x2="{64+(22 if a%90==0 else 24)*math.sin(math.radians(a)):.2f}" y2="{62-(22 if a%90==0 else 24)*math.cos(math.radians(a)):.2f}" stroke="#2A2930" stroke-width="{2.6 if a%90==0 else 1.6}" stroke-linecap="round"/>'
  for a in range(0,360,30))
icons['clock'] = icons['clock'][:3] + ('''<g filter="url(#sh)">
<circle cx="64" cy="64" r="36" fill="#6E707C"/>
<circle cx="64" cy="62" r="36" fill="url(#kBezel)"/>
<circle cx="64" cy="62" r="31" fill="url(#kFace)"/>
''' + ticks + '''
<g filter="url(#sh2)">
<path d="M64 62L64 46" stroke="#1E1D23" stroke-width="3.8" stroke-linecap="round" transform="rotate(-88 64 62)"/>
<path d="M64 62L64 38" stroke="#1E1D23" stroke-width="3" stroke-linecap="round" transform="rotate(24 64 62)"/>
<path d="M64 70L64 37" stroke="#F25C2A" stroke-width="1.6" stroke-linecap="round" transform="rotate(200 64 62)"/>
</g>
<circle cx="64" cy="62" r="3" fill="#F25C2A"/><circle cx="64" cy="62" r="1.2" fill="#FFFFFF"/>
<ellipse cx="54" cy="44" rx="16" ry="7" fill="#FFFFFF" opacity="0.45" transform="rotate(-20 54 44)"/>
</g>''',)

# 6 NOTES
icons['notes'] = ('#FFC83D', '#F29E0C',
  lg('nSheet','#FFFDF2','#FFF3C9') + lg('nStrip','#FF8A2B','#E26B10') + lg('nCurl','#E9D9A3','#FFF6D8',0,0,1,1),
  '''<g filter="url(#sh)">
<path d="M32 36h64v58a6 6 0 0 1-6 6H38a6 6 0 0 1-6-6z" fill="#D9C68C"/>
<path d="M32 34h64v44l-18 18H38a6 6 0 0 1-6-6z" fill="url(#nSheet)"/>
<path d="M40 52h48M40 61h48M40 70h40M40 79h28" stroke="#E9CF7A" stroke-width="2.2" stroke-linecap="round"/>
<path d="M96 78L78 96c0-10 6-18 18-18z" fill="url(#nCurl)"/>
<path d="M96 78L78 96" stroke="#D8C281" stroke-width="1"/>
<rect x="30" y="26" width="68" height="14" rx="5" fill="#B8560A"/>
<rect x="30" y="24" width="68" height="13" rx="5" fill="url(#nStrip)"/>
<path d="M36 25.2h56" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="1.3" stroke-linecap="round"/>
</g>''')

# 7 CALCULATOR
keys=''
for r in range(3):
    for c in range(3):
        x=40+c*17; y=58+r*13
        orange = (r==2 and c==2)
        top = '#FF9F2E' if orange else '#FFFFFF'
        lip = '#C76A00' if orange else '#B7B9C3'
        keys += f'<rect x="{x}" y="{y+1.6}" width="14" height="10" rx="3" fill="{lip}"/><rect x="{x}" y="{y}" width="14" height="10" rx="3" fill="{top}"/>'
icons['calculator'] = ('#43414C', '#1E1D24',
  lg('qBody','#ECEDF2','#CFD1D9') + lg('qScreen','#2B3A33','#1C2622'),
  '''<g filter="url(#sh)">
<rect x="32" y="27" width="64" height="76" rx="10" fill="#8E909B"/>
<rect x="32" y="24" width="64" height="76" rx="10" fill="url(#qBody)"/>
<rect x="38" y="30" width="52" height="20" rx="5" fill="url(#qScreen)"/>
<path d="M41 32.5h32" stroke="#FFFFFF" stroke-opacity="0.18" stroke-width="2" stroke-linecap="round"/>
<path d="M76 37v8M80 41h0" stroke="#7CF2B0" stroke-width="0"/>
<rect x="66" y="35" width="3" height="10" rx="1" fill="#8BF5C0"/><rect x="72" y="35" width="3" height="10" rx="1" fill="#8BF5C0"/><rect x="78" y="35" width="3" height="10" rx="1" fill="#8BF5C0"/><rect x="84" y="35" width="3" height="10" rx="1" fill="#8BF5C0"/>
''' + keys + '''
<path d="M38 25.4h52" stroke="#FFFFFF" stroke-width="1.4" stroke-linecap="round"/>
</g>''')

# 8 MUSIC
icons['music'] = ('#FF6F93', '#DB2F64',
  lg('uN','#FFFFFF','#FFE3EC'),
  '''<g filter="url(#sh)">
<g transform="translate(0 3)" fill="#A3164A">
<path d="M50 40l38-9v46h-7V42l-24 5.7V86h-7z"/>
<ellipse cx="45" cy="86" rx="11" ry="8.5" transform="rotate(-18 45 86)"/>
<ellipse cx="76" cy="78" rx="11" ry="8.5" transform="rotate(-18 76 78)"/>
</g>
<g fill="url(#uN)">
<path d="M50 40l38-9v46h-7V42l-24 5.7V86h-7z"/>
<ellipse cx="45" cy="86" rx="11" ry="8.5" transform="rotate(-18 45 86)"/>
<ellipse cx="76" cy="78" rx="11" ry="8.5" transform="rotate(-18 76 78)"/>
</g>
<path d="M51.5 40.8l35-8.3" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round"/>
</g>''')

# 9 PHOTOS
icons['photos'] = ('#FFFFFF', '#E6EAF0',
  lg('pSky','#8EC9FF','#D7ECFF') + lg('pHill1','#3DBE8B','#1E9468') + lg('pHill2','#7ED9A8','#45B77D') + lg('pSky2','#FFB27A','#FFE0B8'),
  '''<g filter="url(#sh)">
<g transform="rotate(8 64 64)">
<rect x="34" y="30" width="62" height="58" rx="5" fill="#FFFFFF"/>
<rect x="39" y="35" width="52" height="40" rx="2" fill="url(#pSky2)"/>
</g>
<g transform="rotate(-6 64 64)">
<rect x="28" y="36" width="64" height="62" rx="5" fill="#DADFE7"/>
<rect x="28" y="34" width="64" height="62" rx="5" fill="#FFFFFF"/>
<clipPath id="pc"><rect x="33" y="39" width="54" height="42" rx="2"/></clipPath>
<g clip-path="url(#pc)">
<rect x="33" y="39" width="54" height="42" fill="url(#pSky)"/>
<circle cx="74" cy="50" r="5.5" fill="#FFE27A"/>
<path d="M30 76l18-18 14 13 9-8 20 17v4H30z" fill="url(#pHill2)"/>
<path d="M30 82l14-12 12 9 10-7 25 12v2H30z" fill="url(#pHill1)"/>
</g>
</g>
</g>''')

# 10 STORE
icons['store'] = ('#9479F5', '#5B3ECF',
  lg('sBag','#FFFFFF','#E9E2FF') + lg('sSide','#CFC2FA','#B3A2F0'),
  '''<g filter="url(#sh)">
<path d="M50 42v-4a14 14 0 0 1 28 0v4" fill="none" stroke="#2E1A85" stroke-opacity="0.35" stroke-width="5" stroke-linecap="round" transform="translate(0 2)"/>
<path d="M50 42v-4a14 14 0 0 1 28 0v4" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round"/>
<path d="M33 46h62l-4 50a5 5 0 0 1-5 4.6H42a5 5 0 0 1-5-4.6z" fill="#8C78DA" transform="translate(0 3)"/>
<path d="M33 46h62l-4 50a5 5 0 0 1-5 4.6H42a5 5 0 0 1-5-4.6z" fill="url(#sBag)"/>
<path d="M36 47.2h56" stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round"/>
<circle cx="50" cy="56" r="3" fill="#6A50D8"/><circle cx="78" cy="56" r="3" fill="#6A50D8"/>
<path d="M51 88V75a6.5 6.5 0 0 1 13 0v13M64 75a6.5 6.5 0 0 1 13 0v13" fill="none" stroke="#6A50D8" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>
</g>''')

# 11 SETTINGS (gear)
def gear(cx, cy, ro, ri, teeth, tw=0.42):
    pts=[]
    for i in range(teeth):
        a0 = 2*math.pi*i/teeth
        step = 2*math.pi/teeth
        for frac, r in [(0,ri),(0.5-tw/2-0.06,ri),(0.5-tw/2,ro),(0.5+tw/2,ro),(0.5+tw/2+0.06,ri)]:
            a = a0+frac*step
            pts.append((cx+r*math.cos(a), cy+r*math.sin(a)))
    d='M'+' L'.join(f'{x:.2f} {y:.2f}' for x,y in pts)+'Z'
    return d
gd = gear(64,62,36,29,9)
gd_low = gear(64,65.5,36,29,9)
icons['settings'] = ('#9399A3', '#596069',
  lg('gTop','#FBFCFD','#C4C8CF') + lg('gIn','#8C929B','#B7BCC4'),
  f'''<g filter="url(#sh)">
<path d="{gd_low} M64 52.5a13 13 0 1 0 0.01 0Z" fill="#7D838D" fill-rule="evenodd"/>
<path d="{gd} M64 49a13 13 0 1 0 0.01 0Z" fill="url(#gTop)" fill-rule="evenodd"/>
<circle cx="64" cy="62" r="13" fill="none" stroke="url(#gIn)" stroke-width="3"/>
<circle cx="64" cy="62" r="22" fill="none" stroke="#FFFFFF" stroke-opacity="0.6" stroke-width="1.2"/>
</g>''')

# 12 TERMINAL
icons['terminal'] = ('#3A3843', '#141319',
  lg('tScr','#1E2A24','#121814') + lg('tBar','#5A5966','#45444F'),
  '''<g filter="url(#sh)">
<rect x="24" y="33" width="80" height="64" rx="9" fill="#0B0A0E"/>
<rect x="24" y="30" width="80" height="64" rx="9" fill="url(#tScr)"/>
<path d="M24 39a9 9 0 0 1 9-9h62a9 9 0 0 1 9 9v3H24z" fill="url(#tBar)"/>
<rect x="30" y="34.5" width="14" height="3" rx="1.5" fill="#8E8D99"/><circle cx="94" cy="36" r="2.2" fill="#8E8D99"/><circle cx="87" cy="36" r="2.2" fill="#8E8D99"/>
<path d="M36 56l10 8-10 8" fill="none" stroke="#6CF2A2" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M52 74h20" stroke="#6CF2A2" stroke-width="4.5" stroke-linecap="round"/>
<path d="M30 31.4h68" stroke="#FFFFFF" stroke-opacity="0.25" stroke-width="1.2" stroke-linecap="round"/>
</g>''')

def squircle(size=128, n=5.0, pad=0):
    r = size/2 - pad; c = size/2; pts=[]
    for i in range(0,360,3):
        t=math.radians(i); ct=math.cos(t); st=math.sin(t)
        x=c+r*math.copysign(abs(ct)**(2/n),ct); y=c+r*math.copysign(abs(st)**(2/n),st)
        pts.append(f'{x:.2f} {y:.2f}')
    return 'M'+' L'.join(pts)+'Z'

SQ = squircle()
open('squircle-54px.txt','w').write(squircle(54))

def fg_svg(name):
    top,bot,defs,body = icons[name]
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128"><defs>{SH}{defs}</defs>{body}</svg>'

def full_svg(name):
    top,bot,defs,body = icons[name]
    bg = (f'<linearGradient id="bgG" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bot}"/></linearGradient>'
          '<linearGradient id="bgHi" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.35"/><stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0"/></linearGradient>')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128"><defs>{SH}{defs}{bg}'
            f'<clipPath id="shape"><path d="{SQ}"/></clipPath></defs>'
            f'<g clip-path="url(#shape)"><rect width="128" height="128" fill="url(#bgG)"/>'
            f'<path d="{SQ}" fill="none" stroke="url(#bgHi)" stroke-width="3"/>{body}</g></svg>')

names = ['files','web','mail','calendar','clock','notes','calculator','music','photos','store','settings','terminal']
for n in names:
    open(f'foreground/{n}.svg','w').write(fg_svg(n))
    open(f'full/{n}.svg','w').write(full_svg(n))
import json
json.dump({n:[icons[n][0],icons[n][1]] for n in names}, open('bg.json','w'))
print('ok')
