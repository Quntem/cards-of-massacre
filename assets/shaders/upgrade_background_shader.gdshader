shader_type canvas_item;

uniform vec4 background_color = vec4(0.1, 0.1, 0.1, 1.0);  // Background color
uniform vec4 line_color = vec4(0.3, 0.3, 0.3, 1.0);        // Grid line color
uniform float grid_size = 50.0;                            // Size of each grid cell
uniform float line_thickness = 0.02;                       // Thickness of the grid lines

void fragment() {
    vec2 uv = FRAGCOORD.xy / grid_size;

    // Create evenly spaced grid lines in both X and Y directions
    float line = (abs(fract(uv.x) - 0.5) < line_thickness || abs(fract(uv.y) - 0.5) < line_thickness) ? 1.0 : 0.0;

    // Blend the grid color with the background
    COLOR = mix(background_color, line_color, line);
}
