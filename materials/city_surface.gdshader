shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.025, 0.04, 0.068, 1.0);
uniform float tile_scale = 18.0;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.82;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.1;
uniform float detail_strength : hint_range(0.0, 1.0) = 0.22;
uniform float grid_strength : hint_range(0.0, 1.0) = 0.0;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
    vec2 p = UV * tile_scale;
    float n1 = noise2(p * 1.7);
    float n2 = noise2(p * 7.0);
    float grain = (n1 - 0.5) * 0.22 + (n2 - 0.5) * 0.10;
    vec2 cell = fract(p * 0.5);
    float seams = 1.0 - smoothstep(0.0, 0.035, min(min(cell.x, 1.0-cell.x), min(cell.y, 1.0-cell.y)));
    float panel = 1.0 - seams * grid_strength * 0.28;
    float speckle = step(0.994, hash21(floor(p * 31.0)));
    ALBEDO = base_color.rgb * (1.0 + grain * detail_strength) * panel - vec3(speckle * 0.025 * detail_strength);
    ROUGHNESS = clamp(roughness_value + (n2 - 0.5) * 0.12, 0.08, 1.0);
    METALLIC = metallic_value;
}
