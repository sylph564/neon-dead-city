extends Node

@onready var player = get_parent()
var installed = {"Sandevistan": true, "Mantis Blades": true, "Gorilla Arms": true, "Pulse Core": true, "Reflex Booster": true}
var cooldowns = {}
var skill_buttons = {}
var panel: PanelContainer
var capacity_label: Label

func _ready():
    _create_dummy()
    _create_interface()
    _create_arm_implants()

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

func _create_arm_implants():
    var blade_mat = StandardMaterial3D.new()
    blade_mat.albedo_color = Color(0.8, 0.12, 0.28)
    blade_mat.metallic = 0.85
    blade_mat.emission_enabled = true
    blade_mat.emission = Color(0.55, 0.025, 0.12)
    var armor_mat = StandardMaterial3D.new()
    armor_mat.albedo_color = Color(0.34, 0.22, 0.12)
    armor_mat.metallic = 0.9
    for pivot in [player.left_arm_pivot, player.right_arm_pivot]:
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
        gauntlet_mesh.size = Vector3(0.24, 0.25, 0.42)
        gauntlet.mesh = gauntlet_mesh
        gauntlet.position = Vector3(0.0, -0.015, 0.02)
        gauntlet.material_override = armor_mat
        pivot.add_child(gauntlet)
        gorilla_visuals.append(gauntlet)
    _update_arm_implants()

func _update_arm_implants():
    for visual in mantis_visuals:
        visual.visible = installed.get("Mantis Blades", false)
    for visual in gorilla_visuals:
        visual.visible = installed.get("Gorilla Arms", false)

func _create_interface():
    var layer = CanvasLayer.new()
    layer.name = "CyberwareLayer"
    player.add_child(layer)
    var open = Button.new()
    open.text = "CYBERWARE"
    open.position = Vector2(-220, 18)
    open.size = Vector2(200, 54)
    open.anchor_left = 1.0
    open.anchor_right = 1.0
    open.add_theme_font_size_override("font_size", 14)
    open.pressed.connect(_toggle_panel)
    layer.add_child(open)

    panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-235, -255)
    panel.custom_minimum_size = Vector2(470, 510)
    panel.visible = false
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.012, 0.018, 0.03, 0.98)
    style.border_color = Color(0.72, 0.12, 0.28)
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel", style)
    layer.add_child(panel)

    var list = VBoxContainer.new()
    list.add_theme_constant_override("separation", 7)
    panel.add_child(list)
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
        "Reflex Booster": "NERVOUS  •  temporary sprint acceleration"
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
        ["Sandevistan", Vector2(-430, -110), Color(0.08,0.24,0.38)],
        ["Mantis Blades", Vector2(-530, -110), Color(0.28,0.08,0.18)],
        ["Gorilla Arms", Vector2(-630, -110), Color(0.28,0.16,0.06)],
        ["Pulse Core", Vector2(-730, -110), Color(0.06,0.28,0.2)],
        ["Reflex Booster", Vector2(-830, -110), Color(0.22,0.2,0.06)]
    ]
    for spec in specs:
        var b = Button.new()
        b.text = spec[0].to_upper()
        b.position = spec[1]
        b.size = Vector2(92, 58)
        b.anchor_left = 1.0
        b.anchor_top = 1.0
        b.anchor_right = 1.0
        b.anchor_bottom = 1.0
        b.add_theme_font_size_override("font_size", 10)
        var bs = StyleBoxFlat.new()
        bs.bg_color = spec[2]
        bs.border_color = Color(0.7,0.18,0.34)
        bs.set_border_width_all(2)
        bs.set_corner_radius_all(9)
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
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
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
        player.set_cyber_implant(name, installed[name])
    _update_arm_implants()
    _refresh_panel()

func _refresh_panel():
    var count = 0
    for name in installed:
        if installed[name]:
            count += 1
    capacity_label.text = "INSTALLED SLOTS  %d / 5" % count
    var list = panel.get_child(0)
    for row in list.get_children():
        if row is HBoxContainer:
            var name = row.get_meta("implant_name")
            var button = row.get_meta("change_button")
            button.text = "REMOVE" if installed[name] else "INSTALL"
            button.disabled = count >= 5 and not installed[name]

func _activate(name):
    if not installed[name]:
        return
    var now = Time.get_ticks_msec()
    if float(cooldowns.get(name, 0)) > now:
        return
    match name:
        "Sandevistan":
            Engine.time_scale = 0.42
            get_tree().create_timer(5.0, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
            cooldowns[name] = now + 15000
        "Mantis Blades":
            player.set_meta("next_melee_bonus", 2.0)
            player.call("_request_attack")
            cooldowns[name] = now + 7000
        "Gorilla Arms":
            player.set_meta("next_melee_bonus", 2.5)
            player.call("_request_attack")
            cooldowns[name] = now + 7000
        "Pulse Core":
            for target in get_tree().get_nodes_in_group("enemies"):
                if target is Node3D and player.global_position.distance_to(target.global_position) <= 6.0 and target.has_method("take_damage"):
                    target.take_damage(35.0)
            cooldowns[name] = now + 9000
        "Reflex Booster":
            player.sprint_speed = 11.0
            get_tree().create_timer(4.0, true, false, true).timeout.connect(func(): player.sprint_speed = 8.0)
            cooldowns[name] = now + 10000

func _create_dummy():
    var dummy = StaticBody3D.new()
    dummy.name = "CombatTrainingDummy"
    dummy.set_script(preload("res://scripts/damage_dummy.gd"))
    dummy.position = player.global_position - player.global_transform.basis.z * 1.8
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
    dummy.add_child(readout)
    get_tree().current_scene.add_child(dummy)
