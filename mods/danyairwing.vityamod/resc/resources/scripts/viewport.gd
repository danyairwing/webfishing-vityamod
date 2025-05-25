extends ViewportContainer
"""

viewport.set_world(world)
viewport.set_object(obj)
"""
onready var viewport = get_node("Viewport")
var camera_offset_sens = .05
var default_distance = 4
onready var camera_offset = viewport.get_node("CameraOffset")
onready var camera = camera_offset.get_node("Camera")
func set_world(world):
	viewport.get_node("WorldEnvironment").environment = world
func set_object(obj):
	viewport.add_child(obj)
	obj.global_transform.origin = Vector3()
	reset_pos()
var held = false
var held_right = false
	
func reset_pos():
	camera.transform.origin.z = -default_distance
	camera_offset.global_transform.origin = Vector3()
	camera_offset.rotation_degrees = Vector3(0,0,0)
	
	
	
func _gui_input(event):
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.doubleclick:
				reset_pos()
			held = event.pressed
		if event.button_index == BUTTON_RIGHT:
			held_right = event.pressed
		if event.button_index == BUTTON_WHEEL_UP:
			camera.transform.origin.z += camera_offset_sens
		if event.button_index == BUTTON_WHEEL_DOWN:
			camera.transform.origin.z -= camera_offset_sens
	if event is InputEventMouseMotion and held:
		camera_offset.rotation -= Vector3(
			-event.relative.y,
			event.relative.x,
			0)*camera_offset_sens/12
		camera_offset.rotation_degrees = Vector3(
			clamp(camera_offset.rotation_degrees.x,-90, 90),
			camera_offset.rotation_degrees.y,
			camera_offset.rotation_degrees.z)
		
	if event is InputEventMouseMotion and held_right:
		camera_offset.transform.origin += (
		(camera_offset.transform.basis.x*event.relative.x)
		+
		(camera_offset.transform.basis.y*event.relative.y)
		
		)*camera_offset_sens/12
