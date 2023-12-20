extends Node
class_name ServerAdvertiser, 'res://addons/LANServerBroadcast/server_advertiser/server_advertiser.png'

const DEFAULT_PORT := 6111

export (float) var broadcast_interval: float = 1.0
var serverInfo := {"name": "LAN Game"}

var socketUDP: PacketPeerUDP
var broadcastTimer := Timer.new()
var broadcastPort := DEFAULT_PORT

func _enter_tree():
	broadcastTimer.wait_time = broadcast_interval
	broadcastTimer.one_shot = false
	broadcastTimer.autostart = true

func start():
	add_child(broadcastTimer)
	broadcastTimer.connect("timeout", self, "_broadcast") 
		
	socketUDP = PacketPeerUDP.new()
	socketUDP.set_broadcast_enabled(true)
	var result = socketUDP.set_dest_address('255.255.255.255', broadcastPort)
	
	if result == OK:
		print("Broadcast started successfully.")
	else:
		print("Broadcast couldn't start, error code: " + String(result))

func stop():
	broadcastTimer.stop()
	if socketUDP != null:
		socketUDP.close()

func _broadcast():
	var packetMessage := to_json(serverInfo)
	var packet := packetMessage.to_utf8()
	socketUDP.put_packet(packet)
