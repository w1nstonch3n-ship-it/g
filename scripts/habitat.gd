extends Node2D
## V8.1: five plots; up to four deliberately placed decorations per clearing.
## Opening clearing stays editable in habitat.tscn. New land plots render
## under GeneratedForest and can be inspected in Godot's Remote Scene tree.

const PLOT_WIDTH: float = 560.0
const FIRST_PLOT_X: float = 1170.0
const SLOT_OFFSETS = [-180.0, -60.0, 72.0, 184.0]

@onready var pet: Node2D = $Pet
@onready var generated: Node2D = $GeneratedForest
var _previous_visibility: Dictionary = {}
var _last_camera_x: float = 420.0
var _plot_nodes: Dictionary = {}
var _backdrop_nodes: Dictionary = {}
var _last_counts: Dictionary = {}
var _initialized: bool = false

func _ready() -> void:
    GameState.upgrades_changed.connect(refresh_habitat)
    refresh_habitat()
    _initialized = true

func refresh_habitat() -> void:
    var bed_on: bool = GameState.upgrade_count("bed") > 0
    var flowers_on: bool = GameState.upgrade_count("flowers") > 0
    var pond_on: bool = GameState.upgrade_count("pond") > 0
    var land_count: int = GameState.upgrade_count("land")
    $CozyBed.visible = bed_on
    $StarterMat.visible = not bed_on
    $FlowerPatch.visible = flowers_on
    $FlowerPatchExtra.visible = flowers_on
    $Pond.visible = pond_on
    $TrailGate.visible = land_count == 0
    # Replace V7's one-off "new grove" with generated, repeatable plots.
    for obj in [$NewGroveOak, $NewGrovePine, $NewGroveLantern, $NewGroveMushrooms, $NewGroveFlowers]:
        obj.visible = false
    pet.call("set_more_land", land_count > 0)
    for obj in [$CozyBed, $FlowerPatch, $FlowerPatchExtra, $Pond]:
        var prev: bool = bool(_previous_visibility.get(str(obj.name), false))
        if _initialized and obj.visible and not prev:
            _pop(obj)
        _previous_visibility[str(obj.name)] = obj.visible
    # Rebuild only nearby plots; camera-based windowing avoids an ever-
    # increasing number of persistent scene nodes as the forest grows.
    render_near_camera(_last_camera_x, true)

func render_near_camera(camera_x: float, force: bool = false) -> void:
    _last_camera_x = camera_x
    var owned: int = GameState.upgrade_count("land")
    var min_plot: int = maxi(0, int(floor((camera_x - 850.0) / PLOT_WIDTH)))
    var max_plot: int = mini(owned, int(ceil((camera_x + 850.0) / PLOT_WIDTH)))
    var keep: Dictionary = {}
    # Plot 0 is the hand-edited starting clearing.
    for idx in range(min_plot, max_plot + 1):
        keep[idx] = true
        if not _plot_nodes.has(idx) or force:
            if _plot_nodes.has(idx):
                var old_node: Node2D = _plot_nodes[idx]
                generated.remove_child(old_node)
                old_node.queue_free()
            _plot_nodes[idx] = _create_plot(idx, owned)
    for idx in _plot_nodes.keys():
        if not keep.has(idx):
            var expired: Node2D = _plot_nodes[idx]
            generated.remove_child(expired)
            expired.queue_free()
            _plot_nodes.erase(idx)
    var start_tile: int = int(floor((camera_x - 1050.0) / 1600.0))
    var end_tile: int = int(ceil((camera_x + 1050.0) / 1600.0))
    for tile in range(start_tile, end_tile + 1):
        if tile != 0 and not _backdrop_nodes.has(tile):
            var b := Sprite2D.new()
            b.name = "SkyAndHills_%d" % tile
            b.texture = preload("res://assets/world/forest_panorama.png")
            b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            b.position = Vector2(800.0 + 1600.0 * tile, 280.0)
            b.z_index = -50
            generated.add_child(b)
            _backdrop_nodes[tile] = b
    for tile in _backdrop_nodes.keys():
        if tile < start_tile or tile > end_tile:
            var b: Sprite2D = _backdrop_nodes[tile]
            generated.remove_child(b)
            b.queue_free()
            _backdrop_nodes.erase(tile)

func _create_plot(idx: int, total_owned: int) -> Node2D:
    var root := Node2D.new()
    root.name = "Clearing" if idx == 0 else "ForestPlot_%04d" % idx
    generated.add_child(root)
    var center: float = FIRST_PLOT_X + float(idx - 1) * PLOT_WIDTH if idx > 0 else 450.0
    if idx > 0:
        # Automatically furnished woodland gives each land purchase value,
        # even if the user has not bought extra shop decorations yet.
        var variants: Array[String] = ["oak_tree", "pine_tree", "oak_tree", "pine_tree"]
        var a: String = variants[idx % variants.size()]
        var b: String = variants[(idx + 1) % variants.size()]
        _sprite(root, "PlotOak", "res://assets/habitat/" + a + ".png", Vector2(center - 188, 376), 1.45)
        _sprite(root, "PlotPine", "res://assets/habitat/" + b + ".png", Vector2(center + 185, 376), 1.38)
        var label := Label.new()
        label.name = "PlotNumber"
        label.text = "WOODLAND  %02d" % idx
        label.position = Vector2(center - 72.0, 491.0)
        label.add_theme_color_override("font_color", Color("#405c43"))
        label.add_theme_font_size_override("font_size", 16)
        root.add_child(label)
    # Only decorations deliberately placed in this plot appear here.
    for entry in GameState.placed_in_plot(idx):
        var key: String = str(entry.get("key", ""))
        var info: Dictionary = GameState.catalog_item(key)
        if info.is_empty():
            continue
        var slot: int = clampi(int(entry.get("slot", 0)), 0, 3)
        var x: float = (165.0 if slot == 0 else 725.0) if idx == 0 else center + float(SLOT_OFFSETS[slot])
        var y: float = 468.0
        if key in ["oak", "pine", "appletree"]:
            y = 394.0
        elif key in ["lantern", "birdhouse", "fairy_lights", "flag", "signpost", "woodfence"]:
            y = 440.0
        elif key in ["gazebo", "tent", "swing"]:
            y = 455.0
        var scale_value: float = 1.13 if key not in ["oak", "pine", "appletree"] else 1.45
        _sprite(root, "%s_slot_%d" % [key, slot], str(info.get("icon", "")), Vector2(x, y), scale_value)
    return root

func _sprite(parent: Node2D, name_value: String, path: String, location: Vector2, factor: float) -> void:
    if not ResourceLoader.exists(path):
        return
    var obj := Sprite2D.new()
    obj.name = name_value
    obj.texture = load(path) as Texture2D
    obj.position = location
    obj.scale = Vector2.ONE * factor
    obj.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    parent.add_child(obj)
    if _initialized and not name_value.begins_with("Plot"):
        _pop(obj)

func _pop(node: Node2D) -> void:
    var target: Vector2 = node.scale
    node.scale = target * 0.65
    var tween: Tween = create_tween()
    tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(node, "scale", target, 0.45)
