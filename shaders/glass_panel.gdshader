shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(0.39, 0.90, 0.89, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.28;
uniform float frost_strength : hint_range(0.0, 1.0) = 0.06;

void fragment() {
    vec4 base = COLOR;
    float edge_x = smoothstep(0.0, 0.18, UV.x) * smoothstep(1.0, 0.82, UV.x);
    float edge_y = smoothstep(0.0, 0.16, UV.y) * smoothstep(1.0, 0.84, UV.y);
    float rim = 1.0 - min(edge_x, edge_y);
    float shimmer = 0.5 + 0.5 * sin(TIME * 0.8 + UV.x * 5.0 + UV.y * 2.0);
    vec3 tint = mix(base.rgb, base.rgb + rim_color.rgb * 0.16, frost_strength);
    tint += rim_color.rgb * rim * rim_strength * (0.55 + shimmer * 0.45);
    COLOR = vec4(tint, base.a);
}
