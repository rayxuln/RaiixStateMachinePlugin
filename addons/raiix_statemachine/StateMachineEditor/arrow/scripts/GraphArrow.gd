tool
extends Control

signal pressed(node)

var start_position:Vector2 = Vector2(30, 30) setget _on_set_start_position
func _on_set_start_position(v):
	start_position = v
	update()

var end_position:Vector2 = Vector2(60, 60) setget _on_set_end_position
func _on_set_end_position(v):
	end_position = v
	update()
	
var point_offset:float = 20

onready var texture_rect = $TextureRect
export(Texture) var icon:Texture = null setget _on_set_icon
func _on_set_icon(v):
	icon = v
	
	if texture_rect == null:
		yield(self, "ready")
	
	texture_rect.texture = icon

var line_width = 3
export(Color) var line_color = Color.white
export(Color) var focus_line_color = Color.yellow

var focus:bool = false setget _on_set_focus
func _on_set_focus(v):
	var old = focus
	focus = v
	if old != focus:
		get_parent().move_child(self, get_parent().get_child_count()-1)
		update()

var edit_mode = false

var start_node:Control = null setget _on_set_start_node
func _on_set_start_node(v):
	start_node = v
	if start_node:
		start_node.connect("item_rect_changed", self, "_on_start_node_rect_changed")
var end_node:Control = null setget _on_set_end_node
func _on_set_end_node(v):
	end_node = v
	if end_node:
		end_node.connect("item_rect_changed", self, "_on_end_node_rect_changed")

onready var condition_label = $ConditionLabel
onready var condition_label_inversed = $ConditionLabelInversed

export(String) var condition_text = null setget _on_set_condition_text
func _on_set_condition_text(v):
	condition_text = v
	var t = condition_text if condition_text is String else ""
	if condition_label == null:
		yield(self, "ready")
	condition_label.text = t
	condition_label.text = t

var data:Dictionary = {}

func _process(delta):
	if edit_mode:
		var p = get_parent()
		if p is Control:
			self.end_position = p.get_local_mouse_position()

func _draw():
	_update_rect()
	
	draw_rect(Rect2(Vector2.ZERO, rect_size), line_color, true)
	
	if focus:
		draw_rect(Rect2(Vector2.ZERO, rect_size), focus_line_color, false, 1, true)
	else:
		draw_rect(Rect2(Vector2.ZERO, rect_size), line_color, false, 1.0, true)


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			emit_signal("pressed", self)

func graph_arrow_type():
	pass
#----- Methods -----
func _update_rect():
	var res = calc_rect(start_position, end_position, line_width)
	
	rect_position = res[0]
	rect_size = res[1]
	rect_rotation = res[2]
	
	_update_condition_label_inversed_pivot()
	
	if rect_rotation >= -90 and rect_rotation <= 90:
		$ConditionLabel.visible = true
		$ConditionLabelInversed.visible = false
	else:
		$ConditionLabel.visible = false
		$ConditionLabelInversed.visible = true
	

func _update_condition_label_inversed_pivot():
	$ConditionLabelInversed.rect_pivot_offset = $ConditionLabelInversed.rect_size/2.0

func calc_dir(start_position, end_position):
	return (end_position - start_position).normalized()

func calc_nor(dir):
	var nor = Vector3(dir.x, dir.y, 0).cross(Vector3(0, 0, 1))
	nor = Vector2(nor.x, nor.y)
	return nor

func calc_rect(start_position, end_position, line_width):
	var r_pos = Vector2.ZERO
	var r_size = Vector2.ZERO
	var half_line_width = line_width / 2.0

	var dir = calc_dir(start_position, end_position)
	var nor = calc_nor(dir)
	
	var r1 = start_position + nor * half_line_width
	var r2 = end_position + nor * half_line_width
#	var r3 = end_position - nor * half_line_width
	var r4 = start_position - nor * half_line_width
	
	r_pos = r1
	
	r_size.x = (r2-r1).length()
	r_size.y = (r4-r1).length()
	
	return [r_pos, r_size, rad2deg(dir.angle())]
	
func select():
	self.focus = true

func unselect():
	self.focus = false

func calc_node_center(node:Control):
	return node.offset + node.rect_size/2.0 - node.graph_edit.scroll_offset

func check_if_use_offset(start_node, end_node):
	var e_ns = start_node.graph_edit.get_connected_to_nodes(start_node)
	var s_ns = end_node.graph_edit.get_connected_to_nodes(end_node)
	return start_node in s_ns and end_node in e_ns

func update_point_pos_with_nodes():
	var s_p = calc_node_center(start_node)
	var e_p = calc_node_center(end_node)
	var offset = point_offset * calc_nor(calc_dir(s_p, e_p))
	
	if not check_if_use_offset(start_node, end_node):
		offset = Vector2.ZERO
	
#	print("update: " + str(offset))
	
	self.start_position = s_p + offset
	self.end_position = e_p + offset

#------ Singals ------
func _on_start_node_rect_changed():
	if end_node:
		update_point_pos_with_nodes()
	else:
		self.start_position = calc_node_center(start_node)
func _on_end_node_rect_changed():
	if start_node:
		update_point_pos_with_nodes()
	else:
		self.end_position = calc_node_center(end_node)
