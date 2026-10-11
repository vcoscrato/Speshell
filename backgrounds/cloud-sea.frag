#version 440
#extension GL_GOOGLE_include_directive : enable
// Above the clouds at dusk: stone spires rise out of a sea of clouds under a
// banded slate sky with a saffron glow, and long cloud streaks drift high up.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;
} u;
#include "../lib/common.glsl"
#include "landscape.glsl"

// A tall spire around x = c: steep sides, two-tone with its lit left face.
vec3 spire(vec3 col, vec2 q, float c, float top, float w, float seed, vec3 lit, vec3 shade) {
    float side = abs(q.x - c) / w;
    float h = top - pow(side, 1.6) * 0.75 * top + (vnoise(vec2(q.x * 60.0, seed)) - 0.5) * 0.012;
    float inside = below(h, q.y) * cover(1.0 - side);
    float ridgeLine = c + (vnoise(vec2(q.y * 18.0, seed + 1.0)) - 0.5) * w * 0.25;
    return mix(col, q.x < ridgeLine ? lit : shade, inside);
}

void main() {
    vec2 px = qt_TexCoord0 * u.resolution;
    vec2 q = vec2(px.x, u.resolution.y - px.y) / u.resolution.y;
    float aspect = u.resolution.x / u.resolution.y;

    // Sky: saffron at the horizon through dusky blue to deep slate.
    float t = clamp((q.y - 0.3) / 0.7, 0.0, 1.0);
    t = pow(t, 0.55) + (fbm(vec2(q.x * 1.2, q.y * 4.0)) - 0.5) * 0.04;
    vec3 col = ramp3(rgb(222, 164, 98), rgb(84, 106, 136), rgb(20, 27, 38), steps(clamp(t, 0.0, 1.0), 8.0));

    // A pale low sun behind the haze.
    vec2 sun = vec2(aspect * 0.28, 0.36);
    float d = length(q - sun);
    col = mix(col, mix(col, rgb(250, 226, 176), 0.25), cover(0.11 - d));
    col = mix(col, rgb(250, 230, 186), cover(0.055 - d));

    // High cloud streaks.
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        vec2 c = vec2((0.15 + 0.2 * fi + 0.1 * hash(vec2(fi, 1.0))) * aspect, 0.58 + 0.3 * hash(vec2(fi, 2.0)));
        vec2 r = (q - c) / vec2(0.18 + 0.12 * hash(vec2(fi, 3.0)), 0.011);
        float streak = cover(1.0 - length(r));
        col = mix(col, mix(col, rgb(214, 196, 178), 0.35), streak);
    }

    // Spires behind the cloud sea.
    col = spire(col, q, aspect * 0.74, 0.6, 0.1, 1.0, rgb(78, 92, 116), rgb(46, 56, 74));
    col = spire(col, q, aspect * 0.86, 0.47, 0.08, 2.0, rgb(70, 84, 107), rgb(42, 51, 68));
    col = spire(col, q, aspect * 0.1, 0.42, 0.07, 3.0, rgb(70, 84, 107), rgb(42, 51, 68));

    // Cloud sea: billowing banks, lit on top, darker toward the viewer.
    float h0 = 0.3 + 0.035 * billows(q.x, 7.0, 1.0);
    float h1 = 0.24 + 0.045 * billows(q.x + 0.3, 4.6, 2.0);
    float h2 = 0.15 + 0.06 * billows(q.x + 0.7, 3.1, 3.0);
    float h3 = 0.05 + 0.08 * billows(q.x + 1.3, 2.0, 4.0);
    col = mix(col, rgb(196, 170, 150), below(h0, q.y));
    col = mix(col, rgb(150, 150, 162), below(h1, q.y));
    col = mix(col, rgb(196, 182, 168), below(h1, q.y) * (1.0 - below(h1 - 0.006, q.y)));
    col = mix(col, rgb(100, 112, 132), below(h2, q.y));
    col = mix(col, rgb(150, 150, 162), below(h2, q.y) * (1.0 - below(h2 - 0.007, q.y)));
    col = mix(col, rgb(56, 68, 88), below(h3, q.y));
    col = mix(col, rgb(100, 112, 132), below(h3, q.y) * (1.0 - below(h3 - 0.008, q.y)));
    fragColor = vec4(col, 1.0);
}
