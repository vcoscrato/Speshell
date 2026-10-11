#version 440
#extension GL_GOOGLE_include_directive : enable
// Stone country at golden hour: flat-topped mesas striped with rock strata stand
// against a banded gold sky, behind rolling green hills.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;
} u;
#include "../lib/common.glsl"
#include "landscape.glsl"

// Mesa skyline: plateaus with steep sides where the noise crosses a threshold.
float mesa(float x, float freq, float seed) {
    float n = vnoise(vec2(x * freq, seed));
    float top = 0.8 + 0.2 * hash(vec2(floor(x * freq + 0.5), seed + 7.0));
    return smoothstep(0.47, 0.53, n) * top + (vnoise(vec2(x * 90.0, seed)) - 0.5) * 0.006;
}

// A mesa layer: a face with darker strata and a lit rim along the top.
vec3 mesas(vec3 col, vec2 q, float h, vec3 face, vec3 strata, vec3 rim) {
    float inside = below(h, q.y);
    float layer = fract(q.y * 55.0 + vnoise(vec2(q.x * 3.0, 0.0)) * 1.5);
    vec3 c = mix(face, strata, band(layer, 0.7));
    c = mix(c, rim, 1.0 - below(h - 0.005, q.y));
    return mix(col, c, inside);
}

void main() {
    vec2 px = qt_TexCoord0 * u.resolution;
    vec2 q = vec2(px.x, u.resolution.y - px.y) / u.resolution.y;
    float aspect = u.resolution.x / u.resolution.y;

    // Sky: gold at the horizon through olive to deep green-black.
    float t = clamp((q.y - 0.22) / 0.78, 0.0, 1.0);
    t = pow(t, 0.6) + (fbm(vec2(q.x * 1.3, q.y * 5.0)) - 0.5) * 0.05;
    vec3 col = ramp3(rgb(232, 190, 96), rgb(128, 120, 66), rgb(24, 29, 20), steps(clamp(t, 0.0, 1.0), 8.0));

    // Low sun.
    vec2 sun = vec2(aspect * 0.7, 0.4);
    float d = length(q - sun);
    col = mix(col, mix(col, rgb(250, 222, 150), 0.2), cover(0.17 - d));
    col = mix(col, rgb(248, 220, 140), cover(0.09 - d));

    // Mesas, far to near.
    float h0 = 0.27 + 0.2 * mesa(q.x + 0.4, 2.1, 1.0);
    float h1 = 0.2 + 0.17 * mesa(q.x + 2.7, 2.2, 2.0);
    col = mesas(col, q, h0, rgb(150, 124, 86), rgb(134, 110, 76), rgb(214, 178, 112));
    col = mesas(col, q, h1, rgb(112, 90, 64), rgb(98, 78, 56), rgb(178, 142, 92));

    // Rolling green hills in front, lit along their crests.
    float g0 = 0.17 + 0.05 * billows(q.x, 2.2, 5.0);
    float g1 = 0.07 + 0.09 * billows(q.x + 0.9, 1.2, 6.0);
    col = mix(col, rgb(63, 72, 50), below(g0, q.y));
    col = mix(col, rgb(108, 124, 76), below(g0, q.y) * (1.0 - below(g0 - 0.005, q.y)));
    col = mix(col, rgb(34, 40, 27), below(g1, q.y));
    col = mix(col, rgb(76, 94, 52), below(g1, q.y) * (1.0 - below(g1 - 0.006, q.y)));
    fragColor = vec4(col, 1.0);
}
