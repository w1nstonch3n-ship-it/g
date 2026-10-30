extends Node
## Global game data (Project > Project Settings > Globals > Autoload).
## Task kinds: today = one-off due on its creation date;
## once = one-off with an optional deadline;
## daily = repeats once per LOCAL calendar day, between start/end dates.
## Existing V2/V3 saves are migrated safely when loaded.

signal coins_changed
signal tasks_changed
signal boards_changed
signal task_rewarded(title: String, amount: int)
signal task_undone(title: String, amount: int)
signal upgrades_changed
signal pet_fed
signal focus_completed(minutes: int, reward: int)

const SAVE_FILE := "user://little_paw_save.json"
var TASK_REWARDS: Dictionary = {"small": 15, "medium": 40, "huge": 100}
var FOCUS_REWARD_PER_MINUTE: int = 2
var FEED_PRICE: int = 15
const MAX_LAND_EXPANSIONS: int = 5
const LAND_PRICES = [300, 1200, 4200, 12000, 30000]
const DECOR_SLOTS_PER_PLOT: int = 4
var UPGRADE_PRICES: Dictionary = {"bed": 120, "flowers": 60, "pond": 180, "land": 300, "bench": 90, "lantern": 85, "mushrooms": 45, "birdhouse": 110, "daisies": 55, "pine": 95, "oak": 160, "bush": 35, "hammock": 210, "swing": 260, "picnic": 125, "firepit": 185, "beehive": 140, "rockgarden": 80, "signpost": 70, "berrybush": 120, "lilypad": 95, "logpile": 60, "tent": 245, "appletree": 210, "butterflies": 100, "gazebo": 650, "waterfall": 750, "woodfence": 55, "pumpkin": 70, "flag": 90, "fairy_lights": 190}
# V8 catalog is intentionally data-driven: edit prices and labels here.
var UPGRADE_CATALOG: Array[Dictionary] = [
    {"key": "bed", "title": "Dreamy bear bed", "description": "The coziest nap in the clearing", "category": "cozy", "icon": "res://assets/habitat/bed.png", "repeatable": false},
    {"key": "flowers", "title": "Wildflower patch", "description": "Brightens the starting clearing", "category": "nature", "icon": "res://assets/habitat/flowers.png", "repeatable": false},
    {"key": "pond", "title": "Moonlit pond", "description": "A peaceful place to splash", "category": "nature", "icon": "res://assets/habitat/pond.png", "repeatable": false},
    {"key": "land", "title": "Forest land plot", "description": "Five woodland clearings to discover", "category": "nature", "icon": "res://assets/habitat/land.png", "repeatable": true},
    {"key": "bench", "title": "Woodland bench", "description": "A seat by the trees", "category": "cozy", "icon": "res://assets/habitat/bench.png", "repeatable": true},
    {"key": "lantern", "title": "Honey lantern", "description": "Warm golden evening glow", "category": "decor", "icon": "res://assets/habitat/lantern.png", "repeatable": true},
    {"key": "mushrooms", "title": "Mushroom cluster", "description": "Tiny woodland toadstools", "category": "nature", "icon": "res://assets/habitat/mushrooms.png", "repeatable": true},
    {"key": "birdhouse", "title": "Bird house", "description": "Invite tiny feathered guests", "category": "decor", "icon": "res://assets/habitat/birdhouse.png", "repeatable": true},
    {"key": "daisies", "title": "Daisy garden", "description": "Soft wildflowers for Mochi", "category": "nature", "icon": "res://assets/habitat/daisies.png", "repeatable": true},
    {"key": "pine", "title": "Pine sapling", "description": "Tall green needles", "category": "nature", "icon": "res://assets/habitat/pine.png", "repeatable": true},
    {"key": "oak", "title": "Big oak tree", "description": "A shady place to rest", "category": "nature", "icon": "res://assets/habitat/oak.png", "repeatable": true},
    {"key": "bush", "title": "Shrubbery", "description": "A leafy little bush", "category": "nature", "icon": "res://assets/habitat/bush.png", "repeatable": true},
    {"key": "hammock", "title": "Lazy hammock", "description": "Perfect for forest naps", "category": "cozy", "icon": "res://assets/habitat/hammock.png", "repeatable": true},
    {"key": "swing", "title": "Wooden swing", "description": "A playful little nook", "category": "cozy", "icon": "res://assets/habitat/swing.png", "repeatable": true},
    {"key": "picnic", "title": "Picnic blanket", "description": "A little outdoor tea party", "category": "cozy", "icon": "res://assets/habitat/picnic.png", "repeatable": true},
    {"key": "firepit", "title": "Campfire circle", "description": "Cozy light for chilly nights", "category": "decor", "icon": "res://assets/habitat/firepit.png", "repeatable": true},
    {"key": "beehive", "title": "Busy beehive", "description": "Make the garden buzz", "category": "nature", "icon": "res://assets/habitat/beehive.png", "repeatable": true},
    {"key": "rockgarden", "title": "Mossy rock garden", "description": "Pebbles and fresh little plants", "category": "nature", "icon": "res://assets/habitat/rockgarden.png", "repeatable": true},
    {"key": "signpost", "title": "Trail sign", "description": "Mark another woodland trail", "category": "decor", "icon": "res://assets/habitat/signpost.png", "repeatable": true},
    {"key": "berrybush", "title": "Berry bush", "description": "A snack for woodland friends", "category": "nature", "icon": "res://assets/habitat/berrybush.png", "repeatable": true},
    {"key": "lilypad", "title": "Lily pads", "description": "Flowers near the water", "category": "nature", "icon": "res://assets/habitat/lilypad.png", "repeatable": true},
    {"key": "logpile", "title": "Firewood pile", "description": "Stacked logs near the den", "category": "cozy", "icon": "res://assets/habitat/logpile.png", "repeatable": true},
    {"key": "tent", "title": "Tiny tent", "description": "An outdoor hideaway", "category": "cozy", "icon": "res://assets/habitat/tent.png", "repeatable": true},
    {"key": "appletree", "title": "Apple tree", "description": "Red fruit in the forest", "category": "nature", "icon": "res://assets/habitat/appletree.png", "repeatable": true},
    {"key": "butterflies", "title": "Butterfly patch", "description": "Delicate fluttering visitors", "category": "decor", "icon": "res://assets/habitat/butterflies.png", "repeatable": true},
    {"key": "gazebo", "title": "Garden gazebo", "description": "A cozy place to gather", "category": "cozy", "icon": "res://assets/habitat/gazebo.png", "repeatable": true},
    {"key": "waterfall", "title": "Waterfall stones", "description": "A soft blue cascade", "category": "nature", "icon": "res://assets/habitat/waterfall.png", "repeatable": true},
    {"key": "woodfence", "title": "Rustic fence", "description": "A little wooden boundary", "category": "decor", "icon": "res://assets/habitat/woodfence.png", "repeatable": true},
    {"key": "pumpkin", "title": "Pumpkin patch", "description": "Autumn treats for the den", "category": "nature", "icon": "res://assets/habitat/pumpkin.png", "repeatable": true},
    {"key": "flag", "title": "Forest pennant", "description": "Claim your lovely clearing", "category": "decor", "icon": "res://assets/habitat/flag.png", "repeatable": true},
    {"key": "fairy_lights", "title": "Fairy lights", "description": "Make the forest sparkle", "category": "decor", "icon": "res://assets/habitat/fairy_lights.png", "repeatable": true},
]

var coins: int = 45
var pet_happiness: int = 70
var tasks: Array = []
var boards: Array = ["School", "Personal", "Projects"]
var upgrades: Dictionary = {}
var upgrade_counts: Dictionary = {}
var placed_decor: Array = []  # {key, plot, slot}; saved separately from inventory.
var next_task_id: int = 1
var focus_sessions: int = 0
var focus_minutes_total: int = 0
var focus_minutes_today: int = 0
var focus_today_date: String = ""
var _last_day_checked: String = ""
var _check_day_elapsed: float = 0.0

func _ready() -> void:
    _new_game()
    load_game()
    _last_day_checked = today_string()
    _rollover_daily_counters()

func _process(delta: float) -> void:
    # Continue working when the app is left running past midnight.
    _check_day_elapsed += delta
    if _check_day_elapsed < 2.0:
        return
    _check_day_elapsed = 0.0
    var today: String = today_string()
    if today != _last_day_checked:
        _last_day_checked = today
        _rollover_daily_counters()
        tasks_changed.emit()

func today_string() -> String:
    # Local calendar date from the computer/phone OS; requires no internet.
    # The date is checked on each launch and every 2s while running.
    return Time.get_date_string_from_system(false)

func tomorrow_string() -> String:
    return date_after_days(1)

func date_after_days(day_offset: int) -> String:
    # At UTC noon, adding whole days avoids edge cases around DST changes.
    var stamp: int = Time.get_unix_time_from_datetime_string(today_string() + "T12:00:00")
    return Time.get_date_string_from_unix_time(stamp + day_offset * 86400)

func valid_date(value: String) -> bool:
    # Validate YYYY-MM-DD INCLUDING actual month lengths and leap years.
    if value.length() != 10 or value.substr(4, 1) != "-" or value.substr(7, 1) != "-":
        return false
    var digits: String = value.replace("-", "")
    if not digits.is_valid_int() or digits.length() != 8:
        return false
    var year: int = int(value.substr(0, 4))
    var month: int = int(value.substr(5, 2))
    var day: int = int(value.substr(8, 2))
    if year < 2000 or year > 2100 or month < 1 or month > 12 or day < 1:
        return false
    var length: int = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
    var leap: bool = year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
    if month == 2 and leap:
        length = 29
    return day <= length

func _new_game() -> void:
    coins = 45
    pet_happiness = 70
    next_task_id = 3
    focus_sessions = 0
    focus_minutes_total = 0
    focus_minutes_today = 0
    focus_today_date = today_string()
    boards = ["School", "Personal", "Projects"]
    tasks = [
        {"id": 1, "title": "Plan my day", "kind": "today", "size": "small", "due_date": today_string(), "start_date": "", "end_date": "", "board": "Personal", "done": false, "last_completed_date": "", "reward_paid": 0},
        {"id": 2, "title": "Study for 25 minutes", "kind": "today", "size": "medium", "due_date": today_string(), "start_date": "", "end_date": "", "board": "Personal", "done": false, "last_completed_date": "", "reward_paid": 0},
    ]
    upgrades = {"flowers": false, "bed": false, "pond": false, "land": false}
    upgrade_counts = {}
    placed_decor = []

func clean_board(board: String) -> String:
    if board in boards:
        return board
    return "Personal"

func add_board(raw_name: String) -> bool:
    var name: String = raw_name.strip_edges()
    if name.is_empty() or name.length() > 24 or name.to_lower() == "all" or name.contains("\n"):
        return false
    for existing in boards:
        if str(existing).to_lower() == name.to_lower():
            return false
    if boards.size() >= 16:
        return false
    boards.append(name)
    boards_changed.emit()
    save_game()
    return true

func delete_board(board: String) -> bool:
    # Built-in boards stay so old saves and the first-launch tutorial work.
    if board in ["School", "Personal", "Projects"] or not boards.has(board):
        return false
    boards.erase(board)
    for task in tasks:
        if str(task.get("board", "")) == board:
            task["board"] = "Personal"
    boards_changed.emit()
    tasks_changed.emit()
    save_game()
    return true

func task_reward(task: Dictionary) -> int:
    return int(TASK_REWARDS.get(str(task.get("size", "medium")), TASK_REWARDS["medium"]))

func task_is_done(task: Dictionary) -> bool:
    if str(task.get("kind", "once")) == "daily":
        return str(task.get("last_completed_date", "")) == today_string()
    return bool(task.get("done", false))

func task_is_active(task: Dictionary) -> bool:
    if str(task.get("kind", "once")) != "daily":
        return true
    var date: String = today_string()
    var start: String = str(task.get("start_date", ""))
    var end: String = str(task.get("end_date", ""))
    return (start.is_empty() or date >= start) and (end.is_empty() or date <= end)

func task_is_overdue(task: Dictionary) -> bool:
    if str(task.get("kind", "once")) == "daily" or task_is_done(task):
        return false
    var due: String = str(task.get("due_date", ""))
    return not due.is_empty() and due < today_string()

func tasks_for_view(view: String) -> Array:
    var result: Array = []
    for task in tasks:
        if view == "all":
            result.append(task)
        elif str(task.get("kind", "once")) == "daily":
            if task_is_active(task):
                result.append(task)
        else:
            var due: String = str(task.get("due_date", ""))
            if (not task_is_done(task) and (due.is_empty() or due <= today_string())) or str(task.get("last_completed_date", "")) == today_string():
                result.append(task)
    result.sort_custom(_sort_tasks)
    return result

func _sort_tasks(a: Dictionary, b: Dictionary) -> bool:
    if task_is_done(a) != task_is_done(b):
        return not task_is_done(a)
    return int(a.get("id", 0)) < int(b.get("id", 0))

func add_task(raw_title: String, kind: String = "today", size: String = "medium", due_date: String = "", end_date: String = "", board: String = "Personal") -> bool:
    var title: String = raw_title.strip_edges()
    if title.is_empty() or (kind != "today" and kind != "once" and kind != "daily") or not TASK_REWARDS.has(size):
        return false
    var due: String = due_date.strip_edges()
    var end: String = end_date.strip_edges()
    if (not due.is_empty() and not valid_date(due)) or (not end.is_empty() and not valid_date(end)):
        return false
    if kind == "today":
        due = today_string()
        end = ""
    elif kind == "daily":
        if due.is_empty():
            due = today_string()
        if not end.is_empty() and end < due:
            return false
    else:
        end = ""
    tasks.append({
        "id": next_task_id, "title": title, "kind": kind, "size": size, "board": clean_board(board),
        "due_date": "" if kind == "daily" else due,
        "start_date": due if kind == "daily" else "",
        "end_date": end, "done": false, "last_completed_date": "", "reward_paid": 0,
    })
    next_task_id += 1
    tasks_changed.emit()
    save_game()
    return true

func update_task(task_id: int, raw_title: String, kind: String, size: String, due_date: String, end_date: String = "", board: String = "Personal") -> bool:
    var title: String = raw_title.strip_edges()
    if title.is_empty() or (kind != "today" and kind != "once" and kind != "daily") or not TASK_REWARDS.has(size):
        return false
    var due: String = due_date.strip_edges()
    var end: String = end_date.strip_edges()
    if (not due.is_empty() and not valid_date(due)) or (not end.is_empty() and not valid_date(end)):
        return false
    if kind == "today":
        due = today_string()
        end = ""
    elif kind == "daily":
        if due.is_empty():
            due = today_string()
        if not end.is_empty() and end < due:
            return false
    else:
        end = ""
    for task in tasks:
        if int(task.get("id", -1)) != task_id:
            continue
        var old_kind: String = str(task.get("kind", "once"))
        if old_kind != kind:
            if _reverse_completion(task) >= 0:
                coins_changed.emit()
            task["done"] = false
            task["last_completed_date"] = ""
            task["reward_paid"] = 0
        task["title"] = title
        task["board"] = clean_board(board)
        task["kind"] = kind
        task["size"] = size
        task["due_date"] = "" if kind == "daily" else due
        task["start_date"] = due if kind == "daily" else ""
        task["end_date"] = end
        tasks_changed.emit()
        save_game()
        return true
    return false

func finish_task(task_id: int) -> bool:
    for task in tasks:
        if int(task.get("id", -1)) != task_id:
            continue
        if task_is_done(task) or not task_is_active(task):
            return false
        if str(task.get("kind", "once")) != "daily":
            task["done"] = true
        task["last_completed_date"] = today_string()
        var award: int = task_reward(task)
        task["reward_paid"] = award  # Snapshot: editing size later won't affect undo.
        coins += award
        coins_changed.emit()
        tasks_changed.emit()
        save_game()
        task_rewarded.emit(str(task.get("title", "Task")), award)
        return true
    return false

func _reverse_completion(task: Dictionary) -> int:
    # -1 means nothing was completed to undo. Only TODAY's daily award can
    # be reversed; previous days' rewards stay earned.
    if not task_is_done(task):
        return -1
    # Older V4 save files have no reward_paid field. Assume the saved tier;
    # exact original rewards cannot be recovered when the tier was edited.
    var awarded: int = int(task.get("reward_paid", task_reward(task)))
    awarded = maxi(0, awarded)
    # Intentionally permit a negative balance if the coins were already spent.
    # Future earnings repay it, preventing a check/uncheck shopping exploit.
    coins -= awarded
    task["done"] = false
    task["last_completed_date"] = ""
    task["reward_paid"] = 0
    return awarded

func unfinish_task(task_id: int) -> bool:
    for task in tasks:
        if int(task.get("id", -1)) != task_id:
            continue
        var returned: int = _reverse_completion(task)
        if returned < 0:
            return false
        coins_changed.emit()
        tasks_changed.emit()
        save_game()
        task_undone.emit(str(task.get("title", "Task")), returned)
        return true
    return false

func delete_task(task_id: int) -> void:
    for i in range(tasks.size()):
        if int(tasks[i].get("id", -1)) == task_id:
            # Deletion only removes the task, never its earned coins.
            # To reverse a mistaken completion, uncheck it first.
            tasks.remove_at(i)
            tasks_changed.emit()
            save_game()
            return

func upgrade_count(key: String) -> int:
    return maxi(0, int(upgrade_counts.get(key, 0)))

func catalog_item(key: String) -> Dictionary:
    for item in UPGRADE_CATALOG:
        if str(item.get("key", "")) == key:
            return item
    return {}

func is_repeatable(key: String) -> bool:
    return bool(catalog_item(key).get("repeatable", false))

func is_fixed_upgrade(key: String) -> bool:
    # These are designed positions in the first clearing, not loose scenery.
    return key in ["bed", "flowers", "pond", "land"]

func land_maxed() -> bool:
    return upgrade_count("land") >= MAX_LAND_EXPANSIONS

func upgrade_price(key: String) -> int:
    if not UPGRADE_PRICES.has(key):
        return 0
    var count: int = upgrade_count(key)
    if key == "land":
        if count >= MAX_LAND_EXPANSIONS:
            return 0
        return LAND_PRICES[count]
    var base: int = int(UPGRADE_PRICES[key])
    # Small, predictable growth for optional decorations.
    return base + count * maxi(8, int(round(base * 0.16)))

func total_decorations_owned() -> int:
    var total: int = 0
    for item in UPGRADE_CATALOG:
        var key: String = str(item.get("key", ""))
        if not is_fixed_upgrade(key):
            total += upgrade_count(key)
    return total

func placed_count(key: String) -> int:
    var count: int = 0
    for entry in placed_decor:
        if str(entry.get("key", "")) == key:
            count += 1
    return count

func inventory_count(key: String) -> int:
    if is_fixed_upgrade(key):
        return 0
    return maxi(0, upgrade_count(key) - placed_count(key))

func placed_in_plot(plot_index: int) -> Array:
    var contents: Array = []
    for entry in placed_decor:
        if int(entry.get("plot", -1)) == plot_index:
            contents.append(entry)
    return contents

func plot_capacity(plot_index: int) -> int:
    # The starting clearing already contains the den, mat, and original scenery.
    return 2 if plot_index == 0 else DECOR_SLOTS_PER_PLOT

func plot_has_room(plot_index: int) -> bool:
    return plot_index >= 0 and plot_index <= upgrade_count("land") and placed_in_plot(plot_index).size() < plot_capacity(plot_index)

func place_upgrade(key: String, plot_index: int) -> bool:
    if is_fixed_upgrade(key) or inventory_count(key) <= 0 or not plot_has_room(plot_index):
        return false
    var occupied: Dictionary = {}
    for entry in placed_in_plot(plot_index):
        occupied[int(entry.get("slot", -1))] = true
    for slot in range(plot_capacity(plot_index)):
        if not occupied.has(slot):
            placed_decor.append({"key": key, "plot": plot_index, "slot": slot})
            upgrades_changed.emit()
            save_game()
            return true
    return false

func purchase_upgrade(key: String) -> bool:
    var item: Dictionary = catalog_item(key)
    if item.is_empty() or (not is_repeatable(key) and upgrade_count(key) >= 1):
        return false
    if key == "land" and land_maxed():
        return false
    var price: int = upgrade_price(key)
    if price <= 0 or coins < price:
        return false
    coins -= price
    upgrade_counts[key] = upgrade_count(key) + 1
    upgrades[key] = true
    # Loose decorations go into storage until the player places them.
    upgrades_changed.emit()
    coins_changed.emit()
    save_game()
    return true

func sell_upgrade(key: String) -> int:
    # Land is a permanent world unlock and can't be resold.
    if key == "land" or upgrade_count(key) <= 0 or catalog_item(key).is_empty():
        return 0
    var current_count: int = upgrade_count(key)
    var base: int = int(UPGRADE_PRICES.get(key, 0))
    var last_paid: int = base + (current_count - 1) * maxi(8, int(round(base * 0.16)))
    var refund: int = maxi(1, int(round(last_paid * 0.5)))
    # Sell an unplaced item first; if all are placed, remove the last placement.
    if placed_count(key) >= current_count:
        for i in range(placed_decor.size() - 1, -1, -1):
            if str(placed_decor[i].get("key", "")) == key:
                placed_decor.remove_at(i)
                break
    upgrade_counts[key] = current_count - 1
    upgrades[key] = upgrade_count(key) > 0
    coins += refund
    upgrades_changed.emit()
    coins_changed.emit()
    save_game()
    return refund

func remove_from_plot(key: String, plot_index: int) -> bool:
    # Return a placed decoration to inventory, with no coin penalty.
    for i in range(placed_decor.size() - 1, -1, -1):
        if str(placed_decor[i].get("key", "")) == key and int(placed_decor[i].get("plot", -1)) == plot_index:
            placed_decor.remove_at(i)
            upgrades_changed.emit()
            save_game()
            return true
    return false

func feed_pet() -> bool:
    if coins < FEED_PRICE:
        return false
    coins -= FEED_PRICE
    pet_happiness = mini(pet_happiness + 10, 100)
    coins_changed.emit()
    pet_fed.emit()
    save_game()
    return true

func complete_focus_session(minutes: int) -> void:
    # Called only when a study timer reaches 0; breaks never award coins.
    if minutes < 1 or minutes > 180:
        return
    _rollover_daily_counters()
    var reward: int = minutes * FOCUS_REWARD_PER_MINUTE
    focus_sessions += 1
    focus_minutes_total += minutes
    focus_minutes_today += minutes
    coins += reward
    coins_changed.emit()
    focus_completed.emit(minutes, reward)
    save_game()

func _rollover_daily_counters() -> void:
    var date: String = today_string()
    if focus_today_date != date:
        focus_today_date = date
        focus_minutes_today = 0
        save_game()

func save_game() -> void:
    var save_data: Dictionary = {
        "save_version": 81,
        "coins": coins, "pet_happiness": pet_happiness,
        "tasks": tasks, "boards": boards, "upgrades": upgrades, "upgrade_counts": upgrade_counts, "placed_decor": placed_decor, "next_task_id": next_task_id,
        "focus_sessions": focus_sessions,
        "focus_minutes_total": focus_minutes_total,
        "focus_minutes_today": focus_minutes_today,
        "focus_today_date": focus_today_date,
    }
    var file: FileAccess = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if file == null:
        push_warning("Little Paw: couldn't open save file at " + SAVE_FILE)
        return
    file.store_string(JSON.stringify(save_data, "  "))
    file.close()

func load_game() -> void:
    if not FileAccess.file_exists(SAVE_FILE):
        return
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_FILE))
    if not (data is Dictionary):
        push_warning("Little Paw: save data is invalid; defaults loaded instead.")
        return
    # Negative coins represent a reward that was reversed after it was spent.
    # Do not clamp: that would create coins when loading a save.
    coins = int(data.get("coins", coins))
    pet_happiness = clampi(int(data.get("pet_happiness", pet_happiness)), 0, 100)
    if data.get("upgrades") is Dictionary:
        upgrades.merge(data["upgrades"], true)
    if data.get("upgrade_counts") is Dictionary:
        for key in data["upgrade_counts"]:
            if UPGRADE_PRICES.has(str(key)):
                upgrade_counts[str(key)] = maxi(0, int(data["upgrade_counts"][key]))
    # Migrate V7 booleans without awarding free repeatable items on every load.
    for key in upgrades:
        if bool(upgrades[key]) and upgrade_count(str(key)) == 0:
            upgrade_counts[str(key)] = 1
    for key in upgrade_counts:
        upgrades[key] = upgrade_count(str(key)) > 0
    # V8 had unlimited expansion; V8.1 limits purchases to five plots.
    # Existing older saves with additional plots are migrated at five.
    if upgrade_count("land") > MAX_LAND_EXPANSIONS:
        var overflow: int = upgrade_count("land") - MAX_LAND_EXPANSIONS
        # Keep an approximate half-price credit for legacy expansions removed.
        for old_idx in range(MAX_LAND_EXPANSIONS, MAX_LAND_EXPANSIONS + overflow):
            coins += int(round(mini(25000, 300 + old_idx * 125 + mini(10000, old_idx * old_idx * 12)) * 0.5))
        upgrade_counts["land"] = MAX_LAND_EXPANSIONS
    placed_decor = []
    if data.get("placed_decor") is Array:
        for raw in data["placed_decor"]:
            if not (raw is Dictionary):
                continue
            var key: String = str(raw.get("key", ""))
            var plot_index: int = int(raw.get("plot", -1))
            var slot_index: int = int(raw.get("slot", -1))
            if is_fixed_upgrade(key) or upgrade_count(key) <= placed_count(key):
                continue
            if plot_index < 0 or plot_index > upgrade_count("land") or slot_index < 0 or slot_index >= plot_capacity(plot_index):
                continue
            var free: bool = true
            for previous in placed_in_plot(plot_index):
                if int(previous.get("slot", -1)) == slot_index:
                    free = false
                    break
            if free:
                placed_decor.append({"key": key, "plot": plot_index, "slot": slot_index})
    else:
        # Old purchases remain owned. Place only a few automatically, leaving
        # extras safely in inventory to prevent massive visual clutter.
        for item in UPGRADE_CATALOG:
            var key: String = str(item.get("key", ""))
            if is_fixed_upgrade(key):
                continue
            for _owned in range(upgrade_count(key)):
                var placed: bool = false
                for plot_index in range(upgrade_count("land") + 1):
                    if placed_in_plot(plot_index).size() < plot_capacity(plot_index):
                        placed_decor.append({"key": key, "plot": plot_index, "slot": placed_in_plot(plot_index).size()})
                        placed = true
                        break
                if not placed:
                    break
    focus_sessions = maxi(0, int(data.get("focus_sessions", 0)))
    focus_minutes_total = maxi(0, int(data.get("focus_minutes_total", 0)))
    focus_minutes_today = maxi(0, int(data.get("focus_minutes_today", 0)))
    focus_today_date = str(data.get("focus_today_date", today_string()))
    # V5 saves have no boards key; their tasks automatically live in Personal,
    # School or Projects. V6 persists custom board names.
    boards = ["School", "Personal", "Projects"]
    if data.get("boards") is Array:
        for raw_board in data["boards"]:
            var name: String = str(raw_board).strip_edges()
            if name.is_empty() or name.to_lower() == "all" or name.length() > 24:
                continue
            var duplicate: bool = false
            for existing in boards:
                if str(existing).to_lower() == name.to_lower():
                    duplicate = true
                    break
            if not duplicate and boards.size() < 16:
                boards.append(name)
    if data.get("tasks") is Array:
        tasks.clear()
        for item in data["tasks"]:
            if not (item is Dictionary):
                continue
            var task: Dictionary = item.duplicate(true)
            # V2/V3 stored only {id, title, done}. Preserve completion and coins.
            if not task.has("board"):
                task["board"] = "Personal"
            task["board"] = clean_board(str(task["board"]))
            if not task.has("kind"):
                task["kind"] = "once"
            if not task.has("size"):
                task["size"] = "medium"
            if not task.has("due_date"):
                task["due_date"] = ""
            if not task.has("start_date"):
                task["start_date"] = ""
            if not task.has("end_date"):
                task["end_date"] = ""
            if not task.has("last_completed_date"):
                task["last_completed_date"] = ""
            if not task.has("done"):
                task["done"] = false
            if not TASK_REWARDS.has(str(task["size"])):
                task["size"] = "medium"
            if not task.has("reward_paid"):
                # Migration from V4: best available estimate for completed tasks.
                task["reward_paid"] = task_reward(task) if task_is_done(task) else 0
            tasks.append(task)
    var highest: int = 0
    for task in tasks:
        highest = maxi(highest, int(task.get("id", 0)))
    next_task_id = maxi(highest + 1, int(data.get("next_task_id", highest + 1)))
