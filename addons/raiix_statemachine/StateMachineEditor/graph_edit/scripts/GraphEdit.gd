extends Control

export(Vector2) var scroll_offset = Vector2.ZERO

export(float) var zoom:float = 1 setget _on_set_zoom
func _on_set_zoom(v):
	if v <= 0:
		v = 0.1
	if nodes == null:
		yield(self, "ready")
	zoom = v
	nodes.rect_scale = Vector2(zoom, zoom)
	
var target_zoom:float = zoom setget _on_set_target_zoom
func _on_set_target_zoom(v):
	target_zoom = v
	if target_zoom <= 0:
		target_zoom = 0.1
	zooming = true
var zooming:bool = false
var zoom_pos:Vector2 = Vector2.ZERO

onready var node_panel = $NodePanel
onready var nodes = $NodePanel/Nodes

var is_dragging = false

var selection:Array = []

func _input(event):
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == BUTTON_MIDDLE:
			is_dragging = false
	if event is InputEventMouseMotion:
		if is_dragging:
			scroll_offset -= event.relative / zoom
			_update_nodes_position()

func _ready():
	pass

func _process(delta):
	_update_zooming()

#----- Private Methods -----
func _update_nodes_position():
	for n in nodes.get_children():
		n.update_rect_position()

func _update_zooming():
	if zooming:
		var old_mp = nodes.get_local_mouse_position()
		self.zoom = lerp(zoom, target_zoom, 0.17)
		var new_mp = nodes.get_local_mouse_position()
		scroll_offset -= new_mp - old_mp
		_update_nodes_position()
		
		if is_equal_approx(zoom, target_zoom):
			zooming = false
#----- Public Methods -----
func add_node(n:Node):
	if n.has_method("unwrapped"):
		n = n.unwrapped()
	nodes.add_child(n)
	n.graph_edit = self
	
	n.connect("pressed", self, "_on_node_pressed")
	n.connect("picked_up", self, "_on_node_picked_up")
	n.connect("picked_down", self, "_on_node_picked_down")
	
	return n

func select(node):
	if not node in selection:
		unselect_all()
		selection.append(node)
		node.select()

func unselect(node):
	var pos = selection.find(node)
	if pos >= 0:
		selection.remove(pos)
		node.unselect()

func unselect_all():
	for n in selection:
		n.unselect()
	selection.clear()
#----- Singals -----
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_MIDDLE:
			is_dragging = true
		elif event.button_index == BUTTON_WHEEL_UP:
			zoom_pos = event.position
			self.target_zoom += 0.5
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom_pos = event.position
			self.target_zoom -= 0.5
		elif event.pressed and event.button_index == BUTTON_LEFT or event.button_index == BUTTON_RIGHT:
			unselect_all()

func _on_node_pressed(node):
	select(node)

func _on_node_picked_up(node):
	pass

func _on_node_picked_down(node):
	pass
