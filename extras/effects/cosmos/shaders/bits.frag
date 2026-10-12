#version 440
#extension GL_GOOGLE_include_directive : enable
// One particle of Cosmos's control effects, by `kind`: 0 a mote of star dust,
// twinkling as it drifts; 1 a glint, a star flaring with four rays; 2 a nova, a hot
// ring spreading through a fading haze.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float age;          // 0..1 over its life
    float seed;
    float kind;
    float size;         // px across
    vec4 cStar;
    vec4 cHot;
    vec4 cGlow;
    vec4 cHaze;
} u;
#include "../../../lib/common.glsl"

vec4 over(vec4 under, vec3 col, float a) {
    return vec4(col, 1.0) * a + under * (1.0 - a);
}

vec4 mote(vec2 p, float R) {
    float twinkle = 0.55 + 0.45 * sin(u.age * 30.0 + u.seed * 50.0);
    float r = R * (0.45 + 0.4 * twinkle);
    vec3 col = mix(u.cStar.rgb, u.cGlow.rgb, step(0.6, u.seed) * 0.6);
    return vec4(col, 1.0) * cover(r - length(p)) * (1.0 - u.age) * (0.5 + 0.5 * twinkle);
}

vec4 glint(vec2 p, float R) {
    float k = sin(3.1415927 * pow(u.age, 0.6));
    float c = cos(u.seed * 3.0 + u.age), s = sin(u.seed * 3.0 + u.age);
    vec2 q = mat2(c, s, -s, c) * p;
    vec2 a = abs(q);
    float len = R * k;
    float ray = max(cover(1.1 - a.y * (1.0 + 3.0 * a.x / max(len, 1.0))) * step(a.x, len),
                    cover(1.1 - a.x * (1.0 + 3.0 * a.y / max(len, 1.0))) * step(a.y, len));
    float core = cover(R * 0.18 * k + 0.6 - length(p));
    vec4 o = over(vec4(0.0), u.cGlow.rgb, ray * k);
    o = over(o, u.cHot.rgb, max(core, ray * step(length(q), len * 0.45)) * k);
    o = over(o, u.cGlow.rgb, cover(R * 0.5 * k - length(p)) * 0.18 * k);
    return o;
}

vec4 nova(vec2 p, float R) {
    float grow = 1.0 - pow(1.0 - u.age, 3.0);
    float r = R * (0.25 + 0.75 * grow);
    float d = length(p);
    float fade = 1.0 - u.age;
    vec4 o = over(vec4(0.0), u.cHaze.rgb, cover(r - d) * 0.14 * fade * fade);
    o = over(o, u.cGlow.rgb, cover(2.6 * fade + 0.4 - abs(d - r)) * fade);
    o = over(o, u.cHot.rgb, cover(1.0 * fade - abs(d - r)) * fade);
    return o;
}

void main() {
    vec2 p = (qt_TexCoord0 - 0.5) * u.size;
    float R = u.size * 0.5 - 1.0;
    vec4 c = u.kind < 0.5 ? mote(p, R) : u.kind < 1.5 ? glint(p, R) : nova(p, R);
    fragColor = c * u.qt_Opacity;
}
