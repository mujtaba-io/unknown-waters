shader_type canvas_item;

uniform vec4 paper_color : source_color = vec4(0.85, 0.78, 0.65, 1.0);
uniform vec4 stain_color : source_color = vec4(0.75, 0.65, 0.5, 1.0);
uniform float noise_scale = 5.0;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    // Smooth interpolation
    f = f * f * (3.0 - 2.0 * f);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 uv) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.50)));
    for (int i = 0; i < 5; ++i) {
        v += a * noise(uv);
        uv = rot * uv * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 uv = UV * noise_scale;
    
    float n = fbm(uv);
    
    // Base color mixed with noise for texture
    vec4 final_color = mix(paper_color, stain_color, n * 0.4);
    
    // Vignette / burnt edges
    vec2 center = UV - 0.5;
    float dist = length(center);
    float vignette = smoothstep(0.4, 0.8, dist);
    
    // Darken edges slightly
    final_color.rgb -= vignette * 0.3;
    
    COLOR = final_color;
}
