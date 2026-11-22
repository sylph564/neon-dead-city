extends CharacterBody3D
## Ambient pedestrian with a real hitbox, health and readable hit reactions.
@export var point_a: Vector3 = Vector3.ZERO
@export var point_b: Vector3 = Vector3(0, 0, 12)
@export var walk_speed: float = 1.15
@export var max_health: float = 120.0

var health: float = 120.0
var _direction := 1.0
var _phase := 0.0
var _hit_stun := 0.0
var _knockback := Vector3.ZERO
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _base_material: StandardMaterial3D
var _damage_label: Label3D

func _ready() -> void:
    health = max_health
    add_to_group("enemies")
    collision_layer = 2
    collision_mask = 1
    floor_snap_length = 0.25
    _build_character()
    global_position = point_a

func _physics_process(delta: float) -> void:
    var scene := get_tree().current_scene
    var time_factor := float(scene.get_meta("world_time_scale", 1.0)) if scene != null else 1.0
    var step := delta * time_factor
    if _hit_stun > 0.0:
        _hit_stun = maxf(0.0, _hit_stun - delta)
        velocity.x = _knockback.x
        velocity.z = _knockback.z
        _knockback = _knockback.move_toward(Vector3.ZERO, delta * 9.0)
    else:
        var destination := point_b if _direction > 0.0 else point_a
        var offset := destination - global_position
        offset.y = 0.0
        if offset.length() < 0.35:
            _direction *= -1.0
            destination = point_b if _direction > 0.0 else point_a
            offset = destination - global_position
            offset.y = 0.0
        if offset.length() > 0.01:
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
    _phase += step * walk_speed * 5.0
    var moving := Vector2(velocity.x, velocity.z).length() > 0.15
    if _left_leg != null:
        var swing := sin(_phase) * (0.42 if moving and _hit_stun <= 0.0 else 0.04)
        _left_leg.rotation.x = swing
        _right_leg.rotation.x = -swing
        _left_arm.rotation.x = -swing * 0.65
        _right_arm.rotation.x = swing * 0.65

func take_damage(amount: float) -> void:
    if health <= 0.0:
        return
    health = maxf(0.0, health - amount)
    _hit_stun = 0.32
    var camera := get_viewport().get_camera_3d()
    var away := global_position - (camera.global_position if camera != null else global_position + Vector3(0, 0, 1))
    away.y = 0.0
    if away.length() > 0.01:
        _knockback = away.normalized() * 4.2
    if _base_material != null:
        _base_material.albedo_color = Color(1.0, 0.12, 0.2)
        _base_material.emission_enabled = true
        _base_material.emission = Color(0.8, 0.025, 0.08)
        _base_material.emission_energy_multiplier = 1.8
        var flash := create_tween()
        flash.tween_interval(0.12)
        flash.tween_callback(func():
            if is_instance_valid(_base_material):
                _base_material.albedo_color = Color(0.025, 0.055, 0.085)
                _base_material.emission_enabled = false
        )
    if _damage_label != null:
        _damage_label.text = "-%d  //  %d HP" % [int(amount), int(health)]
    if health <= 0.0:
        velocity = Vector3.ZERO
        collision_layer = 0
        collision_mask = 0
        var fall := create_tween()
        fall.tween_property(self, "rotation:z", deg_to_rad(82.0), 0.22)
        fall.tween_interval(3.0)
        fall.tween_callback(queue_free)

func _build_character() -> void:
    _base_material = _mat(Color(0.025, 0.055, 0.085), 0.55, 0.38)
    var accent := _mat(Color(0.02, 0.72, 0.95), 0.3, 0.32, true)
    var skin := _mat(Color(0.38, 0.27, 0.22), 0.0, 0.8)
    var pants := _mat(Color(0.018, 0.025, 0.04), 0.15, 0.8)
    var hit_shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.27
    capsule.height = 1.82
    hit_shape.shape = capsule
    hit_shape.position.y = 0.91
    add_child(hit_shape)
    _body_mesh = _add_capsule("Torso", Vector3(0, 1.12, 0), 0.24, 0.78, _base_material)
    _head_mesh = _add_sphere("Head", Vector3(0, 1.78, 0), 0.17, skin)
    _add_box("ChestLight", Vector3(0, 1.28, -0.235), Vector3(0.24, 0.055, 0.025), accent)
    _add_box("Backpack", Vector3(0, 1.18, 0.25), Vector3(0.34, 0.42, 0.16), pants)
    _left_leg = _add_limb("LeftLeg", Vector3(-0.13, 0.55, 0), Vector3(0.13, 0.64, 0.14), pants)
    _right_leg = _add_limb("RightLeg", Vector3(0.13, 0.55, 0), Vector3(0.13, 0.64, 0.14), pants)
    _left_arm = _add_limb("LeftArm", Vector3(-0.31, 1.17, 0), Vector3(0.12, 0.55, 0.12), _base_material)
    _right_arm = _add_limb("RightArm", Vector3(0.31, 1.17, 0), Vector3(0.12, 0.55, 0.12), _base_material)
    _add_box("ArmBand", Vector3(0.31, 1.1, -0.01), Vector3(0.14, 0.07, 0.14), accent)
    _damage_label = Label3D.new()
    _damage_label.position = Vector3(0, 2.15, 0)
    _damage_label.font_size = 24
    _damage_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    _damage_label.modulate = Color(0.55, 0.95, 1.0)
    _damage_label.text = "HOSTILE  //  120 HP"
    add_child(_damage_label)

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
