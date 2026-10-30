extends Node2D
## Mochi wanders, visits purchased furniture and takes naps by his own choice.
@onready var bear: AnimatedSprite2D = $BearSprite
@onready var heart: Sprite2D = $HappyHeart

var right_bound: float = 780.0
var left_bound: float = 130.0
var state: String = "idle"
var state_time: float = 1.5
var feeding_time: float = 0.0
var heart_time: float = 0.0
var walk_speed: float = 82.0
var target_x: float = 415.0
var next_idle: String = "idle"
var visual_clock: float = 0.0

func _ready() -> void:
    randomize()
    GameState.pet_fed.connect(_on_fed)
    GameState.focus_completed.connect(_on_focus_completed)
    _change_state("idle")

func _process(delta: float) -> void:
    visual_clock += delta
    # Keep pixels on integer positions, avoiding blurry/jittery sub-pixels.
    # The sprite's feet remain aligned to the same world ground line.
    if state == "walk":
        bear.position.y = -45.0 + roundf(sin(visual_clock * 12.0))
    elif state == "idle":
        bear.position.y = -45.0 + roundf(sin(visual_clock * 2.4))
    else:
        bear.position.y = -45.0
    if heart_time > 0.0:
        heart_time -= delta
        heart.visible = heart_time > 0.0
    if feeding_time > 0.0:
        feeding_time -= delta
        if feeding_time <= 0.0:
            _change_state("idle")
        return
    if state == "walk":
        var difference: float = target_x - position.x
        bear.flip_h = difference < 0.0
        position.x = move_toward(position.x, target_x, walk_speed * delta)
        if absf(target_x - position.x) < 1.5:
            _change_state(next_idle)
            state_time = randf_range(2.0, 4.8)
    else:
        state_time -= delta
        if state_time <= 0.0:
            _pick_next_state()

func _pick_next_state() -> void:
    var roll: float = randf()
    if roll < 0.20 and bool(GameState.upgrades.get("bed", false)):
        target_x = 490.0
        next_idle = "sleep"
    elif roll < 0.37 and bool(GameState.upgrades.get("pond", false)):
        target_x = 787.0
        next_idle = "idle"
    else:
        target_x = clampf(position.x + randf_range(-250.0, 250.0), left_bound, right_bound)
        next_idle = "sleep" if randf() < 0.13 else "idle"
    _change_state("walk")
    state_time = 0.0

func _change_state(new_state: String) -> void:
    state = new_state
    if bear.animation != StringName(new_state) or not bear.is_playing():
        bear.play(new_state)

func _on_fed() -> void:
    _change_state("eat")
    feeding_time = 1.8
    heart_time = 2.5
    heart.visible = true

func set_more_land(enabled: bool) -> void:
    right_bound = 820.0 + float(GameState.upgrade_count("land")) * 560.0
    target_x = clampf(target_x, left_bound, right_bound)

func _on_focus_completed(_minutes: int, _reward: int) -> void:
    heart_time = 2.5
    heart.visible = true

func visit_camera_region(camera_x: float) -> void:
    # No teleporting. When you switch clearings, Mochi travels toward you
    # at normal walking speed. The camera stays independent of the bear.
    if absf(position.x - camera_x) > 280.0:
        target_x = clampf(camera_x, left_bound, right_bound)
        next_idle = "idle"
        _change_state("walk")
