extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const CITY_SPACING := 18.0
var rng := RandomNumberGenerator.new()

var startup_label: Label

func _ready() -> void:
    # Show a visible startup screen before generating the city.
    startup_label = _create_hud()
    startup_label.text = "NEON: DEAD CITY\nЗАГРУЗКА ГОРОДА..."
    await get_tree().process_frame

    rng.seed = 5642026
    _create_environment()
    startup_label.text = "NEON: DEAD CITY\nСОЗДАНИЕ УЛИЦ..."
    await get_tree().process_frame
    _create_ground()
    _create_roads()
    startup_label.text = "NEON: DEAD CITY\nПОСТРОЙКА РАЙОНА..."
    await get_tree().process_frame
    await _create_city()
    startup_label.text = "NEON: DEAD CITY\nОСВЕЩЕНИЕ И ДЕТАЛИ..."
    await get_tree().process_frame
    _create_street_lights()
    _create_street_details()
    _create_district_props()
    var player := PLAYER_SCENE.instantiate()
    player.position = Vector3(0, 0.15, 8)
    add_child(player)
    startup_label.text = "NEON: DEAD CITY  //  NIGHT DISTRICT\nЛевый палец — движение  •  Правый — обзор"

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
    moon.shadow_enabled = false
    moon.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
    moon.directional_shadow_max_distance = 48.0
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
    for x in range(-3, 4):
        await get_tree().process_frame
        for z in range(-3, 4):
            if abs(x) <= 1 and abs(z) <= 1:
                continue
            var width := rng.randf_range(5.0, 7.5)
            var depth := rng.randf_range(5.0, 7.5)
            var floors := rng.randi_range(4, 8)
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
    mesh.material_override = _material(Color(shade, shade * 1.2, shade * 1.9), 0.72, 0.22)
    body.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = dimensions
    collision.shape = shape
    body.add_child(collision)
    add_child(body)

    var palette := [
        Color(0.02, 0.65, 0.95), Color(0.85, 0.12, 0.55),
        Color(0.95, 0.55, 0.12), Color(0.18, 0.8, 0.62)
    ]
    var glow_color: Color = palette[rng.randi_range(0, palette.size() - 1)]
    var glass := _emissive_material(glow_color, rng.randf_range(0.45, 1.15))
    var frame := _material(Color(0.012, 0.018, 0.03), 0.42, 0.72)
    var ledge := _material(Color(0.07, 0.085, 0.12), 0.68, 0.48)

    # Recessed-looking window grids on all four sides.
    var cols := 2
    var rows := min(5, max(2, floors - 1))
    for floor_index in range(rows):
        var y := -dimensions.y * 0.5 + 1.15 + float(floor_index) * (dimensions.y - 1.2) / rows
        for col in range(cols):
            var x := -dimensions.x * 0.5 + (float(col) + 0.5) * dimensions.x / cols
            var w := dimensions.x / float(cols) * 0.62
            _add_box(center + Vector3(x, y, dimensions.z * 0.5 + 0.035), Vector3(w, 0.82, 0.045), glass)
            _add_box(center + Vector3(x, y, -dimensions.z * 0.5 - 0.035), Vector3(w, 0.82, 0.045), glass)
        var side_cols := 1
        for col in range(side_cols):
            var z := -dimensions.z * 0.5 + (float(col) + 0.5) * dimensions.z / side_cols
            var w_side := dimensions.z / float(side_cols) * 0.58
            _add_box(center + Vector3(dimensions.x * 0.5 + 0.035, y, z), Vector3(0.045, 0.82, w_side), glass)
            _add_box(center + Vector3(-dimensions.x * 0.5 - 0.035, y, z), Vector3(0.045, 0.82, w_side), glass)

    # Strong horizontal floor bands and vertical structural ribs.
    for floor_index in range(1, min(floors, 6)):
        var band_y := -dimensions.y * 0.5 + float(floor_index) * dimensions.y / floors
        _add_box(center + Vector3(0, band_y, dimensions.z * 0.5 + 0.06), Vector3(dimensions.x + 0.18, 0.10, 0.12), ledge)
        _add_box(center + Vector3(0, band_y, -dimensions.z * 0.5 - 0.06), Vector3(dimensions.x + 0.18, 0.10, 0.12), ledge)
    for side in [-1.0, 1.0]:
        _add_box(center + Vector3(side * (dimensions.x * 0.5 + 0.055), 0, 0), Vector3(0.11, dimensions.y, dimensions.z + 0.12), frame)
        var strip := _emissive_material(glow_color, 0.75)
        _add_box(center + Vector3(side * (dimensions.x * 0.5 + 0.12), 0, dimensions.z * 0.5 + 0.09), Vector3(0.055, dimensions.y * 0.78, 0.055), strip)

    # Ground-floor storefront and illuminated entrance.
    _add_box(center + Vector3(0, -dimensions.y * 0.5 + 1.0, dimensions.z * 0.5 + 0.08), Vector3(min(dimensions.x * 0.48, 2.2), 1.85, 0.08), frame)
    _add_box(center + Vector3(0, -dimensions.y * 0.5 + 1.05, dimensions.z * 0.5 + 0.14), Vector3(min(dimensions.x * 0.38, 1.65), 1.55, 0.035), glass)

    # Roof rim, machinery, vents and antenna.
    var roof_y := dimensions.y * 0.5
    _add_box(center + Vector3(0, roof_y + 0.12, dimensions.z * 0.5), Vector3(dimensions.x + 0.3, 0.24, 0.22), ledge)
    _add_box(center + Vector3(0, roof_y + 0.12, -dimensions.z * 0.5), Vector3(dimensions.x + 0.3, 0.24, 0.22), ledge)
    _add_box(center + Vector3(dimensions.x * 0.5, roof_y + 0.12, 0), Vector3(0.22, 0.24, dimensions.z), ledge)
    _add_box(center + Vector3(-dimensions.x * 0.5, roof_y + 0.12, 0), Vector3(0.22, 0.24, dimensions.z), ledge)
    for unit in range(1):
        var ux := -dimensions.x * 0.22 + float(unit) * dimensions.x * 0.42
        _add_box(center + Vector3(ux, roof_y + 0.48, 0), Vector3(0.9, 0.48, 0.75), frame)
        _add_box(center + Vector3(ux, roof_y + 0.74, 0), Vector3(0.62, 0.06, 0.5), ledge)
    if rng.randf() > 0.65:
        _add_box(center + Vector3(0, roof_y + 1.65, 0), Vector3(0.07, 1.9, 0.07), frame)
        _add_box(center + Vector3(0, roof_y + 2.35, 0), Vector3(0.62, 0.07, 0.07), glass)

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


func _create_district_props() -> void:
    # A parked neon-era compact car, built from lightweight meshes.
    var car := Node3D.new()
    car.position = Vector3(-7.8, 0.0, 8.8)
    car.rotation.y = deg_to_rad(90)
    add_child(car)
    var body_mat := _material(Color(0.035, 0.055, 0.085), 0.28, 0.82)
    var glass_mat := _material(Color(0.015, 0.12, 0.19), 0.16, 0.55)
    var tire_mat := _material(Color(0.008, 0.01, 0.016), 0.95)
    var rim_mat := _material(Color(0.22, 0.3, 0.38), 0.25, 0.9)
    var lamp_mat := _emissive_material(Color(0.02, 0.72, 1.0), 2.2)
    var tail_mat := _emissive_material(Color(1.0, 0.025, 0.12), 1.7)
    _add_car_box(car, Vector3(0, 0.62, 0), Vector3(2.0, 0.62, 4.1), body_mat)
    _add_car_box(car, Vector3(0, 1.12, -0.22), Vector3(1.65, 0.72, 2.05), glass_mat)
    _add_car_box(car, Vector3(0, 0.94, 1.65), Vector3(1.88, 0.12, 0.5), body_mat)
    _add_car_box(car, Vector3(0, 0.92, -1.82), Vector3(1.9, 0.12, 0.42), body_mat)
    _add_car_box(car, Vector3(-0.72, 0.68, 2.07), Vector3(0.34, 0.18, 0.06), lamp_mat)
    _add_car_box(car, Vector3(0.72, 0.68, 2.07), Vector3(0.34, 0.18, 0.06), lamp_mat)
    _add_car_box(car, Vector3(-0.72, 0.68, -2.07), Vector3(0.34, 0.18, 0.06), tail_mat)
    _add_car_box(car, Vector3(0.72, 0.68, -2.07), Vector3(0.34, 0.18, 0.06), tail_mat)
    for side in [-1.0, 1.0]:
        for z in [-1.35, 1.35]:
            var wheel := MeshInstance3D.new()
            var cylinder := CylinderMesh.new()
            cylinder.top_radius = 0.39
            cylinder.bottom_radius = 0.39
            cylinder.height = 0.22
            wheel.mesh = cylinder
            wheel.material_override = tire_mat
            wheel.position = Vector3(side * 1.0, 0.4, z)
            wheel.rotation.z = deg_to_rad(90)
            car.add_child(wheel)
            var hub := MeshInstance3D.new()
            var hub_mesh := CylinderMesh.new()
            hub_mesh.top_radius = 0.19
            hub_mesh.bottom_radius = 0.19
            hub_mesh.height = 0.235
            hub.mesh = hub_mesh
            hub.material_override = rim_mat
            hub.position = wheel.position
            hub.rotation.z = deg_to_rad(90)
            car.add_child(hub)

    # Roadside holographic pylons and a lit transit shelter.
    var cyan := _emissive_material(Color(0.015, 0.58, 0.92), 1.8)
    var pink := _emissive_material(Color(0.82, 0.025, 0.3), 1.5)
    var dark := _material(Color(0.018, 0.025, 0.04), 0.55, 0.65)
    for i in range(3):
        var px := 11.0 + float(i) * 2.0
        _add_box(Vector3(px, 1.65, 5.2), Vector3(0.12, 3.3, 0.12), dark)
        _add_box(Vector3(px, 2.95, 5.2), Vector3(0.2, 0.08, 0.2), cyan if i % 2 == 0 else pink)
    _add_box(Vector3(12.5, 1.45, -5.5), Vector3(4.2, 0.12, 1.35), dark)
    _add_box(Vector3(12.5, 2.7, -5.5), Vector3(4.2, 0.12, 1.35), dark)
    _add_box(Vector3(10.5, 2.05, -5.5), Vector3(0.12, 1.3, 1.35), cyan)
    _add_box(Vector3(14.5, 2.05, -5.5), Vector3(0.12, 1.3, 1.35), cyan)
    _add_box(Vector3(12.5, 2.05, -5.5), Vector3(3.8, 1.15, 0.035), _material(Color(0.025, 0.09, 0.14, 0.55), 0.2, 0.4))

func _add_car_box(parent: Node3D, pos: Vector3, dimensions: Vector3, material: Material) -> void:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = dimensions
    mesh.mesh = box
    mesh.material_override = material
    mesh.position = pos
    parent.add_child(mesh)

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

func _create_hud() -> Label:
    var layer := CanvasLayer.new()
    layer.layer = 10
    add_child(layer)
    var label := Label.new()
    label.text = "NEON: DEAD CITY\nЗАПУСК..."
    label.position = Vector2(24, 20)
    label.add_theme_font_size_override("font_size", 22)
    label.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0))
    layer.add_child(label)
    return label
