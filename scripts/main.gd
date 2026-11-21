extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const CITY_SPACING := 18.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.seed = 5642026
    _create_environment()
    _create_ground()
    _create_roads()
    _create_city()
    _create_street_lights()
    _create_street_details()
    var player := PLAYER_SCENE.instantiate()
    player.position = Vector3(0, 0.15, 8)
    add_child(player)
    _create_hud()

func _create_environment() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.008, 0.015, 0.045)
    sky_material.sky_horizon_color = Color(0.035, 0.055, 0.10)
    sky_material.ground_bottom_color = Color(0.008, 0.01, 0.02)
    sky_material.ground_horizon_color = Color(0.025, 0.035, 0.06)
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.28, 0.34, 0.52)
    environment.ambient_light_energy = 0.45
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.tonemap_exposure = 1.15
    environment.fog_enabled = true
    environment.fog_light_color = Color(0.035, 0.055, 0.12)
    environment.fog_density = 0.006
    world.environment = environment
    add_child(world)

    var moon := DirectionalLight3D.new()
    moon.rotation_degrees = Vector3(-48, -25, 0)
    moon.light_color = Color(0.48, 0.58, 1.0)
    moon.light_energy = 0.72
    moon.shadow_enabled = true
    moon.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
    moon.directional_shadow_max_distance = 85.0
    moon.shadow_bias = 0.06
    moon.shadow_normal_bias = 1.2
    add_child(moon)

func _create_ground() -> void:
    var body := StaticBody3D.new()
    body.name = "CityGround"
    var mesh := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(180, 180)
    mesh.mesh = plane
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.025, 0.03, 0.045)
    material.roughness = 0.92
    mesh.material_override = material
    body.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(180, 0.2, 180)
    collision.shape = shape
    collision.position.y = -0.1
    body.add_child(collision)
    add_child(body)

func _create_roads() -> void:
    var road_material := _material(Color(0.012, 0.016, 0.026), 0.82)
    var line_material := _emissive_material(Color(0.02, 0.32, 0.48), 1.1)
    var sidewalk_material := _material(Color(0.055, 0.065, 0.085), 0.9)
    for i in range(-4, 4):
        var road_offset := (float(i) + 0.5) * CITY_SPACING
        _add_box(Vector3(road_offset, 0.012, 0), Vector3(5.2, 0.025, 150), road_material)
        _add_box(Vector3(0, 0.012, road_offset), Vector3(150, 0.025, 5.2), road_material)
        _add_box(Vector3(road_offset - 2.45, 0.035, 0), Vector3(0.08, 0.025, 150), line_material)
        _add_box(Vector3(road_offset + 2.45, 0.035, 0), Vector3(0.08, 0.025, 150), line_material)
        _add_box(Vector3(0, 0.035, road_offset - 2.45), Vector3(150, 0.025, 0.08), line_material)
        _add_box(Vector3(0, 0.035, road_offset + 2.45), Vector3(150, 0.025, 0.08), line_material)
        _add_box(Vector3(road_offset - 3.0, 0.07, 0), Vector3(0.65, 0.12, 150), sidewalk_material)
        _add_box(Vector3(road_offset + 3.0, 0.07, 0), Vector3(0.65, 0.12, 150), sidewalk_material)
        _add_box(Vector3(0, 0.07, road_offset - 3.0), Vector3(150, 0.12, 0.65), sidewalk_material)
        _add_box(Vector3(0, 0.07, road_offset + 3.0), Vector3(150, 0.12, 0.65), sidewalk_material)

func _create_city() -> void:
    for x in range(-4, 5):
        for z in range(-4, 5):
            if abs(x) <= 1 and abs(z) <= 1:
                continue
            var width := rng.randf_range(5.0, 7.5)
            var depth := rng.randf_range(5.0, 7.5)
            var floors := rng.randi_range(4, 12)
            var height := float(floors) * rng.randf_range(2.7, 3.2)
            var center := Vector3(x * CITY_SPACING, height * 0.5 + 0.12, z * CITY_SPACING)
            _create_building(center, Vector3(width, height, depth), floors)

func _create_building(center: Vector3, dimensions: Vector3, floors: int) -> void:
    var body := StaticBody3D.new()
    body.position = center
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = dimensions
    mesh.mesh = box
    var shade := rng.randf_range(0.025, 0.075)
    var facade := _material(Color(shade, shade * 1.2, shade * 1.9), 0.72, 0.22)
    mesh.material_override = facade
    body.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = dimensions
    collision.shape = shape
    body.add_child(collision)
    add_child(body)

    var window_colors := [
        Color(0.02, 0.65, 0.95),
        Color(0.85, 0.12, 0.55),
        Color(0.95, 0.55, 0.12),
        Color(0.18, 0.8, 0.62)
    ]
    var glow_color: Color = window_colors[rng.randi_range(0, window_colors.size() - 1)]
    var glow := _emissive_material(glow_color, 1.25)
    for floor_index in range(1, floors):
        if rng.randf() < 0.18:
            continue
        var y := -dimensions.y * 0.5 + floor_index * dimensions.y / floors
        for side in [-1.0, 1.0]:
            var window := MeshInstance3D.new()
            var window_mesh := BoxMesh.new()
            window_mesh.size = Vector3(dimensions.x * 0.48, 0.13, 0.035)
            window.mesh = window_mesh
            window.material_override = glow
            window.position = center + Vector3(0, y, side * (dimensions.z * 0.5 + 0.025))
            add_child(window)

    # A few restrained vertical neon strips make silhouettes readable at a distance.
    var strip_material := _emissive_material(glow_color, 0.9)
    for side in [-1.0, 1.0]:
        var strip := MeshInstance3D.new()
        var strip_mesh := BoxMesh.new()
        strip_mesh.size = Vector3(0.09, dimensions.y * 0.72, 0.045)
        strip.mesh = strip_mesh
        strip.material_override = strip_material
        strip.position = center + Vector3(side * (dimensions.x * 0.5 + 0.035), 0, dimensions.z * 0.5 + 0.04)
        add_child(strip)

    # Rooftop ventilation units add a little skyline detail without expensive meshes.
    var roof_unit := MeshInstance3D.new()
    var roof_mesh := BoxMesh.new()
    roof_mesh.size = Vector3(dimensions.x * 0.28, 0.65, dimensions.z * 0.24)
    roof_unit.mesh = roof_mesh
    roof_unit.material_override = _material(Color(0.035, 0.045, 0.065), 0.88)
    roof_unit.position = center + Vector3(0, dimensions.y * 0.5 + 0.32, 0)
    add_child(roof_unit)

func _create_street_lights() -> void:
    var pole_material := _material(Color(0.055, 0.065, 0.085), 0.7, 0.5)
    var lamp_material := _emissive_material(Color(0.08, 0.55, 0.9), 1.8)
    for x in range(-4, 4, 2):
        for z in range(-4, 4, 2):
            if abs(x) <= 1 and abs(z) <= 1:
                continue
            var pos := Vector3((x + 0.5) * CITY_SPACING, 0, (z + 0.5) * CITY_SPACING)
            _add_box(pos + Vector3(0, 2.1, 0), Vector3(0.12, 4.2, 0.12), pole_material)
            _add_box(pos + Vector3(0.45, 4.15, 0), Vector3(1.0, 0.12, 0.22), lamp_material)

func _create_street_details() -> void:
    # Small, readable street props around the starting blocks.
    var metal := _material(Color(0.045, 0.055, 0.075), 0.62, 0.72)
    var dark := _material(Color(0.018, 0.022, 0.032), 0.9)
    var cyan := _emissive_material(Color(0.015, 0.48, 0.72), 1.8)
    var magenta := _emissive_material(Color(0.72, 0.035, 0.32), 1.5)

    # Vending kiosks and illuminated street signs.
    for i in range(4):
        var x := -13.0 + float(i) * 8.5
        _add_box(Vector3(x, 1.0, 3.0), Vector3(1.15, 2.0, 0.8), metal)
        _add_box(Vector3(x, 1.25, 2.57), Vector3(0.82, 0.92, 0.035), cyan if i % 2 == 0 else magenta)
        _add_box(Vector3(x, 2.15, 3.0), Vector3(1.25, 0.12, 0.9), dark)

    # Benches, bins and utility cabinets along the central sidewalks.
    for z in [-12.0, 12.0]:
        _add_box(Vector3(-4.0, 0.48, z), Vector3(1.8, 0.12, 0.55), metal)
        _add_box(Vector3(-4.0, 0.72, z + 0.2), Vector3(1.8, 0.42, 0.1), metal)
        _add_box(Vector3(4.0, 0.65, z), Vector3(0.65, 1.3, 0.65), dark)
        _add_box(Vector3(4.0, 1.32, z), Vector3(0.68, 0.06, 0.68), cyan)

    # Crosswalk bars at the nearest intersection.
    var paint := _material(Color(0.48, 0.56, 0.65), 0.9)
    for i in range(7):
        _add_box(Vector3(-3.0 + float(i) * 0.9, 0.055, 5.4), Vector3(0.48, 0.025, 1.5), paint)
        _add_box(Vector3(5.4, 0.055, -3.0 + float(i) * 0.9), Vector3(1.5, 0.025, 0.48), paint)

    # A large glowing district marker visible from the starting street.
    _add_box(Vector3(0, 5.2, -13.5), Vector3(7.5, 1.25, 0.22), dark)
    _add_box(Vector3(0, 5.2, -13.36), Vector3(7.15, 0.08, 0.035), magenta)
    _add_box(Vector3(0, 5.2, -13.32), Vector3(0.08, 0.78, 0.035), cyan)

func _add_box(pos: Vector3, dimensions: Vector3, material: Material) -> void:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = dimensions
    mesh.mesh = box
    mesh.material_override = material
    mesh.position = pos
    add_child(mesh)

func _material(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    return material

func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
    var material := _material(color, 0.35, 0.15)
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = energy
    return material

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var label := Label.new()
    label.text = "NEON: DEAD CITY  //  NIGHT DISTRICT\nЛевый палец — движение  •  Правый — обзор"
    label.position = Vector2(24, 20)
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0))
    layer.add_child(label)
