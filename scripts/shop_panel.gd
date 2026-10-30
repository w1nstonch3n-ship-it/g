extends VBoxContainer
## V8 shop is data-driven. Adjust prices and items in scripts/game_state.gd.
## Change the card appearance in scenes/shop_item.tscn.

const ITEM_SCENE: PackedScene = preload("res://scenes/shop_item.tscn")
@onready var feed_button: Button = $CarePanel/CareMargin/CareRow/FeedButton
@onready var all_button: Button = $CategoryTabs/AllButton
@onready var cozy_button: Button = $CategoryTabs/CozyButton
@onready var nature_button: Button = $CategoryTabs/NatureButton
@onready var decor_button: Button = $CategoryTabs/DecorButton
@onready var message: Label = $MessageLabel
@onready var items_box: VBoxContainer = $ShopScroll/ShopItems
var cards: Array[PanelContainer] = []
var current_category: String = "all"

func _ready() -> void:
    feed_button.pressed.connect(_feed)
    all_button.pressed.connect(_show_category.bind("all"))
    cozy_button.pressed.connect(_show_category.bind("cozy"))
    nature_button.pressed.connect(_show_category.bind("nature"))
    decor_button.pressed.connect(_show_category.bind("decor"))
    for info in GameState.UPGRADE_CATALOG:
        var card: PanelContainer = ITEM_SCENE.instantiate() as PanelContainer
        card.call("configure", info)
        items_box.add_child(card)
        card.purchase_requested.connect(_buy)
        card.place_requested.connect(_place)
        card.sell_requested.connect(_sell)
        card.store_requested.connect(_store)
        cards.append(card)
    GameState.coins_changed.connect(_refresh)
    GameState.upgrades_changed.connect(_refresh)
    _show_category("all")
    _refresh()
    call_deferred("_connect_habitat_view")

func _refresh() -> void:
    feed_button.disabled = GameState.coins < GameState.FEED_PRICE
    feed_button.text = "%dc  FEED" % GameState.FEED_PRICE
    if feed_button.disabled:
        feed_button.tooltip_text = "Need %d more coins" % (GameState.FEED_PRICE - GameState.coins)
    else:
        feed_button.tooltip_text = "Feed Mochi (+10 happiness)"
    for card in cards:
        card.call("refresh")

func _show_category(category_name: String) -> void:
    current_category = category_name
    all_button.disabled = category_name == "all"
    cozy_button.disabled = category_name == "cozy"
    nature_button.disabled = category_name == "nature"
    decor_button.disabled = category_name == "decor"
    for card in cards:
        card.visible = category_name == "all" or str(card.get("category")) == category_name
    $ShopScroll.scroll_vertical = 0

func _buy(item_key: String, item_title: String) -> void:
    if GameState.purchase_upgrade(item_key):
        message.text = "%s unlocked! Place it from your bag." % item_title if not GameState.is_fixed_upgrade(item_key) else "%s now part of the forest!" % item_title
    else:
        message.text = "Not enough coins, already owned, or max 5 plots."
    _refresh()

func _place(item_key: String, item_title: String) -> void:
    var view: Node = get_tree().get_first_node_in_group("little_paw_habitat_view")
    var plot_index: int = int(view.get("current_plot")) if view != null else 0
    if GameState.place_upgrade(item_key, plot_index):
        message.text = "%s placed in %s!" % [item_title, "the home clearing" if plot_index == 0 else "woodland %02d" % plot_index]
    else:
        message.text = "No room here! Clear a slot, or view another plot."
    _refresh()

func _connect_habitat_view() -> void:
    var view: Node = get_tree().get_first_node_in_group("little_paw_habitat_view")
    var callback: Callable = Callable(self, "_on_plot_changed")
    if view != null and view.has_signal("plot_changed") and not view.is_connected("plot_changed", callback):
        view.connect("plot_changed", callback)

func _on_plot_changed(_index: int) -> void:
    _refresh()

func _store(item_key: String, item_title: String) -> void:
    var view: Node = get_tree().get_first_node_in_group("little_paw_habitat_view")
    var plot_index: int = int(view.get("current_plot")) if view != null else 0
    if GameState.remove_from_plot(item_key, plot_index):
        message.text = "%s returned to your bag." % item_title
    else:
        message.text = "There isn't one here to store."
    _refresh()

func _sell(item_key: String, item_title: String) -> void:
    var refund: int = GameState.sell_upgrade(item_key)
    message.text = "Sold %s for %d coins!" % [item_title, refund] if refund > 0 else "This item can't be sold."
    _refresh()

func _feed() -> void:
    if GameState.feed_pet():
        message.text = "Yum! Mochi gained 10 happiness."
    else:
        message.text = "Earn a few more coins first."
    _refresh()
