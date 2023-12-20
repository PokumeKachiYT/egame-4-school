extends Node
class_name ServerListener, 'res://addons/LANServerBroadcast/server_listener/server_listener.png'

signal new_server
signal remove_server

var cleanUpTimer := Timer.new()
var socketUDP := PacketPeerUDP.new()
var listenPort := ServerAdvertiser.DEFAULT_PORT
var knownServers = {}

# Number of seconds to wait when a server hasn't been heard from
# before calling remove_server
export (int) var server_cleanup_threshold: float = 2

export var started: bool = false

func _init():
	cleanUpTimer.wait_time = server_cleanup_threshold
	cleanUpTimer.one_shot = false
	cleanUpTimer.autostart = true
	cleanUpTimer.connect("timeout", self, 'clean_up')
	add_child(cleanUpTimer)

func start():
	knownServers.clear()
	
	var result = socketUDP.listen(listenPort)
	
	if result != OK:
		print("GameServer LAN service: Error listening on port: " + str(listenPort))
		print("Error code: " + String(result))
	else:
		started = true
		print("GameServer LAN service: Listening on port: " + str(listenPort))

func stop():
	started = false
	socketUDP.close()

func _process(delta):
	if not started:
		return
	if socketUDP.get_available_packet_count() > 0:
		var serverIp = socketUDP.get_packet_ip()
		var serverPort = socketUDP.get_packet_port()
		var array_bytes = socketUDP.get_packet()
		
		if serverIp != '' and serverPort > 0:
			# We've discovered a new server! Add it to the list and let people know
			var key = serverIp + ":" + String(serverPort)
			print(key)
			if not knownServers.has(key):
				var serverMessage = array_bytes.get_string_from_utf8()
				var gameInfo = parse_json(serverMessage)
				gameInfo.ip = serverIp
				gameInfo.lastSeen = OS.get_unix_time()
				gameInfo.key = key
				knownServers[key] = gameInfo
				print("New server found: %s - %s:%s" % [gameInfo.name, gameInfo.ip, gameInfo.port])
				emit_signal("new_server", gameInfo)
			# Update the last seen time
			else:
				var gameInfo = knownServers[key]
				gameInfo.lastSeen = OS.get_unix_time()

func clean_up():
	var now = OS.get_unix_time()
	for serverIp in knownServers:
		var serverInfo = knownServers[serverIp]
		if (now - serverInfo.lastSeen) > server_cleanup_threshold:
			emit_signal("remove_server", serverInfo.key)
			knownServers.erase(serverIp)
			print('Remove old server: %s' % serverIp)
