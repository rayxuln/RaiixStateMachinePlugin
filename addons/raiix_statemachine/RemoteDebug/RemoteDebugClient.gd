extends Node


var server_addr:String = "127.0.0.1"
var server_port:int = 25561

var connecting = false
var connected = false

var stream_peer:StreamPeerTCP = null
var packet_peer:PacketPeerStream = null

var client_id:String

enum VAR_PACKET_TYPE {
	REQUEST,
	RESPOND
}

func _ready():
	start_connecting()
	

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
func respond_set_client_id(req):
	client_id = req.data.client_id
	print_msg("Get id: %s" % client_id)
	
	var res = gen_respond(req.id, req.name)
	send_var_packet(res)
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
	var ms = get_method_list()
	var respond_func = "respond_" + var_packet.name
	for m in ms:
		if m.name == respond_func:
			call(respond_func, var_packet)
			break

func release():
	packet_peer = null
	stream_peer = null

func print_msg(msg:String):
	print("[RDC]%s" % msg)

func print_err(msg:String):
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
#------ Singals -------
func _send_some():
	var rand = ["Hi", "OK", "Fine"]
	send_var_packet(rand[randi()%rand.size()])
	get_tree().create_timer(1).connect("timeout", self, "_send_some")
	



