#version 440
#extension GL_GOOGLE_include_directive : enable
// A gust carrying a captured item in from the left. The item shows behind a ragged
// front whose rows lag by different amounts, like streaks of wind, and is pushed
// along just behind it. Streaks of wind lead and trail the front, a few curling at
// their heads, and leaves tumble along ahead of it.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    float front;        // 0..1 progress of the front across the item
    float fade;         // 1..0 the streaks blowing out and the push easing off after the front
                        // has passed; at 0 the item shows exactly as it is
    float time;
    vec4 cWind;
    vec4 cLeaf;
    vec4 cLeafBack;
    vec4 cOutline;
} u;
layout(binding = 1) uniform sampler2D source;
#include "../../../lib/common.glsl"

const float LAG = 150.0;    // px the slowest rows trail the fastest

// x of the front in the row at y, bent by the flow.
float frontX(float y) {
    float lag = LAG * pow(vnoise(vec2(y / 30.0, 0.5)), 1.3) + 22.0 * vnoise(vec2(y / 11.0, 2.5));
    return u.front * (u.size.x + LAG + 120.0) - 60.0 - lag;
}

float sdLeaf(vec2 p, float r, float d) {
    p = abs(p);
    float b = sqrt(r * r - d * d);
    return ((p.y - b) * d > p.x * b) ? length(p - vec2(0.0, b)) : length(p - vec2(-d, 0.0)) - r;
}

void main() {
    vec2 p = qt_TexCoord0 * u.size;
    // Rows sway as the gust passes, so the streaks bend.
    float y = p.y + 14.0 * (fbm(vec2(p.x / 110.0, p.y / 90.0 - u.time * 0.8)) - 0.5);
    float fx = frontX(y);
    float behind = fx - p.x;                      // > 0: the gust has passed here

    // The item, pushed along just behind the front.
    float push = 16.0 * exp(-max(behind, 0.0) / 45.0) * step(0.0, behind) * u.fade;
    // A soft edge, so the front reads as moving air rather than a cut.
    vec4 col = texture(source, (p - vec2(push, 0.0)) / u.size) * smoothstep(-6.0, 10.0, behind);

    // Streaks: thin lines in some rows, from a tail behind the front to a head ahead.
    float row = floor(y / 7.0);
    float rnd = hash(vec2(row, 3.0));
    if (rnd < 0.3) {
        float len = 50.0 + 130.0 * hash(vec2(row, 4.0));
        float lead = 15.0 + 60.0 * hash(vec2(row, 5.0));
        float along = (p.x - (fx + lead - len)) / len;      // 0 tail .. 1 head
        if (along > 0.0 && along < 1.0) {
            float cy = (row + 0.5) * 7.0;
            float w = 0.3 + 0.8 * sin(3.1415927 * along) * along;
            float line = cover(w - abs(y - cy) + 0.3);
            float a = line * (0.2 + 0.45 * along) * u.fade;
            col = mix(col, vec4(u.cWind.rgb, 1.0), a);
        }
    }

    // Leaves riding ahead of the front, tumbling.
    for (int i = 0; i < 7; i++) {
        float fi = float(i);
        float ly = u.size.y * (0.08 + 0.84 * hash(vec2(fi, 1.0)));
        ly += 30.0 * sin(u.time * (2.0 + 2.0 * hash(vec2(fi, 2.0))) + fi);
        float lx = frontX(ly) + 25.0 + 70.0 * hash(vec2(fi, 3.0));
        vec2 rel = p - vec2(lx, ly);
        float L = 6.0 + 4.0 * hash(vec2(fi, 4.0));
        if (dot(rel, rel) > L * L * 3.0)
            continue;
        float ang = u.time * mix(-9.0, 9.0, hash(vec2(fi, 5.0))) + fi * 2.1;
        float flip = cos(u.time * mix(5.0, 11.0, hash(vec2(fi, 6.0))) + fi);
        vec2 q = mat2(cos(ang), -sin(ang), sin(ang), cos(ang)) * rel;
        q.x /= max(abs(flip), 0.2);
        float d = sdLeaf(q, L, L * 0.62);
        float outline = cover(0.9 - d);
        float body = cover(-d);
        float rib = cover(0.5 - abs(q.x)) * step(abs(q.y), L * 0.7);
        vec3 face = flip > 0.0 ? u.cLeaf.rgb : u.cLeafBack.rgb;
        vec3 leaf = mix(u.cOutline.rgb, mix(face, u.cOutline.rgb, 0.4 * rib), body);
        col = mix(col, vec4(leaf, 1.0), outline * u.fade);
    }

    fragColor = col * u.qt_Opacity;
}
