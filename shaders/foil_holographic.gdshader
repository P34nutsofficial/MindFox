shader_type canvas_item;

uniform vec4 foil_color_a : source_color = vec4(1.0, 0.80, 0.38, 1.0);
uniform vec4 foil_color_b : source_color = vec4(0.39, 0.90, 0.89, 1.0);
uniform float sweep_speed : hint_range(0.1, 4.0) = 0.8;
uniform float sweep_strength : hint_range(0.0, 1.0) = 0.26;

void fragment() {
    vec4 base = COLOR;
    float sweep = fract(UV.x + UV.y * 0.35 + TIME * sweep_speed);
    float band = smoothstep(0.46, 0.49, sweep) * (1.0 - smoothstep(0.49, 0.55, sweep));
    float diagonal = 0.5 + 0.5 * sin((UV.x + UV.y) * 18.0 + TIME * 1.8);
    vec3 foil = mix(foil_color_a.rgb, foil_color_b.rgb, diagonal);
    COLOR = vec4(base.rgb + foil * (band + diagonal * 0.08) * sweep_strength, base.a);
}
