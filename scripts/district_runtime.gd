extends Node3D

const NPC_SCRIPT = preload("res://scripts/city_npc.gd")
const VEHICLE_SCRIPT = preload("res://scripts/city_vehicle.gd")

func _ready() -> void:
    set_meta("world_time_scale", 1.0)
    _create_mobile_environment()
    _add_world_colliders()
    _create_neon_dressing()
    call_deferred("_populate_streets")


func _add_world_colliders() -> void:
    # The original district had decorative building meshes but no collision bodies.
    # Add matching static collision to the large architectural meshes only.
    for child in get_children():
        if not (child is MeshInstance3D):
            continue
        var mesh_node := child as MeshInstance3D
        if not (mesh_node.name.begins_with("Tower") or mesh_node.name == "HomeA" or mesh_node.name == "HomeB"):
            continue
        if not (mesh_node.mesh is BoxMesh):
            continue
        var body := StaticBody3D.new()
        body.name = mesh_node.name + "_Collision"
        body.position = mesh_node.position
        body.rotation = mesh_node.rotation
        body.collision_layer = 1
        body.collision_mask = 1
        var shape_node := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = (mesh_node.mesh as BoxMesh).size * mesh_node.scale
        shape_node.shape = shape
        body.add_child(shape_node)
        add_child(body)

func _create_mobile_environment() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.008, 0.012, 0.028)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.24, 0.32, 0.52)
    environment.ambient_light_energy = 0.62
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.tonemap_exposure = 1.08
    environment.glow_enabled = true
    environment.glow_intensity = 0.45
    environment.glow_strength = 0.85
    environment.glow_bloom = 0.12
    environment.fog_enabled = true
    environment.fog_light_color = Color(0.055, 0.018, 0.075)
    environment.fog_density = 0.005
    world.environment = environment
    add_child(world)


func _create_neon_dressing() -> void:
    var cyan := _neon_material(Color(0.015, 0.72, 1.0), 2.4)
    var magenta := _neon_material(Color(1.0, 0.025, 0.32), 2.2)
    var amber := _neon_material(Color(1.0, 0.48, 0.06), 1.8)
    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color(0.012, 0.018, 0.032)
    dark.metallic = 0.82
    dark.roughness = 0.28
    for i in range(5):
        var x := -18.0 + float(i) * 9.0
        _add_neon_box(Vector3(x, 3.2, -17.2), Vector3(3.2, 1.05, 0.22), dark)
        _add_neon_box(Vector3(x, 3.2, -17.05), Vector3(2.75, 0.055, 0.035), cyan if i % 2 == 0 else magenta)
        _add_neon_box(Vector3(x - 1.38, 3.2, -17.04), Vector3(0.045, 0.72, 0.035), amber)
    for i in range(4):
        var z := -12.0 + float(i) * 8.0
        var pole := MeshInstance3D.new()
        var pole_mesh := BoxMesh.new()
        pole_mesh.size = Vector3(0.09, 4.8, 0.09)
        pole.mesh = pole_mesh
        pole.position = Vector3(-6.25, 2.4, z)
        pole.material_override = dark
        add_child(pole)
        _add_neon_box(Vector3(-6.25, 4.82, z), Vector3(0.7, 0.08, 0.08), cyan)
        var lamp := OmniLight3D.new()
        lamp.position = Vector3(-6.25, 4.5, z)
        lamp.light_color = Color(0.04, 0.55, 1.0) if i % 2 == 0 else Color(1.0, 0.04, 0.25)
        lamp.light_energy = 0.7
        lamp.omni_range = 5.0
        add_child(lamp)

func _add_neon_box(pos: Vector3, size: Vector3, material: Material) -> void:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.position = pos
    mesh.material_override = material
    add_child(mesh)

func _neon_material(color: Color, energy: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = energy
    return material

func _populate_streets() -> void:
    var pedestrian_paths = [
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
        npc.set("walk_speed", 0.85 + float(i % 3) * 0.22)
        add_child(npc)

    _spawn_vehicle("TrafficCar_A", -1.0, -2.8, 4.2)
    _spawn_vehicle("TrafficCar_B", 1.0, 2.8, 3.5)

func _spawn_vehicle(label: String, direction: float, lane_z: float, speed: float) -> void:
    var vehicle := Node3D.new()
    vehicle.name = label
    vehicle.set_script(VEHICLE_SCRIPT)
    vehicle.set("direction", direction)
    vehicle.set("lane_z", lane_z)
    vehicle.set("speed", speed)
    add_child(vehicle)
