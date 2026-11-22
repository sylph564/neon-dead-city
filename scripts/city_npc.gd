extends Node3D
## Lightweight ambient pedestrian for the mobile city scene.
@export var point_a: Vector3 = Vector3.ZERO
@export var point_b: Vector3 = Vector3(0, 0, 12)
@export var walk_speed: float = 1.15
var _direction := 1.0
var _phase := 0.0
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D

func _ready() -> void:
    _build_character()
    global_position = point_a

func _process(delta: float) -> void:
    var scene := get_tree().current_scene
    var time_factor := 1.0
    if scene != null:
        time_factor = float(scene.get_meta("world_time_scale", 1.0))
    var step := delta * time_factor
    var destination := point_b if _direction > 0.0 else point_a
    var offset := destination - global_position
    if offset.length() < 0.18:
        _direction *= -1.0
        destination = point_b if _direction > 0.0 else point_a
        offset = destination - global_position
    if offset.length() > 0.01:
        var heading := offset.normalized()
        global_position += heading * walk_speed * step
        rotation.y = atan2(-heading.x, -heading.z)
    _phase += step * walk_speed * 5.0
    if _left_leg != null:
        _left_leg.rotation.x = sin(_phase) * 0.42
        _right_leg.rotation.x = -sin(_phase) * 0.42
        _left_arm.rotation.x = -sin(_phase) * 0.28
        _right_arm.rotation.x = sin(_phase) * 0.28

func _build_character() -> void:
    var outfit := _mat(Color(0.025, 0.055, 0.085), 0.55, 0.38)
    var accent := _mat(Color(0.02, 0.72, 0.95), 0.3, 0.32, true)
    var skin := _mat(Color(0.38, 0.27, 0.22), 0.0, 0.8)
    var pants := _mat(Color(0.018, 0.025, 0.04), 0.15, 0.8)
    _add_capsule("Torso", Vector3(0, 1.12, 0), 0.24, 0.78, outfit)
    _add_sphere("Head", Vector3(0, 1.78, 0), 0.17, skin)
    _add_box("ChestLight", Vector3(0, 1.28, -0.235), Vector3(0.24, 0.055, 0.025), accent)
    _add_box("Backpack", Vector3(0, 1.18, 0.25), Vector3(0.34, 0.42, 0.16), pants)
    _left_leg = _add_limb("LeftLeg", Vector3(-0.13, 0.55, 0), Vector3(0.13, 0.64, 0.14), pants)
    _right_leg = _add_limb("RightLeg", Vector3(0.13, 0.55, 0), Vector3(0.13, 0.64, 0.14), pants)
    _left_arm = _add_limb("LeftArm", Vector3(-0.31, 1.17, 0), Vector3(0.12, 0.55, 0.12), outfit)
    _right_arm = _add_limb("RightArm", Vector3(0.31, 1.17, 0), Vector3(0.12, 0.55, 0.12), outfit)
    _add_box("ArmBand", Vector3(0.31, 1.1, -0.01), Vector3(0.14, 0.07, 0.14), accent)

func _mat(color: Color, metallic: float, roughness: float, glow: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    if glow:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 1.4
    return material

func _add_capsule(label: String, pos: Vector3, radius: float, height: float, material: Material) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = label
    var shape := CapsuleMesh.new()
    shape.radius = radius
    shape.height = height
    mesh.mesh = shape
    mesh.position = pos
    mesh.material_override = material
    add_child(mesh)

func _add_sphere(label: String, pos: Vector3, radius: float, material: Material) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = label
    var shape := SphereMesh.new()
    shape.radius = radius
    shape.height = radius * 2.0
    mesh.mesh = shape
    mesh.position = pos
    mesh.material_override = material
    add_child(mesh)

func _add_box(label: String, pos: Vector3, size: Vector3, material: Material) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = label
    var shape := BoxMesh.new()
    shape.size = size
    mesh.mesh = shape
    mesh.position = pos
    mesh.material_override = material
    add_child(mesh)

func _add_limb(label: String, pos: Vector3, size: Vector3, material: Material) -> Node3D:
    var pivot := Node3D.new()
    pivot.name = label
    pivot.position = pos
    add_child(pivot)
    var mesh := MeshInstance3D.new()
    var shape := CapsuleMesh.new()
    shape.radius = size.x * 0.5
    shape.height = size.y
    mesh.mesh = shape
    mesh.material_override = material
    mesh.position.y = -size.y * 0.42
    pivot.add_child(mesh)
    return pivot
