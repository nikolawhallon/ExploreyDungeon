extends Node2D

export(int)   var map_w            = 200 / 4
export(int)   var map_h            = 120 / 4
export(float) var ground_seed      = 0.8
export(int)   var wall_condition   = 4
export(int)   var ground_condition = 3

enum Tiles { GROUND, WALL }

enum ActualTiles {
	TW_LW_BW,		TW_LW_BRC,	TW_BLC_BRC,			TW_RW_BLC,	TRC_BLC_BRC,	TW_BLC,	TW_BRC,	TLC_BLC_BRC,	TW_LW,		TLC_TRC,	TW,			TW_RW,
	LW_RW,			LW_TRC_BRC,	TLC_TRC_BLC_BRC,	RW_TLC_BLC,	LW_TRC,			TLC,	TRC,	RW_TLC,			LW,			TLC_BRC,	GROUND,		TRC_BRC,
	BW_LW_RW,		BW_LW_TRC,	BW_TLC_TRC,			BW_RW_TLC,	LW_BRC,			BLC,	BRC,	RW_BLC,			TLC_BLC,	BLACK,		TRC_BLC,	RW,
	TW_BW_LW_RW,	TW_BW_LW,	TW_BW,				TW_BW_RW,	TLC_TRC_BRC,	BW_TLC,	BW_TRC,	TLC_TRW_BLC,	BW_LW,		BW,			BLC_BRC,	BW_RW,
	FACE
}

var tiles = []

var biggest_cave

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	
	for _x in range(0, map_w):
		var column = []
		column.resize(map_h)
		tiles.append(column)

	generate()

func generate():
	$Walls.clear()
	$Ground.clear()
	fill_wall()
	random_ground()
	double_vertically()
	dig_caves()
	get_biggest_cave()
	remove_vertical_singles()
	convert_tile_array_to_tilemap()

func fill_wall():
	for x in range(0, map_w):
		for y in range(0, map_h):
			tiles[x][y] = Tiles.WALL

func random_ground():
	for x in range(3, map_w - 3):
		for y in range(3, map_h - 3):
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
	if $Ground.get_cell(x, y) == ActualTiles.GROUND:
		return true

	return false

func convert_tile_array_to_tilemap():
	# this is part of a bit of a hacky way to get the borders of the level
	# we are basically guaranteed by the various logic in this script that the border
	# of the level will have walls at least 2 tiles thick,
	# so the very edge of the level can be safely filled with BLACK tiles
	# without needing to check neighboring tiles, some of which are non-existant (because it's the border)
	for x in range(0, map_w):
		for y in range(0, map_h):
			if x < 2 or y < 2 or x > map_w - 2 or y > map_h - 2:
				tiles[x][y] = Tiles.WALL
			if x == 0 or y == 0 or x == map_w - 1 or y == map_h - 1:
				$Walls.set_cell(x, y, ActualTiles.BLACK)

	for y in range(1, map_h - 1):
		for x in range(1, map_w - 1):
			if tiles[x][y] == Tiles.GROUND:
				$Ground.set_cell(x, y, ActualTiles.GROUND)

	# this loop in particular is kinda hacky, in order to correctly fill in wall faces
	# this has the side effect of altering the tiles array to have GROUND where it should
	# really be marked as "WALL"
	for y in range(1, map_h - 1):
		for x in range(1, map_w - 1):
			if tiles[x][y] == Tiles.WALL and tiles[x][y + 1] == Tiles.GROUND and $Walls.get_cell(x, y) != ActualTiles.FACE:
				tiles[x][y] = Tiles.GROUND
				$Walls.set_cell(x, y, ActualTiles.FACE)

	for y in range(1, map_h - 1):
		for x in range(1, map_w - 1):
			if tiles[x][y] != Tiles.GROUND:
				# first row
				if (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.GROUND and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.GROUND and
					tiles[x + 1][y] == Tiles.GROUND and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TW_LW_BW)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.GROUND and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.GROUND and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.GROUND
				):
					$Walls.set_cell(x, y, ActualTiles.TW_LW_BRC)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.GROUND and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.GROUND and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.GROUND
				):
					$Walls.set_cell(x, y, ActualTiles.TW_BLC_BRC)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.GROUND and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.GROUND and

					tiles[x - 1][y + 1] == Tiles.GROUND and
					tiles[x][y + 1] == Tiles.WALL
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TW_RW_BLC)
				elif (
					tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.GROUND and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.GROUND and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.GROUND
				):
					$Walls.set_cell(x, y, ActualTiles.TRC_BLC_BRC)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.GROUND and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.GROUND and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TW_BLC)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.GROUND and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.GROUND
				):
					$Walls.set_cell(x, y, ActualTiles.TW_BRC)
				elif (
					tiles[x - 1][y - 1] == Tiles.GROUND and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.GROUND and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.GROUND
				):
					$Walls.set_cell(x, y, ActualTiles.TLC_BLC_BRC)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.GROUND and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.GROUND and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TW_LW)
				elif (
					tiles[x - 1][y - 1] == Tiles.GROUND and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.GROUND and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TLC_TRC)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.GROUND and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TW)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.GROUND and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.GROUND and

					tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TW_RW)

				# second row
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.GROUND and
					tiles[x + 1][y] == Tiles.GROUND and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.LW_RW)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.GROUND and

					tiles[x - 1][y] == Tiles.GROUND and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.GROUND
				):
					$Walls.set_cell(x, y, ActualTiles.LW_TRC_BRC)
				elif (
					tiles[x - 1][y - 1] == Tiles.GROUND and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.GROUND and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.GROUND and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.GROUND
				):
					$Walls.set_cell(x, y, ActualTiles.TLC_TRC_BLC_BRC)
				elif (
					tiles[x - 1][y - 1] == Tiles.GROUND and
					tiles[x][y - 1] == Tiles.WALL and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.GROUND and

					tiles[x - 1][y + 1] == Tiles.GROUND and
					tiles[x][y + 1] == Tiles.WALL
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.RW_TLC_BLC)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.GROUND and

					tiles[x - 1][y] == Tiles.GROUND and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.LW_TRC)
				elif (
					tiles[x - 1][y - 1] == Tiles.GROUND and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TLC)
				elif (
					tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.GROUND and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TRC)
				elif (
					tiles[x - 1][y - 1] == Tiles.GROUND and
					tiles[x][y - 1] == Tiles.WALL and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.GROUND and

					tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.RW_TLC)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.GROUND and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.LW)
				elif (
					tiles[x - 1][y - 1] == Tiles.GROUND and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.GROUND
				):
					$Walls.set_cell(x, y, ActualTiles.TLC_BRC)
				elif (
					tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.GROUND and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.GROUND
				):
					$Walls.set_cell(x, y, ActualTiles.TRC_BRC)

				# third row
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.GROUND and
					tiles[x + 1][y] == Tiles.GROUND and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.GROUND
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.BW_LW_RW)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.GROUND and

					tiles[x - 1][y] == Tiles.GROUND and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.GROUND
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.BW_LW_TRC)
				elif (
					tiles[x - 1][y - 1] == Tiles.GROUND and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.GROUND and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.GROUND
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.BW_TLC_TRC)
				elif (
					tiles[x - 1][y - 1] == Tiles.GROUND and
					tiles[x][y - 1] == Tiles.WALL and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.GROUND and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.GROUND
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.BW_RW_TLC)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.GROUND and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.GROUND
				):
					$Walls.set_cell(x, y, ActualTiles.LW_BRC)
				elif (
					tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.GROUND and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.BLC)
				elif (
					tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.GROUND
				):
					$Walls.set_cell(x, y, ActualTiles.BRC)
				elif (
					tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.GROUND and

					tiles[x - 1][y + 1] == Tiles.GROUND and
					tiles[x][y + 1] == Tiles.WALL
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.RW_BLC)
				elif (
					tiles[x - 1][y - 1] == Tiles.GROUND and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.GROUND and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TLC_BLC)
				elif (
					tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.BLACK)
				elif (
					tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.GROUND and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.GROUND and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TRC_BLC)
				elif (
					tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.GROUND and

					tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.RW)

				# fourth row
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.GROUND and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.GROUND and
					tiles[x + 1][y] == Tiles.GROUND and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.GROUND
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TW_BW_LW_RW)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.GROUND and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.GROUND and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.GROUND
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TW_BW_LW)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.GROUND and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.GROUND
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TW_BW)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.GROUND and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.GROUND and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.GROUND
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TW_BW_RW)
				elif (
					tiles[x - 1][y - 1] == Tiles.GROUND and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.GROUND and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.GROUND
				):
					$Walls.set_cell(x, y, ActualTiles.TLC_TRC_BRC)
				elif (
					tiles[x - 1][y - 1] == Tiles.GROUND and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.GROUND
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.BW_TLC)
				elif (
					tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.GROUND and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.GROUND
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.BW_TRC)
				elif (
					tiles[x - 1][y - 1] == Tiles.GROUND and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.GROUND and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.GROUND and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.TLC_TRW_BLC)
				elif (
					#tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.GROUND and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.GROUND
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.BW_LW)
				elif (
					tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.GROUND
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.BW)
				elif (
					tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.WALL and

					tiles[x - 1][y + 1] == Tiles.GROUND and
					tiles[x][y + 1] == Tiles.WALL and
					tiles[x + 1][y + 1] == Tiles.GROUND
				):
					$Walls.set_cell(x, y, ActualTiles.BLC_BRC)
				elif (
					tiles[x - 1][y - 1] == Tiles.WALL and
					tiles[x][y - 1] == Tiles.WALL and
					#tiles[x + 1][y - 1] == Tiles.WALL and

					tiles[x - 1][y] == Tiles.WALL and
					tiles[x + 1][y] == Tiles.GROUND and

					#tiles[x - 1][y + 1] == Tiles.WALL and
					tiles[x][y + 1] == Tiles.GROUND
					#tiles[x + 1][y + 1] == Tiles.WALL
				):
					$Walls.set_cell(x, y, ActualTiles.BW_RW)
