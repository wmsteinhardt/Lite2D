extends Sprite

var num_collided = 0
# Indiocate the tile map
export var tilemap_name = 'Tilemaps/spacestation_interactive'
var tilemap_bg_name = null
var tilemap_bg = null 
onready var tilemap = get_tree().get_current_scene().get_node(tilemap_name)
onready var tile_size = tilemap.get_cell_size()


# Load the shaders
onready var lightshader = preload("res://global/Utilities/Shader_Stuff/LightShader_v0.shader")
onready var lightshader_noNM = preload("res://global/Utilities/Shader_Stuff/LightShaderNoNM_v0.shader")

# Settings for the shader
export var intensity = 1.0
export var height = 1.0
export var radius = 100
export var color = Color(0,0.25,0.25,0)
export var light_tilemaps = true
export var light_bg_tilemap = false
export var light_bodies = true
export var shadow_mode = false
var lit_objects_array = []
var lit_objects_array_noNM = []
var lit_tiles_yet = false
var on = true
var n_rot = 120 # Number of discrete directions to check

func _ready():
	$RayCast2D.set_enabled(true)
	$RayCast2D.set_collide_with_bodies(true)
	$RayCast2D.cast_to = Vector2(0,radius)

	self.modulate = color
	illuminate_target_sprite(self,false)
	if shadow_mode == true:
		self.visible = false
	if not tilemap_bg_name == null:
		tilemap_bg = get_tree().get_current_scene().get_node(tilemap_bg_name)

func _physics_process(delta):
	if on:
		if light_bodies:
			$RayCast2D.clear_exceptions()
			# Each frame, we first check previously found objects remove illumination
			# and remove them from the list if they are further away than 
			# the specified radius of the light source
			for j in lit_objects_array:
				j.get_node('Sprite').set_material(null)
				var displacement = j.position-self.position
				if displacement.length() > radius*1.25:
					lit_objects_array.erase(j)
					
			for j in lit_objects_array_noNM:
				j.get_node('AnimatedSprite').set_material(null)
				var displacement = j.position-self.position
				if displacement.length() > radius:
					lit_objects_array_noNM.erase(j)
					
			for i in range(0,n_rot): # Rotate RayCast2D, looking for objects to illuminate
				$RayCast2D.rotation_degrees = i*360.0/n_rot 
				if $RayCast2D.get_collider() is TileMap: # for this part, we exclude the tilemap
					$RayCast2D.add_exception($RayCast2D.get_collider())
				for j in range(len(lit_objects_array)): # except in pathlogical cases, gets us objects behind others
					$RayCast2D.add_exception(lit_objects_array[j])
				$RayCast2D.force_raycast_update() # but we still want to check this direction if a tilemap was found
				if $RayCast2D.get_collider() != null:
					# Check if there is something to illuminate
					if $RayCast2D.get_collider().has_node('Sprite'): 
						if not $RayCast2D.get_collider() in lit_objects_array:
							lit_objects_array.append($RayCast2D.get_collider()) 
					# AnimatedSprites don't support normal maps
					elif $RayCast2D.get_collider().has_node('AnimatedSprite'):
						if not $RayCast2D.get_collider() in lit_objects_array_noNM:

							lit_objects_array_noNM.append($RayCast2D.get_collider())
			# Apply shaders to found objects
			for i in lit_objects_array:
				illuminate_target_body(i,true)
			for i in lit_objects_array_noNM:
				illuminate_target_body(i,false)
	if light_tilemaps:
		if lit_tiles_yet == false:
			illuminate_tiles(tilemap)
			if light_bg_tilemap:
				print('lighting background tiles')
				illuminate_tiles(tilemap_bg)

	
func illuminate_target_body(body,has_normal_map):
	var target_position = body.position
	var direction = (target_position-self.position)/100.0 # Determine location of object relative to light source
	num_collided+=1
	# Generate a 3D vector to reflect the a) "height" of the light source (out of plane - z)
	# and b) relative position of the object with respect to the light source
	# and also account for the sprite direction.
	direction = Vector3(direction.x*body.get_node('Sprite').scale.x,direction.y*body.get_node('Sprite').scale.y,height)
	# Give the object a material to apply the shader
	body.get_node('Sprite').material = ShaderMaterial.new()
	if has_normal_map:
		body.get_node('Sprite').material.shader = lightshader
	else:
		body.get_node('AnimatedSprite').material.shader = lightshader_noNM
	# Specify the shader settings
	body.get_node('Sprite').material.set_shader_param("source_dir",Vector3(direction.x,direction.y,height))
	body.get_node('Sprite').material.set_shader_param("source_radius",radius)
	body.get_node('Sprite').material.set_shader_param("intensity",intensity)
	body.get_node('Sprite').material.set_shader_param("source_color",color)
	body.get_node('Sprite').material.set_shader_param("shadow_mode",shadow_mode)

func illuminate_tiles(target_tilemap):
	print(str(target_tilemap.name))
	lit_tiles_yet = true
	# define arrays to fill up with affected tiles (tile ids) and positions
	var tile_id_array = []
	var map_pos_array = []
	var world_pos_array = []
	var sprite_array = []
	var cell_orient_array = []
	# Vector that we will rotate about the light position to find all affected tiles
	var probe_vector = Vector2.ZERO
	var num_casts = 128
	var half_radius = radius*0.5
	# The immediately following lines ought to find the tile upon which the lite2d is placed.
	var tile_id = target_tilemap.get_cellv(target_tilemap.world_to_map(self.position))
	var map_pos = target_tilemap.world_to_map(self.position)
	var world_pos = target_tilemap.map_to_world(map_pos)
	var cell_orient = []
	if not map_pos_array.has(map_pos) and tile_id != -1:
		map_pos_array.append(map_pos)
		tile_id_array.append(tile_id)
		world_pos_array.append(world_pos)
		cell_orient.append(tilemap.is_cell_x_flipped(map_pos.x,map_pos.y))
		cell_orient.append(tilemap.is_cell_y_flipped(map_pos.x,map_pos.y))
		cell_orient.append(tilemap.is_cell_transposed(map_pos.x,map_pos.y))
		cell_orient_array.append(cell_orient)
	for j in range(0,2):
		for i in range(0,num_casts):
			if j < 1:
				probe_vector = self.position+Vector2(half_radius*cos(i*PI/num_casts*2.0),half_radius*sin(i*PI/num_casts*2.0))
			else:
				probe_vector = self.position+Vector2(radius*cos(i*PI/num_casts*2.0),radius*sin(i*PI/num_casts*2.0))
			map_pos = target_tilemap.world_to_map(probe_vector)
			tile_id = target_tilemap.get_cellv(map_pos)
			world_pos = target_tilemap.map_to_world(map_pos)
			cell_orient = []
			if not map_pos_array.has(map_pos) and tile_id != -1:
				cell_orient.append(target_tilemap.is_cell_x_flipped(map_pos.x,map_pos.y)) # Also track tile orientations
				cell_orient.append(target_tilemap.is_cell_y_flipped(map_pos.x,map_pos.y))
				cell_orient.append(target_tilemap.is_cell_transposed(map_pos.x,map_pos.y))
				map_pos_array.append(map_pos)
				tile_id_array.append(tile_id)
				world_pos_array.append(world_pos)
				cell_orient_array.append(cell_orient)
	
	for i in range(len(tile_id_array)):
		sprite_array.append(Sprite.new())
		target_tilemap.add_child(sprite_array[i])
		sprite_array[i].texture = target_tilemap.tile_set.tile_get_texture(tile_id_array[i])
		sprite_array[i].normal_map = target_tilemap.tile_set.tile_get_normal_map(tile_id_array[i])
		sprite_array[i].position = world_pos_array[i]+tile_size*0.5
		var direction = sprite_array[i].position - self.position
		sprite_array[i].material = ShaderMaterial.new()
		sprite_array[i].material.shader = lightshader

		sprite_array[i].material.set_shader_param("source_dir",Vector3(direction.x/tile_size.x,direction.y/tile_size.y,height))
		sprite_array[i].material.set_shader_param("intensity",intensity)
		sprite_array[i].material.set_shader_param("source_radius",radius/tile_size.x)
		sprite_array[i].material.set_shader_param("source_color",color)
		sprite_array[i].material.set_shader_param("shadow_mode",shadow_mode)
		sprite_array[i].material.set_shader_param("flip_x",cell_orient_array[i][0])
		sprite_array[i].material.set_shader_param("flip_y",cell_orient_array[i][1])
		sprite_array[i].material.set_shader_param("transposed",cell_orient_array[i][2])
		sprite_array[i].material.set_shader_param("is_tile",true)
		print('added material to tile')
		
func illuminate_target_sprite(target_sprite,has_normal_map):
	var target_position = target_sprite.position
	var direction = (target_position-self.position)/100.0 # Determine location of object relative to light source
	num_collided+=1
	# Generate a 3D vector to reflect the a) "height" of the light source (out of plane - z)
	# and b) relative position of the object with respect to the light source
	# and also account for the sprite direction.
	direction = Vector3(direction.x*target_sprite.scale.x,direction.y*target_sprite.scale.y,height)
	# Give the object a material to apply the shader
	target_sprite.material = ShaderMaterial.new()
	if has_normal_map:
		target_sprite.material.shader = lightshader
	else:
		target_sprite.material.shader = lightshader_noNM
	# Specify the shader settings
	target_sprite.material.set_shader_param("source_dir",Vector3(direction.x,direction.y,height))
	target_sprite.material.set_shader_param("source_radius",radius)
	target_sprite.material.set_shader_param("intensity",intensity)
	target_sprite.material.set_shader_param("source_color",color)
	target_sprite.material.set_shader_param("shadow_mode",shadow_mode)
