tool
extends HSplitContainer


var old_tree_info = null

onready var tree = $VBoxContainer/Tree

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

#----- Signals ------
func _on_Tree_item_double_clicked():
	pass # Replace with function body.
