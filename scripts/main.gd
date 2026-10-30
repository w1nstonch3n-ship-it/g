extends Control
## Navigation: PET is the cozy idle world. PLANNER is the full-sized board.
## Both stay alive as nodes when you switch pages; focus timers keep running.

@onready var pet_page: Control = $PetPage
@onready var planner_page: Control = $PlannerPage
@onready var pet_tab: Button = $TopNav/NavMargin/NavRow/PetTab
@onready var planner_tab: Button = $TopNav/NavMargin/NavRow/PlannerTab
@onready var coin_label: Label = $TopNav/NavMargin/NavRow/CoinLabel
@onready var pet_line: Label = $PetPage/Sidebar/Padding/Stack/PetLine
@onready var shop_tab: Button = $PetPage/Sidebar/Padding/Stack/PetTabs/ShopTab
@onready var focus_tab: Button = $PetPage/Sidebar/Padding/Stack/PetTabs/FocusTab
@onready var shop_panel: VBoxContainer = $PetPage/Sidebar/Padding/Stack/ShopPanel
@onready var focus_panel: ScrollContainer = $PetPage/Sidebar/Padding/Stack/FocusPanel
@onready var pet_header: Label = $PetPage/Sidebar/Padding/Stack/PetHeader
@onready var pet_divider: HSeparator = $PetPage/Sidebar/Padding/Stack/Divider
@onready var footer: Label = $PetPage/Sidebar/Padding/Stack/Footer
@onready var toast: Label = $PetPage/Toast

var toast_time: float = 0.0

func _ready() -> void:
    pet_tab.pressed.connect(_show_pet)
    planner_tab.pressed.connect(_show_planner)
    shop_tab.pressed.connect(_show_shop)
    focus_tab.pressed.connect(_show_focus)
    GameState.coins_changed.connect(_refresh_header)
    GameState.pet_fed.connect(_on_pet_fed)
    GameState.focus_completed.connect(_on_focus_completed)
    _refresh_header()
    _show_shop()
    _show_pet()

func _process(delta: float) -> void:
    if toast_time > 0.0:
        toast_time -= delta
        toast.visible = toast_time > 0.0

func _refresh_header() -> void:
    coin_label.text = "%d coins" % maxi(0, GameState.coins) if GameState.coins >= 0 else "0 coins  /  %d owed" % abs(GameState.coins)
    pet_line.text = "YOUR FOREST FRIEND   /   %d%% HAPPY" % GameState.pet_happiness

func _show_pet() -> void:
    pet_page.show()
    planner_page.hide()
    pet_tab.disabled = true
    planner_tab.disabled = false

func _show_planner() -> void:
    pet_page.hide()
    planner_page.show()
    pet_tab.disabled = false
    planner_tab.disabled = true

func _show_shop() -> void:
    shop_panel.show()
    focus_panel.hide()
    shop_tab.disabled = true
    focus_tab.disabled = false
    pet_header.show()
    pet_divider.show()
    footer.hide()

func _show_focus() -> void:
    shop_panel.hide()
    focus_panel.show()
    shop_tab.disabled = false
    focus_tab.disabled = true
    pet_header.show()
    pet_divider.show()
    footer.hide()

func _on_pet_fed() -> void:
    toast.text = "Mochi loved the snack! <3"
    toast_time = 2.0
    toast.show()

func _on_focus_completed(minutes: int, reward: int) -> void:
    toast.text = "%d-minute focus complete! +%d coins" % [minutes, reward]
    toast_time = 3.0
    toast.show()
