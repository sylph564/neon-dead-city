extends StaticBody3D

var total_damage := 0.0
var first_hit_ms := 0
var last_hit_ms := 0
var health := 100000.0
@onready var readout: Label3D = $DamageReadout

func take_damage(amount: float) -> void:
    var now := Time.get_ticks_msec()
    if now - last_hit_ms > 3000:
        total_damage = 0.0
        first_hit_ms = now
    if first_hit_ms == 0:
        first_hit_ms = now
    last_hit_ms = now
    total_damage += amount
    health -= amount
    var elapsed := maxf(0.25, float(now - first_hit_ms) / 1000.0)
    var dps := total_damage / elapsed
    readout.text = "DAMAGE  %.0f\nDPS  %.1f\nTOTAL  %.0f" % [amount, dps, total_damage]
