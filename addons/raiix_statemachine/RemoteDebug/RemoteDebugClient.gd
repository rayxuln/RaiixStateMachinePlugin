extends Node

var enable:bool = true

var server_addr:String = "127.0.0.1"
var server_port:int = 25561

var connecting = false
var connected = false

var stream_peer:StreamPeerTCP = null
var packet_peer:PacketPeerStream = null

var client_id:String

var current_listening_sm:StateMachine = null

enum VAR_PACKET_TYPE {
	REQUEST,
	RESPOND
}

func _ready():
	if enable:
		start_connecting()
	else:
		queue_free()
	

func _process(delta):
	if not connected:
		if connecting:
			match stream_peer.get_status():
				StreamPeerTCP.STATUS_CONNECTED:
					print_msg("Connect to server successfully!")
					connecting = false
					connected = true
					stream_peer.set_no_delay(true)
				StreamPeerTCP.STATUS_ERROR:
					print_err("Connect to server fail!")
					connecting = false
					release()
	else:
		match stream_peer.get_status():
			StreamPeerTCP.STATUS_CONNECTED:
				wait_for_packet()
			StreamPeerTCP.STATUS_ERROR:
				print_err("Disconnect to the server because some errors!")
				connected = false
				release()
			StreamPeerTCP.STATUS_NONE:
				print_err("Disconnect to the server because why not.")
				connected = false
				release()
		
#----- Request -----
func gen_request(n):
	return {
		'type': VAR_PACKET_TYPE.REQUEST,
		'id': OS.get_ticks_msec(),
		'name': n,
		'data': {}
	}
func gen_respond(id, n):
	return {
		'type': VAR_PACKET_TYPE.RESPOND,
		'name': n,
		'id': id,
		'code': 0,
		'msg': 'ok',
		'data': {}
	}

func request_sm_state_changed(old_state:String, new_state:String, by_transition:bool, sm_path:String):
	var req = gen_request('sm_state_changed')
	req.data.old_state = old_state
	req.data.new_state = new_state
	req.data.by_transition = by_transition
	req.data.sm_path = sm_path
	
	send_var_packet(req)

#----- Handler -----
func gen_handler_func(packet):
	var h_req = "h_req_"
	var h_res = "h_res_"
	if packet.type == VAR_PACKET_TYPE.REQUEST:
		return h_req + packet.name
	if packet.type == VAR_PACKET_TYPE.RESPOND:
		return h_res + packet.name
	printerr("Unkown packet type.")
	return ""
#req
func h_req_set_client_id(req):
	client_id = req.data.client_id
	print_msg("Get id: %s" % client_id)
	
	var res = gen_respond(req.id, req.name)
	send_var_packet(res)
func h_req_get_tree_info(req):
	var res = gen_respond(req.id, req.name)
	
	res.data.tree_info = gen_tree_info()
	
	send_var_packet(res)
func h_req_get_smr(req):
	var res = gen_respond(req.id, req.name)
	
	var smr = get_smr(req.data.sm_path)
	if not smr:
		res.code = -1
		res.msg = "Can't get smr of " + req.data.sm_path
	else:
		res.data.smr = smr
	
	send_var_packet(res)
func h_req_get_sm_state(req):
	var res = gen_respond(req.id, req.name)
	
	var sm = get_sm(req.data.sm_path)
	if not sm:
		res.code = -1
		res.msg = "Can't get state machine node of " + req.data.sm_path
	else:
		res.data.state = sm.get_current_state_name()
	
	send_var_packet(res)
func h_req_change_state(req):
#	var res = gen_respond(req.id, req.name)
	
	change_sm_state(req.data.sm_path, req.data.state)
func h_req_listen_sm(req):
#	var res = gen
	var sm = null
	if req.data.sm_path:
		sm = get_sm(req.data.sm_path)
	if sm != current_listening_sm:
		if current_listening_sm:
			if current_listening_sm.is_connected("state_changed", self, "_on_sm_state_changed"):
				current_listening_sm.disconnect("state_changed", self, "_on_sm_state_changed")
		current_listening_sm = sm
		if current_listening_sm:
			if not current_listening_sm.is_connected("state_changed", self, "_on_sm_state_changed"):
				current_listening_sm.connect("state_changed", self, "_on_sm_state_changed", [current_listening_sm])
#res
#------ Methods ------
func start_connecting():
	print_msg("RemoteDebugClient stated, connecting to %s:%d" % [server_addr, server_port])
	
	packet_peer = PacketPeerStream.new()
	packet_peer.allow_object_decoding = true
	stream_peer = StreamPeerTCP.new()
	
	var res = stream_peer.connect_to_host(server_addr, server_port)
	if res != OK:
		connection_fail(res)
	else:
		packet_peer.stream_peer = stream_peer
		connecting = true
	

func connection_fail(err):
	release()
	print_err("Error(%d), connection fail!" % err)
	connecting = false

func wait_for_packet():
	if packet_peer.get_available_packet_count() > 0:
		for i in packet_peer.get_available_packet_count():
			var v = packet_peer.get_var(true)
			var res = packet_peer.get_packet_error()
			if res == OK:
				handle_var_packet(v)
			else:
				print_err("Error(%d), a packet fail!" % res)
			
			

func send_var_packet(var_packet):
	var_packet = encode_var(var_packet)
	if connected:
		packet_peer.put_var(var_packet)

func handle_var_packet(var_packet):
	var_packet = decode_var(var_packet)
	
	
	var handler_func = gen_handler_func(var_packet)
	if self.has_method(handler_func):
		call(handler_func, var_packet)
	else:
		printerr("Not match handler for \"%s\"" % handler_func)

func release():
	packet_peer = null
	stream_peer = null

func print_msg(msg:String):
	if connected:
		print("[RDC:%s]%s" % [client_id, msg])
	else:
		print("[RDC]%s" % msg)

func print_err(msg:String):
	if connected:
		printerr("[RDC:%s]%s" % [client_id, msg])
	else:
		printerr("[RDC]%s" % msg)


func encode_var(v):
	var bs = var2bytes(v, true)
	return [bs.size(), bs.compress()]

#encoded_v = [origin_size, compressed_bytes]
func decode_var(encoded_v:Array):
	var origin_size:int = encoded_v[0]
	var encoded_bs:PoolByteArray = encoded_v[1]
	var bs = encoded_bs.decompress(origin_size)
	return bytes2var(bs, true)

func _gen_tree_info_node(n, is_sm:bool=false, is_root:bool=false):
	return {
		"name": n,
		"children": [],
		"sm": is_sm,
		"root": is_root
	}
func _gen_tree_info(node:Node):
	var tree_node = _gen_tree_info_node(node.name, node is StateMachine and node.state_machine_resource)
	for c in node.get_children():
		tree_node.children.append(_gen_tree_info(c))
	return tree_node
	
func gen_tree_info():
	var root = get_tree().root
	var root_node = _gen_tree_info_node('root', false, true)
	
	for c in root.get_children():
		root_node.children.append(_gen_tree_info(c))
	
	return root_node

func get_sm(sm_path):
	return get_tree().root.get_node_or_null(sm_path)

func get_smr(sm_path):
	var sm = get_sm(sm_path)
	if not sm:
		return null
	
	return sm.state_machine_resource

func change_sm_state(sm_path, state):
	var sm = get_sm(sm_path)
	if sm:
		sm.change_state(state)
	else:
		print_err("Try to change %s state to %s fail" % [sm_path, state])
#------ Singals -------
func _send_some():
	var rand = ["Hi", "OK", "Fine"]
	send_var_packet(rand[randi()%rand.size()])
	get_tree().create_timer(1).connect("timeout", self, "_send_some")
	

func _on_sm_state_changed(old_state, new_state, by_transition, sm):
	request_sm_state_changed(old_state, new_state, by_transition, sm.get_path())

