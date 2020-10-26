tool
extends WindowDialog

var ClientTab = preload("../client_tab/ClientTab.tscn")

var editor_plugin:EditorPlugin 
var server:Node setget , _on_get_server
func _on_get_server():
	return editor_plugin.remote_debug_server

onready var tab_container = $TabContainer
onready var center_container = $CenterContainer
onready var get_client_id_timer = $UpdateTimer
#----- Methods -----
func has_client_tab(id):
	for c in tab_container.get_children():
		if c.name == id:
			return true
	return false
func update_client_tabs():
	var cs = self.server.get_all_client_id()
	
	if cs.size() == 0:
		tab_container.visible = false
		center_container.visible = true
		return
	
	tab_container.visible = true
	center_container.visible = false
	
	# add that doesn't added
	for c_id in cs:
		if not has_client_tab(c_id):
			var client_tab = ClientTab.instance()
			tab_container.add_child(client_tab)
			client_tab.name = c_id
	
	# remove that doesn't in cs
	var removed_cs = []
	for c in tab_container.get_children():
		if not c.name in cs:
			removed_cs.append(c)
			print("Remove " + c.name)
	for c in removed_cs:
		tab_container.remove_child(c)
		c.queue_free()

func get_current_client_id():
	return get_current_tab().name

func get_current_tab():
	return tab_container.get_child(tab_container.current_tab)
func update_tree(tab, tree_root_info):
	tab.update_tree(tree_root_info)
#----- Singals -----
func _on_RemoteViewer_about_to_show():
	update_client_tabs()
	get_client_id_timer.start()
	


func _on_RemoteViewer_popup_hide():
	get_client_id_timer.stop()


func _on_GetClientIDTimer_timeout():
	update_client_tabs()
	if tab_container.get_child_count() <= 0:
		return
	var client_id = get_current_client_id()
	self.server.request_get_tree_info(self.server.get_client_peer(client_id))
	var tree_info = yield(self.server, "res_get_tree_info")[0]
	
	update_tree(get_current_tab(), tree_info)

