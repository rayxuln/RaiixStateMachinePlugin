tool
extends Control

signal script_selected(path)
signal about_to_hide


#----- Methods -----
func popup():
	$FileDialog.popup_centered()


func _on_FileDialog_file_selected(path):
	emit_signal("script_selected", path)


func _on_FileDialog_popup_hide():
	emit_signal("about_to_hide")
