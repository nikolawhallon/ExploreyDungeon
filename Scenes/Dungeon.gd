extends TileMap

export(int)   var map_w            = 160 / 4
export(int)   var map_h            = 100 / 4
export(float) var ground_seed      = 0.65
export(int)   var wall_condition   = 4
export(int)   var ground_condition = 3

enum Tiles { GROUND, WALL }

# TODO: I don't love the logic for getting the biggest cave, although it works
# once this is re-worked to decouple cave creation from tile populating,
# maybe the logic can be refined to my liking
var biggest_cave

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	generate()

func generate():
	clear()
	fill_wall()
	random_ground()
	dig_caves()
	get_biggest_cave()
	
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

func get_biggest_cave():
	biggest_cave = []
	
	for x in range (0, map_w):
		for y in range (0, map_h):
			if get_cell(x, y) == Tiles.GROUND:
				flood_fill(x, y)

	for tile in biggest_cave:
		set_cellv(tile, Tiles.GROUND)

# this function takes a GROUND tile and does a flood fill
# making it and neighboring tiles WALL tiles, but the cells
# are kept track of in the biggest_cave variable if the cave
# created by the flood fill is biggest cave
# then, the biggest cave can be filled back with GROUND
# TODO: this flood fill ought not change tiles, but just return the
# arrays of tiles which define a cave
func flood_fill(x, y):
	var cave = []
	var to_fill = [Vector2(x, y)]
	while to_fill:
		var tile = to_fill.pop_back()

		if !cave.has(tile):
			cave.append(tile)
			set_cellv(tile, Tiles.WALL)

			# check adjacent cells
			var north = Vector2(tile.x, tile.y - 1)
			var south = Vector2(tile.x, tile.y + 1)
			var east  = Vector2(tile.x + 1, tile.y)
			var west  = Vector2(tile.x - 1, tile.y)

			for neighbor in [north, south, east, west]:
				if get_cellv(neighbor) == Tiles.GROUND:
					if !to_fill.has(neighbor) and !cave.has(neighbor):
						to_fill.append(neighbor)

	if cave.size() >= biggest_cave.size():
		biggest_cave = cave

func is_ground(x, y):
	if get_cell(x, y) == Tiles.GROUND:
		return true

	return false
