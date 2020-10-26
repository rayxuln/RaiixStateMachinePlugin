extends Node

var server_addr:String = "127.0.0.1"
var server_port:int = 25561


var client_peers:Array = []

var server:TCP_Server

enum VAR_PACKET_TYPE {
	REQUEST,
	RESPOND
}


func _ready():
	server = TCP_Server.new()
	start_listening()
	

func _process(delta):
	if server.is_listening():
		if server.is_connection_available():
			var client:StreamPeerTCP = server.take_connection()
			var peer:PacketPeerStream = PacketPeerStream.new()
			peer.allow_object_decoding = true
			peer.stream_peer = client
			request_set_client_id(peer)
			client_peers.append(peer)
	
	var bad_peer = []
	for c in client_peers:
		var peer = c as PacketPeerStream
		var client = peer.stream_peer as StreamPeerTCP
		if client.get_status() == StreamPeerTCP.STATUS_ERROR:
			print_msg("Client disconnected because error.")
			bad_peer.append(peer)
			continue
		if client.get_status() == StreamPeerTCP.STATUS_NONE:
			print_msg("Client disconnected because why not.")
			bad_peer.append(peer)
			continue
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			if peer.get_available_packet_count() > 0:
				for i in peer.get_available_packet_count():
					var v = peer.get_var(true)
					var res = peer.get_packet_error()
					if res == OK:
						handle_var_packet(v, peer)
					else:
						print_err("Error(%d), a packet fail!" % res)
	
	if bad_peer.size() > 0:
		var new_client_peers = []
		for c in client_peers:
			if not c in bad_peer:
				new_client_peers.append(c)
		client_peers = new_client_peers
#----- Request -----
func gen_request(n):
	return {
		'type': VAR_PACKET_TYPE.REQUEST,
		'id': OS.get_ticks_msec(),
		'name': n,
		'data': {}
	}
func request_set_client_id(client_peer):
	var req = gen_request('set_client_id')
	req.data.client_id = gen_client_id(client_peer)
	send_var_packet(req, client_peer)
#----- Respond -----
func gen_respond(id, n):
	return {
		'type': VAR_PACKET_TYPE.RESPOND,
		'name': n,
		'id': id,
		'code': 0,
		'msg': 'ok',
		'data': {}
	}
func gen_handler_func(packet):
	var h_req = "h_req_" # request handler
	var h_res = "h_res_" # respond handler
	if packet.type == VAR_PACKET_TYPE.REQUEST:
		return h_req + packet.name
	if packet.type == VAR_PACKET_TYPE.RESPOND:
		return h_res + packet.name
	printerr("Unkown packet type.")
	return ""
func h_res_set_client_id(res, client_peer):
	print_msg("Set client id of %s ok" % gen_client_id(client_peer))
#----- Methods -----
func start_listening():
	print_msg("Server listen on %s:%d" % [server_addr, server_port])
	var res = server.listen(server_port, server_addr)
	if res != OK:
		print_err("Error(%d): Can't listen on %s:%d" % [res, server_addr, server_port])

func stop_listening():
	if server.is_listening():
		server.stop()

func send_var_packet(var_packet, client_peer:PacketPeerStream):
	var_packet = encode_var(var_packet)
	client_peer.put_var(var_packet)

func send_var_packet_to_all(var_packet):
	var_packet = encode_var(var_packet)
	for c in client_peers:
		c.put_var(var_packet)

func handle_var_packet(var_packet, client_peer:PacketPeerStream):
	var_packet = decode_var(var_packet)
	
	var handler_func = gen_handler_func(var_packet)
	if self.has_method(handler_func):
		call(handler_func, var_packet, client_peer)

func print_msg(msg:String):
	print("[RDS]%s" % msg)

func print_err(msg:String):
	printerr("[RDS]%s" % msg)

func gen_client_id(client_peer:PacketPeerStream):
	var client = client_peer.stream_peer as StreamPeerTCP
	return "%s:%d" % [client.get_connected_host(), client.get_connected_port()]

func get_client_peer(id:String):
	for c in client_peers:
		if gen_client_id(c) == id:
			return c
	return null

func encode_var(v):
	var bs = var2bytes(v, true)
	return [bs.size(), bs.compress()]

#encoded_v = [origin_size, compressed_bytes]
func decode_var(encoded_v:Array):
	var origin_size:int = encoded_v[0]
	var encoded_bs:PoolByteArray = encoded_v[1]
	var bs = encoded_bs.decompress(origin_size)
	return bytes2var(bs, true)
#----- Signals -----
func _send_some():
	var rand = ["Hi", "OK", "Fine"]
	send_var_packet_to_all(rand[randi()%rand.size()])
	get_tree().create_timer(1).connect("timeout", self, "_send_some")

