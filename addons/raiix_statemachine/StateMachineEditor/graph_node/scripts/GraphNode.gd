tool
extends PanelContainer

signal picked_up(node)
signal picked_down(node)
signal pressed(node)
signal right_button_pressed
signal left_button_pressed
signal double_pressed

export(Vector2) var offset = Vector2.ZERO setget _on_set_offset
func _on_set_offset(v):
	offset = v
	data["offset"] = offset
	update_rect_position()

onready var panel = $Panel
onready var panel_stylebox = panel.get_stylebox("panel") as StyleBoxFlat

onready var main_title = $HBoxContainer/MainTitle
onready var top_tiltle = $Panel/TopTitle
onready var left_button = $HBoxContainer/LeftButton
onready var right_button = $HBoxContainer/RightButton

export(String) var text:String = "Unkwon" setget _on_set_text
func _on_set_text(v):
	text = v
	main_title.text = text
	

export(String) var tip_text:String = "tip" setget _on_set_tip_text
func _on_set_tip_text(v):
	tip_text = v
	top_tiltle.text = tip_text

export(Texture) var left_button_tex:Texture = null setget _on_set_left_button_tex
func _on_set_left_button_tex(v):
	left_button_tex = v
	left_button.icon = left_button_tex
	if v:
		left_button.visible = true
	else:
		left_button.visible = false

export(Texture) var right_button_tex:Texture = null setget _on_set_right_button_tex
func _on_set_right_button_tex(v):
	right_button_tex = v
	right_button.icon = right_button_tex
	if v:
		right_button.visible = true
	else:
		right_button.visible = false
	
var graph_edit:Control

var picking:bool = false

var selected:bool = false

var data:Dictionary = {}

export(Color) var hover_shadow_color:Color = Color.yellow
var hover:bool = false setget _on_set_hover
var _hover_shadow_color_save
func _on_set_hover(v):
	var old = hover
	hover = v
	if old != hover:
		if panel == null:
				yield(self, "ready")
		if hover:
			_hover_shadow_color_save = panel_stylebox.shadow_color
			panel_stylebox.shadow_color = hover_shadow_color
			panel_stylebox.shadow_size = 5
		else:
			panel_stylebox.shadow_color = _hover_shadow_color_save
			panel_stylebox.shadow_size = 0

export(Color) var active_shadow_color:Color = Color.aqua
var active:bool = false setget _on_set_active
var _active_shadow_color_save
func _on_set_active(v):
	var old = active
	active = v
	if old != active:
		if panel == null:
				yield(self, "ready")
		if active:
			_active_shadow_color_save = panel_stylebox.shadow_color
			panel_stylebox.shadow_color = active_shadow_color
			panel_stylebox.shadow_size = 5
		else:
			panel_stylebox.shadow_color = _active_shadow_color_save
			panel_stylebox.shadow_size = 0

func _ready():
	panel_stylebox = panel_stylebox.duplicate()
	panel.add_stylebox_override("panel", panel_stylebox)
	
	_on_set_text(text)
	_on_set_tip_text(tip_text)
	_on_set_left_button_tex(left_button_tex)
	_on_set_right_button_tex(right_button_tex)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			if not picking:
				emit_signal("pressed", self)
			picking = true
			emit_signal("picked_up", self)
		if event.pressed and event.button_index == BUTTON_RIGHT:
			emit_signal("pressed", self)
		if not event.pressed and event.button_index == BUTTON_LEFT:
			picking = false
			emit_signal("picked_down", self)
		if event.pressed and event.button_index == BUTTON_LEFT and event.doubleclick:
			emit_signal("double_pressed")

func graph_node_type():
	pass
#----- Public Methods -----
func update_rect_position():
	#rect_global_position = (offset - graph_edit.scroll_offset) / graph_edit.zoom + graph_edit.rect_global_position
	rect_position = offset - graph_edit.scroll_offset

func select():
	panel_stylebox.shadow_size = 5
	selected = true
	
	get_parent().move_child(self, get_parent().get_child_count()-1)

func unselect():
	if not active:
		panel_stylebox.shadow_size = 0
	selected = false



func _on_LeftButton_pressed():
	emit_signal("left_button_pressed")


func _on_RightButton_pressed():
	emit_signal("right_button_pressed")


func _on_LeftButton_button_down():
	if not picking:
		emit_signal("pressed", self)
		


func _on_RightButton_button_down():
	if not picking:
		emit_signal("pressed", self)
