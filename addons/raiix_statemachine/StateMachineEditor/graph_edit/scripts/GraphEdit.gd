extends Control

signal node_gui_input(event, node)
signal connect_node_request(start_node, end_node)

export(Vector2) var scroll_offset = Vector2.ZERO

var min_zoom = 0.3

export(float) var zoom:float = 1 setget _on_set_zoom
func _on_set_zoom(v):
	if v <= min_zoom:
		v = min_zoom
	if nodes == null:
		yield(self, "ready")
	zoom = v
	var z = Vector2(zoom, zoom)
	nodes.rect_scale = z
	arrows.rect_scale = z
	
var target_zoom:float = zoom setget _on_set_target_zoom
func _on_set_target_zoom(v):
	target_zoom = v
	if target_zoom <= min_zoom:
		target_zoom = min_zoom
	zooming = true
var zooming:bool = false
var zoom_pos:Vector2 = Vector2.ZERO

onready var node_panel = $NodePanel
onready var nodes = $NodePanel/Nodes
onready var arrows = $NodePanel/Arrows

var is_dragging = false

var selection:Array = []
var cancel_on_new_selection:bool = true

var dragging_nodes:bool = false

var arrow_placing_mode:bool = false
var arrow_placing_start_node:Control = null
var arrow_placing_hovering_node:Control = null
var arrow_placing_arrow:Control = null

func _input(event):
	if event is InputEventMouseButton:
		if not event.pressed:
			if event.button_index == BUTTON_MIDDLE:
				is_dragging = false
			elif event.button_index == BUTTON_LEFT:
				dragging_nodes = false
		
		if event.pressed and event.command:
			cancel_on_new_selection = false
		else:
			cancel_on_new_selection = true
	elif event is InputEventMouseMotion:
		if is_dragging:
			scroll_offset -= event.relative / zoom
			_update_nodes_position()
		if dragging_nodes:
			_move_selected_nodes_position(event.relative / zoom)
		
func _ready():
	pass

func _process(delta):
	_update_zooming()

#----- Private Methods -----
func _update_nodes_position():
	for n in nodes.get_children():
		n.update_rect_position()

func _move_selected_nodes_position(offset):
	for n in selection:
		n.offset += offset
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
	n.connect("gui_input", self, "_on_node_gui_input", [n])
	n.connect("mouse_entered", self, "_on_node_mouse_entered", [n])
	n.connect("mouse_exited", self, "_on_node_mouse_exited", [n])

	return n

func remove_node(n:Node):
	nodes.remove_child(n)

func place_arrow(start_node:Control):
	arrow_placing_mode = true
	arrow_placing_start_node = start_node
	
	var a = preload("../../arrow/GraphArrow.tscn").instance()
	arrows.add_child(a)
	a.start_position = start_node.offset + (start_node.rect_size)/2.0 - scroll_offset
	a.edit_mode = true
	
	arrow_placing_arrow = a

func connect_nodes(start_node:Control, end_node:Control):
	var a = preload("../../arrow/GraphArrow.tscn").instance()
	arrows.add_child(a)
	a.edit_mode = false
	
	a.start_position = start_node.offset + (start_node.rect_size)/2.0 - scroll_offset
	a.end_position = end_node.offset + (end_node.rect_size)/2.0 - scroll_offset
	
	a.start_node = start_node
	a.end_node = end_node
	
	a.connect("gui_input", self, "_on_node_gui_input", [a])

func select(node):
	if not node in selection:
		if cancel_on_new_selection:
			unselect_all()
		selection.append(node)
		node.select()

func unselect(node):
	var pos = selection.find(node)
	if pos >= 0:
		selection.remove(pos)
		if node:
			node.unselect()

func unselect_all():
	for n in selection:
		if n:
			n.unselect()
	selection.clear()

func go_home():
	scroll_offset = Vector2.ZERO
	_update_nodes_position()
	self.zoom = 1
	target_zoom = 1
	zooming = false
#----- Singals -----
func _gui_input(event):
	if arrow_placing_mode:
		pass
	else:
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == BUTTON_MIDDLE:
				is_dragging = true
			elif event.button_index == BUTTON_WHEEL_UP:
				zoom_pos = event.position
				self.target_zoom += 0.1
			elif event.button_index == BUTTON_WHEEL_DOWN:
				zoom_pos = event.position
				self.target_zoom -= 0.1
			elif event.pressed and event.button_index == BUTTON_LEFT or event.button_index == BUTTON_RIGHT:
				unselect_all()

func _on_node_gui_input(event, node):
	emit_signal("node_gui_input", event, node)
	
	if not arrow_placing_mode:
		# Enable dragging canvas
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == BUTTON_MIDDLE:
				is_dragging = true
	else:
		# send connect request
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == BUTTON_LEFT:
				emit_signal("connect_node_request", arrow_placing_start_node, arrow_placing_hovering_node)
				arrow_placing_mode = false
				if arrow_placing_hovering_node:
					arrow_placing_hovering_node.hover = false
				arrow_placing_arrow.queue_free()

func _on_node_pressed(node):
	if not arrow_placing_mode:
		select(node)

func _on_node_picked_up(node):
	if not arrow_placing_mode:
		dragging_nodes = true

func _on_node_picked_down(node):
	if not arrow_placing_mode:
		dragging_nodes = false


func _on_HomeButton_pressed():
	if not arrow_placing_mode:
		go_home()

func _on_node_mouse_entered(node):
	if arrow_placing_mode and arrow_placing_start_node != node:
		node.hover = true
		arrow_placing_hovering_node = node

func _on_node_mouse_exited(node):
	if node.hover:
		node.hover = false
	if arrow_placing_hovering_node == node:
		arrow_placing_hovering_node = null
