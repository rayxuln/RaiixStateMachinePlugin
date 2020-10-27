tool
extends Control

signal inspecting_data_changed(key, value)

onready var cond_list = $VBoxContainer/VBoxContainer/Conds/ScrollContainer/List
onready var remove_button = $VBoxContainer/VBoxContainer/Conds/HBoxContainer/RemoveButton
onready var clear_button = $VBoxContainer/VBoxContainer/Conds/HBoxContainer/ClearButton
onready var title = $VBoxContainer/Title
onready var from_option_button = $VBoxContainer/VBoxContainer/From/OptionButton
onready var to_option_button = $VBoxContainer/VBoxContainer/To/OptionButton


var editor_plugin:EditorPlugin

var current_cond_edit:Control = null

var inspecting:bool = false

var last_from_option_index = -1
var last_to_option_index = -1

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			if current_cond_edit:
				current_cond_edit.lose_focus()
				current_cond_edit = null
				remove_button.disabled = true

#----- Methods -----
func inspect(data:Dictionary, states:Array):
	inspecting = true
	
	title.text = "From %s to %s" % [data.from, data.to]
	
	from_option_button.clear()
	to_option_button.clear()
	for s in states:
		from_option_button.add_item(s)
		to_option_button.add_item(s)
	
	for i in from_option_button.get_item_count():
		if from_option_button.get_item_text(i) == data.from:
			from_option_button.select(i)
			last_from_option_index = i
			break;
	for i in to_option_button.get_item_count():
		if to_option_button.get_item_text(i) == data.to:
			to_option_button.select(i)
			last_to_option_index = i
			break;
	
#	from_option_button.text = data.from
#	to_option_button.text = data.to
#
	clear_cond_list()
	for c in data.cond:
		if c == null:
			add_cond_edit("")
		else:
			add_cond_edit(c)
	
	inspecting = false
	
	if not get_parent():
		editor_plugin.add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, self)
		var tab = get_parent() as TabContainer
		tab.current_tab = tab.get_child_count()-1

func uninspect():
	if get_parent():
		editor_plugin.remove_control_from_docks(self)

func add_cond_edit(cond):
	var e = preload("../CondEdit.tscn").instance()
	cond_list.add_child(e)
	e.text = cond
	e.connect("focus_entered", self, "_on_cond_edit_focus_entered", [e])
	e.connect("request_remove", self, "_on_cond_edit_request_remove", [e])
	e.connect("text_changed", self, "_on_cond_edit_text_changed", [e])
	e.connect("order_changed", self, "_on_cond_edit_order_changed", [e])

	if not inspecting:
		if current_cond_edit:
			e.get_parent().move_child(e, current_cond_edit.get_index()+1)
			current_cond_edit = null
	
func clear_cond_list():
	current_cond_edit = null
	var cs = []
	for c in cond_list.get_children():
		cs.append(c)
	
	for c in cs:
		c.queue_free()

func get_cond():
	var res = []
	for c in cond_list.get_children():
		if c.is_queued_for_deletion():
			continue
		if c.text == "":
			res.append(null)
		else:
			res.append(c.text)
	return res

func set_back_title(from_state, to_state):
	title.text = "From %s to %s" % [from_state, to_state]

func set_back_from_option_button():
	inspecting = true
	from_option_button.select(last_from_option_index)
	inspecting = false

func set_back_to_option_button():
	inspecting = true
	to_option_button.select(last_to_option_index)
	inspecting = false
#----- Singals -----
func _on_AddButton_pressed():
	add_cond_edit("\"New Condition\"")
	clear_button.disabled = false
	
	if not inspecting:
		emit_signal("inspecting_data_changed", "cond", get_cond())


func _on_RemoveButton_pressed():
	if current_cond_edit:
		current_cond_edit.queue_free()
		current_cond_edit = null
		remove_button.disabled = true
		
		if not inspecting:
			emit_signal("inspecting_data_changed", "cond", get_cond())

func _on_cond_edit_focus_entered(e):
	current_cond_edit = e
	remove_button.disabled = false
	

func _on_ClearButton_pressed():
	clear_button.disabled = true
	clear_cond_list()
	
	if not inspecting:
		emit_signal("inspecting_data_changed", "cond", get_cond())

func _on_cond_edit_request_remove(e):
	if current_cond_edit == e:
		current_cond_edit = null
	e.queue_free()
	
	if not inspecting:
		emit_signal("inspecting_data_changed", "cond", get_cond())

func _on_cond_edit_text_changed(text, e):
	if not inspecting:
		emit_signal("inspecting_data_changed", "cond", get_cond())

func _on_cond_edit_order_changed(e):
	if not inspecting:
		emit_signal("inspecting_data_changed", "cond", get_cond())


func _on_From_OptionButton_item_selected(index):
	if not inspecting:
		var s = from_option_button.get_item_text(index)
		if s != to_option_button.text:
			last_from_option_index = index
			emit_signal("inspecting_data_changed", "from", s)
		else:
			inspecting = true
			from_option_button.select(last_from_option_index)
			printerr("Don't try to point from self.")
			inspecting = false


func _on_To_OptionButton_item_selected(index):
	if not inspecting:
		var s = to_option_button.get_item_text(index)
		if s != from_option_button.text:
			last_to_option_index = index
			emit_signal("inspecting_data_changed", "to", s)
		else:
			inspecting = true
			to_option_button.select(last_to_option_index)
			printerr("Don't try to point to self.")
			inspecting = false
	

