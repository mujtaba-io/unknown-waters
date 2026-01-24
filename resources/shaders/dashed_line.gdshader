shader_type canvas_item;

uniform float dash_size = 20.0;
uniform float gap_size = 15.0;
uniform vec4 color : source_color = vec4(0.8, 0.2, 0.2, 1.0);

void fragment() {
    // We assume the Line2D texture_mode is set to TILE.
    // This allows UV.x to be > 1.0 representing the distance along the line.
    // Use a placeholder texture to enable this mode.
    
    // Calculate distance in pixels approx (if texture width matches dash unit)
    // Or just use UV.x directly if we scale it right.
    
    float total_period = dash_size + gap_size;
    
    // Check if we are in the 'dash' part of the period
    // Since UV.x scales with length in Tile mode, we can modulate it.
    // We might need to scale UV.x by the texture width used.
    // Assume texture width is 1.0 for simplicity, we adjust logic in UV space.
    
    // Actually, simple mod logic with SCREEN_UV or UV varies.
    // Let's rely on standard UV. Screen space is bad for moving maps.
    
    float pos = UV.x * 100.0; // Multiplier adjusts frequency if UV is 0..1 per segment
    // But in TILE mode, UV.x goes 0..1 per 'texture width'.
    // So if texture width is e.g. 32px, then UV.x=1.0 is 32px.
    
    float pattern = fract(UV.x); // 0..1 per tile
    
    // Let's create a rough stroke
    if (pattern > 0.6) {
        discard; // Gap
    }
    
    // Rough edges (noise)
    float noise = fract(sin(dot(UV, vec2(12.9898, 78.233))) * 43758.5453);
    if (UV.y < 0.1 * noise || UV.y > 1.0 - 0.1 * noise) {
        discard;
    }
    
    COLOR = color;
}
