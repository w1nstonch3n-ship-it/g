extends PanelContainer
## Reusable, scene-editable upgrade card. Catalog data lives in GameState.gd.
signal purchase_requested(item_key: String, item_title: String)
signal place_requested(item_key: String, item_title: String)
signal sell_requested(item_key: String, item_title: String)
signal store_requested(item_key: String, item_title: String)

@export var item_key: String = "bed"
@export_enum("cozy", "nature", "decor") var category: String = "cozy"
@export var item_title: String = "Cozy bed"
@export_multiline var item_description: String = "A softer place for naps"
@export var item_icon: Texture2D

@onready var icon: TextureRect = $Padding/Row/ItemIcon
@onready var title_label: Label = $Padding/Row/Copy/Title
@onready var description_label: Label = $Padding/Row/Copy/Description
@onready var price_label: Label = $Padding/Row/Purchase/Price
@onready var buy_button: Button = $Padding/Row/Purchase/BuyButton
@onready var place_button: Button = $Padding/Row/Purchase/PlaceButton
@onready var sell_button: Button = $Padding/Row/Purchase/SellButton

func configure(info: Dictionary) -> void:
    item_key = str(info.get("key", "bed"))
    category = str(info.get("category", "cozy"))
    item_title = str(info.get("title", item_key))
    item_description = str(info.get("description", ""))
    var path: String = str(info.get("icon", ""))
    if ResourceLoader.exists(path):
        item_icon = load(path) as Texture2D

func _ready() -> void:
    title_label.text = item_title
    description_label.text = item_description
    icon.texture = item_icon
    tooltip_text = item_title + " — " + item_description
    buy_button.pressed.connect(_request_buy)
    place_button.pressed.connect(_request_place_or_store)
    sell_button.pressed.connect(func() -> void: sell_requested.emit(item_key, item_title))
    refresh()

func refresh() -> void:
    var count: int = GameState.upgrade_count(item_key)
    var repeatable: bool = GameState.is_repeatable(item_key)
    var sold_out: bool = (not repeatable and count > 0) or (item_key == "land" and GameState.land_maxed())
    var price: int = GameState.upgrade_price(item_key)
    if item_key == "land":
        price_label.text = "MAX 5 PLOTS" if sold_out else "Plot %d/5: %dc" % [count + 1, price]
    else:
        price_label.text = "OWNED" if sold_out else "%dc" % price
    buy_button.text = "MAXED" if item_key == "land" and sold_out else ("OWNED" if sold_out else "BUY")
    buy_button.disabled = sold_out or GameState.coins < price
    var in_bag: int = GameState.inventory_count(item_key)
    if GameState.is_fixed_upgrade(item_key):
        description_label.text = item_description if count == 0 else "%s  |  owned" % item_description
    else:
        description_label.text = "%s  |  placed %d · bag %d" % [item_description, GameState.placed_count(item_key), in_bag]
    place_button.visible = not GameState.is_fixed_upgrade(item_key)
    var current_plot: int = _view_plot()
    var in_current: bool = false
    for entry in GameState.placed_in_plot(current_plot):
        if str(entry.get("key", "")) == item_key:
            in_current = true
            break
    place_button.disabled = in_bag <= 0 and not in_current
    place_button.text = "PLACE %d" % in_bag if in_bag > 0 else ("STORE" if in_current else "PLACE")
    place_button.tooltip_text = "Place a decoration here" if in_bag > 0 else "Return the last one in this plot to your bag"
    sell_button.visible = item_key != "land"
    sell_button.disabled = count <= 0
    sell_button.text = "SELL"
    sell_button.tooltip_text = "Sell one for 50% of its last purchase price"
    if sold_out:
        buy_button.tooltip_text = "Five plots is the maximum" if item_key == "land" else "Already owned"
    elif GameState.coins < price:
        buy_button.tooltip_text = "Need %d more coins" % (price - GameState.coins)
    else:
        buy_button.tooltip_text = "Buy an upgrade"

func _request_buy() -> void:
    purchase_requested.emit(item_key, item_title)

func _view_plot() -> int:
    var view: Node = get_tree().get_first_node_in_group("little_paw_habitat_view")
    return int(view.get("current_plot")) if view != null else 0

func _request_place_or_store() -> void:
    if GameState.inventory_count(item_key) > 0:
        place_requested.emit(item_key, item_title)
    else:
        store_requested.emit(item_key, item_title)
