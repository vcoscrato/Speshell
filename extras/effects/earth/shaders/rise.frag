#version 440
#extension GL_GOOGLE_include_directive : enable
// A captured item rising into place as Voronoi blocks of stone, top first. Each
// block comes up from below in shadow, overshoots a little, and lands; dust puffs
// along its edges as it does, and the cracks between blocks close once the
// neighborhood has settled. Blocks already in place stand in front of rising ones.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    float rise;         // 0..1 overall progress
    vec4 cShade;
    vec4 cDust;
    vec4 cJade;
} u;
layout(binding = 1) uniform sampler2D source;
#include "../../../lib/common.glsl"

const float CELL = 58.0;
const float DROP = 46.0;    // px a block starts below its place
const float MOVE = 0.4;     // share of the whole each block takes to rise

vec2 siteOf(vec2 g) {
    return (g + 0.5 + (hash2(g) - 0.5) * 0.85) * CELL;
}

// 0..1 progress of the block at `site`: higher blocks go first.
float progressOf(vec2 site) {
    float delay = clamp(site.y / u.size.y, 0.0, 1.0) * 0.46 + 0.12 * hash(site);
    return clamp((u.rise - delay) / MOVE, 0.0, 1.0);
}

// Rises fast, overshoots its place, and drops back.
float lift(float c) {
    float k = 1.0 - c;
    return 1.0 - k * k * k + 0.12 * sin(3.1415927 * c) * c;
}

void main() {
    vec2 p = qt_TexCoord0 * u.size;
    vec2 g = floor(p / CELL);

    // Find the block covering p: a block's outline moves with it, so test each nearby
    // block shifted back by its own offset. The most settled one wins; higher rows
    // settle first, so testing them first skips most of the rest.
    float bestOff = 1e9;
    float bestC = 0.0;
    for (int y = -2; y <= 1; y++)
        for (int x = -1; x <= 1; x++) {
            vec2 s = siteOf(g + vec2(x, y));
            float c = progressOf(s);
            if (c <= 0.0)
                continue;
            float off = DROP * (1.0 - lift(c));
            if (off >= bestOff)
                continue;
            vec2 q = p - vec2(0.0, off);
            if (distance(voronoiSite(q, CELL, 0.85), s) < 0.5) {
                bestOff = off;
                bestC = c;
            }
        }

    vec4 col = vec4(0.0);
    if (bestC > 0.0) {
        vec2 q = p - vec2(0.0, bestOff);
        col = texture(source, q / u.size);
        // In shadow while it rises.
        col.rgb = mix(col.rgb, u.cShade.rgb * col.a, 0.45 * (1.0 - bestC));
        // Cracks along its outline, closing once every block has landed.
        float edge = voronoiEdge(q, CELL, 0.85);
        float settle = smoothstep(0.8, 1.0, u.rise);
        float crack = (1.0 - smoothstep(0.4, 1.6, edge)) * (1.0 - settle);
        col.rgb = mix(col.rgb, u.cShade.rgb * col.a, 0.85 * crack);
        // A lit rim along the crack catches the light as it lands.
        float rim = (1.0 - smoothstep(1.6, 3.0, edge)) * step(1.6, edge) * (1.0 - settle);
        col.rgb = mix(col.rgb, u.cJade.rgb * col.a, 0.3 * rim * bestC);

        // Dust puffing from its edges as it lands.
        vec2 dcell = floor(p / 6.0);
        if (hash(dcell + 2.0) < 0.22) {
            float landed = smoothstep(0.55, 0.8, bestC) * (1.0 - smoothstep(0.85, 1.0, u.rise));
            float puff = landed * (1.0 - smoothstep(0.0, 9.0, edge)) * (1.0 - bestC * 0.6);
            vec2 d = (dcell + 0.5) * 6.0 + (hash2(dcell) - 0.5) * 4.0 - p;
            col = mix(col, vec4(u.cDust.rgb, 1.0), 0.75 * cover(1.1 - length(d)) * puff);
        }
    }

    fragColor = col * u.qt_Opacity;
}
