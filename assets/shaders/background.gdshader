shader_type canvas_item;

uniform float size : hint_range(1.0, 100.0) = 25.0;
uniform vec4 color1 = vec4(1.0, 1.0, 1.0, 1.0); 
uniform vec4 color2 = vec4(0.7, 0.7, 0.7, 1.0);
uniform float speed : hint_range(0.0, 10.0) = 1.0;
//uniform float timeline : hint_range(0.0, 6.28);

void fragment() {
    vec2 pos = FRAGCOORD.xy / size;

    int row = int(floor(pos.x));
    
    float time_offset = (row % 2 == 0 ? cos(TIME*speed-45.0) : sin(TIME*speed-45.0));

    pos.y -= time_offset;
    pos = floor(pos);

    float pattern_mask = mod(pos.x + mod(pos.y, 2.0), 2.0);
    COLOR = mix(color1, color2, pattern_mask);
}
