extends Control
## V6 planner with editor-visible columns, custom board tabs and a compact editor.
## Daily habits stay in Daily Habits even when checked, so resets are obvious.

const CARD_SCENE: PackedScene = preload("res://scenes/board_card.tscn")

@onready var board_buttons: HBoxContainer = $BoardMargin/Stack/BoardBar/BoardScroll/BoardButtons
@onready var new_task_button: Button = $BoardMargin/Stack/Heading/NewTaskButton
@onready var new_board_button: Button = $BoardMargin/Stack/BoardBar/NewBoardButton
@onready var delete_board_button: Button = $BoardMargin/Stack/BoardBar/DeleteBoardButton
@onready var status_label: Label = $BoardMargin/Stack/InfoLine/StatusLabel
@onready var count_label: Label = $BoardMargin/Stack/InfoLine/CountLabel
@onready var editor: Control = $TaskEditor
@onready var board_overlay: Control = $NewBoardOverlay
@onready var board_name_input: LineEdit = $NewBoardOverlay/BoardPanel/Padding/Stack/BoardNameInput
@onready var board_error: Label = $NewBoardOverlay/BoardPanel/Padding/Stack/BoardError
@onready var board_save_button: Button = $NewBoardOverlay/BoardPanel/Padding/Stack/Buttons/SaveButton
@onready var board_cancel_button: Button = $NewBoardOverlay/BoardPanel/Padding/Stack/Buttons/CancelButton
@onready var delete_board_dialog: ConfirmationDialog = $DeleteBoardDialog
@onready var delete_task_dialog: ConfirmationDialog = $DeleteTaskDialog

var selected_board: String = "All"
var pending_delete_task: int = -1
var toast_seconds: float = 0.0
var columns: Dictionary = {}
var empty_labels: Dictionary = {}

func _ready() -> void:
    for key in ["Today", "Upcoming", "Habits", "Done"]:
        var prefix: String = "BoardMargin/Stack/ColumnRow/%sColumn/Layout/" % key
        columns[key] = get_node(prefix + "TaskScroll/TaskCards")
        empty_labels[key] = get_node(prefix + "EmptyLabel")
    new_task_button.pressed.connect(_open_new)
    new_board_button.pressed.connect(_open_new_board)
    delete_board_button.pressed.connect(_ask_delete_board)
    board_save_button.pressed.connect(_create_board)
    board_cancel_button.pressed.connect(func() -> void: board_overlay.hide())
    board_name_input.text_submitted.connect(func(_value: String) -> void: _create_board())
    delete_board_dialog.confirmed.connect(_delete_selected_board)
    delete_task_dialog.confirmed.connect(_delete_pending_task)
    GameState.tasks_changed.connect(_refresh)
    GameState.boards_changed.connect(_boards_changed)
    GameState.task_rewarded.connect(_on_task_rewarded)
    GameState.task_undone.connect(_on_task_undone)
    _rebuild_board_tabs()
    _set_board("All")
    board_overlay.hide()

func _process(delta: float) -> void:
    if toast_seconds > 0.0:
        toast_seconds -= delta
        if toast_seconds <= 0.0:
            _show_daily_status()

func _show_daily_status() -> void:
    status_label.text = "TODAY %s  |  Daily habits reset at local midnight (no Wi-Fi needed)." % GameState.today_string()
    status_label.remove_theme_color_override("font_color")

func _on_task_rewarded(_title: String, amount: int) -> void:
    status_label.text = "NICE WORK! +%d coins for Mochi!" % amount
    status_label.add_theme_color_override("font_color", Color("#4C7852"))
    toast_seconds = 3.0

func _on_task_undone(_title: String, amount: int) -> void:
    status_label.text = "UNDONE - %d coins returned to your task balance." % amount
    status_label.add_theme_color_override("font_color", Color("#8D6748"))
    toast_seconds = 3.0

func _boards_changed() -> void:
    _rebuild_board_tabs()
    _refresh()

func _rebuild_board_tabs() -> void:
    for child in board_buttons.get_children():
        board_buttons.remove_child(child)
        child.queue_free()
    for board in ["All"] + GameState.boards:
        var tab: Button = Button.new()
        tab.text = str(board).to_upper()
        tab.custom_minimum_size = Vector2(100, 32)
        tab.add_theme_font_size_override("font_size", 13)
        board_buttons.add_child(tab)
        tab.pressed.connect(_set_board.bind(str(board)))
        tab.disabled = str(board) == selected_board

func _set_board(board: String) -> void:
    if board != "All" and not GameState.boards.has(board):
        board = "All"
    selected_board = board
    for tab in board_buttons.get_children():
        tab.disabled = tab.text == board.to_upper()
    delete_board_button.disabled = board in ["All", "School", "Personal", "Projects"]
    _refresh()

func _column_for(task: Dictionary) -> String:
    if str(task.get("kind", "once")) == "daily":
        return "Habits"
    if GameState.task_is_done(task):
        return "Done"
    var due: String = str(task.get("due_date", ""))
    if not due.is_empty() and due > GameState.today_string():
        return "Upcoming"
    return "Today"

func _refresh() -> void:
    for column in columns.values():
        for child in column.get_children():
            column.remove_child(child)
            child.queue_free()
    var shown_count: int = 0
    var completed_count: int = 0
    var all_tasks: Array = GameState.tasks.duplicate()
    all_tasks.sort_custom(_sort_tasks)
    for task in all_tasks:
        if selected_board != "All" and str(task.get("board", "Personal")) != selected_board:
            continue
        var column_key: String = _column_for(task)
        var card: PanelContainer = CARD_SCENE.instantiate()
        columns[column_key].add_child(card)
        card.call("set_task", task)
        card.connect("edit_requested", _open_edit)
        card.connect("delete_requested", _ask_delete_task)
        shown_count += 1
        if GameState.task_is_done(task):
            completed_count += 1
    for key in empty_labels:
        empty_labels[key].visible = columns[key].get_child_count() == 0
    count_label.text = "%d / %d done" % [completed_count, shown_count]
    if toast_seconds <= 0.0:
        _show_daily_status()

func _sort_tasks(a: Dictionary, b: Dictionary) -> bool:
    var a_date: String = str(a.get("due_date", ""))
    var b_date: String = str(b.get("due_date", ""))
    if a_date.is_empty():
        a_date = "9999-12-31"
    if b_date.is_empty():
        b_date = "9999-12-31"
    if a_date != b_date:
        return a_date < b_date
    return int(a.get("id", 0)) < int(b.get("id", 0))

func _open_new() -> void:
    editor.call("open_new", selected_board if selected_board != "All" else "Personal")

func _open_edit(task_id: int) -> void:
    editor.call("open_edit", task_id)

func _open_new_board() -> void:
    board_name_input.text = ""
    board_error.text = ""
    board_overlay.show()
    board_name_input.grab_focus()

func _create_board() -> void:
    var name: String = board_name_input.text.strip_edges()
    if GameState.add_board(name):
        board_overlay.hide()
        _set_board(name)
    else:
        board_error.text = "Enter a unique name (1-24 characters, max 16 boards)."

func _ask_delete_board() -> void:
    if selected_board in ["All", "School", "Personal", "Projects"]:
        return
    delete_board_dialog.dialog_text = "Remove '%s'? Its tasks will move to Personal. Nothing is lost." % selected_board
    delete_board_dialog.popup_centered(Vector2i(480, 180))

func _delete_selected_board() -> void:
    GameState.delete_board(selected_board)
    _set_board("All")

func _ask_delete_task(task_id: int, title: String) -> void:
    pending_delete_task = task_id
    delete_task_dialog.dialog_text = "Delete '%s'? Coins already earned will be kept. To undo a reward, uncheck the task first." % title
    delete_task_dialog.popup_centered(Vector2i(500, 190))

func _delete_pending_task() -> void:
    if pending_delete_task >= 0:
        GameState.delete_task(pending_delete_task)
    pending_delete_task = -1
