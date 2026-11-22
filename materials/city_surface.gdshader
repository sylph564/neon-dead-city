shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.025, 0.04, 0.068, 1.0);
uniform float tile_scale = 18.0;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.82;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.1;
uniform float detail_strength : hint_range(0.0, 1.0) = 0.22;
uniform float grid_strength : hint_range(0.0, 1.0) = 0.0;
uniform float wetness_strength : hint_range(0.0, 1.0) = 0.25;

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
    float fine_grain = noise2(p * 23.0);
    float grain = (n1 - 0.5) * 0.22 + (n2 - 0.5) * 0.10 + (fine_grain - 0.5) * 0.035;

    vec2 cell = fract(p * 0.5);
    float edge = min(min(cell.x, 1.0 - cell.x), min(cell.y, 1.0 - cell.y));
    float seams = 1.0 - smoothstep(0.0, 0.035, edge);
    float panel = 1.0 - seams * grid_strength * 0.28;
    float speckle = step(0.994, hash21(floor(p * 31.0)));

    // Patchy wet asphalt response: cheap procedural roughness variation, no costly screen-space reflections.
    float wet_noise = noise2(p * 0.32 + vec2(5.7, 2.4));
    float wet_patch = smoothstep(0.43, 0.82, wet_noise) * wetness_strength;
    vec3 dry_color = base_color.rgb * (1.0 + grain * detail_strength) * panel;
    vec3 wet_color = dry_color * vec3(0.72, 0.82, 1.08);

    ALBEDO = mix(dry_color, wet_color, wet_patch) - vec3(speckle * 0.025 * detail_strength);
    ROUGHNESS = clamp(mix(roughness_value + (n2 - 0.5) * 0.12, 0.2, wet_patch), 0.08, 1.0);
    METALLIC = clamp(mix(metallic_value, metallic_value + 0.22, wet_patch), 0.0, 1.0);
}
