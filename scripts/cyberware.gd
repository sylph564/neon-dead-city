extends Node

@onready var player: CharacterBody3D = get_parent() as CharacterBody3D
var installed = {"Sandevistan": true, "Mantis Blades": true, "Gorilla Arms": true, "Pulse Core": true, "Reflex Booster": true, "Monowire": true, "Projectile Launch System": true}
var cooldowns = {}
var skill_buttons = {}
var panel: PanelContainer
var capacity_label: Label

func _ready():
    # Wait until the Player has completed its own _ready() and created its camera/arms.
    call_deferred("_initialize_cyberware")

func _initialize_cyberware():
    if not is_instance_valid(player):
        push_error("Cyberware: Player reference is missing")
        return
    _create_interface()
    _create_sandevistan_overlay()
    _create_dummy()
    _create_arm_implants()
    for implant_name in installed:
        if player.has_method("set_cyber_implant"):
            player.call("set_cyber_implant", implant_name, installed[implant_name])

func _process(_delta):
    var now = Time.get_ticks_msec()
    for name in skill_buttons:
        var button = skill_buttons[name]
        var left = maxf(0.0, float(cooldowns.get(name, 0)) - now) / 1000.0
        button.disabled = not installed[name] or left > 0.0
        if not installed[name]:
            button.text = "OFF"
        elif left > 0.0:
            button.text = "%.1f" % left
        else:
            button.text = name.to_upper()


var mantis_visuals = []
var gorilla_visuals = []
var monowire_visuals = []
var launcher_visuals = []
var sandevistan_overlay: ColorRect
var sandevistan_label: Label
var sandevistan_token := 0

func _create_arm_implants():
    var blade_mat = StandardMaterial3D.new()
    blade_mat.albedo_color = Color(0.8, 0.12, 0.28)
    blade_mat.metallic = 0.85
    blade_mat.emission_enabled = true
    blade_mat.emission = Color(0.55, 0.025, 0.12)
    var armor_mat = StandardMaterial3D.new()
    armor_mat.albedo_color = Color(0.34, 0.22, 0.12)
    armor_mat.metallic = 0.9
    for pivot in [player.get("left_arm_pivot"), player.get("right_arm_pivot")]:
        if pivot == null:
            continue
        var blade = MeshInstance3D.new()
        var blade_mesh = BoxMesh.new()
        blade_mesh.size = Vector3(0.055, 0.055, 0.72)
        blade.mesh = blade_mesh
        blade.position = Vector3(0.0, 0.02, -0.47)
        blade.material_override = blade_mat
        pivot.add_child(blade)
        mantis_visuals.append(blade)
        var gauntlet = MeshInstance3D.new()
        var gauntlet_mesh = BoxMesh.new()
        gauntlet_mesh.size = Vector3(0.18, 0.17, 0.25)
        gauntlet.mesh = gauntlet_mesh
        gauntlet.position = Vector3(0.0, -0.015, -0.12)
        gauntlet.material_override = armor_mat
        pivot.add_child(gauntlet)
        gorilla_visuals.append(gauntlet)
        var wire = MeshInstance3D.new()
        var wire_mesh = CylinderMesh.new()
        wire_mesh.top_radius = 0.018
        wire_mesh.bottom_radius = 0.018
        wire_mesh.height = 0.95
        wire.mesh = wire_mesh
        wire.position = Vector3(0.0, 0.04, -0.48)
        wire.rotation.x = deg_to_rad(90)
        var wire_mat = StandardMaterial3D.new()
        wire_mat.albedo_color = Color(0.05, 0.88, 1.0)
        wire_mat.emission_enabled = true
        wire_mat.emission = Color(0.02, 0.72, 1.0)
        wire_mat.emission_energy_multiplier = 2.4
        wire.material_override = wire_mat
        pivot.add_child(wire)
        monowire_visuals.append(wire)
        var launcher = MeshInstance3D.new()
        var launcher_mesh = BoxMesh.new()
        launcher_mesh.size = Vector3(0.19, 0.12, 0.3)
        launcher.mesh = launcher_mesh
        launcher.position = Vector3(0.0, 0.11, -0.2)
        var launcher_mat = StandardMaterial3D.new()
        launcher_mat.albedo_color = Color(0.09, 0.12, 0.17)
        launcher_mat.metallic = 0.85
        launcher_mat.emission_enabled = true
        launcher_mat.emission = Color(0.9, 0.12, 0.04)
        launcher_mat.emission_energy_multiplier = 1.1
        launcher.material_override = launcher_mat
        pivot.add_child(launcher)
        launcher_visuals.append(launcher)
    _update_arm_implants()

func _update_arm_implants():
    for visual in mantis_visuals:
        visual.visible = installed.get("Mantis Blades", false)
    for visual in gorilla_visuals:
        visual.visible = installed.get("Gorilla Arms", false)
    for visual in monowire_visuals:
        visual.visible = installed.get("Monowire", false)
    for visual in launcher_visuals:
        visual.visible = installed.get("Projectile Launch System", false)

func _create_interface():
    var layer = CanvasLayer.new()
    layer.name = "CyberwareLayer"
    layer.layer = 50
    layer.follow_viewport_enabled = false
    var scene_root = get_tree().current_scene
    if scene_root == null:
        scene_root = get_tree().root
    scene_root.add_child(layer)
    var open = Button.new()
    open.text = "CYBERWARE"
    open.position = Vector2(-178, 18)
    open.size = Vector2(160, 48)
    open.anchor_left = 1.0
    open.anchor_right = 1.0
    open.add_theme_font_size_override("font_size", 14)
    open.pressed.connect(_toggle_panel)
    layer.add_child(open)

    panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-190, -170)
    panel.size = Vector2(380, 340)
    panel.custom_minimum_size = Vector2(380, 340)
    panel.visible = false
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.012, 0.018, 0.03, 0.98)
    style.border_color = Color(0.72, 0.12, 0.28)
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel", style)
    layer.add_child(panel)

    var scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    panel.add_child(scroll)
    var list = VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 6)
    scroll.add_child(list)
    var heading = Label.new()
    heading.text = "NEUROLINK  /  CYBERWARE"
    heading.add_theme_font_size_override("font_size", 20)
    heading.add_theme_color_override("font_color", Color(0.25, 0.9, 1.0))
    list.add_child(heading)
    capacity_label = Label.new()
    capacity_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.24))
    list.add_child(capacity_label)
    _create_character_preview(list)

    var descriptions = {
        "Sandevistan": "OS  •  slows the world for 5 seconds",
        "Mantis Blades": "ARMS  •  longer melee reach and blade damage",
        "Gorilla Arms": "ARMS  •  heavy strikes deal 2.5x damage",
        "Pulse Core": "CIRCULATORY  •  damages targets within 6m",
        "Reflex Booster": "NERVOUS  •  temporary sprint acceleration",
        "Monowire": "ARMS  •  extended-range energy whip strike",
        "Projectile Launch System": "ARMS  •  short-range radial energy blast"
    }
    for name in descriptions:
        var row = HBoxContainer.new()
        var info = Label.new()
        info.text = name + "\n" + descriptions[name]
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        info.add_theme_font_size_override("font_size", 12)
        row.add_child(info)
        var change = Button.new()
        change.custom_minimum_size = Vector2(100, 42)
        change.pressed.connect(_toggle_implant.bind(name))
        row.add_child(change)
        row.set_meta("implant_name", name)
        row.set_meta("change_button", change)
        list.add_child(row)
    var close = Button.new()
    close.text = "CLOSE"
    close.pressed.connect(_toggle_panel)
    list.add_child(close)
    _refresh_panel()

    var specs = [
        ["Sandevistan", Color(0.08, 0.24, 0.38)],
        ["Mantis Blades", Color(0.28, 0.08, 0.18)],
        ["Gorilla Arms", Color(0.28, 0.16, 0.06)],
        ["Pulse Core", Color(0.06, 0.28, 0.2)],
        ["Reflex Booster", Color(0.22, 0.2, 0.06)],
        ["Monowire", Color(0.02, 0.3, 0.38)],
        ["Projectile Launch System", Color(0.38, 0.12, 0.04)]
    ]
    for i in range(specs.size()):
        var spec = specs[i]
        var b = Button.new()
        b.text = str(spec[0]).to_upper()
        b.position = Vector2(-548 + i * 78, 78)
        b.size = Vector2(72, 48)
        b.anchor_left = 1.0
        b.anchor_top = 0.0
        b.anchor_right = 1.0
        b.anchor_bottom = 0.0
        b.add_theme_font_size_override("font_size", 8)
        b.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
        var bs = StyleBoxFlat.new()
        bs.bg_color = spec[1]
        bs.border_color = Color(0.12, 0.72, 0.95)
        bs.set_border_width_all(2)
        bs.set_corner_radius_all(8)
        b.add_theme_stylebox_override("normal", bs)
        b.pressed.connect(_activate.bind(spec[0]))
        layer.add_child(b)
        skill_buttons[spec[0]] = b



func _create_character_preview(parent):
    var holder = HBoxContainer.new()
    holder.custom_minimum_size = Vector2(0, 135)
    parent.add_child(holder)
    var preview = SubViewportContainer.new()
    preview.custom_minimum_size = Vector2(132, 132)
    preview.stretch = true
    holder.add_child(preview)
    var viewport = SubViewport.new()
    viewport.size = Vector2i(220, 220)
    viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
    preview.add_child(viewport)
    var world = Node3D.new()
    viewport.add_child(world)
    var camera = Camera3D.new()
    camera.position = Vector3(0, 1.25, 3.8)
    camera.look_at(Vector3(0, 1.0, 0))
    viewport.add_child(camera)
    var key = DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-28, -25, 0)
    key.light_energy = 1.3
    world.add_child(key)
    var body_mat = StandardMaterial3D.new()
    body_mat.albedo_color = Color(0.035, 0.055, 0.075)
    body_mat.metallic = 0.45
    var accent = StandardMaterial3D.new()
    accent.albedo_color = Color(0.05, 0.72, 0.88)
    accent.emission_enabled = true
    accent.emission = Color(0.02, 0.45, 0.7)
    var torso = MeshInstance3D.new()
    var torso_mesh = CapsuleMesh.new()
    torso_mesh.radius = 0.28
    torso_mesh.height = 0.9
    torso.mesh = torso_mesh
    torso.position.y = 1.15
    torso.material_override = body_mat
    world.add_child(torso)
    var head = MeshInstance3D.new()
    var head_mesh = SphereMesh.new()
    head_mesh.radius = 0.19
    head_mesh.height = 0.38
    head.mesh = head_mesh
    head.position.y = 1.82
    head.material_override = body_mat
    world.add_child(head)
    for side in [-1.0, 1.0]:
        var arm = MeshInstance3D.new()
        var arm_mesh = CapsuleMesh.new()
        arm_mesh.radius = 0.09
        arm_mesh.height = 0.72
        arm.mesh = arm_mesh
        arm.position = Vector3(side * 0.39, 1.15, 0)
        arm.rotation.z = side * -0.18
        arm.material_override = accent
        world.add_child(arm)
        var leg = MeshInstance3D.new()
        var leg_mesh = CapsuleMesh.new()
        leg_mesh.radius = 0.12
        leg_mesh.height = 0.85
        leg.mesh = leg_mesh
        leg.position = Vector3(side * 0.16, 0.43, 0)
        leg.material_override = body_mat
        world.add_child(leg)
    var caption = Label.new()
    caption.text = "OPERATOR  //  ACTIVE LOADOUT\\nNEURAL PROFILE: SYL-01"
    caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    caption.add_theme_font_size_override("font_size", 12)
    caption.add_theme_color_override("font_color", Color(0.55,0.82,0.9))
    holder.add_child(caption)

func _toggle_panel():
    panel.visible = not panel.visible
    _refresh_panel()

func _toggle_implant(name):
    installed[name] = not installed[name]
    if player.has_method("set_cyber_implant"):
        player.call("set_cyber_implant", name, installed[name])
    _update_arm_implants()
    _refresh_panel()

func _refresh_panel():
    var count = 0
    for name in installed:
        if installed[name]:
            count += 1
    capacity_label.text = "INSTALLED SLOTS  %d / 7" % count
    var scroll = panel.get_child(0) as ScrollContainer
    var list = scroll.get_child(0) as VBoxContainer
    for row in list.get_children():
        if row is HBoxContainer and row.has_meta("implant_name"):
            var name = row.get_meta("implant_name")
            var button = row.get_meta("change_button")
            button.text = "REMOVE" if installed[name] else "INSTALL"
            button.disabled = count >= 7 and not installed[name]

func _create_sandevistan_overlay() -> void:
    var layer := CanvasLayer.new()
    layer.name = "SandevistanFX"
    layer.layer = 80
    get_tree().current_scene.add_child(layer)
    sandevistan_overlay = ColorRect.new()
    sandevistan_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    sandevistan_overlay.color = Color(0.015, 0.52, 0.95, 0.13)
    sandevistan_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    sandevistan_overlay.visible = false
    layer.add_child(sandevistan_overlay)
    sandevistan_label = Label.new()
    sandevistan_label.text = "SANDEVISTAN  //  TIME DILATION"
    sandevistan_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
    sandevistan_label.position = Vector2(-150, 72)
    sandevistan_label.add_theme_font_size_override("font_size", 18)
    sandevistan_label.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0))
    sandevistan_overlay.add_child(sandevistan_label)

func _activate(name):
    if not installed.get(name, false):
        return
    var now = Time.get_ticks_msec()
    if float(cooldowns.get(name, 0)) > now:
        return
    match name:
        "Sandevistan":
            _activate_sandevistan()
            cooldowns[name] = now + 15000
        "Mantis Blades":
            player.set_meta("next_melee_bonus", 2.0)
            player.set_meta("next_melee_range", 3.2)
            player.call("_request_attack")
            cooldowns[name] = now + 7000
        "Gorilla Arms":
            player.set_meta("next_melee_bonus", 2.5)
            player.set_meta("next_melee_range", 2.4)
            player.call("_request_attack")
            cooldowns[name] = now + 7000
        "Pulse Core":
            _pulse_core()
            cooldowns[name] = now + 9000
        "Reflex Booster":
            player.set("sprint_speed", 11.0)
            player.set_meta("reflex_boost_active", true)
            get_tree().create_timer(4.0, true, false, true).timeout.connect(func():
                if is_instance_valid(player):
                    player.set("sprint_speed", 8.0)
                    player.set_meta("reflex_boost_active", false)
            )
            cooldowns[name] = now + 10000
        "Monowire":
            player.set_meta("next_melee_bonus", 2.2)
            player.set_meta("next_melee_range", 5.4)
            player.call("_request_attack")
            cooldowns[name] = now + 8000
        "Projectile Launch System":
            _fire_projectile()
            cooldowns[name] = now + 11000

func _activate_sandevistan() -> void:
    sandevistan_token += 1
    var token := sandevistan_token
    get_tree().current_scene.set_meta("world_time_scale", 0.22)
    player.set_meta("sandevistan_active", true)
    sandevistan_overlay.visible = true
    var camera_tween := player.create_tween()
    camera_tween.tween_property(player.camera, "fov", 96.0, 0.22)
    var timer := get_tree().create_timer(5.0, true, false, true)
    timer.timeout.connect(func():
        if token == sandevistan_token:
            if is_instance_valid(get_tree().current_scene):
                get_tree().current_scene.set_meta("world_time_scale", 1.0)
            if is_instance_valid(player):
                player.set_meta("sandevistan_active", false)
                var reset_tween := player.create_tween()
                reset_tween.tween_property(player.camera, "fov", 82.0, 0.3)
            if is_instance_valid(sandevistan_overlay):
                sandevistan_overlay.visible = false
    )

func _pulse_core() -> void:
    for target in get_tree().get_nodes_in_group("enemies"):
        if target is Node3D and player.global_position.distance_to(target.global_position) <= 6.0 and target.has_method("take_damage"):
            target.take_damage(35.0)
    _spawn_blast(player.global_position + (-player.global_transform.basis.z * 3.0), 3.0, Color(0.05, 0.78, 1.0))

func _fire_projectile() -> void:
    var origin: Vector3 = player.camera.global_position
    var finish: Vector3 = origin + (-player.camera.global_transform.basis.z * 22.0)
    var query := PhysicsRayQueryParameters3D.create(origin, finish)
    query.exclude = [player.get_rid()]
    var result := player.get_world_3d().direct_space_state.intersect_ray(query)
    var impact := finish
    if not result.is_empty():
        impact = result.position
    for target in get_tree().get_nodes_in_group("enemies"):
        if target is Node3D and target.global_position.distance_to(impact) <= 4.5 and target.has_method("take_damage"):
            target.take_damage(60.0)
    _spawn_projectile_visual(origin, impact, Color(1.0, 0.22, 0.06))
    _spawn_blast(impact, 4.5, Color(1.0, 0.22, 0.06))

func _spawn_projectile_visual(origin: Vector3, destination: Vector3, tint: Color) -> void:
    var projectile := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.12
    mesh.height = 0.24
    projectile.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.emission_enabled = true
    material.emission = tint
    material.emission_energy_multiplier = 4.0
    projectile.material_override = material
    get_tree().current_scene.add_child(projectile)
    projectile.global_position = origin
    var tween := projectile.create_tween()
    tween.tween_property(projectile, "global_position", destination, 0.18)
    tween.tween_callback(projectile.queue_free)

func _spawn_blast(at: Vector3, radius: float, tint: Color) -> void:
    var root := get_tree().current_scene
    var effect := Node3D.new()
    effect.name = "CyberwareImpactFX"
    root.add_child(effect)
    effect.global_position = at
    var orb := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.5
    sphere.height = 1.0
    orb.mesh = sphere
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(tint.r, tint.g, tint.b, 0.55)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.emission_enabled = true
    material.emission = tint
    material.emission_energy_multiplier = 3.0
    orb.material_override = material
    orb.scale = Vector3.ONE * 0.15
    effect.add_child(orb)
    var light := OmniLight3D.new()
    light.light_color = tint
    light.light_energy = 2.4
    light.omni_range = radius * 1.8
    effect.add_child(light)
    var tween := effect.create_tween()
    tween.set_parallel(true)
    tween.tween_property(orb, "scale", Vector3.ONE * radius, 0.32)
    tween.tween_property(light, "light_energy", 0.0, 0.32)
    tween.chain().tween_callback(effect.queue_free)

func _create_dummy():
    var dummy = StaticBody3D.new()
    dummy.name = "CombatTrainingDummy"
    dummy.set_script(preload("res://scripts/damage_dummy.gd"))
    dummy.position = Vector3.ZERO
    dummy.add_to_group("enemies")
    var shape = CollisionShape3D.new()
    var capsule = CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.9
    shape.shape = capsule
    shape.position.y = 0.95
    dummy.add_child(shape)
    var visual = MeshInstance3D.new()
    var mesh = CapsuleMesh.new()
    mesh.radius = 0.42
    mesh.height = 1.9
    visual.mesh = mesh
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.42,0.12,0.18)
    material.metallic = 0.5
    visual.material_override = material
    visual.position.y = 0.95
    dummy.add_child(visual)
    var readout = Label3D.new()
    readout.name = "DamageReadout"
    readout.position.y = 2.2
    readout.text = "TRAINING TARGET\nDMG 0  |  DPS 0"
    readout.font_size = 32
    readout.modulate = Color(0.35,0.95,1.0)
    readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    dummy.add_child(readout)
    var scene_root = get_tree().current_scene
    if scene_root == null:
        scene_root = get_tree().root
    scene_root.add_child(dummy)
    dummy.global_position = player.global_position + (-player.global_transform.basis.z * 2.35)
