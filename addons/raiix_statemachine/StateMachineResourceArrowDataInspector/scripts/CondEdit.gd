tool
extends HBoxContainer


signal text_changed(text)
signal text_entered(text)
signal order_changed
signal request_remove()

export(String) var text:String setget _on_set_text, _on_get_text
func _on_set_text(v):
	$LineEdit.text = v
func _on_get_text():
	return $LineEdit.text
	

#----- Methods -----
func lose_focus():
	$VBoxContainer/UpButton.release_focus()
	$VBoxContainer/DownButton.release_focus()
	$LineEdit.release_focus()

#----- Signals -----
func _on_UpButton_pressed():
	var p = get_parent()
	var new_pos = get_index()-1
	if new_pos >= 0:
		p.move_child(self, new_pos)
		$VBoxContainer/UpButton.release_focus()
		emit_signal("order_changed")


func _on_DownButton_pressed():
	var p = get_parent()
	var new_pos = get_index()+1
	if new_pos < p.get_child_count():
		p.move_child(self, new_pos)
		$VBoxContainer/DownButton.release_focus()
		emit_signal("order_changed")


func _on_LineEdit_text_changed(new_text):
	emit_signal("text_changed", new_text)


func _on_LineEdit_text_entered(new_text):
	emit_signal("text_entered", new_text)


func _on_LineEdit_focus_entered():
	emit_signal("focus_entered")


func _on_LineEdit_focus_exited():
	emit_signal("focus_exited")


func _on_RemoveButton_pressed():
	emit_signal("request_remove")
