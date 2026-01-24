shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.3);
uniform float speed : hint_range(0.0, 5.0) = 0.5;
uniform float line_thickness : hint_range(0.0, 0.1) = 0.02;
uniform float perspective : hint_range(0.1, 2.0) = 0.5;

void fragment() {
    vec2 uv = UV;
    
    // Animate lines moving towards the player (downwards)
    float time_offset = TIME * speed;
    
    // Apply perspective effect: wider gaps near bottom (y=1), narrower near top (y=0)
    // We modify the Y coordinate before generating the pattern
    float perspective_y = pow(uv.y, perspective);
    
    // Generate horizontal lines
    float line_pos = fract(perspective_y * 10.0 - time_offset);
    float line = step(1.0 - line_thickness, line_pos);
    
    // Fading at the top for horizon
    float alpha = smoothstep(0.0, 0.3, uv.y);
    
    vec4 base_color = texture(TEXTURE, UV); // Use base color/texture of the rect
    COLOR = mix(COLOR, line_color, line * alpha * line_color.a); 
}
