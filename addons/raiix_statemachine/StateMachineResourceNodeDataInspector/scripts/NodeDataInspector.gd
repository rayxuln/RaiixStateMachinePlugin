tool
extends Control

signal inspecting_data_changed(key, value)

var editor_plugin:EditorPlugin

var choosing_script_file:bool = false

var title:String = "" setget _on_set_title
func _on_set_title(v):
	title = v
	$VBoxContainer/Title.text = v

#----- Methods ------
func inspect(title, d:Dictionary):
	$VBoxContainer.visible = true
	$CenterContainer.visible = false
	
	$VBoxContainer/Title.text = title
	$VBoxContainer/VBoxContainer/Name/LineEdit.text = d.name
	if not d.script or not ResourceLoader.exists(d.script):
		$VBoxContainer/VBoxContainer/Script/HBoxContainer/Button.text = "Choose..."
	else:
		$VBoxContainer/VBoxContainer/Script/HBoxContainer/Button.text = get_file_name(d.script)
		$VBoxContainer/VBoxContainer/Script/HBoxContainer/Button.hint_tooltip = d.script
	$VBoxContainer/VBoxContainer/SubStateMachine/CheckBox.pressed = d.sub_state_machine != null
	$VBoxContainer/VBoxContainer/Init/CheckBox.pressed = d.init
	
	editor_plugin.add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, self)
	var tab = get_parent() as TabContainer
	tab.current_tab = tab.get_child_count()-1

func uninspect():
	$VBoxContainer.visible = false
	$CenterContainer.visible = true
	
	if get_parent():
		editor_plugin.remove_control_from_docks(self)

func get_file_name(path:String):
	var ss = path.split('.')
	var n:String = ss[0]
	ss = n.split('/')
	return ss[ss.size()-1]

#----- Signals -----
func _on_LineEdit_text_changed(new_text):
	emit_signal("inspecting_data_changed", "name", new_text)

func _on_Script_Button_pressed():
	choosing_script_file = true
	editor_plugin.get_script_file(self, "_on_script_file_selected", "_on_script_file_dialog_about_to_hide")

func _on_script_file_dialog_about_to_hide():
	choosing_script_file = false

func _on_script_file_selected(path):
	if choosing_script_file and ResourceLoader.exists(path):
		$VBoxContainer/VBoxContainer/Script/HBoxContainer/Button.text = get_file_name(path)
		$VBoxContainer/VBoxContainer/Script/HBoxContainer/Button.hint_tooltip = path
		emit_signal("inspecting_data_changed", "script", path)

func _on_SubStateMachine_CheckBox_toggled(button_pressed):
	emit_signal("inspecting_data_changed", "sub_state_machine", button_pressed)


func _on_Init_CheckBox_toggled(button_pressed):
	emit_signal("inspecting_data_changed", "init", button_pressed)


func _on_ClearButton_pressed():
	$VBoxContainer/VBoxContainer/Script/HBoxContainer/Button.text = "Choose..."
	emit_signal("inspecting_data_changed", "script", null)
