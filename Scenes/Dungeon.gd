extends TileMap

export(int)   var map_w            = 160 / 4
export(int)   var map_h            = 100 / 4
export(float) var ground_seed      = 0.8
export(int)   var wall_condition   = 4
export(int)   var ground_condition = 3

enum Tiles { GROUND, WALL }

var tiles = []

var biggest_cave

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	
	for x in range(0, map_w):
		var column = []
		column.resize(map_h)
		tiles.append(column)

	generate()

func generate():
	clear()
	fill_wall()
	random_ground()
	double_vertically()
	dig_caves()
	get_biggest_cave()
	remove_vertical_singles()
	convert_tile_array_to_tilemap()

func convert_tile_array_to_tilemap():
	for x in range(0, map_w):
		for y in range(0, map_h):
			set_cell(x, y, tiles[x][y])

func fill_wall():
	for x in range(0, map_w):
		for y in range(0, map_h):
			tiles[x][y] = Tiles.WALL

func random_ground():
	for x in range(1, map_w - 1):
		for y in range(1, map_h - 1):
			if rng.randf() < ground_seed:
				tiles[x][y] = Tiles.GROUND

func double_vertically():
	for x in range(1, map_w - 1):
		for y in range(1, map_h - 1):
			if tiles[x][y] == Tiles.WALL:
				if tiles[x][y - 1] != Tiles.WALL and tiles[x][y + 1] != Tiles.WALL:
					tiles[x][y + 1] = Tiles.WALL

func remove_vertical_singles():
	for x in range(1, map_w - 1):
		for y in range(1, map_h - 1):
			if tiles[x][y] == Tiles.WALL:
				if tiles[x][y - 1] != Tiles.WALL and tiles[x][y + 1] != Tiles.WALL:
					tiles[x][y] = Tiles.GROUND

func dig_caves():
	for _i in range(10):
		for x in range(1, map_w - 1):
			for y in range(1, map_h - 1):
				if check_nearby_walls(x, y) > wall_condition:
					tiles[x][y] = Tiles.WALL
				elif check_nearby_walls(x, y) < ground_condition:
					tiles[x][y] = Tiles.GROUND

# check in 8 dirs to see how many tiles are walls
func check_nearby_walls(x, y):
	var count = 0
	if tiles[x][y - 1]    == Tiles.WALL:  count += 1
	if tiles[x][y + 1]    == Tiles.WALL:  count += 1
	if tiles[x - 1][y]    == Tiles.WALL:  count += 1
	if tiles[x + 1][y]    == Tiles.WALL:  count += 1
	if tiles[x + 1][y + 1] == Tiles.WALL:  count += 1
	if tiles[x + 1][y - 1] == Tiles.WALL:  count += 1
	if tiles[x - 1][y + 1] == Tiles.WALL:  count += 1
	if tiles[x - 1][y - 1] == Tiles.WALL:  count += 1
	return count

func get_biggest_cave():
	biggest_cave = []
	
	for x in range (0, map_w):
		for y in range (0, map_h):
			if tiles[x][y] == Tiles.GROUND:
				flood_fill(x, y)

	for tile in biggest_cave:
		tiles[tile.x][tile.y] = Tiles.GROUND

func flood_fill(x, y):
	var cave = []
	var to_fill = [Vector2(x, y)]
	while to_fill:
		var tile = to_fill.pop_back()

		if !cave.has(tile):
			cave.append(tile)
			tiles[tile.x][tile.y] = Tiles.WALL

			# check adjacent cells
			var north = Vector2(tile.x, tile.y - 1)
			var south = Vector2(tile.x, tile.y + 1)
			var east  = Vector2(tile.x + 1, tile.y)
			var west  = Vector2(tile.x - 1, tile.y)

			for neighbor in [north, south, east, west]:
				if tiles[neighbor.x][neighbor.y] == Tiles.GROUND:
					if !to_fill.has(neighbor) and !cave.has(neighbor):
						to_fill.append(neighbor)

	if cave.size() >= biggest_cave.size():
		biggest_cave = cave

func is_ground(x, y):
	if tiles[x][y] == Tiles.GROUND:
		return true

	return false
