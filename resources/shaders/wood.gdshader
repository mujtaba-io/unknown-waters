shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.4, 0.25, 0.15, 1.0);
uniform vec4 dark_color : source_color = vec4(0.25, 0.15, 0.05, 1.0);
uniform float grain_scale = 10.0;
uniform float distortion = 0.5;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(random(i), random(i + vec2(1.0, 0.0)), f.x),
               mix(random(i + vec2(0.0, 1.0)), random(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
    vec2 uv = UV * grain_scale;
    
    // Distorted UV for wood grain rings
    float n = noise(uv * vec2(0.1, 1.0));
    float grain = noise(vec2(uv.x * 0.1 + n * distortion, uv.y * 3.0));
    
    // Streaks
    float streaks = noise(vec2(uv.x * 10.0, uv.y * 0.2));
    
    float final_grain = mix(grain, streaks, 0.5);
    
    COLOR = mix(base_color, dark_color, final_grain * 0.6);
}
