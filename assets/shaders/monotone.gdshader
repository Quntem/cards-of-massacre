shader_type canvas_item;

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);

    // Ensure alpha is applied properly
    vec4 modulate_color = COLOR;
    texture_color.rgb *= modulate_color.rgb;
    texture_color.a *= modulate_color.a;

    // Compute grayscale based on the modulated color
    float luminance = dot(texture_color.rgb, vec3(0.15, 0.15, 0.15));

    // Output monotone color with correct alpha
    COLOR = vec4(vec3(luminance), texture_color.a);
}
