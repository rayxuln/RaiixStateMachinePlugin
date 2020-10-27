tool
extends WindowDialog

var title = "State Machine Remote Viewer"

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
		var removed_tabs = []
		for t in tab_container.get_children():
			tab_container.remove_child(t)
			removed_tabs.append(t)
		for t in removed_tabs:
			t.queue_free()
		return
	
	tab_container.visible = true
	center_container.visible = false
	
	# add that doesn't added
	for c_id in cs:
		if not has_client_tab(c_id):
			var client_tab = ClientTab.instance()
			tab_container.add_child(client_tab)
			client_tab.connect("node_double_clicked", self, "_on_node_double_clicked", [client_tab])
			client_tab.connect("graph_node_left_button_pressed", self, "_on_graph_node_left_button_pressed", [client_tab])
			client_tab.connect("smr_path_changed", self, "_on_smr_path_changed", [client_tab])
			client_tab.connect("tree_some_node_removed", self, "_on_tree_some_node_removed", [client_tab])
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

func get_current_state_machine_path():
	var tab = get_current_tab()
	return tab.get_current_state_machine_path()

func fetch_state_machine_current_state():
	var client_id = get_current_client_id()
	var tab = get_current_tab()
	self.server.request_get_sm_state(tab.get_current_state_machine_path(), self.server.get_client_peer(client_id))
	var state = yield(self.server, "res_get_sm_state")[0]
	if not tab:
		return
	if state:
#		print("Current state: " + state)
		tab.update_state("null", state, false)
	else:
		window_title = title
		tab.state_machine_resource = null
		tab.state_machine_node_path = ""
#----- Singals -----
func _on_RemoteViewer_about_to_show():
	if not self.server.is_connected("req_sm_state_changed", self, "_on_remote_sm_state_changed"):
		self.server.connect("req_sm_state_changed", self, "_on_remote_sm_state_changed")
	
	_on_GetClientIDTimer_timeout() # force update
	get_client_id_timer.start()
	if get_current_tab():
		if get_current_tab().state_machine_resource:
#			get_sm_state_timer.start()
			fetch_state_machine_current_state()
			self.server.request_listen_sm(get_current_state_machine_path(), self.server.get_client_peer(get_current_client_id()))


func _on_RemoteViewer_popup_hide():
	get_client_id_timer.stop()
	if get_current_tab():
		self.server.request_listen_sm(null, self.server.get_client_peer(get_current_client_id()))

func _on_GetClientIDTimer_timeout():
	update_client_tabs()
	if tab_container.get_child_count() <= 0:
		return
	var client_id = get_current_client_id()
	var client_peer = self.server.get_client_peer(client_id)
	if not client_peer:
		return
	self.server.request_get_tree_info(get_current_tab().search_line_edit.text, client_peer)
	var tree_info = yield(self.server, "res_get_tree_info")[0]
	
	update_tree(get_current_tab(), tree_info)

func _on_node_double_clicked(node_path, is_sm, is_root, tab):
	if is_sm:
		var client_id = get_current_client_id()
		self.server.request_get_smr(node_path, self.server.get_client_peer(client_id))
		var smr = yield(self.server, "res_get_smr")[0]
		if smr:
			window_title = title + ' - ' + node_path
			tab.state_machine_resource = smr
			tab.state_machine_node_path = node_path
			fetch_state_machine_current_state()
			self.server.request_listen_sm(node_path, self.server.get_client_peer(client_id))
		else:
			self.server.request_listen_sm(null, self.server.get_client_peer(client_id))
	else:
		window_title = title
		tab.state_machine_resource = null
		tab.state_machine_node_path = ""
		self.server.request_listen_sm(null, self.server.get_client_peer(get_current_client_id()))
	
func _on_graph_node_left_button_pressed(node, tab):
	var client_id = get_current_client_id()
	if node.get_meta("left_button_state") == "stop":
		self.server.request_change_state(tab.get_current_state_machine_path(), node.name, self.server.get_client_peer(client_id))
	else:
		self.server.request_change_state(tab.get_current_state_machine_path(), "null", self.server.get_client_peer(client_id))
		


func _on_smr_path_changed(old_sm_path, new_sm_path, tab):
	fetch_state_machine_current_state()
	self.server.request_listen_sm(new_sm_path, self.server.get_client_peer(tab.name))


func _on_remote_sm_state_changed(old_state, new_state, by_transition, sm_path, client_id):
	sm_path = sm_path.split('/root/')[1]
#	print("[%s]%s state change from %s to %s (t:%s)" % [client_id, sm_path, old_state, new_state, str(by_transition)])
	if get_current_client_id() == client_id:
		if get_current_state_machine_path() == sm_path:
			get_current_tab().update_state(old_state, new_state, by_transition)
	else:
		self.server.request_listen_sm(null, self.server.get_client_peer(client_id))

func _on_tree_some_node_removed(tab):
	if tab == get_current_tab():
		fetch_state_machine_current_state()


func _on_TabContainer_tab_changed(tab):
	fetch_state_machine_current_state()
