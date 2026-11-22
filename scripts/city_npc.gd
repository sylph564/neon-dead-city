extends CharacterBody3D
## Ambient pedestrian with collision, simple patrol movement and a talk interaction.
@export var point_a: Vector3 = Vector3.ZERO
@export var point_b: Vector3 = Vector3(0, 0, 12)
@export var walk_speed: float = 1.15
@export_range(0, 3, 1) var outfit_variant: int = 0

var _direction := 1.0
var _phase := 0.0
var _talk_time := 0.0
var _talk_count := 0
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _base_material: StandardMaterial3D
var _accent_material: StandardMaterial3D
var _name_label: Label3D

const DIALOGUE := [
    "Слышал? На старой станции снова пропал свет.",
    "Не стой долго под рекламными панелями. Они искрят.",
    "Ночной рынок открыт до рассвета. Ищи красные вывески.",
    "Говорят, над кварталом поставили новую систему наблюдения.",
    "Если нужен транспорт — жди у синей разметки."
]

func _ready() -> void:
    add_to_group("pedestrians")
    collision_layer = 2
    collision_mask = 1
    floor_snap_length = 0.22
    safe_margin = 0.035
    _build_character()
    global_position = point_a

func _physics_process(delta: float) -> void:
    var scene := get_tree().current_scene
    var time_factor := float(scene.get_meta("world_time_scale", 1.0)) if scene != null else 1.0
    var step := delta * time_factor
    _talk_time = maxf(0.0, _talk_time - delta)
    var destination := point_b if _direction > 0.0 else point_a
    var offset := destination - global_position
    offset.y = 0.0
    if offset.length() < 0.45:
        _direction *= -1.0
        destination = point_b if _direction > 0.0 else point_a
        offset = destination - global_position
        offset.y = 0.0

    if offset.length() > 0.02:
        var heading := offset.normalized()
        velocity.x = heading.x * walk_speed * time_factor
        velocity.z = heading.z * walk_speed * time_factor
        rotation.y = atan2(-heading.x, -heading.z)
    else:
        velocity.x = 0.0
        velocity.z = 0.0

    if not is_on_floor():
        velocity.y -= 18.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()
    if is_on_wall():
        _direction *= -1.0

    var moving := Vector2(velocity.x, velocity.z).length() > 0.15
    _phase += step * walk_speed * 5.0
    if moving and _talk_time <= 0.0:
        var swing := sin(_phase) * 0.42
        _left_leg.rotation.x = swing
        _right_leg.rotation.x = -swing
        _left_arm.rotation.x = -swing * 0.62
        _right_arm.rotation.x = swing * 0.62
    else:
        _left_leg.rotation.x = lerp(_left_leg.rotation.x, 0.0, delta * 7.0)
        _right_leg.rotation.x = lerp(_right_leg.rotation.x, 0.0, delta * 7.0)
        _left_arm.rotation.x = lerp(_left_arm.rotation.x, 0.0, delta * 7.0)
        _right_arm.rotation.x = lerp(_right_arm.rotation.x, sin(_phase * 8.0) * 0.72 if _talk_time > 0.0 else 0.0, delta * 10.0)

func interact() -> String:
    _talk_count += 1
    _talk_time = 1.4
    if _name_label != null:
        _name_label.text = "CITIZEN // CONNECTED"
        _name_label.modulate = Color(1.0, 0.78, 0.28)
    var line: String = DIALOGUE[(_talk_count - 1) % DIALOGUE.size()]
    return line

func _build_character() -> void:
    var outfits := [Color(0.025, 0.055, 0.085), Color(0.075, 0.028, 0.055), Color(0.045, 0.065, 0.052), Color(0.055, 0.045, 0.09)]
    var accents := [Color(0.02, 0.72, 0.95), Color(1.0, 0.12, 0.32), Color(1.0, 0.48, 0.06), Color(0.32, 0.52, 1.0)]
    _base_material = _mat(outfits[outfit_variant % outfits.size()], 0.55, 0.38)
    _accent_material = _mat(accents[outfit_variant % accents.size()], 0.3, 0.32, true)
    var skin := _mat(Color(0.38, 0.27, 0.22), 0.0, 0.8)
    var pants := _mat(Color(0.018, 0.025, 0.04), 0.15, 0.8)

    var hit_shape := CollisionShape3D.new()
    hit_shape.name = "PedestrianCollision"
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.29
    capsule.height = 1.82
    hit_shape.shape = capsule
    hit_shape.position.y = 0.91
    add_child(hit_shape)

    _add_capsule("Torso", Vector3(0, 1.12, 0), 0.24, 0.78, _base_material)
    _add_sphere("Head", Vector3(0, 1.78, 0), 0.17, skin)
    _add_box("ChestLight", Vector3(0, 1.28, -0.235), Vector3(0.24, 0.055, 0.025), _accent_material)
    _add_box("Backpack", Vector3(0, 1.18, 0.25), Vector3(0.34, 0.42, 0.16), pants)
    _left_leg = _add_limb("LeftLeg", Vector3(-0.13, 0.55, 0), Vector3(0.13, 0.64, 0.14), pants)
    _right_leg = _add_limb("RightLeg", Vector3(0.13, 0.55, 0), Vector3(0.13, 0.64, 0.14), pants)
    _left_arm = _add_limb("LeftArm", Vector3(-0.31, 1.17, 0), Vector3(0.12, 0.55, 0.12), _base_material)
    _right_arm = _add_limb("RightArm", Vector3(0.31, 1.17, 0), Vector3(0.12, 0.55, 0.12), _base_material)
    _add_box("ArmBand", Vector3(0.31, 1.1, -0.01), Vector3(0.14, 0.07, 0.14), _accent_material)

    _name_label = Label3D.new()
    _name_label.position = Vector3(0, 2.15, 0)
    _name_label.font_size = 22
    _name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    _name_label.modulate = Color(0.55, 0.95, 1.0)
    _name_label.text = "CITIZEN  //  E TO TALK"
    add_child(_name_label)

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

func _add_capsule(label: String, pos: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.name = label
    var shape := CapsuleMesh.new()
    shape.radius = radius
    shape.height = height
    mesh.mesh = shape
    mesh.position = pos
    mesh.material_override = material
    add_child(mesh)
    return mesh

func _add_sphere(label: String, pos: Vector3, radius: float, material: Material) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.name = label
    var shape := SphereMesh.new()
    shape.radius = radius
    shape.height = radius * 2.0
    mesh.mesh = shape
    mesh.position = pos
    mesh.material_override = material
    add_child(mesh)
    return mesh

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
