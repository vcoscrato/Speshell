#version 440
#extension GL_GOOGLE_include_directive : enable
// Rocks held aloft around the open launcher: faceted boulders that rise out of the
// ground one after another, bob gently while the launcher is open, and drop back
// when it closes. Each is a convex polygon with a lit top face and sides in flat
// tones by facing.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec4 rect;         // this item's rect on screen (px)
    vec4 panel;        // panel rect on screen (px)
    float ground;      // px, screen y of the ground line
    float lift;        // 0..1 entrance: rocks rise in turn
    float fall;        // 0..1 exit: rocks drop in turn
    vec4 cLight;
    vec4 cMid;
    vec4 cDark;
    vec4 cEdge;
} u;
#include "../../../lib/common.glsl"

const int ROCKS = 7;
const int SIDES = 7;
// Rest position as a fraction of the panel plus a px offset (xy, zw), and the size
// (px). Older GLSL targets have no constant arrays.
vec4 place(int i, out float size) {
    if (i == 0) { size = 26.0; return vec4(0.0, 0.36, -54.0, 0.0); }
    if (i == 1) { size = 12.0; return vec4(0.0, 0.8, -32.0, 0.0); }
    if (i == 2) { size = 16.0; return vec4(0.14, 0.0, 0.0, -40.0); }
    if (i == 3) { size = 30.0; return vec4(0.8, 0.0, 0.0, -58.0); }
    if (i == 4) { size = 22.0; return vec4(1.0, 0.58, 50.0, 0.0); }
    if (i == 5) { size = 10.0; return vec4(1.0, 0.16, 28.0, 0.0); }
    size = 8.0;
    return vec4(0.5, 0.0, 0.0, -26.0);
}

float backOut(float x) {
    float c = 1.7;
    return 1.0 + (c + 1.0) * pow(x - 1.0, 3.0) + c * pow(x - 1.0, 2.0);
}

void main() {
    vec2 p = u.rect.xy + qt_TexCoord0 * u.rect.zw;
    vec3 col = vec3(0.0);
    float a = 0.0;
    vec2 light = normalize(vec2(-0.45, -1.0));

    for (int i = 0; i < ROCKS; i++) {
        float fi = float(i);
        float size;
        vec4 pl = place(i, size);
        vec2 rest = u.panel.xy + u.panel.zw * pl.xy + pl.zw;
        float seed = hash(vec2(fi, 7.7)) * 6.2831853;
        rest.y += 7.0 * sin(u.time * 1.7 + seed) * (size / 26.0 + 0.4);
        float rise = backOut(clamp(u.lift * 1.6 - 0.1 * fi, 0.0, 1.0));
        float drop = clamp(u.fall * 1.5 - 0.08 * fi, 0.0, 1.0);
        vec2 from = vec2(rest.x, u.ground + size * 1.3);
        vec2 pos = mix(from, rest, rise);
        pos.y += drop * drop * (u.ground + size * 1.3 - rest.y);
        vec2 rel = p - pos;

        // Grit trickling from under the bigger rocks while they hover.
        if (size > 13.0 && rise >= 1.0 && drop <= 0.0 && abs(rel.x) < size && rel.y > 0.0 && rel.y < size + 50.0) {
            for (int j = 0; j < 3; j++) {
                float fj = float(j);
                float age = fract(u.time / 1.7 + fj / 3.0 + seed);
                float cycle = floor(u.time / 1.7 + fj / 3.0 + seed);
                vec2 g = vec2((hash(vec2(fi + fj, cycle)) - 0.5) * size, size * 0.6 + 50.0 * age * age);
                float gs = mix(3.2, 1.6, age);
                float grain = cover(gs - max(abs(rel.x - g.x), abs(rel.y - g.y))) * (1.0 - age * age);
                col = mix(col, u.cLight.rgb, grain);
                a = mix(a, 1.0, grain);
            }
        }
        if (dot(rel, rel) > size * size * 2.6)
            continue;

        float ang = 0.14 * sin(u.time * 0.8 + seed * 1.3) + seed;
        float cs = cos(ang), sn = sin(ang);
        vec2 lp = mat2(cs, sn, -sn, cs) * rel;
        // Convex polygon: the furthest of SIDES jittered half-planes, and the facet it belongs to.
        float d = -1e3;
        vec2 facet = vec2(0.0);
        float dTop = -1e3;
        for (int k = 0; k < SIDES; k++) {
            float fk = float(k);
            float th = (fk + 0.35 * hash(vec2(fi, fk))) * 6.2831853 / float(SIDES);
            vec2 nrm = vec2(cos(th), sin(th));
            float reach = size * (0.82 + 0.3 * hash(vec2(fk, fi + 3.0)));
            float dk = dot(lp, nrm) - reach;
            if (dk > d) { d = dk; facet = nrm; }
            // The top face: the same polygon, shrunk and nudged toward the light.
            dTop = max(dTop, dot(lp - mat2(cs, sn, -sn, cs) * light * size * 0.22, nrm) - reach * 0.55);
        }
        float body = cover(-d);
        if (body <= 0.0 && cover(-d + 1.6) <= 0.0)
            continue;
        vec2 worldN = transpose(mat2(cs, sn, -sn, cs)) * facet;
        float lit = dot(worldN, light);
        vec3 rock = lit > 0.35 ? u.cMid.rgb : (lit > -0.4 ? mix(u.cMid.rgb, u.cDark.rgb, 0.5) : u.cDark.rgb);
        rock = mix(rock, u.cLight.rgb, cover(-dTop));
        // A jagged crack across the bigger rocks.
        if (size > 15.0) {
            float along = dot(lp, vec2(-0.6, 0.8));
            float zig = (abs(fract(along / 9.0 + fi * 0.37) - 0.5) - 0.25) * 6.0;
            float crack = abs(dot(lp, vec2(0.8, 0.6)) - size * 0.1 + zig);
            rock = mix(rock, u.cDark.rgb, cover(0.9 - crack) * cover(-d - 3.0) * step(along, size * 0.3));
        }
        float edge = cover(-d + 1.6);
        vec3 c = mix(u.cEdge.rgb, rock, body);
        float above = smoothstep(0.75, -0.75, p.y - u.ground);
        float cov = edge * above;
        col = mix(col, c, cov);                         // premultiplied "over"
        a = mix(a, 1.0, cov);
    }
    fragColor = vec4(col, a) * u.qt_Opacity;
}
