#version 440
#extension GL_GOOGLE_include_directive : enable
// Ember dusk: a low sun behind volcanic ridges in a banded crimson sky, with
// embers drifting up.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;
} u;
#include "../lib/common.glsl"
#include "landscape.glsl"

void main() {
    vec2 px = qt_TexCoord0 * u.resolution;
    vec2 q = vec2(px.x, u.resolution.y - px.y) / u.resolution.y;
    float aspect = u.resolution.x / u.resolution.y;

    // Sky: ember glow at the horizon up to near-black maroon, in flat bands.
    float t = clamp((q.y - 0.16) / 0.84, 0.0, 1.0);
    t = pow(t, 0.6) + (fbm(vec2(q.x * 1.3, q.y * 5.0)) - 0.5) * 0.05;
    vec3 col = ramp3(rgb(214, 98, 44), rgb(110, 31, 27), rgb(21, 10, 12), steps(clamp(t, 0.0, 1.0), 8.0));

    // Sun with two halo rings.
    vec2 sun = vec2(aspect * 0.63, 0.31);
    float d = length(q - sun);
    col = mix(col, mix(col, rgb(246, 160, 74), 0.1), cover(0.24 - d));
    col = mix(col, mix(col, rgb(246, 160, 74), 0.22), cover(0.17 - d));
    col = mix(col, rgb(247, 178, 82), cover(0.12 - d));
    col = mix(col, rgb(255, 222, 150), cover(0.085 - d) * 0.6);

    // A volcano rises out of the back range, its crater glowing.
    vec2 cone = vec2(aspect * 0.24, 0.47);
    float volcano = cone.y - 0.04 - max(abs(q.x - cone.x) - 0.035, 0.0) * 1.05
        + (vnoise(vec2(q.x * 30.0, 2.0)) - 0.5) * 0.008;
    float h0 = max(0.19 + 0.17 * ridge(q.x, 2.0, 1.0), volcano);
    // A smoke plume leaning away from the crater, in two dark bands.
    float rise = max(q.y - (cone.y - 0.045), 0.0);
    float axis = cone.x + rise * 0.6 + rise * rise * 1.4 + (fbm(vec2(q.y * 4.0, 7.0)) - 0.5) * 0.06 * rise * 3.0;
    float width = 0.014 + rise * 0.11 + (fbm(vec2(q.x * 6.0, q.y * 6.0)) - 0.5) * 0.05 * rise * 3.0;
    float plume = cover(width - abs(q.x - axis)) * cover(q.y - cone.y + 0.05) * (1.0 - smoothstep(0.75, 1.0, q.y));
    col = mix(col, rgb(36, 13, 14), plume * 0.5);
    col = mix(col, rgb(28, 10, 11), plume * cover(width * 0.55 - abs(q.x - axis)) * 0.45);

    // Ridges, back to front, each with a rim lit from the sun.
    float h1 = 0.12 + 0.13 * ridge(q.x + 3.1, 2.9, 2.0);
    float h2 = 0.03 + 0.10 * ridge(q.x + 7.3, 3.8, 3.0);
    float rim = exp(-abs(q.x - sun.x) * 2.2);
    col = mix(col, rgb(74, 24, 23), below(h0, q.y));
    col = mix(col, rgb(160, 52, 34), below(h0, q.y) * (1.0 - below(h0 - 0.004, q.y)) * rim);
    float crater = cover(0.03 - abs(q.x - cone.x)) * cover(q.y - (cone.y - 0.075));
    col = mix(col, rgb(240, 120, 50), crater * below(h0, q.y) * (1.0 - below(h0 - 0.007, q.y)));
    col = mix(col, rgb(44, 15, 16), below(h1, q.y));
    col = mix(col, rgb(110, 36, 28), below(h1, q.y) * (1.0 - below(h1 - 0.003, q.y)) * rim);
    col = mix(col, rgb(20, 8, 8), below(h2, q.y));

    // Embers drifting up, brighter near the ridges.
    for (int i = 0; i < 70; i++) {
        vec2 h = hash2(vec2(float(i), 4.2));
        vec2 e = vec2(h.x * aspect, 0.08 + 0.8 * h.y * h.y);
        float r = mix(0.0018, 0.0042, hash(vec2(float(i), 9.0)));
        float glow = 1.0 - e.y;
        col = mix(col, rgb(245, 133, 58), cover(r - length(q - e)) * glow);
        col = mix(col, rgb(255, 214, 140), cover(r * 0.45 - length(q - e)) * glow);
    }
    fragColor = vec4(col, 1.0);
}
