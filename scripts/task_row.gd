extends PanelContainer
## Each task row is editor-visible in scenes/task_row.tscn.
signal edit_requested(task_id: int)

@onready var check: CheckBox = $Padding/Contents/Details/TaskCheck
@onready var detail_label: Label = $Padding/Contents/Details/MetaLabel
@onready var reward: Label = $Padding/Contents/Actions/RewardLabel
@onready var edit_button: Button = $Padding/Contents/Actions/RowButtons/EditButton
@onready var delete_button: Button = $Padding/Contents/Actions/RowButtons/DeleteButton
var task_id: int = -1

func set_task(task_data: Dictionary) -> void:
    task_id = int(task_data.get("id", -1))
    var name: String = str(task_data.get("title", "Untitled"))
    check.text = name.substr(0, 24) + ("..." if name.length() > 24 else "")
    check.tooltip_text = name if name.length() > 24 else ""
    var done: bool = GameState.task_is_done(task_data)
    var active: bool = GameState.task_is_active(task_data)
    check.set_pressed_no_signal(done)
    # Completed tasks remain clickable so mistakes can be reversed.
    check.disabled = not active
    var kind: String = str(task_data.get("kind", "once"))
    var due: String = str(task_data.get("due_date", ""))
    var size: String = str(task_data.get("size", "medium")).to_upper()
    if kind == "daily":
        var start: String = str(task_data.get("start_date", ""))
        var end: String = str(task_data.get("end_date", ""))
        detail_label.text = "DAILY  |  %s" % ("starts " + start if not active and GameState.today_string() < start else ("ended " + end if not active else "due today"))
    elif GameState.task_is_overdue(task_data):
        detail_label.text = "OVERDUE  |  %s" % due
    elif due.is_empty():
        detail_label.text = "ANYTIME"
    else:
        detail_label.text = "DUE  |  %s" % due
    var paid: int = int(task_data.get("reward_paid", GameState.task_reward(task_data)))
    reward.text = ("UNDO -%d" % paid) if done else ("%s +%d" % [size, GameState.task_reward(task_data)])
    check.toggled.connect(_on_toggled)
    edit_button.pressed.connect(_on_edit)
    delete_button.pressed.connect(_on_delete)

func _on_toggled(is_checked: bool) -> void:
    var success: bool = GameState.finish_task(task_id) if is_checked else GameState.unfinish_task(task_id)
    if not success:
        # Restore the visual state if the action is rejected (e.g. inactive day).
        check.set_pressed_no_signal(not is_checked)

func _on_edit() -> void:
    edit_requested.emit(task_id)

func _on_delete() -> void:
    GameState.delete_task(task_id)
