import os
# macOS 26-style layered glass icons: coloured squircle + glass object on top
# (translucent white body, bright rim, specular highlight, refraction tint, soft shadow).
import math
def squircle(size=128, n=5.0):
    r=size/2; c=size/2; pts=[]
    for i in range(0,360,3):
        t=math.radians(i); ct=math.cos(t); st=math.sin(t)
        x=c+r*math.copysign(abs(ct)**(2/n),ct); y=c+r*math.copysign(abs(st)**(2/n),st)
        pts.append(f'{x:.2f} {y:.2f}')
    return 'M'+' L'.join(pts)+'Z'
SQ=squircle()

def icon(name, c1, c2, c3, glyph, extra_back='', extra_front=''):
    # glyph: SVG shapes (fill/stroke as needed) drawn white; reused as mask for glass layers
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">
<defs>
<clipPath id="sq"><path d="{SQ}"/></clipPath>
<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{c1}"/><stop offset="0.55" stop-color="{c2}"/><stop offset="1" stop-color="{c3}"/></linearGradient>
<radialGradient id="glow" cx="0.25" cy="0.15" r="0.7"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.45"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
<linearGradient id="body" gradientUnits="userSpaceOnUse" x1="0" y1="20" x2="0" y2="108"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.78"/><stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0.38"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0.55"/></linearGradient>
<linearGradient id="rim" gradientUnits="userSpaceOnUse" x1="20" y1="18" x2="108" y2="110"><stop offset="0" stop-color="#FFFFFF" stop-opacity="1"/><stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0.25"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0.85"/></linearGradient>
<filter id="blur2" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="2"/></filter>
<filter id="shadow" x="-30%" y="-30%" width="160%" height="170%"><feGaussianBlur stdDeviation="4"/></filter>
<mask id="gm" maskUnits="userSpaceOnUse" x="0" y="0" width="128" height="128"><g fill="#FFF" stroke="#FFF">{glyph}</g></mask>
<mask id="rm" maskUnits="userSpaceOnUse" x="0" y="0" width="128" height="128">
<g fill="#FFF" stroke="#FFF" stroke-width="3.2">{glyph}</g>
<g fill="#000" stroke="#000" transform="translate(64 64) scale(0.955) translate(-64 -64)">{glyph}</g>
</mask>
</defs>
<g clip-path="url(#sq)">
<rect width="128" height="128" fill="url(#bg)"/>
<rect width="128" height="128" fill="url(#glow)"/>
{extra_back}
<g transform="translate(0 5)" opacity="0.35" filter="url(#shadow)"><g fill="#0A0630" stroke="#0A0630">{glyph}</g></g>
<g mask="url(#gm)">
<g transform="translate(64 64) scale(1.25) rotate(14) translate(-64 -64)"><rect width="128" height="128" fill="url(#bg)"/></g>
<rect width="128" height="128" fill="url(#body)"/>
<rect x="0" y="60" width="128" height="68" fill="{c3}" opacity="0.16"/>
</g>
<rect width="128" height="128" fill="url(#rim)" mask="url(#rm)"/>
{extra_front}
<path d="{SQ}" fill="none" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="2.5"/>
</g>
</svg>'''

S='stroke-linecap="round" stroke-linejoin="round"'
icons = {
 # name: (c1,c2,c3, glyph, extra_front)
 'files': ('#5AA8FF','#2E6BF0','#1D3FB8',
   '<path d="M24 40a7 7 0 0 1 7-7h20l8 8h38a7 7 0 0 1 7 7v42a7 7 0 0 1-7 7H31a7 7 0 0 1-7-7z" stroke="none"/>',
   '<path d="M30 50h68" stroke="#FFFFFF" stroke-opacity="0.8" stroke-width="2" stroke-linecap="round"/><ellipse cx="44" cy="44" rx="12" ry="3" fill="#FFF" opacity="0.6" filter="url(#blur2)"/>'),
 'web': ('#7FD3FF','#2F8CF0','#1449B8',
   '<circle cx="64" cy="64" r="38" stroke="none"/>',
   f'<g fill="none" stroke="#FFFFFF" stroke-opacity="0.75" stroke-width="2.4" {S}><ellipse cx="64" cy="64" rx="16" ry="38"/><path d="M26 64h76M31 46h66M31 82h66"/></g><ellipse cx="50" cy="40" rx="14" ry="6" fill="#FFF" opacity="0.6" transform="rotate(-25 50 40)" filter="url(#blur2)"/>'),
 'mail': ('#FFB36B','#FF6A4D','#D93A3A',
   '<rect x="22" y="34" width="84" height="60" rx="10" stroke="none"/>',
   f'<path d="M26 40l38 28 38-28" fill="none" stroke="#FFFFFF" stroke-opacity="0.85" stroke-width="3" {S}/><ellipse cx="44" cy="40" rx="14" ry="3" fill="#FFF" opacity="0.6" filter="url(#blur2)"/>'),
 'calendar': ('#FF8A80','#F2443A','#B81F2A',
   '<rect x="28" y="26" width="72" height="76" rx="14" stroke="none"/>',
   '<text x="64" y="50" text-anchor="middle" font-family="DejaVu Sans, Arial, sans-serif" font-size="12" font-weight="700" letter-spacing="1.5" fill="#FFFFFF" fill-opacity="0.95">NOV</text><text x="64" y="88" text-anchor="middle" font-family="DejaVu Sans, Arial, sans-serif" font-size="34" font-weight="700" fill="#FFFFFF" fill-opacity="0.95">20</text><path d="M34 31h60" stroke="#FFF" stroke-opacity="0.7" stroke-width="2" stroke-linecap="round"/>'),
 'clock': ('#6B6A7A','#2E2C38','#121118',
   '<circle cx="64" cy="64" r="38" stroke="none"/>',
   f'<g stroke="#FFFFFF" stroke-opacity="0.9" {S}><path d="M64 64V40" stroke-width="4"/><path d="M64 64l14 8" stroke-width="4"/></g><path d="M64 70V34" stroke="#FF9F43" stroke-width="2" stroke-linecap="round" transform="rotate(200 64 64)"/><circle cx="64" cy="64" r="3.5" fill="#FF9F43"/>' + ''.join(f'<circle cx="{64+31*math.sin(math.radians(a)):.1f}" cy="{64-31*math.cos(math.radians(a)):.1f}" r="{2.2 if a%90==0 else 1.3}" fill="#FFF" fill-opacity="0.9"/>' for a in range(0,360,30))),
 'notes': ('#FFE27A','#FFB627','#F08A00',
   '<rect x="30" y="22" width="68" height="84" rx="12" stroke="none"/>',
   f'<g stroke="#FFFFFF" stroke-opacity="0.85" stroke-width="3" {S}><path d="M42 50h44M42 62h44M42 74h30"/></g><path d="M30 36h68" stroke="#FFFFFF" stroke-opacity="0.9" stroke-width="3"/>'),
 'calculator': ('#8E8D99','#45434F','#1E1D24',
   '<rect x="32" y="20" width="64" height="88" rx="14" stroke="none"/>',
   '<rect x="40" y="28" width="48" height="18" rx="5" fill="#FFFFFF" fill-opacity="0.35"/>' + ''.join(f'<circle cx="{46+c*18}" cy="{60+r*16}" r="5.5" fill="{"#FF9F43" if (c==2) else "#FFFFFF"}" fill-opacity="{0.95 if c==2 else 0.75}"/>' for r in range(3) for c in range(3))),
 'music': ('#FF8FB1','#F2416E','#B8144A',
   '<path d="M52 36l40-10v52a10 10 0 1 1-8-9.8V40l-24 6v38a10 10 0 1 1-8-9.8z" stroke="none"/>',
   '<ellipse cx="66" cy="32" rx="14" ry="3" fill="#FFF" opacity="0.7" transform="rotate(-14 66 32)" filter="url(#blur2)"/>'),
 'photos': ('#9EF0C9','#2FC48A','#14866A',
   '<rect x="22" y="30" width="84" height="68" rx="12" stroke="none"/>',
   '<circle cx="84" cy="48" r="7" fill="#FFF3B0" fill-opacity="0.95"/><path d="M26 92l26-28 16 16 12-10 24 22" fill="#FFFFFF" fill-opacity="0.55"/>'),
 'store': ('#B6A2FF','#7C5CFF','#4A2FD6',
   '<path d="M30 46h68l-5 50a8 8 0 0 1-8 7H43a8 8 0 0 1-8-7z" stroke="none"/><path d="M50 46v-4a14 14 0 0 1 28 0v4" fill="none" stroke-width="6" stroke-linecap="round"/>',
   f'<path d="M51 88V75a6.5 6.5 0 0 1 13 0v13M64 75a6.5 6.5 0 0 1 13 0v13" fill="none" stroke="#FFFFFF" stroke-opacity="0.95" stroke-width="4.5" {S}/>'),
 'settings': ('#B8BDC7','#6B717C','#3B4049',
   None, '<circle cx="64" cy="64" r="11" fill="none" stroke="#FFFFFF" stroke-opacity="0.85" stroke-width="3"/>'),
 'terminal': ('#5E5C6B','#2A2933','#0E0D12',
   '<rect x="20" y="28" width="88" height="72" rx="14" stroke="none"/>',
   f'<path d="M38 54l12 10-12 10" fill="none" stroke="#7CFFB2" stroke-width="5" {S}/><path d="M56 78h24" stroke="#7CFFB2" stroke-width="5" stroke-linecap="round"/>'),
}
# gear glyph
def gear(cx, cy, ro, ri, teeth, tw=0.42):
    pts=[]
    for i in range(teeth):
        a0=2*math.pi*i/teeth; step=2*math.pi/teeth
        for frac,r in [(0,ri),(0.5-tw/2-0.06,ri),(0.5-tw/2,ro),(0.5+tw/2,ro),(0.5+tw/2+0.06,ri)]:
            a=a0+frac*step; pts.append((cx+r*math.cos(a), cy+r*math.sin(a)))
    return 'M'+' L'.join(f'{x:.2f} {y:.2f}' for x,y in pts)+'Z'
g=icons['settings']
icons['settings']=(g[0],g[1],g[2], f'<path d="{gear(64,64,40,32,9)} M64 52a12 12 0 1 0 0.01 0Z" fill-rule="evenodd" stroke="none"/>', g[4])

os.makedirs('out',exist_ok=True)
for n,(c1,c2,c3,glyph,front) in icons.items():
    open(f'out/{n}.svg','w').write(icon(n,c1,c2,c3,glyph,'',front))
print(len(icons))
