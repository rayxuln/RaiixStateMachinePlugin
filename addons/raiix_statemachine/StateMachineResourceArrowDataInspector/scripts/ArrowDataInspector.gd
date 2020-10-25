extends Control


onready var cond_list = $VBoxContainer/VBoxContainer/Conds/ScrollContainer/List
onready var remove_button = $VBoxContainer/VBoxContainer/Conds/HBoxContainer/RemoveButton
onready var clear_button = $VBoxContainer/VBoxContainer/Conds/HBoxContainer/ClearButton

var current_cond_edit:Control = null

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			if current_cond_edit:
				current_cond_edit.lose_focus()
				current_cond_edit = null
				remove_button.disabled = true

#----- Methods -----
func add_cond_edit(cond):
	var e = preload("../CondEdit.tscn").instance()
	cond_list.add_child(e)
	e.text = cond
	e.connect("focus_entered", self, "_on_cond_edit_focus_entered", [e])

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
		if c.text == "":
			res.append(null)
		else:
			res.append(c.text)
	return res
#----- Singals -----
func _on_AddButton_pressed():
	add_cond_edit("\"New Condition\"")
	clear_button.disabled = false


func _on_RemoveButton_pressed():
	if current_cond_edit:
		current_cond_edit.queue_free()
		current_cond_edit = null
		remove_button.disabled = true

func _on_cond_edit_focus_entered(e):
	current_cond_edit = e
	remove_button.disabled = false
	

func _on_ClearButton_pressed():
	clear_button.disabled = true
	clear_cond_list()
