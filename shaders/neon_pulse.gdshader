shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.80, 0.40, 1.0);
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.6;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.22;

void fragment() {
    vec4 base = COLOR;
    float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
    float edge = 1.0 - min(smoothstep(0.0, 0.13, UV.x) * smoothstep(1.0, 0.87, UV.x), smoothstep(0.0, 0.13, UV.y) * smoothstep(1.0, 0.87, UV.y));
    vec3 result = base.rgb + glow_color.rgb * pulse * pulse_strength;
    result += glow_color.rgb * edge * pulse_strength * 0.55;
    COLOR = vec4(result, base.a);
}
