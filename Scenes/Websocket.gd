extends Node

signal event_received

var client = WebSocketClient.new()
var ws_connected = false

var URL = "ws://127.0.0.1:5000"

var id = null

func delete():
	print("destroying websocket")
	get_tree().queue_delete(self)

func _ready():
	print("websocket ready")
	initialize()

func initialize():
	client.connect("connection_closed", self, "_closed")
	client.connect("connection_error", self, "_closed")
	client.connect("connection_established", self, "_connected")
	client.connect("data_received", self, "_on_data")

	if OS.get_name() == "HTML5":
		var protocols = PoolStringArray([])
		var err = client.connect_to_url(URL, protocols, false, PoolStringArray())
		if err != OK:
			print("unable to connect")
			set_process(false)
	else:
		var headers = PoolStringArray([])
		var err = client.connect_to_url(URL, PoolStringArray(), false, headers)
		if err != OK:
			print("unable to connect")
			set_process(false)

func _closed(was_clean = false):
	print("closed, clean: ", was_clean)
	set_process(false)

func _connected(_proto):
	print("websocket connected")
	ws_connected = true
	
func _on_data():
	var packet = client.get_peer(1).get_packet()
	if client.get_peer(1).was_string_packet():
		var message = packet.get_string_from_utf8()
		
		var message_json = JSON.parse(message)
		if message_json.error == OK:
			if typeof(message_json.result) == TYPE_DICTIONARY:
				if message_json.result.has("id"):
					id = message_json.result["id"]
				elif message_json.result.has("source"):
					if id == null:
						return
					if message_json.result["source"] == id:
						return
					var event = message_json.result["event"]
					emit_signal("event_received", event)
	else:
		print("binary message received")

func _process(_delta):
	client.poll()

func send_event(event):
	if !ws_connected:
		return

	if id == null:
		return
		
	var message = {
		"source": id,
		"event": event, 
	}
	client.get_peer(1).set_write_mode(0)
	client.get_peer(1).put_packet(JSON.print(message).to_utf8())
	client.get_peer(1).set_write_mode(1)
	print("finished sending event")
