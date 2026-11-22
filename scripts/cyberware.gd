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
    if is_instance_valid(sandevistan_overlay) and sandevistan_overlay.visible:
        var hue := fposmod(float(now) * 0.00018, 1.0)
        sandevistan_overlay.color = Color.from_hsv(hue, 0.82, 0.95, 0.10)
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
        var blade_mesh = CylinderMesh.new()
        blade_mesh.top_radius = 0.006
        blade_mesh.bottom_radius = 0.035
        blade_mesh.height = 0.92
        blade_mesh.radial_segments = 6
        blade.mesh = blade_mesh
        blade.rotation.x = deg_to_rad(90)
        blade.position = Vector3(0.0, 0.025, -0.52)
        blade.material_override = blade_mat
        pivot.add_child(blade)
        mantis_visuals.append(blade)
        var blade_spine = MeshInstance3D.new()
        var spine_mesh = BoxMesh.new()
        spine_mesh.size = Vector3(0.018, 0.028, 0.76)
        blade_spine.mesh = spine_mesh
        blade_spine.position = Vector3(0.035, 0.025, -0.52)
        blade_spine.material_override = blade_mat
        pivot.add_child(blade_spine)
        mantis_visuals.append(blade_spine)
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
    var layer := CanvasLayer.new()
    layer.name = "CyberwareLayer"
    layer.layer = 50
    get_tree().current_scene.add_child(layer)
    var open := Button.new()
    open.text = "CYBERWARE  /  TAB"
    open.position = Vector2(-205, 18)
    open.size = Vector2(188, 48)
    open.anchor_left = 1.0
    open.anchor_right = 1.0
    open.add_theme_font_size_override("font_size", 13)
    open.add_theme_color_override("font_color", Color(1.0, 0.82, 0.72))
    var open_style := StyleBoxFlat.new()
    open_style.bg_color = Color(0.12, 0.025, 0.045, 0.94)
    open_style.border_color = Color(0.72, 0.18, 0.28)
    open_style.set_border_width_all(2)
    open_style.set_corner_radius_all(6)
    open.add_theme_stylebox_override("normal", open_style)
    open.pressed.connect(_toggle_panel)
    layer.add_child(open)

    panel = PanelContainer.new()
    panel.name = "CyberwareMenu"
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.offset_left = 18
    panel.offset_top = 18
    panel.offset_right = -18
    panel.offset_bottom = -18
    panel.visible = false
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.075, 0.012, 0.025, 0.985)
    panel_style.border_color = Color(0.48, 0.075, 0.14, 1.0)
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(8)
    panel.add_theme_stylebox_override("panel", panel_style)
    layer.add_child(panel)
    var margin := MarginContainer.new()
    for key in ["left", "right"]:
        margin.add_theme_constant_override("margin_" + key, 14)
    for key in ["top", "bottom"]:
        margin.add_theme_constant_override("margin_" + key, 12)
    panel.add_child(margin)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 10)
    margin.add_child(layout)
    var header := HBoxContainer.new()
    layout.add_child(header)
    var heading := Label.new()
    heading.text = "N E U R O L I N K   /   CYBERWARE"
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_theme_font_size_override("font_size", 21)
    heading.add_theme_color_override("font_color", Color(1.0, 0.78, 0.69))
    header.add_child(heading)
    var subtitle := Label.new()
    subtitle.text = "NIGHT CITY // RIPPERDOC TERMINAL"
    subtitle.add_theme_font_size_override("font_size", 10)
    subtitle.add_theme_color_override("font_color", Color(0.7, 0.35, 0.4))
    header.add_child(subtitle)
    var columns := HBoxContainer.new()
    columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    columns.add_theme_constant_override("separation", 12)
    layout.add_child(columns)

    var left_panel := PanelContainer.new()
    left_panel.custom_minimum_size = Vector2(300, 0)
    var left_style := StyleBoxFlat.new()
    left_style.bg_color = Color(0.105, 0.018, 0.035, 0.96)
    left_style.border_color = Color(0.32, 0.055, 0.11)
    left_style.set_border_width_all(1)
    left_style.set_corner_radius_all(5)
    left_panel.add_theme_stylebox_override("panel", left_style)
    columns.add_child(left_panel)
    var left_margin := MarginContainer.new()
    left_margin.add_theme_constant_override("margin_left", 9)
    left_margin.add_theme_constant_override("margin_right", 9)
    left_margin.add_theme_constant_override("margin_top", 9)
    left_margin.add_theme_constant_override("margin_bottom", 9)
    left_panel.add_child(left_margin)
    var left_stack := VBoxContainer.new()
    left_stack.add_theme_constant_override("separation", 7)
    left_margin.add_child(left_stack)
    var list_title := Label.new()
    list_title.text = "IMPLANT CATALOGUE"
    list_title.add_theme_font_size_override("font_size", 13)
    list_title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.2))
    left_stack.add_child(list_title)
    capacity_label = Label.new()
    capacity_label.add_theme_font_size_override("font_size", 11)
    capacity_label.add_theme_color_override("font_color", Color(0.95, 0.72, 0.35))
    left_stack.add_child(capacity_label)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    left_stack.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 5)
    scroll.add_child(list)
    var descriptions := {
        "Sandevistan": ["OS", "Time dilation / 5 sec"],
        "Mantis Blades": ["ARMS", "Deployable blades / fast slashes"],
        "Gorilla Arms": ["ARMS", "Reinforced actuators / heavy hits"],
        "Pulse Core": ["CIRCULATORY", "Close-range electromagnetic burst"],
        "Reflex Booster": ["NERVOUS", "Movement acceleration / 4 sec"],
        "Monowire": ["ARMS", "Extended energy filament attack"],
        "Projectile Launch System": ["ARMS", "Arm-mounted explosive projectile"]
    }
    var icons := {"Sandevistan":"◈", "Mantis Blades":"╱", "Gorilla Arms":"▣", "Pulse Core":"◎", "Reflex Booster":"ϟ", "Monowire":"⌁", "Projectile Launch System":"✦"}
    for name in descriptions:
        var row := HBoxContainer.new()
        row.custom_minimum_size = Vector2(0, 54)
        row.set_meta("implant_name", name)
        var icon := Label.new()
        icon.text = icons[name]
        icon.custom_minimum_size = Vector2(30, 0)
        icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        icon.add_theme_font_size_override("font_size", 21)
        icon.add_theme_color_override("font_color", Color(1.0, 0.72, 0.2))
        row.add_child(icon)
        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        info.add_theme_constant_override("separation", 1)
        row.add_child(info)
        var title := Label.new()
        title.text = name.to_upper()
        title.add_theme_font_size_override("font_size", 10)
        title.add_theme_color_override("font_color", Color(0.96, 0.82, 0.78))
        info.add_child(title)
        var desc := Label.new()
        desc.text = str(descriptions[name][0]) + "  //  " + str(descriptions[name][1])
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.add_theme_font_size_override("font_size", 9)
        desc.add_theme_color_override("font_color", Color(0.66, 0.48, 0.5))
        info.add_child(desc)
        var change := Button.new()
        change.custom_minimum_size = Vector2(72, 36)
        change.add_theme_font_size_override("font_size", 9)
        change.pressed.connect(_toggle_implant.bind(name))
        row.add_child(change)
        row.set_meta("change_button", change)
        var row_style := StyleBoxFlat.new()
        row_style.bg_color = Color(0.16, 0.025, 0.05, 0.95)
        row_style.border_color = Color(0.34, 0.065, 0.12)
        row_style.set_border_width_all(1)
        row_style.set_corner_radius_all(4)
        var row_panel := PanelContainer.new()
        row_panel.add_theme_stylebox_override("panel", row_style)
        row_panel.add_child(row)
        list.add_child(row_panel)

    var center_panel := PanelContainer.new()
    center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var center_style := StyleBoxFlat.new()
    center_style.bg_color = Color(0.055, 0.012, 0.025, 0.98)
    center_style.border_color = Color(0.28, 0.045, 0.09)
    center_style.set_border_width_all(1)
    center_style.set_corner_radius_all(5)
    center_panel.add_theme_stylebox_override("panel", center_style)
    columns.add_child(center_panel)
    var center_box := VBoxContainer.new()
    center_box.add_theme_constant_override("separation", 6)
    center_panel.add_child(center_box)
    _create_character_preview(center_box)

    var right_panel := PanelContainer.new()
    right_panel.custom_minimum_size = Vector2(132, 0)
    var right_style := StyleBoxFlat.new()
    right_style.bg_color = Color(0.105, 0.018, 0.035, 0.96)
    right_style.border_color = Color(0.32, 0.055, 0.11)
    right_style.set_border_width_all(1)
    right_style.set_corner_radius_all(5)
    right_panel.add_theme_stylebox_override("panel", right_style)
    columns.add_child(right_panel)
    var right_stack := VBoxContainer.new()
    right_stack.alignment = BoxContainer.ALIGNMENT_CENTER
    right_stack.add_theme_constant_override("separation", 12)
    right_panel.add_child(right_stack)
    var cap_title := Label.new()
    cap_title.text = "CAPACITY"
    cap_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cap_title.add_theme_font_size_override("font_size", 12)
    cap_title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.22))
    right_stack.add_child(cap_title)
    var capacity_bar := ProgressBar.new()
    capacity_bar.name = "CapacityBar"
    capacity_bar.min_value = 0
    capacity_bar.max_value = 7
    capacity_bar.value = 7
    capacity_bar.custom_minimum_size = Vector2(34, 250)
    capacity_bar.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
    var bar_bg := StyleBoxFlat.new()
    bar_bg.bg_color = Color(0.16, 0.045, 0.035)
    capacity_bar.add_theme_stylebox_override("background", bar_bg)
    var bar_fill := StyleBoxFlat.new()
    bar_fill.bg_color = Color(1.0, 0.72, 0.12)
    capacity_bar.add_theme_stylebox_override("fill", bar_fill)
    right_stack.add_child(capacity_bar)
    var cap_note := Label.new()
    cap_note.text = "NEURAL\nLOAD"
    cap_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cap_note.add_theme_font_size_override("font_size", 10)
    cap_note.add_theme_color_override("font_color", Color(0.92, 0.63, 0.3))
    right_stack.add_child(cap_note)
    var close := Button.new()
    close.text = "CLOSE  ×"
    close.custom_minimum_size = Vector2(106, 40)
    close.pressed.connect(_toggle_panel)
    right_stack.add_child(close)
    _refresh_panel()

    var specs := [["Sandevistan", Color(0.08, 0.24, 0.38)], ["Mantis Blades", Color(0.28, 0.08, 0.18)], ["Gorilla Arms", Color(0.28, 0.16, 0.06)], ["Pulse Core", Color(0.06, 0.28, 0.2)], ["Reflex Booster", Color(0.22, 0.2, 0.06)], ["Monowire", Color(0.02, 0.3, 0.38)], ["Projectile Launch System", Color(0.38, 0.12, 0.04)]]
    var captions := ["SAND", "MANTIS", "GORILLA", "PULSE", "REFLEX", "WIRE", "PLS"]
    for i in range(specs.size()):
        var spec = specs[i]
        var b := Button.new()
        b.text = captions[i]
        b.position = Vector2(-548 + i * 78, -72)
        b.size = Vector2(72, 48)
        b.anchor_left = 1.0
        b.anchor_top = 1.0
        b.anchor_right = 1.0
        b.anchor_bottom = 1.0
        b.add_theme_font_size_override("font_size", 9)
        b.add_theme_color_override("font_color", Color(0.96, 0.85, 0.8))
        var bs := StyleBoxFlat.new()
        bs.bg_color = spec[1]
        bs.border_color = Color(0.75, 0.18, 0.25)
        bs.set_border_width_all(1)
        bs.set_corner_radius_all(5)
        b.add_theme_stylebox_override("normal", bs)
        b.pressed.connect(_activate.bind(spec[0]))
        layer.add_child(b)
        skill_buttons[spec[0]] = b

func _create_character_preview(parent):
    var title := Label.new()
    title.text = "OPERATOR PROFILE  //  SYL-01"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 15)
    title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.2))
    parent.add_child(title)
    var preview := SubViewportContainer.new()
    preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
    preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    preview.stretch = true
    parent.add_child(preview)
    var viewport := SubViewport.new()
    viewport.size = Vector2i(480, 560)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    preview.add_child(viewport)
    var world := Node3D.new()
    viewport.add_child(world)
    var camera := Camera3D.new()
    camera.position = Vector3(0, 1.35, 4.1)
    camera.fov = 38.0
    camera.look_at(Vector3(0, 1.0, 0))
    viewport.add_child(camera)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-28, -25, 0)
    key.light_energy = 1.5
    world.add_child(key)
    var rim := OmniLight3D.new()
    rim.position = Vector3(-1.8, 2.0, -1.0)
    rim.light_color = Color(0.15, 0.55, 1.0)
    rim.light_energy = 1.8
    rim.omni_range = 5.0
    world.add_child(rim)
    var body_mat := StandardMaterial3D.new()
    body_mat.albedo_color = Color(0.025, 0.035, 0.055)
    body_mat.metallic = 0.72
    body_mat.roughness = 0.3
    var accent := StandardMaterial3D.new()
    accent.albedo_color = Color(0.75, 0.08, 0.2)
    accent.metallic = 0.65
    accent.emission_enabled = true
    accent.emission = Color(0.3, 0.015, 0.05)
    accent.emission_energy_multiplier = 0.8
    var torso := MeshInstance3D.new()
    var torso_mesh := CapsuleMesh.new()
    torso_mesh.radius = 0.31
    torso_mesh.height = 1.0
    torso.mesh = torso_mesh
    torso.position.y = 1.18
    torso.material_override = body_mat
    world.add_child(torso)
    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.2
    head_mesh.height = 0.4
    head.mesh = head_mesh
    head.position.y = 1.88
    head.material_override = body_mat
    world.add_child(head)
    for side in [-1.0, 1.0]:
        var arm := MeshInstance3D.new()
        var arm_mesh := CapsuleMesh.new()
        arm_mesh.radius = 0.105
        arm_mesh.height = 0.82
        arm.mesh = arm_mesh
        arm.position = Vector3(side * 0.4, 1.15, 0)
        arm.rotation.z = side * -0.18
        arm.material_override = accent
        world.add_child(arm)
        var leg := MeshInstance3D.new()
        var leg_mesh := CapsuleMesh.new()
        leg_mesh.radius = 0.14
        leg_mesh.height = 0.92
        leg.mesh = leg_mesh
        leg.position = Vector3(side * 0.17, 0.43, 0)
        leg.material_override = body_mat
        world.add_child(leg)
    var caption := Label.new()
    caption.text = "NEURAL LINK STABLE   //   RIPPERDOC ACCESS GRANTED"
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    caption.add_theme_font_size_override("font_size", 10)
    caption.add_theme_color_override("font_color", Color(0.68, 0.48, 0.45))
    parent.add_child(caption)

func _toggle_panel():
    panel.visible = not panel.visible
    for button in skill_buttons.values():
        button.visible = not panel.visible
    _refresh_panel()

func _toggle_implant(name):
    installed[name] = not installed[name]
    if player.has_method("set_cyber_implant"):
        player.call("set_cyber_implant", name, installed[name])
    _update_arm_implants()
    _refresh_panel()

func _refresh_panel():
    var count := 0
    for name in installed:
        if installed[name]:
            count += 1
    capacity_label.text = "INSTALLED SLOTS  %d / 7" % count
    var bar := panel.find_child("CapacityBar", true, false) as ProgressBar
    if bar != null:
        bar.value = count
    var scroll := panel.find_child("ScrollContainer", true, false) as ScrollContainer
    if scroll == null:
        return
    var list := scroll.get_child(0) as VBoxContainer
    for row_panel in list.get_children():
        if row_panel.get_child_count() == 0:
            continue
        var row := row_panel.get_child(0)
        if row.has_meta("implant_name"):
            var implant_name: String = row.get_meta("implant_name")
            var button := row.get_meta("change_button") as Button
            button.text = "REMOVE" if installed[implant_name] else "INSTALL"
            button.disabled = count >= 7 and not installed[implant_name]

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
    if name == "Mantis Blades" or name == "Gorilla Arms" or name == "Monowire":
        player.call("set_active_combat_implant", name)
    if name in ["Mantis Blades", "Gorilla Arms", "Monowire"]:
        player.call("set_active_combat_implant", name)
    var now = Time.get_ticks_msec()
    if float(cooldowns.get(name, 0)) > now:
        return
    match name:
        "Sandevistan":
            _activate_sandevistan()
            cooldowns[name] = now + 15000
        "Mantis Blades":
            player.set_meta("next_melee_bonus", 1.0)
            player.set_meta("next_melee_range", 3.0)
            player.call("_request_attack")
            cooldowns[name] = now + 7000
        "Gorilla Arms":
            player.set_meta("next_melee_bonus", 1.0)
            player.set_meta("next_melee_range", 2.5)
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
            player.set_meta("next_melee_bonus", 1.0)
            player.set_meta("next_melee_range", 4.8)
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
    dummy.collision_layer = 2
    dummy.collision_mask = 1
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
    dummy.global_position = player.global_position + (player.global_transform.basis.x * 2.8) + (-player.global_transform.basis.z * 2.35)
