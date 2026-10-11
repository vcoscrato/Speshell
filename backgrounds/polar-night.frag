#version 440
#extension GL_GOOGLE_include_directive : enable
// Polar night: a full moon over a dark sea, ice cliffs on the horizon, the moon's
// path broken across banded swells, and ice floes drifting close by.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;
} u;
#include "../lib/common.glsl"
#include "landscape.glsl"

// A flat ice floe centered at c: lit top, shaded front.
vec3 floe(vec3 col, vec2 q, vec2 c, vec2 size, float seed) {
    vec2 rel = q - c;
    float edge = (vnoise(vec2(rel.x / size.x * 4.0, seed)) - 0.5) * size.y * 0.6;
    float top = sdRoundRect(rel - vec2(0.0, size.y * 0.5), vec2(size.x, size.y * 0.5), size.y * 0.4) + edge;
    float front = sdRoundRect(rel, vec2(size.x * 0.97, size.y * 0.45), size.y * 0.3);
    col = mix(col, rgb(70, 118, 146), cover(-front));
    return mix(col, rgb(188, 222, 236), cover(-top));
}

void main() {
    vec2 px = qt_TexCoord0 * u.resolution;
    vec2 q = vec2(px.x, u.resolution.y - px.y) / u.resolution.y;
    float aspect = u.resolution.x / u.resolution.y;
    float horizon = 0.38;

    // Sky: steel blue at the horizon up to near-black navy, with stars.
    float t = clamp((q.y - horizon) / (1.0 - horizon), 0.0, 1.0);
    t = pow(t, 0.6) + (fbm(vec2(q.x * 1.4, q.y * 5.0)) - 0.5) * 0.04;
    vec3 col = ramp3(rgb(44, 86, 112), rgb(16, 38, 56), rgb(5, 12, 19), steps(clamp(t, 0.0, 1.0), 7.0));
    vec2 cell = floor(q * 90.0);
    vec2 star = (cell + 0.2 + 0.6 * hash2(cell)) / 90.0;
    float starOn = step(0.95, hash(cell + 3.0)) * step(horizon + 0.08, q.y);
    col = mix(col, rgb(210, 230, 240), starOn * cover(0.0011 * (0.6 + hash(cell + 5.0)) - length(q - star)));

    // Full moon with a halo ring and two darker patches.
    vec2 moon = vec2(aspect * 0.24, 0.76);
    float d = length(q - moon);
    col = mix(col, mix(col, rgb(160, 200, 220), 0.12), cover(0.13 - d));
    col = mix(col, rgb(227, 238, 244), cover(0.065 - d));
    col = mix(col, rgb(208, 224, 234), cover(0.022 - length(q - moon - vec2(0.02, -0.014))));
    col = mix(col, rgb(208, 224, 234), cover(0.011 - length(q - moon - vec2(-0.024, 0.02))));
    col = mix(col, rgb(208, 224, 234), cover(0.008 - length(q - moon - vec2(-0.012, -0.034))));

    // Ice cliffs along the horizon: flat tops, lit faces, and shadowed bases.
    float cliffs = step(0.45, fract(q.x * 0.9 + 0.2)) * step(fract(q.x * 0.9 + 0.2), 0.85);
    float shelf = horizon + 0.012 + (0.02 + 0.035 * steps(vnoise(vec2(q.x * 7.0, 1.5)), 4.0)) * cliffs;
    col = mix(col, rgb(122, 168, 192), below(shelf, q.y));
    col = mix(col, rgb(184, 216, 230), below(shelf, q.y) * (1.0 - below(shelf - 0.006, q.y)));
    col = mix(col, rgb(62, 104, 130), below(horizon + 0.012, q.y));

    // Sea: swells that crowd toward the horizon, in alternating flat bands.
    if (q.y < horizon) {
        float depth = (horizon - q.y) / horizon;
        float row = pow(depth, 0.6) * 22.0 + (vnoise(vec2(q.x * (3.0 + 10.0 * (1.0 - depth)), floor(pow(depth, 0.6) * 22.0))) - 0.5) * 0.8;
        vec3 sea = mix(rgb(14, 38, 54), rgb(9, 27, 40), depth);
        col = mix(sea, sea * 1.35, band(fract(row), 0.72));
        // The moon's path: broken dashes under the moon, widening toward the viewer.
        float lane = abs(q.x - moon.x) / (0.03 + 0.14 * depth);
        float dash = band(fract(row + 0.15), 0.78) * step(vnoise(vec2(q.x * 30.0, floor(row))), 0.7);
        col = mix(col, rgb(150, 190, 210), cover(1.0 - lane - vnoise(vec2(floor(row), 3.0)) * 0.7) * dash * 0.85);
    }

    col = floe(col, q, vec2(aspect * 0.72, 0.16), vec2(0.16, 0.02), 1.0);
    col = floe(col, q, vec2(aspect * 0.9, 0.06), vec2(0.22, 0.026), 2.0);
    col = floe(col, q, vec2(aspect * 0.52, 0.27), vec2(0.07, 0.01), 3.0);
    fragColor = vec4(col, 1.0);
}
