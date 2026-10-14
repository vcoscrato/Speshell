#version 440
#extension GL_GOOGLE_include_directive : enable
// A captured item struck into place by lightning. A bolt forks down through it from
// the top in an instant, and the item shows outward from the bolt behind a ragged,
// glowing front, top rows first. The bolt flashes twice, lighting the item, then
// dies; at the end the item shows exactly as it is.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    float progress;     // 0..1
    float time;
    vec4 cCore;
    vec4 cGlow;
    vec4 cEdge;
} u;
layout(binding = 1) uniform sampler2D source;
#include "../../../lib/common.glsl"

const float STRIKE = 0.35;      // share of the whole the bolt takes to reach the bottom
const float SPREAD = 0.4;       // share each row takes to show across

// Piecewise-linear noise: straight runs between random kinks.
float zig(float x, float seed) {
    float i = floor(x), f = fract(x);
    return mix(hash(vec2(i, seed)), hash(vec2(i + 1.0, seed)), f) - 0.5;
}

float boltX(float y) {
    return u.size.x * (0.5 + 0.3 * zig(y / 110.0, 1.0) + 0.1 * zig(y / 28.0, 2.0));
}

void main() {
    vec2 p = qt_TexCoord0 * u.size;
    float t = u.progress;
    float tip = u.size.y * min(1.0, t / STRIKE);
    float bx = boltX(p.y);
    float bx2 = boltX(p.y + 1.0);
    float d = abs(p.x - bx) / sqrt(1.0 + (bx2 - bx) * (bx2 - bx));

    // Shown outward from the bolt, each row once the bolt has passed it.
    float start = STRIKE * p.y / u.size.y;
    float reach = max(0.0, t - start) / SPREAD * (u.size.x + 60.0);
    reach += 18.0 * (vnoise(vec2(p.y / 9.0, t * 20.0)) - 0.5) * step(t, 0.99);
    float across = abs(p.x - bx);
    float shown = cover(reach - across);
    vec4 col = texture(source, qt_TexCoord0) * shown;

    // The front glows as it spreads, and the item glows where the bolt lit it.
    float front = (1.0 - smoothstep(0.0, 9.0, reach - across)) * shown * (1.0 - smoothstep(0.7, 0.95, t));
    col.rgb = mix(col.rgb, u.cEdge.rgb * col.a, 0.85 * front);
    col.rgb = mix(col.rgb, u.cGlow.rgb * col.a, 0.85 * front * (1.0 - smoothstep(0.0, 3.0, reach - across)));

    // The bolt: on as it strikes, flickering off, a second flash, then gone.
    float flash = t < STRIKE ? 1.0 : t < 0.5 ? 1.0 - (t - STRIKE) / 0.15 * 0.8
                : t < 0.58 ? 1.0 : 1.0 - smoothstep(0.58, 0.85, t);
    float lit = flash * exp(-d / 140.0) * 0.18 * step(start, t);
    col.rgb = mix(col.rgb, u.cCore.rgb * col.a, lit);
    float on = flash * step(p.y, tip);
    // Forks off the main channel, drawn once the bolt has passed them.
    float fork = 1e3;
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        float y0 = u.size.y * (0.12 + 0.22 * fi + 0.06 * hash(vec2(fi, 3.0)));
        float len = 70.0 + 70.0 * hash(vec2(fi, 4.0));
        float side = mod(fi, 2.0) < 1.0 ? 1.0 : -1.0;
        float s = (p.y - y0) / len;                          // 0..1 down the fork
        if (s < 0.0 || s > 1.0 || tip < y0 + s * len)
            continue;
        float fx = boltX(y0) + side * s * len * 0.8 + 14.0 * zig(p.y / 12.0, fi + 7.0);
        fork = min(fork, abs(p.x - fx) - 1.2 * (1.0 - s));
    }
    float w = 1.6;
    vec4 bolt = vec4(0.0);
    bolt = mix(bolt, vec4(u.cEdge.rgb, 1.0), cover(w + 6.0 - d) * 0.45);
    bolt = mix(bolt, vec4(u.cGlow.rgb, 1.0), cover(w + 2.2 - d));
    bolt = mix(bolt, vec4(u.cCore.rgb, 1.0), cover(w - d));
    bolt = mix(bolt, vec4(u.cGlow.rgb, 1.0), cover(1.6 - fork));
    bolt = mix(bolt, vec4(u.cCore.rgb, 1.0), cover(0.6 - fork));
    col = mix(col, bolt, bolt.a * on);

    fragColor = col * u.qt_Opacity;
}
