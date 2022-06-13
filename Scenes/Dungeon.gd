extends TileMap

export(int)   var map_w            = 160 / 4
export(int)   var map_h            = 100 / 4
export(float) var ground_seed      = 0.65
export(int)   var wall_condition   = 4
export(int)   var ground_condition = 3

enum Tiles { GROUND, WALL }

var caves = []

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	generate()

func generate():
	clear()
	fill_wall()
	random_ground()
	dig_caves()

# start by filling the map with wall tiles
func fill_wall():
	for x in range(0, map_w):
		for y in range(0, map_h):
			set_cell(x, y, Tiles.WALL)

# then randomly place ground tiles
func random_ground():
	for x in range(1, map_w - 1):
		for y in range(1, map_h - 1):
			if rng.randf() < ground_seed:
				set_cell(x, y, Tiles.GROUND)

func dig_caves():
	for _i in range(10):
		for x in range(1, map_w - 1):
			for y in range(1, map_h - 1):
				if check_nearby_walls(x, y) > wall_condition:
					set_cell(x, y, Tiles.WALL)
				elif check_nearby_walls(x, y) < ground_condition:
					set_cell(x, y, Tiles.GROUND)

# check in 8 dirs to see how many tiles are walls
func check_nearby_walls(x, y):
	var count = 0
	if get_cell(x, y - 1)    == Tiles.WALL:  count += 1
	if get_cell(x, y + 1)    == Tiles.WALL:  count += 1
	if get_cell(x - 1, y)    == Tiles.WALL:  count += 1
	if get_cell(x + 1, y)    == Tiles.WALL:  count += 1
	if get_cell(x + 1, y + 1) == Tiles.WALL:  count += 1
	if get_cell(x + 1, y - 1) == Tiles.WALL:  count += 1
	if get_cell(x - 1, y + 1) == Tiles.WALL:  count += 1
	if get_cell(x - 1, y - 1) == Tiles.WALL:  count += 1
	return count

func is_ground(x, y):
	if get_cell(x, y) == Tiles.GROUND:
		return true

	return false
