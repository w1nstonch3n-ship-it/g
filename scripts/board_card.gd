extends PanelContainer
## Scene-editable card with complete, edit and delete actions.
signal edit_requested(task_id: int)
signal delete_requested(task_id: int, title: String)

@onready var check: CheckBox = $CardStack/TopLine/TaskCheck
@onready var edit_button: Button = $CardStack/TopLine/EditButton
@onready var delete_button: Button = $CardStack/TopLine/DeleteButton
@onready var meta_label: Label = $CardStack/MetaLabel
@onready var reward_label: Label = $CardStack/RewardLabel
var task_id: int = -1
var task_title: String = ""

func _ready() -> void:
    check.toggled.connect(_on_toggled)
    edit_button.pressed.connect(func() -> void: edit_requested.emit(task_id))
    delete_button.pressed.connect(func() -> void: delete_requested.emit(task_id, task_title))
    var ink: Color = Color("#3D352B")
    for key in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
        check.add_theme_color_override(key, ink)

func set_task(task_data: Dictionary) -> void:
    task_id = int(task_data.get("id", -1))
    task_title = str(task_data.get("title", "Untitled"))
    var cutoff: int = 22
    check.text = task_title.substr(0, cutoff) + ("..." if task_title.length() > cutoff else "")
    check.tooltip_text = task_title if task_title.length() > cutoff else ""
    var completed: bool = GameState.task_is_done(task_data)
    check.set_pressed_no_signal(completed)
    check.disabled = not GameState.task_is_active(task_data)
    var board: String = str(task_data.get("board", "Personal")).to_upper()
    var kind: String = str(task_data.get("kind", "once"))
    var due: String = str(task_data.get("due_date", ""))
    var due_text: String = "ANYTIME"
    if kind == "daily":
        if completed:
            due_text = "DONE TODAY - BACK TOMORROW"
        elif not GameState.task_is_active(task_data):
            var start: String = str(task_data.get("start_date", ""))
            var end: String = str(task_data.get("end_date", ""))
            due_text = "STARTS " + start if start > GameState.today_string() else "ENDED " + end
        else:
            due_text = "DAILY - RESETS AT MIDNIGHT"
    elif GameState.task_is_overdue(task_data):
        due_text = "OVERDUE " + due
    elif not due.is_empty():
        due_text = "DUE " + due
    meta_label.text = "%s  |  %s" % [board, due_text]
    var size: String = str(task_data.get("size", "medium")).to_upper()
    if completed:
        reward_label.text = "DONE TODAY - uncheck to undo" if kind == "daily" else "COMPLETED - uncheck to undo"
    else:
        reward_label.text = "%s  +%d COINS" % [size, GameState.task_reward(task_data)]

func _on_toggled(is_checked: bool) -> void:
    var success: bool = GameState.finish_task(task_id) if is_checked else GameState.unfinish_task(task_id)
    if not success:
        check.set_pressed_no_signal(not is_checked)
