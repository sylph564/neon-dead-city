extends Node3D

const NPC_SCRIPT = preload("res://scripts/city_npc.gd")
const VEHICLE_SCRIPT = preload("res://scripts/city_vehicle.gd")

func _ready() -> void:
    set_meta("world_time_scale", 1.0)
    _create_mobile_environment()
    _add_world_colliders()
    _create_neon_dressing()
    _create_street_props()
    _create_skyline()
    call_deferred("_populate_streets")

func _add_world_colliders() -> void:
    # Convert the visible block shells into matching static collision bodies.
    # Only large architectural BoxMeshes are used; windows and signs stay decorative.
    for child in get_children():
        if not (child is MeshInstance3D):
            continue
        var mesh_node := child as MeshInstance3D
        if not (mesh_node.mesh is BoxMesh):
            continue
        var box := mesh_node.mesh as BoxMesh
        if box.size.y < 4.0 or box.size.x < 3.0 or box.size.z < 3.0:
            continue
        if mesh_node.name.begins_with("Window") or mesh_node.name.begins_with("Neon"):
            continue
        var body := StaticBody3D.new()
        body.name = mesh_node.name + "_WorldCollision"
        body.transform = mesh_node.transform
        body.collision_layer = 1
        body.collision_mask = 1
        var shape_node := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = box.size
        shape_node.shape = shape
        body.add_child(shape_node)
        add_child(body)

func _create_mobile_environment() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.006, 0.012, 0.035)
    sky_material.sky_horizon_color = Color(0.055, 0.025, 0.075)
    sky_material.ground_bottom_color = Color(0.006, 0.008, 0.018)
    sky_material.ground_horizon_color = Color(0.025, 0.035, 0.065)
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.28, 0.34, 0.55)
    environment.ambient_light_energy = 0.68
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.tonemap_exposure = 1.12
    environment.glow_enabled = true
    environment.glow_intensity = 0.62
    environment.glow_strength = 0.9
    environment.glow_bloom = 0.14
    environment.fog_enabled = true
    environment.fog_light_color = Color(0.045, 0.025, 0.09)
    environment.fog_density = 0.0065
    world.environment = environment
    add_child(world)

    # Reuse the scene's existing sun light instead of adding another shadow caster.
    var sun := get_node_or_null("Sun") as DirectionalLight3D
    if sun != null:
        sun.light_color = Color(0.48, 0.58, 1.0)
        sun.light_energy = 0.82
        sun.shadow_enabled = true
        sun.directional_shadow_max_distance = 46.0

func _create_neon_dressing() -> void:
    var cyan := _neon_material(Color(0.015, 0.72, 1.0), 2.6)
    var magenta := _neon_material(Color(1.0, 0.025, 0.32), 2.4)
    var amber := _neon_material(Color(1.0, 0.48, 0.06), 2.0)
    var violet := _neon_material(Color(0.48, 0.12, 1.0), 2.2)
    var dark := _mat(Color(0.012, 0.018, 0.032), 0.82, 0.28)

    # Dense shop signs along the visible street wall.
    for i in range(7):
        var x := -24.0 + float(i) * 8.0
        _add_neon_box(Vector3(x, 3.15, -17.2), Vector3(3.35, 1.08, 0.24), dark)
        _add_neon_box(Vector3(x, 3.62, -17.04), Vector3(2.9, 0.045, 0.035), cyan if i % 2 == 0 else magenta)
        _add_neon_box(Vector3(x - 1.43, 3.15, -17.04), Vector3(0.04, 0.72, 0.035), amber)
        _add_neon_box(Vector3(x + 1.43, 3.15, -17.04), Vector3(0.04, 0.72, 0.035), violet)

    # Tall vertical identity strips make the block silhouette readable at distance.
    for i in range(6):
        var x := -22.0 + float(i) * 8.8
        _add_neon_box(Vector3(x, 7.0, -17.0), Vector3(0.075, 5.8, 0.08), cyan if i % 2 == 0 else magenta)

    # Compact street lamps: emissive geometry plus only a few dynamic lights.
    for i in range(5):
        var z := -14.0 + float(i) * 7.0
        _add_neon_box(Vector3(-6.25, 2.35, z), Vector3(0.10, 4.7, 0.10), dark)
        _add_neon_box(Vector3(-6.25, 4.72, z), Vector3(0.76, 0.08, 0.08), cyan)
        if i % 2 == 0:
            var lamp := OmniLight3D.new()
            lamp.position = Vector3(-6.25, 4.45, z)
            lamp.light_color = Color(0.04, 0.55, 1.0)
            lamp.light_energy = 0.55
            lamp.omni_range = 5.5
            add_child(lamp)

    # Small animated hologram panels.
    for i in range(3):
        var holo_mat := _neon_material(Color(0.48, 0.12, 1.0), 2.2) if i % 2 == 0 else _neon_material(Color(0.015, 0.72, 1.0), 2.4)
        holo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        var panel := _add_neon_box(Vector3(7.0 + float(i) * 5.5, 3.7, -16.85), Vector3(1.5, 1.9, 0.07), holo_mat)
        panel.name = "HoloPanel_%02d" % i
        var tween := create_tween().set_loops()
        tween.tween_property(holo_mat, "albedo_color:a", 0.42, 0.8)
        tween.tween_property(holo_mat, "albedo_color:a", 1.0, 0.8)

func _create_street_props() -> void:
    var metal := _mat(Color(0.025, 0.035, 0.055), 0.78, 0.34)
    var cyan := _neon_material(Color(0.02, 0.68, 1.0), 2.0)
    var amber := _neon_material(Color(1.0, 0.38, 0.055), 1.8)
    var puddle := StandardMaterial3D.new()
    puddle.albedo_color = Color(0.025, 0.09, 0.16, 0.72)
    puddle.metallic = 0.72
    puddle.roughness = 0.12
    puddle.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

    # Bollards and illuminated curb markers.
    for side in [-1.0, 1.0]:
        for i in range(7):
            var z := -15.0 + float(i) * 4.7
            _add_neon_box(Vector3(side * 6.0, 0.48, z), Vector3(0.24, 0.92, 0.24), metal)
            _add_neon_box(Vector3(side * 6.0, 0.88, z), Vector3(0.25, 0.08, 0.25), amber)

    # Crosswalk bars and lane reflectors at the junction.
    for i in range(8):
        var z := -3.5 + float(i) * 1.0
        _add_neon_box(Vector3(-4.0, 0.045, z), Vector3(0.16, 0.035, 0.62), cyan)
        _add_neon_box(Vector3(4.0, 0.045, z), Vector3(0.16, 0.035, 0.62), cyan)

    # Rain puddles are flat, cheap meshes; no realtime reflection probes required.
    for i in range(9):
        var x := -5.2 + float(i % 3) * 4.9
        var z := -13.0 + (float(i) / 3.0) * 11.0
        var puddle_mesh := MeshInstance3D.new()
        var plane := PlaneMesh.new()
        plane.size = Vector2(1.1 + float(i % 2) * 0.7, 0.42 + float(i % 3) * 0.16)
        puddle_mesh.mesh = plane
        puddle_mesh.position = Vector3(x, 0.022, z)
        puddle_mesh.material_override = puddle
        add_child(puddle_mesh)

    # A compact street kiosk gives the sidewalk a readable landmark.
    _add_neon_box(Vector3(6.35, 0.95, -11.8), Vector3(0.9, 1.9, 1.05), metal)
    _add_neon_box(Vector3(6.35, 1.3, -11.24), Vector3(0.68, 0.62, 0.035), cyan)
    _add_neon_box(Vector3(6.35, 1.94, -11.8), Vector3(1.0, 0.08, 1.12), amber)

func _add_neon_box(pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.position = pos
    mesh.material_override = material
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(mesh)
    return mesh

func _mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    return material

func _neon_material(color: Color, energy: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = energy
    return material

func _create_skyline() -> void:
    var dark_palette := [
        Color(0.018, 0.026, 0.052),
        Color(0.028, 0.022, 0.048),
        Color(0.018, 0.038, 0.055),
        Color(0.038, 0.025, 0.052)
    ]
    var neon_palette := [
        Color(0.02, 0.55, 0.95),
        Color(0.85, 0.04, 0.28),
        Color(0.95, 0.38, 0.06),
        Color(0.22, 0.58, 1.0)
    ]
    for i in range(16):
        var angle := TAU * float(i) / 16.0
        var radius := 61.0 + float(i % 3) * 5.0
        var center := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        var width := 7.0 + float(i % 3) * 2.2
        var depth := 7.0 + float((i + 1) % 3) * 2.0
        var height := 22.0 + float((i * 7) % 19)
        var building := MeshInstance3D.new()
        var shell := BoxMesh.new()
        shell.size = Vector3(width, height, depth)
        building.mesh = shell
        building.position = center + Vector3(0.0, height * 0.5, 0.0)
        building.material_override = _mat(dark_palette[i % dark_palette.size()], 0.72, 0.34)
        building.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(building)

        var glow := _neon_material(neon_palette[i % neon_palette.size()], 1.25)
        var strip_x := width * 0.5 + 0.055
        _add_neon_box(center + Vector3(strip_x, height * 0.52, 0.0), Vector3(0.065, height * 0.82, depth * 0.72), glow)
        _add_neon_box(center + Vector3(-strip_x, height * 0.38, 0.0), Vector3(0.045, height * 0.62, depth * 0.55), glow)
        _add_neon_box(center + Vector3(0.0, height + 0.12, 0.0), Vector3(width + 0.3, 0.22, depth + 0.3), _mat(Color(0.06, 0.075, 0.11), 0.7, 0.38))
        if i % 4 == 0:
            _add_neon_box(center + Vector3(0.0, height + 1.5, 0.0), Vector3(0.10, 2.8, 0.10), glow)

func _populate_streets() -> void:
    var pedestrian_paths := [
        [Vector3(-5.45, 0.0, -15.0), Vector3(-5.45, 0.0, 12.0)],
        [Vector3(5.45, 0.0, 13.0), Vector3(5.45, 0.0, -12.0)],
        [Vector3(-5.45, 0.0, 10.0), Vector3(-5.45, 0.0, -14.0)],
        [Vector3(5.45, 0.0, -14.0), Vector3(5.45, 0.0, 11.0)],
        [Vector3(-5.45, 0.0, -10.0), Vector3(-5.45, 0.0, 14.0)],
        [Vector3(5.45, 0.0, 9.0), Vector3(5.45, 0.0, -15.0)]
    ]
    for i in range(pedestrian_paths.size()):
        var npc := CharacterBody3D.new()
        npc.name = "StreetPedestrian_%02d" % (i + 1)
        npc.set_script(NPC_SCRIPT)
        npc.set("point_a", pedestrian_paths[i][0])
        npc.set("point_b", pedestrian_paths[i][1])
        npc.set("walk_speed", 0.78 + float(i % 3) * 0.18)
        npc.set("outfit_variant", i % 4)
        add_child(npc)

    # Vehicles follow two fixed lanes on the east-west road, never random coordinates.
    _spawn_vehicle("TrafficCar_A", 1.0, -2.15, 3.4)
    _spawn_vehicle("TrafficCar_B", -1.0, 2.15, 3.1)
    _spawn_vehicle("TrafficCar_C", 1.0, -2.15, 3.8, -22.0)

func _spawn_vehicle(label: String, direction: float, lane_z: float, speed: float, start_x: float = -45.0) -> void:
    var vehicle := CharacterBody3D.new()
    vehicle.name = label
    vehicle.set_script(VEHICLE_SCRIPT)
    vehicle.set("direction", direction)
    vehicle.set("lane_z", lane_z)
    vehicle.set("speed", speed)
    vehicle.set("min_x", -45.0)
    vehicle.set("max_x", 45.0)
    add_child(vehicle)
    if start_x != -45.0:
        var spawn_position := vehicle.global_position
        spawn_position.x = start_x
        vehicle.global_position = spawn_position
