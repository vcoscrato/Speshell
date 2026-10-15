#version 440
#extension GL_GOOGLE_include_directive : enable
// A sheet of water sliding down over a captured item from the top edge. Its falling
// front is a foam crest with tongues running ahead and droplets flung below; ahead of
// it nothing shows. Inside the sheet the item shows deep under water: bent, tinted,
// streaked, and netted with caustics. Behind the sheet's waterline the item shows dry,
// but for drops still running down the glass.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    float head;         // 0..1 how far the front has come down
    float tail;         // 0..1 how far the waterline behind it has come down; at 1
                        // the item shows exactly as it is
    float time;
    vec4 cLight;
    vec4 cFoam;
    vec4 cWater;
} u;
layout(binding = 1) uniform sampler2D source;
#include "../../lib/common.glsl"

// y of the front at x: tongues of water run ahead of it unevenly.
float front(float x) {
    float y = -50.0 + u.head * (u.size.y + 160.0);
    float tongues = 30.0 * pow(fbm(vec2(x / 46.0, 3.0 + u.time * 0.6)), 1.6);
    float waves = 4.0 * sin(x / 31.0 + u.time * 9.0) + 2.0 * sin(x / 13.0 - u.time * 13.0);
    return y + tongues + waves;
}

// y of the waterline at x, sagging where more water still runs.
float waterline(float x) {
    float y = -40.0 + u.tail * (u.size.y + 300.0);
    return y - 26.0 * fbm(vec2(x / 60.0, 8.0 + u.time * 0.8)) + 3.0 * sin(x / 27.0 - u.time * 8.0);
}

void main() {
    vec2 p = qt_TexCoord0 * u.size;
    float s = front(p.x);
    float w = waterline(p.x);
    float behind = s - p.y;                        // > 0 the front has passed
    float under = p.y - w;                         // > 0 below the waterline
    float sheet = max(s - w, 1.0);
    float depth = clamp(under / sheet, 0.0, 1.0);  // 0 at the waterline, 1 at the front
    float wet = cover(under) * cover(behind);

    // The item, bent by the moving water: more inside the sheet, a little in its wake.
    vec2 flow = vec2(fbm(p / 38.0 + vec2(0.0, -u.time * 3.0)), fbm(p / 38.0 + vec2(4.0, -u.time * 3.0))) - 0.5;
    vec2 bend = flow * 14.0 * wet + vec2(0.0, sin(p.x / 17.0 + u.time * 11.0)) * 2.0 * wet;
    vec4 col = texture(source, (p + bend) / u.size);
    float a = col.a;

    // Deep water tint, deepest in the middle of the sheet.
    float deep = wet * (0.3 + 0.16 * sin(depth * 3.14159));
    col.rgb = mix(col.rgb, u.cWater.rgb * a, deep);
    // Streaks of light running down the sheet.
    float streak = fbm(vec2(p.x / 6.0, p.y / 110.0 - u.time * 5.0));
    col.rgb = mix(col.rgb, u.cLight.rgb * a, 0.35 * wet * smoothstep(0.55, 0.75, streak));
    // Caustics: two nets of light overlap, and their lines thin out where the light is weak.
    vec2 cp = p + flow * 26.0 - vec2(0.0, u.time * 120.0);
    float edge = min(voronoiEdge(cp, 44.0, 1.0), voronoiEdge(cp * 1.37 + 31.0, 44.0, 1.0) + 0.4);
    float light = smoothstep(0.3, 0.7, fbm(p / 70.0 + vec2(u.time * 0.5, 2.0)));
    float net = (1.0 - smoothstep(0.4, 1.4 + 2.0 * light, edge)) * light;
    col.rgb = mix(col.rgb, u.cLight.rgb * a, 0.4 * net * wet);

    // The waterline: a bright meniscus over a darker lip.
    float line = cover(1.2 - abs(under - 1.0)) * cover(behind);
    float lip = cover(under - 2.0) * (1.0 - smoothstep(2.0, 8.0, under)) * cover(behind);
    col.rgb = mix(col.rgb, u.cWater.rgb * 0.6 * a, 0.5 * lip);
    col.rgb = mix(col.rgb, u.cLight.rgb * a, 0.75 * line * a);

    // Drops left on the glass behind the waterline, running down after it.
    float drying = 1.0 - smoothstep(0.0, 140.0, -under);
    if (under < 0.0 && drying > 0.0) {
        float lane = floor(p.x / 11.0);
        float speed = 0.4 + 0.5 * hash(vec2(lane, 2.0));
        float y = w - (30.0 + 110.0 * hash(vec2(lane, 5.0))) * (1.0 - speed * 0.6);
        vec2 dp = vec2(p.x - (lane + 0.5) * 11.0, p.y - y);
        float r = 1.4 + 1.6 * hash(vec2(lane, 9.0));
        float drop = hash(vec2(lane, 1.0)) < 0.45 ? cover(r - length(dp * vec2(1.0, 0.75))) : 0.0;
        // A thin trail above each drop.
        float trail = hash(vec2(lane, 1.0)) < 0.45
            ? cover(0.6 - abs(dp.x)) * step(dp.y, 0.0) * exp(dp.y / 40.0) * 0.5 : 0.0;
        col.rgb = mix(col.rgb, u.cLight.rgb * a, max(drop * 0.8, trail) * drying * a);
    }

    col *= cover(behind);

    // The front: a lit band behind a foam crest.
    float lit = cover(behind) * (1.0 - smoothstep(2.0, 16.0, behind));
    col = mix(col, vec4(u.cLight.rgb, 1.0), 0.6 * lit);
    col = mix(col, vec4(u.cFoam.rgb, 1.0), cover(2.0 - abs(behind - 0.5)));

    // Droplets flung down ahead of the crest.
    vec2 cell = floor(vec2(p.x / 9.0, (p.y - s - u.time * 140.0) / 9.0));
    if (behind < 0.0 && behind > -44.0 && hash(cell) < 0.08) {
        vec2 c = (cell + 0.5) * 9.0;
        vec2 v = vec2(p.x, p.y - s - u.time * 140.0) - c;
        float r = 1.0 + 1.2 * hash(cell + 3.0);
        col = mix(col, vec4(u.cFoam.rgb, 1.0), 0.8 * cover(r - length(v)) * (1.0 + behind / 44.0));
    }

    fragColor = col * u.qt_Opacity;
}
