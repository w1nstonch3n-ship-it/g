extends PanelContainer
signal plot_changed(plot_index: int)
## Arrows or Shift+wheel pan, +/- or Ctrl+wheel zoom the forest only.
@onready var camera: Camera2D = $ViewportFrame/WorldViewport/Camera
@onready var habitat: Node2D = $ViewportFrame/WorldViewport/Habitat
@onready var left_button: Button = $Overlay/Controls/ScrollLeft
@onready var right_button: Button = $Overlay/Controls/ScrollRight
@onready var area_label: Label = $Overlay/Controls/AreaLabel
@onready var zoom_out_button: Button = $Overlay/Controls/ZoomOut
@onready var zoom_in_button: Button = $Overlay/Controls/ZoomIn
@onready var zoom_label: Label = $Overlay/Controls/ZoomLabel
var camera_x: float = 420.0
var current_plot: int = 0
var _known_plot_count: int = 0
const PLOT_WIDTH: float = 560.0
const ZOOM_LEVELS = [0.70, 0.85, 1.0, 1.15, 1.30, 1.45]
var zoom_index: int = 2

func _ready() -> void:
    add_to_group("little_paw_habitat_view")
    left_button.pressed.connect(_move.bind(-220.0))
    right_button.pressed.connect(_move.bind(220.0))
    zoom_out_button.pressed.connect(_step_zoom.bind(-1))
    zoom_in_button.pressed.connect(_step_zoom.bind(1))
    _known_plot_count = GameState.upgrade_count("land")
    GameState.upgrades_changed.connect(_on_upgrades_changed)
    _refresh_camera()

func _unhandled_input(event: InputEvent) -> void:
    if not visible or not is_visible_in_tree():
        return
    if event is InputEventMouseButton and get_global_rect().has_point(get_global_mouse_position()):
        if event.ctrl_pressed:
            if event.button_index == MOUSE_BUTTON_WHEEL_UP:
                _step_zoom(1)
                get_viewport().set_input_as_handled()
            elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
                _step_zoom(-1)
                get_viewport().set_input_as_handled()
        elif event.shift_pressed:
            if event.button_index == MOUSE_BUTTON_WHEEL_UP:
                _move(-110.0)
                get_viewport().set_input_as_handled()
            elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
                _move(110.0)
                get_viewport().set_input_as_handled()

func _step_zoom(direction: int) -> void:
    zoom_index = clampi(zoom_index + direction, 0, ZOOM_LEVELS.size() - 1)
    _refresh_camera()

func _move(amount: float) -> void:
    camera_x = clampf(camera_x + amount, 420.0, _max_camera_x())
    _refresh_camera()

func _max_camera_x() -> float:
    return 560.0 + PLOT_WIDTH * GameState.upgrade_count("land")

func _on_upgrades_changed() -> void:
    var current: int = GameState.upgrade_count("land")
    if current > _known_plot_count:
        # Reveal the newly unlocked clearing, even if purchased repeatedly.
        camera_x = _max_camera_x() - 130.0
    _known_plot_count = current
    _refresh_camera()

func _refresh_camera() -> void:
    camera_x = clampf(camera_x, 420.0, _max_camera_x())
    camera.position = Vector2(camera_x, 310.0)
    camera.zoom = Vector2.ONE * ZOOM_LEVELS[zoom_index]
    zoom_label.text = "%d%%" % roundi(ZOOM_LEVELS[zoom_index] * 100.0)
    zoom_out_button.disabled = zoom_index == 0
    zoom_in_button.disabled = zoom_index == ZOOM_LEVELS.size() - 1
    habitat.call("render_near_camera", camera_x)
    $ViewportFrame/WorldViewport/Habitat/Pet.call("visit_camera_region", camera_x)
    left_button.disabled = camera_x <= 420.0
    right_button.disabled = camera_x >= _max_camera_x()
    var idx: int = clampi(int(round((camera_x - 420.0) / PLOT_WIDTH)), 0, GameState.upgrade_count("land"))
    if current_plot != idx:
        current_plot = idx
        plot_changed.emit(idx)
    if idx == 0:
        area_label.text = "HOME CLEARING  ·  %d/%d DECOR" % [GameState.placed_in_plot(0).size(), GameState.plot_capacity(0)]
    else:
        area_label.text = "WOODLAND %02d / %02d  ·  %d/%d DECOR" % [idx, GameState.MAX_LAND_EXPANSIONS, GameState.placed_in_plot(idx).size(), GameState.plot_capacity(idx)]
