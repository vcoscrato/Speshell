#version 440
#extension GL_GOOGLE_include_directive : enable
// One particle of Water's control effects, by `kind`: 0 a droplet streaming along its
// path (the item turns with it), whole until it lands when it `arrive`s; 1 a
// ripple, two rings spreading, flattened by `squash` when it lies on a surface; 2 a
// bubble wobbling as it rises.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float age;          // 0..1 over its life
    float seed;
    float kind;
    float size;         // px across
    float squash;       // ripples: height over width
    float arrive;       // drops: 1 to swell in and vanish where they land instead of fading
    vec4 cWater;
    vec4 cLight;
    vec4 cFoam;
    vec4 cDeep;
} u;
#include "../../../lib/common.glsl"

vec4 over(vec4 under, vec3 col, float a) {
    return vec4(col, 1.0) * a + under * (1.0 - a);
}

vec4 drop(vec2 p, float R) {
    // Arriving, it swells in and stays whole until it lands.
    float k = u.arrive > 0.5 ? smoothstep(0.0, 0.2, u.age) : 1.0;
    p /= max(k, 0.05);
    float r = R * 0.45;
    // A round head with a tail streaming behind it.
    float tail = clamp(-p.x / (R * 0.9), 0.0, 1.0);
    float d = min(length(p - vec2(R * 0.2, 0.0)) - r,
                  max(abs(p.y) - r * (1.0 - tail), max(p.x - R * 0.2, -p.x - R * 0.9)));
    vec4 c = over(vec4(0.0), u.cDeep.rgb, cover(-d));
    c = over(c, u.cWater.rgb, cover(-d - 1.0));
    c = over(c, u.cLight.rgb, cover(-d - 1.0) * band(-p.y, r * 0.25));
    c = over(c, u.cFoam.rgb, cover(r * 0.35 - length(p - vec2(R * 0.3, -r * 0.35))));
    return c * (u.arrive > 0.5 ? step(0.05, k) : 1.0 - smoothstep(0.75, 1.0, u.age));
}

vec4 ripple(vec2 p, float R) {
    p.y /= max(u.squash, 0.1);
    vec4 c = vec4(0.0);
    for (int i = 0; i < 2; i++) {
        float a = clamp(u.age * 1.25 - float(i) * 0.25, 0.0, 1.0);
        float r = R * (0.15 + 0.85 * (1.0 - pow(1.0 - a, 2.0)));
        // Thicker toward the viewer when it lies flat.
        float w = (1.4 - float(i) * 0.4) * (u.squash < 0.9 ? 1.0 + 0.6 * clamp(p.y / r, 0.0, 1.0) : 1.0);
        float ring = cover(w - abs(length(p) - r) / max(1.0, 1.0 / u.squash * 0.5));
        float fade = (1.0 - a) * step(0.001, a);
        c = over(c, mix(u.cFoam.rgb, u.cLight.rgb, float(i)), ring * fade);
    }
    return c;
}

vec4 bubble(vec2 p, float R) {
    float r = R * (0.65 + 0.15 * sin(u.age * 20.0 + u.seed * 9.0));
    p.x *= 1.0 + 0.12 * sin(u.age * 26.0 + u.seed * 5.0);
    float d = length(p) - r;
    vec4 c = over(vec4(0.0), u.cLight.rgb, cover(1.0 - abs(d)) * 0.9);
    c = over(c, u.cWater.rgb, cover(-d - 1.0) * 0.25);
    c = over(c, u.cFoam.rgb, cover(r * 0.28 - length(p + vec2(r * 0.35, r * 0.35))));
    return c * (1.0 - smoothstep(0.8, 1.0, u.age));
}

void main() {
    vec2 p = (qt_TexCoord0 - 0.5) * u.size;
    float R = u.size * 0.5 - 1.0;
    vec4 c = u.kind < 0.5 ? drop(p, R) : u.kind < 1.5 ? ripple(p, R) : bubble(p, R);
    fragColor = c * u.qt_Opacity;
}
