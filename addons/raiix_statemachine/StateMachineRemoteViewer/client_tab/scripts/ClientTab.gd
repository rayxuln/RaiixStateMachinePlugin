tool
extends HSplitContainer


signal node_double_clicked(node_path, is_sm, is_root)
signal graph_node_left_button_pressed(node)
signal smr_path_changed(old_sm_path, new_sm_path)
signal tree_some_node_removed
signal on_search_line_edit_text_changed(new_text)

var old_tree_info = null

var go_to_icon_tex = preload("../../../images/edit_icon.png")
var play_icon_tex = preload("../../../images/play_icon.png")
var pause_icon_tex = preload("../../../images/pause_icon.png")

onready var tree = $VBoxContainer/Tree
onready var graph_edit = $GraphEditContainer/GraphEdit
onready var graph_edit_container = $GraphEditContainer
onready var info_container = $InfoContainer
onready var search_line_edit = $VBoxContainer/SearchLineEdit
onready var path_button_container = $GraphEditContainer/HBoxContainer/PathButtonContainer

var state_machine_resource:Resource = null setget _on_set_state_machine_resource
func _on_set_state_machine_resource(v):
	state_machine_resource = v
	if v:
		graph_edit_container.visible = true
		info_container.visible = false
		
		graph_edit.zoom = v.zoom
		graph_edit.scroll_offset = v.scroll_offset
		_load_state_machine_resource_to_graph_edit(v)
	else:
		graph_edit_container.visible = false
		info_container.visible = true
		
		graph_edit.clear_all_nodes()

var state_machine_node_path = ""

func _ready():
	graph_edit_container.visible = false
	info_container.visible = true

#----- Methods ------
func _gen_tree_node(p, tree_info_node):
	var tree_item = tree.create_item(p)
	tree_item.set_text(0, tree_info_node.name)
	tree_item.set_meta("sm", tree_info_node.sm)
	tree_item.set_meta("root", tree_info_node.root)
	for c in tree_info_node.children:
		_gen_tree_node(tree_item, c)

func _update_tree(tree_item:TreeItem, new_tree_info_node):
	var removed_tree_items = []
	# update children first
	var i:TreeItem = tree_item.get_children()
	while i:
		var is_stil_here = false
		for c in new_tree_info_node.children:
			if c.name == i.get_text(0):
				_update_tree(i, c)
				is_stil_here = true
				break
		if not is_stil_here:
			removed_tree_items.append(i)
		i = i.get_next()
	
	# delete that did delete
	if removed_tree_items.size() > 0:
		emit_signal("tree_some_node_removed")
	for r in removed_tree_items:
		r.free()
	
	# add that doesn't added
	for c in new_tree_info_node.children:
		var is_new = true
		i = tree_item.get_children()
		while i:
			if c.name == i.get_text(0):
				is_new = false
				break
			i = i.get_next()
		if is_new:
			_gen_tree_node(tree_item, c)
	
	
	
func add_path_button(n, path):
	var b = Button.new()
	path_button_container.add_child(b)
	b.name = n
	b.text = n
	b.set_meta("path", path)
	b.connect("pressed", self, "_on_path_button_pressed", [b])

func add_seperator():
	var s = VSeparator.new()
	path_button_container.add_child(s)

func clear_path_button_caintainer():
	if path_button_container.get_child_count() == 0:
		return
	var cs = []
	for c in path_button_container.get_children():
		cs.append(c)
	for c in cs:
		c.queue_free()

func generate_path_buttons_from_path(path:String):
	clear_path_button_caintainer()
	add_path_button('root', '/')
	var ss = path.split('/')
	var temp = '/'
	for s in ss:
		if not s.empty():
			temp += '/' + s
			add_seperator()
			add_path_button(s, temp)

func update_tree(tree_root):
	if old_tree_info == null:
		_gen_tree_node(null, tree_root)
		old_tree_info = tree_root
		tree.update()
		return
	
	var root = tree.get_root()
	_update_tree(root, tree_root)
	
	old_tree_info = tree_root
	tree.update()

func get_current_state_machine_path():
	if not state_machine_resource:
		return ""
	var r_path = state_machine_resource.path
	var res = state_machine_node_path
	var ss = r_path.split("/")
	for s in ss:
		if not s.empty():
			res += '/' + s + '/StateMachine'
#	print("The final sm path: " + res)
	return res

func change_node_left_button_state(node):
	if node.get_meta("left_button_state") == "play":
		node.set_meta("left_button_state", "stop")
		node.left_button_tex = play_icon_tex
		node.active = false
	elif node.get_meta("left_button_state") == "stop":
		node.set_meta("left_button_state", "play")
		node.left_button_tex = pause_icon_tex
		node.active = true

func update_state(old_state, new_state, by_transition):
	for node in graph_edit.nodes.get_children():
		if node.name == new_state:
			if not node.active:
				change_node_left_button_state(node)
		else:
			if node.active:
				change_node_left_button_state(node)
	
	if by_transition:
		var a = graph_edit.get_arrow(old_state, new_state)
		if a:
			a.active = true

func _load_state_machine_resource_to_graph_edit(sm_r):
	var sm_data = sm_r.current
	
	graph_edit.clear_all_nodes()
	
	# gen nodes
	for node_data in sm_data.states:
		var n = preload("../../../StateMachineEditor/graph_node/GraphNode.tscn").instance()
		graph_edit.add_node(n)
		n.tip_text = "Init" if node_data.init else ""
		n.name = node_data.name
		n.text = node_data.name
		n.offset = node_data.offset
		n.data = node_data
		n.left_button_tex = play_icon_tex
		n.set_meta("left_button_state", "stop") # stop | play
		n.right_button_tex = go_to_icon_tex if node_data.sub_state_machine else null
	
	# connect nodes
	for arrow_data in sm_data.transitions:
		var from = graph_edit.nodes.get_node_or_null(arrow_data.from)
		var to = graph_edit.nodes.get_node_or_null(arrow_data.to)
		
		graph_edit.connect_nodes(from, to, arrow_data)
	
	graph_edit.target_zoom = graph_edit.zoom
	
	generate_path_buttons_from_path(sm_r.path)

#----- Signals ------
func _on_Tree_item_activated():
	var i = tree.get_selected()
	if not i:
		return
	if i == tree.get_root():
		emit_signal("node_double_clicked", '.', false, true)
		return
	
	var is_sm = i.get_meta("sm")
	var path = ""
	while i and i != tree.get_root():
		if path.empty():
			path = i.get_text(0)
		else:
			path = i.get_text(0) + '/' + path
		i = i.get_parent()
	emit_signal("node_double_clicked", path, is_sm, false)

func _on_path_button_pressed(button):
	var old_sm_path = get_current_state_machine_path()
	state_machine_resource.go_to(button.get_meta("path"))
	var new_sm_path = get_current_state_machine_path()
	emit_signal("smr_path_changed", old_sm_path, new_sm_path)
	_load_state_machine_resource_to_graph_edit(state_machine_resource)


func _on_GraphEdit_node_reight_button_pressed(node):
	var old_sm_path = get_current_state_machine_path()
	state_machine_resource.go_to(node.name)
	var new_sm_path = get_current_state_machine_path()
	emit_signal("smr_path_changed", old_sm_path, new_sm_path)
	
	_load_state_machine_resource_to_graph_edit(state_machine_resource)


func _on_GraphEdit_node_left_button_pressed(node):
#	change_node_left_button_state(node)
	emit_signal("graph_node_left_button_pressed", node)


func _on_SearchLineEdit_text_changed(new_text):
	emit_signal("on_search_line_edit_text_changed", new_text)
