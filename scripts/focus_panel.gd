extends ScrollContainer
## V6.2: compact timer, scroll-safe on smaller windows, still runs when hidden.
## Uses monotonic ticks so pausing the editor/window does not add frame drift.

@onready var timer_label: Label = $Content/TimerCard/TimerMargin/TimerStack/TimerLabel
@onready var progress_bar: ProgressBar = $Content/TimerCard/TimerMargin/TimerStack/ProgressBar
@onready var time_label: Label = $Content/TimerCard/TimerMargin/TimerStack/TimeLabel
@onready var mode_select: OptionButton = $Content/HeaderRow/ModeSelect
@onready var start_pause_button: Button = $Content/ActionButtons/StartPauseButton
@onready var reset_button: Button = $Content/ActionButtons/ResetButton
@onready var message_label: Label = $Content/MessageLabel
@onready var stats_label: Label = $Content/StatsLabel
@onready var short_button: Button = $Content/DurationButtons/ShortButton
@onready var classic_button: Button = $Content/DurationButtons/ClassicButton
@onready var long_button: Button = $Content/DurationButtons/LongButton
@onready var test_button: Button = $Content/DurationButtons/TestButton
@onready var custom_minutes: SpinBox = $Content/CustomRow/CustomMinutes
@onready var apply_custom: Button = $Content/CustomRow/ApplyCustom

var duration_minutes: int = 25
var seconds_left: int = 25 * 60
var deadline_ms: int = 0
var timer_state: String = "idle"  # idle / running / paused / complete
var timer_mode: String = "study" # study / break

func _ready() -> void:
    mode_select.add_item("STUDY")
    mode_select.add_item("BREAK")
    mode_select.select(0)
    mode_select.item_selected.connect(_choose_mode)
    short_button.pressed.connect(_choose_duration.bind(5))
    classic_button.pressed.connect(_choose_duration.bind(25))
    long_button.pressed.connect(_choose_duration.bind(45))
    test_button.pressed.connect(_choose_duration.bind(1))
    apply_custom.pressed.connect(_apply_custom)
    start_pause_button.pressed.connect(_toggle_timer)
    reset_button.pressed.connect(_reset_timer)
    GameState.focus_completed.connect(_on_focus_completed)
    _refresh()

func _process(_delta: float) -> void:
    if timer_state != "running":
        return
    seconds_left = maxi(0, int(ceil(float(deadline_ms - Time.get_ticks_msec()) / 1000.0)))
    if seconds_left == 0:
        _complete_session()
    else:
        _refresh()

func _choose_mode(index: int) -> void:
    if timer_state == "running" or timer_state == "paused":
        return
    timer_mode = "study" if index == 0 else "break"
    seconds_left = duration_minutes * 60
    timer_state = "idle"
    message_label.text = "Mochi is rooting for you!" if timer_mode == "study" else "Time to recharge."
    _refresh()

func _choose_duration(minutes: int) -> void:
    if timer_state == "running" or timer_state == "paused":
        return
    duration_minutes = minutes
    seconds_left = minutes * 60
    timer_state = "idle"
    message_label.text = "Ready when you are."
    _refresh()

func _apply_custom() -> void:
    _choose_duration(int(custom_minutes.value))

func _toggle_timer() -> void:
    if timer_state == "running":
        seconds_left = maxi(0, int(ceil(float(deadline_ms - Time.get_ticks_msec()) / 1000.0)))
        if seconds_left == 0:
            _complete_session()
            return
        timer_state = "paused"
        message_label.text = "Paused."
    else:
        if timer_state == "complete":
            seconds_left = duration_minutes * 60
        deadline_ms = Time.get_ticks_msec() + seconds_left * 1000
        timer_state = "running"
        message_label.text = "You've got this!"
    _refresh()

func _reset_timer() -> void:
    timer_state = "idle"
    seconds_left = duration_minutes * 60
    message_label.text = "Timer reset. No coins awarded."
    _refresh()

func _complete_session() -> void:
    if timer_state != "running":
        return
    timer_state = "complete"
    seconds_left = 0
    if timer_mode == "study":
        GameState.complete_focus_session(duration_minutes)
        message_label.text = "Nice work! You earned coins."
    else:
        message_label.text = "Break finished. Ready to go?"
    _refresh()

func _on_focus_completed(_minutes: int, _reward: int) -> void:
    _refresh()

func _refresh() -> void:
    var minutes: int = int(seconds_left / 60)
    var seconds: int = seconds_left % 60
    timer_label.text = "%02d:%02d" % [minutes, seconds]
    progress_bar.value = 100.0 * (1.0 - float(seconds_left) / float(maxi(1, duration_minutes * 60)))
    start_pause_button.text = {
        "idle": "START", "running": "PAUSE",
        "paused": "RESUME", "complete": "AGAIN",
    }.get(timer_state, "START")
    var locked: bool = timer_state == "running" or timer_state == "paused"
    for button in [short_button, classic_button, long_button, test_button, apply_custom]:
        button.disabled = locked
    mode_select.disabled = locked
    custom_minutes.editable = not locked
    var reward: int = duration_minutes * GameState.FOCUS_REWARD_PER_MINUTE if timer_mode == "study" else 0
    time_label.text = "%d min %s  |  +%d coins" % [duration_minutes, timer_mode, reward]
    stats_label.text = "%d sessions | %d min total | %d today" % [GameState.focus_sessions, GameState.focus_minutes_total, GameState.focus_minutes_today]
