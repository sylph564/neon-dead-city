extends CharacterBody3D
## Deterministic street traffic. Cars stay inside marked lanes and use physics collision.
@export var speed: float = 4.0
@export var min_x: float = -45.0
@export var max_x: float = 45.0
@export var lane_z: float = -2.25
@export var direction: float = 1.0

var _wheels: Array[MeshInstance3D] = []
var _blocked_time := 0.0
var _body_material: StandardMaterial3D

func _ready() -> void:
    collision_layer = 4
    collision_mask = 1 | 2 | 4
    floor_snap_length = 0.0
    safe_margin = 0.04
    global_position = Vector3(min_x if direction > 0.0 else max_x, 0.0, lane_z)
    _orient_to_lane()
    _build_vehicle()

func _physics_process(delta: float) -> void:
    var scene := get_tree().current_scene
    var time_factor := float(scene.get_meta("world_time_scale", 1.0)) if scene != null else 1.0
    var step := delta * time_factor
    velocity = Vector3(speed * direction * time_factor, 0.0, 0.0)
    var collision := move_and_collide(velocity * delta)
    if collision != null:
        _blocked_time += delta
        velocity = Vector3.ZERO
        if _blocked_time > 1.15:
            direction *= -1.0
            _orient_to_lane()
            _blocked_time = 0.0
    else:
        _blocked_time = 0.0
        var wrap_position := global_position
        if direction > 0.0 and global_position.x >= max_x:
            wrap_position.x = min_x
            global_position = wrap_position
        elif direction < 0.0 and global_position.x <= min_x:
            wrap_position.x = max_x
            global_position = wrap_position
        for wheel in _wheels:
            wheel.rotate_x(step * speed * 1.8)

func _orient_to_lane() -> void:
    rotation.y = -PI * 0.5 if direction > 0.0 else PI * 0.5

func _build_vehicle() -> void:
    _body_material = _mat(Color(0.018, 0.035, 0.065), 0.82, 0.24)
    var glass_mat := _mat(Color(0.012, 0.12, 0.18), 0.62, 0.16)
    var tire_mat := _mat(Color(0.006, 0.008, 0.014), 0.0, 0.98)
    var cyan := _mat(Color(0.015, 0.72, 1.0), 0.15, 0.24, true)
    var red := _mat(Color(1.0, 0.025, 0.12), 0.1, 0.22, true)
    var trim := _mat(Color(0.08, 0.11, 0.16), 0.72, 0.34)

    var collision := CollisionShape3D.new()
    collision.name = "VehicleCollision"
    var hull := BoxShape3D.new()
    hull.size = Vector3(1.82, 1.12, 3.55)
    collision.shape = hull
    collision.position.y = 0.62
    add_child(collision)

    _box("Chassis", Vector3(0, 0.58, 0), Vector3(1.9, 0.52, 3.7), _body_material)
    _box("Cabin", Vector3(0, 1.0, -0.18), Vector3(1.52, 0.62, 1.8), glass_mat)
    _box("Roof", Vector3(0, 1.33, -0.18), Vector3(1.42, 0.08, 1.65), trim)
    _box("FrontBumper", Vector3(0, 0.38, -1.88), Vector3(1.82, 0.16, 0.12), trim)
    _box("RearBumper", Vector3(0, 0.38, 1.88), Vector3(1.82, 0.16, 0.12), trim)
    _box("FrontLightL", Vector3(-0.62, 0.68, -1.89), Vector3(0.34, 0.13, 0.05), cyan)
    _box("FrontLightR", Vector3(0.62, 0.68, -1.89), Vector3(0.34, 0.13, 0.05), cyan)
    _box("RearLightL", Vector3(-0.62, 0.68, 1.89), Vector3(0.34, 0.13, 0.05), red)
    _box("RearLightR", Vector3(0.62, 0.68, 1.89), Vector3(0.34, 0.13, 0.05), red)
    _box("SideStripL", Vector3(-0.958, 0.55, 0), Vector3(0.035, 0.055, 2.7), cyan)
    _box("SideStripR", Vector3(0.958, 0.55, 0), Vector3(0.035, 0.055, 2.7), cyan)

    for side in [-1.0, 1.0]:
        for z in [-1.18, 1.18]:
            var wheel := MeshInstance3D.new()
            var cylinder := CylinderMesh.new()
            cylinder.top_radius = 0.31
            cylinder.bottom_radius = 0.31
            cylinder.height = 0.18
            cylinder.radial_segments = 12
            wheel.mesh = cylinder
            wheel.material_override = tire_mat
            wheel.position = Vector3(side * 0.96, 0.34, z)
            wheel.rotation.z = deg_to_rad(90)
            add_child(wheel)
            _wheels.append(wheel)

func _box(label: String, pos: Vector3, size: Vector3, material: Material) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = label
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.position = pos
    mesh.material_override = material
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(mesh)

func _mat(color: Color, metallic: float, roughness: float, glow: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    if glow:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 2.0
    return material
