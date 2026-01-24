shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float speed = 2.0;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center);
    float radius = 0.4;
    
    // Core dot
    float core = smoothstep(radius, radius - 0.01, dist);
    
    // Pulsing ring
    float pulse = fract(TIME * speed * 0.5);
    float ring_radius = radius + pulse * 0.5; // Expand outwards
    float ring = smoothstep(ring_radius, ring_radius - 0.05, dist);
    ring *= (1.0 - pulse); // Fade out as it expands
    
    // Combine (don't draw ring inside core)
    ring = max(0.0, ring - core);
    
    vec4 final_color = color;
    final_color.a *= (core + ring);
    
    COLOR = final_color;
}
