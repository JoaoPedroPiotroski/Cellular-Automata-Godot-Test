extends Node2D

export var number_of_particle_types = 3

var particles := [
]
var awoken_particles := [
]
var grid := [	
]
var image : Image
var texture : ImageTexture
var mouse_spawning_particles = false
var next_particle = 1
var visual_thread : Thread
var should_visual_update = true
var update_thread : Thread
var currently_updating = false
var spawning_type = 0

onready var sprite = $Sprite
onready var display_rect = $ColorRect
onready var mouse_spawner_timer = $MouseSpawnerTimer

class Particle:
	var id := 1
	var position := Vector2.ZERO
	var checks := []
	var switch := []
	var color := Color.white
	var type := 0
	enum TYPES {
		SAND,
		WATER,
		GAS
	}

func _ready():
	display_rect.material.set_shader_param('num_particle_types', number_of_particle_types)
	visual_thread = Thread.new()
	update_thread = Thread.new()
	image = Image.new()
	texture = ImageTexture.new()
	image.create(300, 120, false, Image.FORMAT_RGBA8)
	for i in range(120):
		grid.append([]) 
	for y in range(len(grid)):
		for x in range(300):
			grid[y].append(0) 

func _input(event):
	if Input.is_key_pressed(KEY_1):
		spawning_type = 0
	elif Input.is_key_pressed(KEY_2):
		spawning_type = 1
	elif Input.is_key_pressed(KEY_3):
		spawning_type = 2
	if event is InputEventMouseButton:
		if event.pressed:
			spawn_particle(event.position)
			mouse_spawning_particles = true
		else:
			mouse_spawning_particles = false
	
func get_particle(id : int):
	return particles[id-1]

func get_from_grid(x: int, y: int):
	return grid[y][x]
	
func set_grid(pos : Vector2, id : int):
	grid[pos.y][pos.x] = id

func spawn_particle(spawn_pos : Vector2):
	if is_inside_grid(spawn_pos):
		var particle = Particle.new()
		particle.id = next_particle
		next_particle += 1
		particle.position = spawn_pos
#		if spawning_type == 0:
#				particle.type = 0
#				particle.color = Color.bisque
#		elif spawning_type == 1:
#				particle.color = Color.powderblue
#				particle.type = 1
		match(spawning_type):
			0:
				particle.type = 0
				particle.color = Color.bisque
				particle.checks = [
					'down',
					'down_right',
					'down_left'
				]
				particle.switch = [
					1,
					2
				]
			1:
				particle.color = Color.powderblue
				particle.type = 1
				particle.checks = [
					'down',
					'down_right',
					'down_left',
					'left',
					'right'
				]
				particle.switch = [
					2
				]
			2:
				particle.color = Color.white
				particle.type = 2
				particle.checks = [
					'up',
					'up_left',
					'up_right',
					'left',
					'right'
				]
		set_grid(particle.position, particle.id)
		awoken_particles.append(particle)
		particles.append(particle)

func get_adjacent_spaces(pos : Vector2):
	return {
		'left': Vector2(int(pos.x -1), int(pos.y)),
		'right': Vector2(int(pos.x +1), int(pos.y)),
		'down': Vector2(int(pos.x), int(pos.y +1)),
		'up': Vector2(int(pos.x), int(pos.y -1)),
		'down_right': Vector2(int(pos.x + 1), int(pos.y + 1)),
		'down_left': Vector2(int(pos.x -1), int(pos.y +1)),
		'up_right': Vector2(int(pos.x + 1), int(pos.y -1)),
		'up_left': Vector2(int(pos.x -1), int(pos.y -1))
	}

func is_inside_grid(pos : Vector2):
	return pos.y > 0 and pos.y < len(grid)-1 and pos.x > 0 and pos.x < len(grid[0])-1

func frame_update():
	print('CURRENT FPS: ' + String(Engine.get_frames_per_second()))
	print('NUMBER OF PARTICLES: ' + String(len(particles)))
	print('NUMBER OF AWOKEN PARTICLES: ' + String(len(awoken_particles)))
	print(Engine.get_frames_per_second())
	if mouse_spawning_particles:
		spawn_particle(get_local_mouse_position())
		
#	if not update_thread.is_alive():
#		update_thread.start(self, 'update_particles') 
#
#	if should_visual_update:
#		visual_thread.start(self, 'draw_grid', null, 0)
	visual_thread.start(self, 'draw_grid', null, 0)
	update_particles()
	if update_thread.is_alive():
		var wait_to_finish = update_thread.wait_to_finish()
	if visual_thread.is_alive():
		var wait_to_finish = visual_thread.wait_to_finish()

func update_particles():
#	print('UPDATE THREAD')
#	print('ACTIVE: ' + String(update_thread.is_active()))
#	print('ALIVE: ' + String(update_thread.is_alive()))
#	print('TIME: ' + String(Time.get_ticks_msec()))
	for particle in awoken_particles:
		var has_updated = false
		var adjacents = get_adjacent_spaces(particle.position)
		var checks = particle.checks.duplicate()
		checks.shuffle()
		for check in checks:
			if is_inside_grid(adjacents[check]):
				if get_from_grid(adjacents[check].x, adjacents[check].y) == 0:
					set_grid(particle.position, 0)
					set_grid(adjacents[check], particle.id)
					particle.position = adjacents[check]
					has_updated = true
				else:
					for s in particle.switch:
						var par = get_from_grid(adjacents[check].x, adjacents[check].y)
						var gpar = get_particle(par)
						if get_particle(par).type == s:
							#print('switch: ' + String(s) + ' | ' + 'particle: ' + String(get_particle(par).type))
							set_grid(particle.position, get_particle(par).id)
							get_particle(par).position = particle.position
							if not awoken_particles.has(get_particle(par)):
								awoken_particles.append(get_particle(par))
							set_grid(adjacents[check], particle.id)
							particle.position = adjacents[check]
							has_updated = true
#		match(particle.type):
#			0:
#				if is_inside_grid(adjacents['down']):
#					if get_from_grid(adjacents['down'].x, adjacents['down'].y) == 0:
#						set_grid(particle.position, 0)
#						set_grid(adjacents['down'], particle.id)
#						particle.position = adjacents['down']
#						has_updated = true
#					elif get_from_grid(adjacents['down_left'].x, adjacents['down_left'].y) == 0:
#						set_grid(particle.position, 0)
#						set_grid(adjacents['down_left'], particle.id)
#						particle.position = adjacents['down_left']
#						has_updated = true
#					elif get_from_grid(adjacents['down_right'].x, adjacents['down_right'].y) == 0:
#						set_grid(particle.position, 0)
#						set_grid(adjacents['down_right'], particle.id)
#						particle.position = adjacents['down_right']
#						has_updated = true
#			1:
#				var found_down = false
#				if is_inside_grid(adjacents['down']):
#					if get_from_grid(adjacents['down'].x, adjacents['down'].y) == 0:
#						set_grid(particle.position, 0)
#						set_grid(adjacents['down'], particle.id)
#						particle.position = adjacents['down']
#						has_updated = true
#						found_down = true
#					elif get_from_grid(adjacents['down_left'].x, adjacents['down_left'].y) == 0:
#						set_grid(particle.position, 0)
#						set_grid(adjacents['down_left'], particle.id)
#						particle.position = adjacents['down_left']
#						has_updated = true
#						found_down = true
#					elif get_from_grid(adjacents['down_right'].x, adjacents['down_right'].y) == 0:
#						set_grid(particle.position, 0)
#						set_grid(adjacents['down_right'], particle.id)
#						particle.position = adjacents['down_right']
#						has_updated = true
#						found_down = true
#				if not found_down:
#					#var found_left = false
#					var found_choice1 = false
#					var choices = ['left', 'right']
#					choices.shuffle()
#					var choice = choices[0]
#					if is_inside_grid(adjacents[choice]):
#						if get_from_grid(adjacents[choice].x, adjacents[choice].y) == 0:
#							set_grid(particle.position, 0)
#							set_grid(adjacents[choice], particle.id)
#							particle.position = adjacents[choice]
#							has_updated = true
#							found_choice1 = true
#					if not found_choice1:
#						choice = choices[1]
#						if is_inside_grid(adjacents[choice]):
#							if get_from_grid(adjacents[choice].x, adjacents[choice].y) == 0:
#								set_grid(particle.position, 0)
#								set_grid(adjacents[choice], particle.id)
#								particle.position = adjacents[choice]
#								has_updated = true
							#found_left = true
#					if not found_left and is_inside_grid(adjacents['right']):
#						if get_from_grid(adjacents['right'].x, adjacents['right'].y) == 0:
#							set_grid(particle.position, 0)
#							set_grid(adjacents['right'], particle.id)
#							has_updated = true
#							particle.position = adjacents['right']
		if not has_updated:
			awoken_particles.erase(particle)
		else:
			for pos in adjacents:
				var par = get_from_grid(adjacents[pos].x, adjacents[pos].y) 
				if par != 0 and not awoken_particles.has(get_particle(par)): 
					awoken_particles.append(get_particle(par))
	set_deferred('currently_updating', false)
							
func draw_grid():
	image.lock()
	for y in len(grid)-1:
		for x in len(grid[y]):
			match(get_from_grid(x, y)):
				0:
					image.set_pixel(x, y, Color.black)
				_:
					var col : float = (float(get_particle(get_from_grid(x, y)).type) + float(1)) / float(number_of_particle_types)
					image.set_pixel(x, y, Color(col, col, col))
	image.unlock()
	should_visual_update = false
	texture.create_from_image(image, 0)
	display_rect.material.set_shader_param('grid', texture)


func _on_UpdateVisual_timeout():
	should_visual_update = true


func _on_ForceUpdate_timeout():
	awoken_particles = particles.duplicate()


