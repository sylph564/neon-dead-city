extends Node3D
## Low-cost ambient traffic vehicle. No physics bodies or dynamic shadows.
@export var speed: float = 4.0
@export var min_x: float = -72.0
@export var max_x: float = 72.0
@export var lane_z: float = -9.0
@export var direction: float = 1.0
var _wheels: Array[MeshInstance3D] = []

func _ready() -> void:
    global_position = Vector3(min_x if direction > 0.0 else max_x, 0.0, lane_z)
    rotation.y = -PI * 0.5 if direction > 0.0 else PI * 0.5
    _build_vehicle()

func _process(delta: float) -> void:
    var scene := get_tree().current_scene
    var time_factor := 1.0
    if scene != null:
        time_factor = float(scene.get_meta("world_time_scale", 1.0))
    position.x += speed * direction * delta * time_factor
    if direction > 0.0 and position.x > max_x:
        position.x = min_x
    elif direction < 0.0 and position.x < min_x:
        position.x = max_x
    for wheel in _wheels:
        wheel.rotate_x(delta * speed * 2.0 * time_factor)

func _build_vehicle() -> void:
    var body_mat := _mat(Color(0.025, 0.045, 0.075), 0.78, 0.28)
    var glass_mat := _mat(Color(0.015, 0.18, 0.24), 0.55, 0.18)
    var tire_mat := _mat(Color(0.008, 0.01, 0.015), 0.0, 0.96)
    var cyan := _mat(Color(0.015, 0.62, 1.0), 0.2, 0.28, true)
    var red := _mat(Color(1.0, 0.025, 0.08), 0.1, 0.25, true)
    _box("Chassis", Vector3(0, 0.58, 0), Vector3(1.9, 0.55, 3.7), body_mat)
    _box("Cabin", Vector3(0, 1.0, -0.18), Vector3(1.55, 0.62, 1.8), glass_mat)
    _box("FrontLightL", Vector3(-0.62, 0.68, -1.88), Vector3(0.34, 0.13, 0.05), cyan)
    _box("FrontLightR", Vector3(0.62, 0.68, -1.88), Vector3(0.34, 0.13, 0.05), cyan)
    _box("RearLightL", Vector3(-0.62, 0.68, 1.88), Vector3(0.34, 0.13, 0.05), red)
    _box("RearLightR", Vector3(0.62, 0.68, 1.88), Vector3(0.34, 0.13, 0.05), red)
    for side in [-1.0, 1.0]:
        for z in [-1.18, 1.18]:
            var wheel := MeshInstance3D.new()
            var cylinder := CylinderMesh.new()
            cylinder.top_radius = 0.31
            cylinder.bottom_radius = 0.31
            cylinder.height = 0.18
            cylinder.radial_segments = 10
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
    add_child(mesh)

func _mat(color: Color, metallic: float, roughness: float, glow: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    if glow:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 1.6
    return material
