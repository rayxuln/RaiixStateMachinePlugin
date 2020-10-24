extends Control

var start_position:Vector2 = Vector2(30, 30) setget _on_set_start_position
func _on_set_start_position(v):
	start_position = v
	update()

var end_position:Vector2 = Vector2(60, 60) setget _on_set_end_position
func _on_set_end_position(v):
	end_position = v
	update()

onready var texture_rect = $TextureRect
export(Texture) var icon:Texture = null setget _on_set_icon
func _on_set_icon(v):
	icon = v
	
	if texture_rect == null:
		yield(self, "ready")
	
	texture_rect.texture = icon

var line_width = 5
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


func _process(delta):
	if edit_mode:
		var p = get_parent()
		if p is Control:
			self.end_position = p.get_local_mouse_position()

func _draw():
	_update_rect()
	if focus:
		draw_rect(Rect2(Vector2.ZERO, rect_size), focus_line_color, false, 2)
	draw_rect(Rect2(Vector2.ZERO, rect_size), line_color, true)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			event = make_input_local(event)
			if not Rect2(Vector2(0,0),rect_size).has_point(event.position):
				self.focus = false

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			self.focus = true

#----- Methods -----
func _update_rect():
	var res = calc_rect(start_position, end_position, line_width)
	
	rect_position = res[0]
	rect_size = res[1]
	rect_rotation = res[2]
	
func calc_rect(start_position, end_position, line_width):
	var r_pos = Vector2.ZERO
	var r_size = Vector2.ZERO
	var half_line_width = line_width / 2.0

	var dir = (end_position - start_position).normalized()
	var nor = Vector3(dir.x, dir.y, 0).cross(Vector3(0, 0, 1))
	nor = Vector2(nor.x, nor.y)
	
	var r1 = start_position + nor * half_line_width
	var r2 = end_position + nor * half_line_width
#	var r3 = end_position - nor * half_line_width
	var r4 = start_position - nor * half_line_width
	
	r_pos = r1
	
	r_size.x = (r2-r1).length()
	r_size.y = (r4-r1).length()
	
	return [r_pos, r_size, rad2deg(dir.angle())]
	
	
#------ Singals ------
func _on_start_node_rect_changed():
	self.start_position = start_node.offset + (start_node.rect_size)/2.0 - start_node.graph_edit.scroll_offset
func _on_end_node_rect_changed():
	self.end_position = end_node.offset + (end_node.rect_size)/2.0 - end_node.graph_edit.scroll_offset
