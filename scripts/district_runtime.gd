extends Node3D

const NPC_SCRIPT = preload("res://scripts/city_npc.gd")
const VEHICLE_SCRIPT = preload("res://scripts/city_vehicle.gd")

func _ready() -> void:
    set_meta("world_time_scale", 1.0)
    _create_mobile_environment()
    call_deferred("_populate_streets")

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
    environment.fog_enabled = true
    environment.fog_light_color = Color(0.035, 0.055, 0.12)
    environment.fog_density = 0.0045
    environment.glow_enabled = true
    environment.glow_intensity = 0.45
    environment.glow_strength = 0.65
    world.environment = environment
    add_child(world)

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
        var npc := Node3D.new()
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
