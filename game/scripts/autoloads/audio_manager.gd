extends Node

## Central SFX player. One autoload, one bus, a small voice pool, so no scene
## has to own an AudioStreamPlayer or invent its own volume.
##
## Usage:
##     AudioManager.play(AudioManager.Sfx.HARVEST)
##
## The streams are normalized at authoring time (see
## `assets/audio/sfx/README.md`); the SFX bus only trims the whole pack.

enum Sfx {
	UI_CLICK,
	UI_OPEN,
	UI_CLOSE,
	UI_DENY,
	PLANT,
	HARVEST,
	REMOVE,
	SCAN,
	REPAIR,
	REPORT,
	RADIATION_ALARM,
	EVENT,
}

## Emitted after a voice starts; useful for tests and future captions.
signal sfx_played(sfx: Sfx)

const SFX_BUS: StringName = &"SFX"
const PLAYER_COUNT: int = 10

const STREAMS: Dictionary[int, AudioStream] = {
	Sfx.UI_CLICK: preload("res://assets/audio/sfx/ui_click.ogg"),
	Sfx.UI_OPEN: preload("res://assets/audio/sfx/ui_open.ogg"),
	Sfx.UI_CLOSE: preload("res://assets/audio/sfx/ui_close.ogg"),
	Sfx.UI_DENY: preload("res://assets/audio/sfx/ui_deny.ogg"),
	Sfx.PLANT: preload("res://content/machines/hydroponics/sounds/plant.ogg"),
	Sfx.HARVEST: preload("res://content/machines/hydroponics/sounds/harvest.ogg"),
	Sfx.REMOVE: preload("res://content/machines/hydroponics/sounds/remove.ogg"),
	Sfx.SCAN: preload("res://assets/audio/sfx/scan.ogg"),
	Sfx.REPAIR: preload("res://assets/audio/sfx/repair.ogg"),
	Sfx.REPORT: preload("res://assets/audio/sfx/report.ogg"),
	Sfx.RADIATION_ALARM: preload("res://assets/audio/sfx/radiation_alarm.ogg"),
	Sfx.EVENT: preload("res://assets/audio/sfx/event.ogg"),
}

## Small pitch jitter for repeated world actions; UI sounds stay fixed so they
## feel like the same control every time.
const PITCH_VARIATION: Dictionary[int, float] = {
	Sfx.PLANT: 0.05,
	Sfx.HARVEST: 0.06,
	Sfx.REMOVE: 0.05,
	Sfx.SCAN: 0.02,
	Sfx.REPAIR: 0.04,
}

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _muted: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index: int in range(PLAYER_COUNT):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxVoice%d" % index
		player.bus = SFX_BUS
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_players.append(player)


func play(sfx: Sfx, volume_db: float = 0.0) -> void:
	if _muted or _players.is_empty():
		return
	var stream: AudioStream = STREAMS.get(sfx) as AudioStream
	if stream == null:
		return
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	var variation: float = float(PITCH_VARIATION.get(sfx, 0.0))
	player.pitch_scale = 1.0 + randf_range(-variation, variation)
	player.play()
	sfx_played.emit(sfx)


func set_muted(value: bool) -> void:
	_muted = value
	if not _muted:
		return
	for player: AudioStreamPlayer in _players:
		player.stop()


func toggle_muted() -> bool:
	set_muted(not _muted)
	return _muted


func is_muted() -> bool:
	return _muted


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_M:
		toggle_muted()
		get_viewport().set_input_as_handled()
