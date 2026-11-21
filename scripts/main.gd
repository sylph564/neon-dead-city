extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.seed = 5642026
    _create_environment()
    _create_ground()
    _create_city()
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
    world.environment = environment
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -25, 0)
    sun.light_color = Color(0.48, 0.58, 1.0)
    sun.light_energy = 0.55
    add_child(sun)

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

func _create_city() -> void:
    for x in range(-4, 5):
        for z in range(-4, 5):
            if abs(x) <= 1 and abs(z) <= 1:
                continue
            var width := rng.randf_range(5.0, 8.0)
            var depth := rng.randf_range(5.0, 8.0)
            var floors := rng.randi_range(3, 12)
            var height := float(floors) * rng.randf_range(2.7, 3.4)
            var center := Vector3(x * 18.0, height * 0.5, z * 18.0)
            _create_building(center, Vector3(width, height, depth), floors)

func _create_building(center: Vector3, dimensions: Vector3, floors: int) -> void:
    var body := StaticBody3D.new()
    body.position = center
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = dimensions
    mesh.mesh = box
    var facade := StandardMaterial3D.new()
    var shade := rng.randf_range(0.025, 0.09)
    facade.albedo_color = Color(shade, shade * 1.2, shade * 1.9)
    facade.metallic = 0.25
    facade.roughness = 0.72
    mesh.material_override = facade
    body.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = dimensions
    collision.shape = shape
    body.add_child(collision)
    add_child(body)

    for floor_index in range(1, floors):
        for side in [-1.0, 1.0]:
            var window := MeshInstance3D.new()
            var window_mesh := BoxMesh.new()
            window_mesh.size = Vector3(dimensions.x * 0.48, 0.12, 0.035)
            window.mesh = window_mesh
            var glow := StandardMaterial3D.new()
            glow.albedo_color = Color(0.02, rng.randf_range(0.25, 0.8), rng.randf_range(0.55, 1.0))
            glow.emission_enabled = true
            glow.emission = glow.albedo_color
            glow.emission_energy_multiplier = 1.3
            window.material_override = glow
            window.position = center + Vector3(0, -dimensions.y * 0.5 + floor_index * dimensions.y / floors, side * (dimensions.z * 0.5 + 0.025))
            add_child(window)

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var label := Label.new()
    label.text = "NEON: DEAD CITY  //  PROTOTYPE\nЛевый палец — движение  •  Правый — обзор"
    label.position = Vector2(24, 20)
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0))
    layer.add_child(label)
