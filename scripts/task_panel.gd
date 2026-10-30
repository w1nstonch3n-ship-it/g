extends VBoxContainer
signal form_closed
## Editable task creator. Change the labels and buttons in scenes/task_panel.tscn.
## One-time deadlines are optional. Daily repeats are due EVERY active day.

const TASK_ROW: PackedScene = preload("res://scenes/task_row.tscn")

@onready var new_button: Button = $NewTaskButton
@onready var form_panel: PanelContainer = $FormPanel
@onready var title_input: LineEdit = $FormPanel/FormScroll/FormPadding/FormStack/TitleInput
@onready var kind_select: OptionButton = $FormPanel/FormScroll/FormPadding/FormStack/KindSelect
@onready var size_select: OptionButton = $FormPanel/FormScroll/FormPadding/FormStack/SizeSelect
@onready var board_select: OptionButton = $FormPanel/FormScroll/FormPadding/FormStack/BoardSelect
@onready var date_label: Label = $FormPanel/FormScroll/FormPadding/FormStack/DateLabel
@onready var date_input: LineEdit = $FormPanel/FormScroll/FormPadding/FormStack/DateInput
@onready var quick_dates: HBoxContainer = $FormPanel/FormScroll/FormPadding/FormStack/QuickDates
@onready var today_button: Button = $FormPanel/FormScroll/FormPadding/FormStack/QuickDates/TodayButton
@onready var tomorrow_button: Button = $FormPanel/FormScroll/FormPadding/FormStack/QuickDates/TomorrowButton
@onready var week_button: Button = $FormPanel/FormScroll/FormPadding/FormStack/QuickDates/WeekButton
@onready var end_label: Label = $FormPanel/FormScroll/FormPadding/FormStack/EndLabel
@onready var end_input: LineEdit = $FormPanel/FormScroll/FormPadding/FormStack/EndInput
@onready var form_error: Label = $FormPanel/FormScroll/FormPadding/FormStack/FormError
@onready var save_button: Button = $FormPanel/FormScroll/FormPadding/FormStack/FormButtons/SaveTaskButton
@onready var cancel_button: Button = $FormPanel/FormScroll/FormPadding/FormStack/FormButtons/CancelButton
@onready var today_filter: Button = $TaskFilters/TodayFilter
@onready var all_filter: Button = $TaskFilters/AllFilter
@onready var rows: VBoxContainer = $TaskScroll/TaskRows
@onready var progress_label: Label = $ProgressLabel

var edit_task_id: int = -1
var filter_mode: String = "today"
var editor_only: bool = false

func _ready() -> void:
    kind_select.add_item("Today (one-time)", 0)
    kind_select.add_item("Schedule once", 1)
    kind_select.add_item("Repeat every day", 2)
    size_select.add_item("Small  |  +15 coins", 0)
    size_select.add_item("Medium  |  +40 coins", 1)
    size_select.add_item("Huge  |  +100 coins", 2)
    board_select.add_item("School")
    board_select.add_item("Personal")
    board_select.add_item("Projects")
    new_button.pressed.connect(_new_task)
    save_button.pressed.connect(_save_task)
    cancel_button.pressed.connect(_close_form)
    title_input.text_submitted.connect(_on_title_submitted)
    kind_select.item_selected.connect(_kind_changed)
    today_button.pressed.connect(_date_today)
    tomorrow_button.pressed.connect(_date_tomorrow)
    week_button.pressed.connect(_date_next_week)
    today_filter.pressed.connect(_filter_today)
    all_filter.pressed.connect(_filter_all)
    GameState.tasks_changed.connect(_refresh)
    _set_filter("today")
    _close_form()

func use_as_editor() -> void:
    editor_only = true
    $SectionTitle.hide()
    $SectionHint.hide()
    new_button.hide()
    $TaskFilters.hide()
    $TaskScroll.hide()
    progress_label.hide()

func open_new(board: String) -> void:
    _new_task()
    board_select.select(["School", "Personal", "Projects"].find(GameState.clean_board(board)))

func open_edit(task_id: int) -> void:
    _edit_task(task_id)

func _on_title_submitted(_text: String) -> void:
    _save_task()

func _date_today() -> void:
    date_input.text = GameState.today_string()

func _date_tomorrow() -> void:
    date_input.text = GameState.date_after_days(1)

func _date_next_week() -> void:
    date_input.text = GameState.date_after_days(7)

func _filter_today() -> void:
    _set_filter("today")

func _filter_all() -> void:
    _set_filter("all")

func _new_task() -> void:
    edit_task_id = -1
    title_input.text = ""
    kind_select.select(0)
    size_select.select(1)
    board_select.select(1)
    date_input.text = GameState.today_string()
    end_input.text = ""
    form_error.text = ""
    save_button.text = "CREATE TASK"
    form_panel.show()
    _kind_changed(0)
    title_input.grab_focus()

func _edit_task(task_id: int) -> void:
    for task in GameState.tasks:
        if int(task.get("id", -1)) != task_id:
            continue
        edit_task_id = task_id
        title_input.text = str(task.get("title", ""))
        var kind: String = str(task.get("kind", "once"))
        kind_select.select(["today", "once", "daily"].find(kind))
        var size: String = str(task.get("size", "medium"))
        size_select.select(["small", "medium", "huge"].find(size))
        board_select.select(["School", "Personal", "Projects"].find(GameState.clean_board(str(task.get("board", "Personal")))))
        date_input.text = str(task.get("start_date", "")) if kind == "daily" else str(task.get("due_date", ""))
        end_input.text = str(task.get("end_date", ""))
        form_error.text = ""
        save_button.text = "SAVE CHANGES"
        form_panel.show()
        _kind_changed(kind_select.selected)
        title_input.grab_focus()
        return

func _kind_changed(index: int) -> void:
    date_label.visible = index != 0
    date_input.visible = index != 0
    quick_dates.visible = index != 0
    end_label.visible = index == 2
    end_input.visible = index == 2
    if index == 1:
        date_label.text = "DUE DATE (YYYY-MM-DD; blank = anytime)"
    elif index == 2:
        date_label.text = "FIRST DAY (YYYY-MM-DD; blank = today)"
    if index == 0:
        form_error.text = "Due today; does not repeat."
    elif index == 2:
        form_error.text = "Due every day until the optional end date."
    else:
        form_error.text = ""

func _save_task() -> void:
    var kinds: Array = ["today", "once", "daily"]
    var sizes: Array = ["small", "medium", "huge"]
    var kind: String = str(kinds[kind_select.selected])
    var size: String = str(sizes[size_select.selected])
    var board: String = ["School", "Personal", "Projects"][board_select.selected]
    var due: String = date_input.text.strip_edges() if kind != "today" else GameState.today_string()
    var end: String = end_input.text.strip_edges() if kind == "daily" else ""
    if title_input.text.strip_edges().is_empty():
        form_error.text = "Give the task a name."
        return
    if not due.is_empty() and not GameState.valid_date(due):
        form_error.text = "Use a real date: YYYY-MM-DD."
        return
    if not end.is_empty() and not GameState.valid_date(end):
        form_error.text = "End date must be YYYY-MM-DD."
        return
    if kind == "daily" and not end.is_empty() and end < (due if not due.is_empty() else GameState.today_string()):
        form_error.text = "End date must be on/after the first day."
        return
    var success: bool = false
    if edit_task_id < 0:
        success = GameState.add_task(title_input.text, kind, size, due, end, board)
    else:
        success = GameState.update_task(edit_task_id, title_input.text, kind, size, due, end, board)
    if success:
        _close_form()
    else:
        form_error.text = "Couldn't save. Check the fields."

func _close_form() -> void:
    form_panel.hide()
    if editor_only:
        form_closed.emit()
    edit_task_id = -1
    form_error.text = ""

func _set_filter(mode: String) -> void:
    filter_mode = mode
    today_filter.disabled = mode == "today"
    all_filter.disabled = mode == "all"
    _refresh()

func _refresh() -> void:
    for child in rows.get_children():
        rows.remove_child(child)
        child.queue_free()
    var visible_tasks: Array = GameState.tasks_for_view(filter_mode)
    var done_count: int = 0
    for task in visible_tasks:
        var row := TASK_ROW.instantiate()
        rows.add_child(row)
        row.call("set_task", task)
        row.connect("edit_requested", _edit_task)
        if GameState.task_is_done(task):
            done_count += 1
    progress_label.text = "%d / %d completed  |  %s" % [done_count, visible_tasks.size(), "Today" if filter_mode == "today" else "All tasks"]
