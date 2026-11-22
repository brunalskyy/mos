#version 140
// Dual Kawase upsample (KWin blur) + mOS Liquid Glass on the last pass.
// Liquid Glass: Bruno Woznicki (mOS). Lens idea from the Better Blur refraction
// work by DaddelZeit and iGerman00. GPL-2.0-or-later.

uniform sampler2D texUnit;
uniform float offset;
uniform vec2 halfpixel;

uniform float glassStrength; // 0 = plain frosted blur
uniform vec2 regionSize;     // glass size in device pixels
uniform float edgeSize;      // how far in from the edge the glass bends light
uniform float cornerRadius;
uniform float fringing;      // rainbow split at the edge
uniform float shine;         // rim highlight
uniform vec2 lightPos;       // where the light is (the mouse), pixels, top-down
uniform vec4 merge;          // left, top, right, bottom: 1 = melts into neighbouring glass

in vec2 uv;

out vec4 fragColor;

vec4 kawase(vec2 c)
{
    vec4 sum = texture(texUnit, c + vec2(-halfpixel.x * 2.0, 0.0) * offset);
    sum += texture(texUnit, c + vec2(-halfpixel.x, halfpixel.y) * offset) * 2.0;
    sum += texture(texUnit, c + vec2(0.0, halfpixel.y * 2.0) * offset);
    sum += texture(texUnit, c + vec2(halfpixel.x, halfpixel.y) * offset) * 2.0;
    sum += texture(texUnit, c + vec2(halfpixel.x * 2.0, 0.0) * offset);
    sum += texture(texUnit, c + vec2(halfpixel.x, -halfpixel.y) * offset) * 2.0;
    sum += texture(texUnit, c + vec2(0.0, -halfpixel.y * 2.0) * offset);
    sum += texture(texUnit, c + vec2(-halfpixel.x, -halfpixel.y) * offset) * 2.0;
    return sum / 12.0;
}

// Rounded box distance (Inigo Quilez): negative inside
float roundBox(vec2 p, vec2 b, float r)
{
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

// The glass shape. Sides that touch other glass are pushed outwards so they have no edge.
float glassShape(vec2 p)
{
    float grow = edgeSize + cornerRadius + 4.0;
    vec2 lo = -merge.xy * grow;
    vec2 hi = regionSize + merge.zw * grow;
    vec2 halfSize = 0.5 * (hi - lo);
    return roundBox(p - 0.5 * (lo + hi), halfSize, min(cornerRadius, min(halfSize.x, halfSize.y)));
}

void main(void)
{
    if (glassStrength <= 0.0) {
        fragColor = kawase(uv);
        return;
    }

    vec2 p = vec2(uv.x, 1.0 - uv.y) * regionSize; // pixels, top-down
    float d = glassShape(p);
    float inside = max(-d, 0.0);
    float e = max(edgeSize, 1.0);

    // Outward normal of the edge
    vec2 g = vec2(glassShape(p + vec2(1.0, 0.0)) - glassShape(p - vec2(1.0, 0.0)),
                  glassShape(p + vec2(0.0, 1.0)) - glassShape(p - vec2(0.0, 1.0)));
    vec2 n = length(g) > 1e-5 ? normalize(g) : vec2(0.0, -1.0);

    // Lens: near the edge we read from further inside, so the background is
    // magnified and bent around the rim like thick curved glass.
    float lens = 1.0 - clamp(inside / e, 0.0, 1.0);
    lens *= lens;
    float push = lens * e * min(1.2, 1.1 * glassStrength);
    vec2 inward = vec2(-n.x, n.y) / regionSize; // inward, in texture space (y flipped)
    vec2 lo = halfpixel * 2.0;
    vec2 hi = vec2(1.0) - halfpixel * 2.0;
    float f = fringing * lens;

    vec4 colour = kawase(clamp(uv + inward * push, lo, hi));
    colour.r = kawase(clamp(uv + inward * push * (1.0 + f), lo, hi)).r;
    colour.b = kawase(clamp(uv + inward * push * (1.0 - f), lo, hi)).b;

    // Rim light: bright on the side facing the light, a softer catch on the opposite side
    vec2 toLight = lightPos - 0.5 * regionSize;
    vec2 l = length(toLight) > 1e-3 ? normalize(toLight) : vec2(-0.5, -0.86);
    float facing = dot(n, l);
    float catchLight = pow(max(facing, 0.0), 3.0) + 0.45 * pow(max(-facing, 0.0), 3.0);
    float line = 1.0 - smoothstep(0.0, 2.2, inside);    // crisp 2 px edge
    float glow = 1.0 - smoothstep(0.0, e * 0.7, inside);  // soft inner glow
    float rim = line * (0.3 + 0.7 * catchLight) * 0.9 + glow * 0.22 * catchLight;

    // A faint sheen across the top, like light on a glass slab
    float sheen = (1.0 - smoothstep(0.0, regionSize.y * 0.55, p.y)) * 0.035;

    colour.rgb = min(colour.rgb + vec3((rim + sheen) * shine) * colour.a, vec3(colour.a));
    fragColor = colour;
}
