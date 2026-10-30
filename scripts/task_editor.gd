extends Control
## Compact full-height task editor, visually editable in scenes/task_editor.tscn.
## No ScrollContainer: every field and the Save button stays visible.
signal form_closed

@onready var panel: PanelContainer = $EditorPanel
@onready var title_label: Label = $EditorPanel/Padding/Stack/Heading/Title
@onready var close_button: Button = $EditorPanel/Padding/Stack/Heading/CloseButton
@onready var name_input: LineEdit = $EditorPanel/Padding/Stack/NameInput
@onready var kind_select: OptionButton = $EditorPanel/Padding/Stack/FirstRow/KindField/KindSelect
@onready var size_select: OptionButton = $EditorPanel/Padding/Stack/FirstRow/SizeField/SizeSelect
@onready var board_select: OptionButton = $EditorPanel/Padding/Stack/SecondRow/BoardField/BoardSelect
@onready var date_input: LineEdit = $EditorPanel/Padding/Stack/SecondRow/DateField/DateInput
@onready var date_label: Label = $EditorPanel/Padding/Stack/SecondRow/DateField/DateLabel
@onready var extra_row: HBoxContainer = $EditorPanel/Padding/Stack/ExtraRow
@onready var end_input: LineEdit = $EditorPanel/Padding/Stack/ExtraRow/EndField/EndInput
@onready var quick_row: HBoxContainer = $EditorPanel/Padding/Stack/QuickRow
@onready var today_button: Button = $EditorPanel/Padding/Stack/QuickRow/TodayButton
@onready var tomorrow_button: Button = $EditorPanel/Padding/Stack/QuickRow/TomorrowButton
@onready var week_button: Button = $EditorPanel/Padding/Stack/QuickRow/WeekButton
@onready var help_label: Label = $EditorPanel/Padding/Stack/HelpLabel
@onready var error_label: Label = $EditorPanel/Padding/Stack/ErrorLabel
@onready var save_button: Button = $EditorPanel/Padding/Stack/Buttons/SaveButton
@onready var cancel_button: Button = $EditorPanel/Padding/Stack/Buttons/CancelButton

var edit_id: int = -1

func _ready() -> void:
    kind_select.add_item("Just today", 0)
    kind_select.add_item("One-time / project", 1)
    kind_select.add_item("Every day", 2)
    size_select.add_item("Small  +15", 0)
    size_select.add_item("Medium  +40", 1)
    size_select.add_item("Huge  +100", 2)
    kind_select.item_selected.connect(_kind_changed)
    today_button.pressed.connect(func() -> void: date_input.text = GameState.today_string())
    tomorrow_button.pressed.connect(func() -> void: date_input.text = GameState.tomorrow_string())
    week_button.pressed.connect(func() -> void: date_input.text = GameState.date_after_days(7))
    close_button.pressed.connect(close)
    cancel_button.pressed.connect(close)
    save_button.pressed.connect(_save)
    name_input.text_submitted.connect(func(_name: String) -> void: _save())
    hide()

func _load_boards(selected: String) -> void:
    board_select.clear()
    var index: int = 0
    for board in GameState.boards:
        board_select.add_item(str(board))
        if str(board) == selected:
            index = board_select.item_count - 1
    board_select.select(index)

func open_new(board: String) -> void:
    edit_id = -1
    title_label.text = "CREATE A TASK"
    save_button.text = "ADD TASK +"
    name_input.text = ""
    kind_select.select(0)
    size_select.select(1)
    _load_boards(GameState.clean_board(board))
    date_input.text = GameState.today_string()
    end_input.text = ""
    error_label.text = ""
    _kind_changed(0)
    show()
    name_input.grab_focus()

func open_edit(task_id: int) -> void:
    for task in GameState.tasks:
        if int(task.get("id", -1)) != task_id:
            continue
        edit_id = task_id
        title_label.text = "EDIT TASK"
        save_button.text = "SAVE CHANGES"
        name_input.text = str(task.get("title", ""))
        var kind: String = str(task.get("kind", "once"))
        kind_select.select(maxi(0, ["today", "once", "daily"].find(kind)))
        size_select.select(maxi(0, ["small", "medium", "huge"].find(str(task.get("size", "medium")))))
        _load_boards(str(task.get("board", "Personal")))
        date_input.text = str(task.get("start_date", "")) if kind == "daily" else str(task.get("due_date", ""))
        end_input.text = str(task.get("end_date", ""))
        error_label.text = ""
        _kind_changed(kind_select.selected)
        show()
        name_input.grab_focus()
        return

func _kind_changed(index: int) -> void:
    date_label.text = "START DATE" if index == 2 else "DUE DATE"
    date_input.editable = index != 0
    date_input.modulate.a = 1.0 if index != 0 else 0.55
    extra_row.visible = index == 2
    quick_row.visible = index != 0
    if index == 0:
        date_input.text = GameState.today_string()
        help_label.text = "One-time task due today. You can finish it whenever you like."
    elif index == 1:
        help_label.text = "One-time task. Leave the due date blank if there is no deadline."
    else:
        help_label.text = "Resets at local midnight. Completing it earns coins once per day."
    error_label.text = ""

func _save() -> void:
    var kinds: Array = ["today", "once", "daily"]
    var sizes: Array = ["small", "medium", "huge"]
    var kind: String = str(kinds[kind_select.selected])
    var size: String = str(sizes[size_select.selected])
    var board: String = board_select.get_item_text(board_select.selected)
    var due: String = date_input.text.strip_edges() if kind != "today" else GameState.today_string()
    var end: String = end_input.text.strip_edges() if kind == "daily" else ""
    if name_input.text.strip_edges().is_empty():
        error_label.text = "Please name your task."
        return
    if not due.is_empty() and not GameState.valid_date(due):
        error_label.text = "Enter a valid date (YYYY-MM-DD)."
        return
    if not end.is_empty() and not GameState.valid_date(end):
        error_label.text = "End date must be YYYY-MM-DD."
        return
    if kind == "daily" and not end.is_empty() and end < (due if not due.is_empty() else GameState.today_string()):
        error_label.text = "End date must be after the start date."
        return
    var ok: bool
    if edit_id < 0:
        ok = GameState.add_task(name_input.text, kind, size, due, end, board)
    else:
        ok = GameState.update_task(edit_id, name_input.text, kind, size, due, end, board)
    if ok:
        close()
    else:
        error_label.text = "Could not save. Check the task details."

func close() -> void:
    hide()
    edit_id = -1
    form_closed.emit()
