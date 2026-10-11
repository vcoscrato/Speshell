#version 440
#extension GL_GOOGLE_include_directive : enable
// Water held while the launcher is open: two streams chase each other around the
// panel just outside its border, undulating as they flow, shaded in flat bands
// with glints running along them and droplets shed from their tails.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec4 rect;         // this item's rect on screen (px)
    vec4 panel;        // panel rect on screen (px)
    float radius;      // panel corner radius (px)
    float gap;         // px between the panel border and the streams' spine
    float flow;        // 0 no water .. 1 full streams
    float speed;       // px/s along the border
    float tubeWidth;   // half-width (px)
    vec4 cDeep;
    vec4 cMid;
    vec4 cLight;
    vec4 cFoam;
} u;
#include "../../../lib/common.glsl"

const int STREAMS = 2;

void main() {
    vec2 p = u.rect.xy + qt_TexCoord0 * u.rect.zw;
    vec2 c = u.panel.xy + u.panel.zw * 0.5;
    vec2 h = u.panel.zw * 0.5 + u.gap;
    float r = u.radius + u.gap;
    float P = rrPerimeter(h, r);
    vec2 rel = p - c;
    float s = rrArc(rel, h, r);
    float len = P * 0.3 * u.flow;
    float w0 = u.tubeWidth * mix(0.5, 1.0, u.flow);
    // The streams swell in and out from the border as they flow.
    float sway = 6.0 * sin(s / 47.0 - u.time * 3.1) + 2.5 * sin(s / 23.0 + u.time * 4.3);
    float d = sdRoundRect(rel, h, r) - sway;             // across the spine: > 0 outside

    float inside = 0.0, rim = 0.0, n = 0.0, along = 0.0;
    for (int i = 0; i < STREAMS; i++) {
        float head = u.time * u.speed + float(i) * P / float(STREAMS);
        float behind = mod(head - s, P);                 // px back from this stream's head
        if (behind > len + w0)
            continue;
        float t = behind / max(len, 1.0);
        // A round, slightly swollen head tapering to a thin tail.
        float w = w0 * sqrt(clamp(behind / w0, 0.0, 1.0)) * pow(clamp(1.0 - t, 0.0, 1.0), 0.7)
                * (1.0 + 0.3 * exp(-behind / (3.0 * w0)));
        float cov = cover(w - abs(d));
        if (cov > inside) {
            inside = cov;
            n = d / max(w, 1.0);
            along = behind;
        }
        rim = max(rim, cover(w + 1.8 - abs(d)));
    }

    // Droplets flung from each tail, trailing behind and drifting outward.
    float drops = 0.0;
    for (int i = 0; i < STREAMS; i++) {
        float head = u.time * u.speed + float(i) * P / float(STREAMS);
        for (int j = 0; j < 3; j++) {
            float fj = float(j);
            float back = len + 18.0 + 22.0 * fj;
            vec2 dir = normalize(rrPoint(head - back + 1.0, h, r) - rrPoint(head - back - 1.0, h, r));
            vec2 out_ = vec2(dir.y, -dir.x);
            vec2 dp = c + rrPoint(head - back, h, r) + out_ * (4.0 + 5.0 * fj);
            float size = (3.6 - 0.9 * fj) * u.flow;
            drops = max(drops, cover(size - length(p - dp)));
        }
    }

    // Flat bands across the tube, with glints sliding along it faster than the flow.
    vec3 col = u.cMid.rgb;
    col = mix(col, u.cDeep.rgb, cover(n - 0.4));          // the outer side is in shade
    float glint = band(vnoise(vec2((along + u.time * u.speed * 0.5) / 38.0, 0.0)), 0.55);
    col = mix(col, u.cLight.rgb, cover(-n - 0.15) * cover(0.85 + n));
    col = mix(col, u.cFoam.rgb, cover(0.16 - abs(n + 0.5)) * glint);

    vec3 outCol = mix(u.cDeep.rgb * 0.7, col, inside);
    outCol = mix(outCol, u.cLight.rgb, drops * (1.0 - inside));
    float a = max(rim, drops);
    fragColor = vec4(outCol * a, a) * u.qt_Opacity;
}
