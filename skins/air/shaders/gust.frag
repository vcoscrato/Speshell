#version 440
#extension GL_GOOGLE_include_directive : enable
// Airbending gusts: a ring of tapered, outlined wind strokes spiralling around a
// center, each with a thinner echo, over faint swirling mist in flat bands.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec2 resolution;
    vec2 origin;       // px, this item's top-left on screen
    vec2 center;
    float count;       // strokes around the ring
    float phase;       // ring rotation (rad)
    float r0;          // spiral radius at u = 0
    float k;           // spiral tightness: radius shrinks by e^-k per radian
    float spin;        // +1 counter-clockwise on screen, -1 clockwise
    float head;        // head position along the spiral (rad)
    float len;         // stroke length (rad)
    float strokeWidth; // stroke half-width (px)
    float strokeAlpha;
    float cycle;       // s; > 0 makes each stroke loop on its own staggered cycle,
                       // its head running 0..head and fading in and out
    float mist;        // 0..1 mist strength
    float mistRadius;  // px, middle of the mist ring
    vec4 mask;         // px rect the wind passes behind (zero size: none)
    float maskRadius;
    vec4 cBody;
    vec4 cRim;
} u;
#include "../../../lib/common.glsl"

void main() {
    vec2 p = u.origin + qt_TexCoord0 * u.resolution;
    float keep = 1.0;
    if (u.mask.z > 0.0) {
        keep = cover(sdRoundRect(p - u.mask.xy - u.mask.zw * 0.5, u.mask.zw * 0.5, u.maskRadius) - 2.0);
        if (keep <= 0.0) {
            fragColor = vec4(0.0);
            return;
        }
    }
    float body = 0.0, rim = 0.0;
    for (int i = 0; i < 8; i++) {
        float fi = float(i);
        if (fi >= u.count)
            break;
        float th0 = u.phase + fi * 6.2831853 / u.count;
        float r0 = u.r0 * (1.0 + 0.1 * sin(fi * 2.3 + 0.7));
        float head = u.head - 0.35 * hash(vec2(fi, 3.1));
        float strokeA = 1.0;
        if (u.cycle > 0.0) {
            float age = fract(u.time / u.cycle + fi / u.count);
            head = age * u.head;
            strokeA = sin(3.1415927 * age);
        }
        float s = gustStroke(p, u.center, r0, u.k, th0, u.spin, head, u.len, u.strokeWidth, 0.06);
        float e = gustStroke(p, u.center, r0 * 0.88, u.k, th0 + 0.3 * u.spin, u.spin, head - 0.5,
                             u.len * 0.6, u.strokeWidth * 0.45, 0.05);
        float b = max(cover(s), cover(e)), r = max(cover(s + 2.5), cover(e + 2.0));
        // Overlapping strokes: the most opaque one shows.
        if (r * strokeA > rim) { body = b; rim = r * strokeA; }
    }

    // Mist: noise wound into a vortex, banded into two faint flat tones.
    float mistA = 0.0;
    if (u.mist > 0.0) {
        vec2 rel = p - u.center;
        float r = length(rel);
        float twist = 1.6 * log(max(r, 1.0) / u.mistRadius) * -u.spin + u.time * 0.6 * u.spin;
        vec2 q = mat2(cos(twist), sin(twist), -sin(twist), cos(twist)) * rel;
        float ring = exp(-pow((r - u.mistRadius) / (0.55 * u.mistRadius), 2.0));
        if (ring * u.mist > 0.3) {
            float m = fbm(q / 130.0 + 7.0) * ring * u.mist;
            mistA = band(m, 0.34) * 0.045 + band(m, 0.44) * 0.055;
        }
    }

    vec3 strokeCol = mix(u.cRim.rgb, u.cBody.rgb, body);
    float strokeA = rim * u.strokeAlpha;
    vec3 col = mix(u.cBody.rgb * mistA, strokeCol, strokeA);
    float a = strokeA + mistA * (1.0 - strokeA);
    fragColor = vec4(col, a) * keep * u.qt_Opacity;
}
