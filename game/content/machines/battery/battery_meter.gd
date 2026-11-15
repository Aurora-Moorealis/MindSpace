class_name BatteryMeter
extends Node2D

## Small segmented charge meter drawn above a battery. Five segments, all amber
## when the battery is full and all casing grey when it is empty.

const SEGMENTS: int = 5
const SEGMENT_SIZE: Vector2 = Vector2(5.0, 7.0)
const SEGMENT_GAP: float = 1.0
const OUTLINE_COLOR: Color = Color("#0f171f")
const FILLED_COLOR: Color = Color("#ffe27a")
const EMPTY_COLOR: Color = Color("#5f6b78")

var _ratio: float = 0.0


## Sets the filled proportion in [0, 1] and redraws the meter.
func set_ratio(value: float) -> void:
	_ratio = clampf(value, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var total_width: float = float(SEGMENTS) * SEGMENT_SIZE.x
	total_width += float(SEGMENTS - 1) * SEGMENT_GAP
	var origin: Vector2 = Vector2(-total_width * 0.5, 0.0)
	var frame: Rect2 = Rect2(
		origin - Vector2.ONE, Vector2(total_width + 2.0, SEGMENT_SIZE.y + 2.0)
	)
	draw_rect(frame, OUTLINE_COLOR)
	for index: int in range(SEGMENTS):
		var threshold: float = float(index + 1) / float(SEGMENTS)
		var color: Color = FILLED_COLOR if _ratio + 0.0001 >= threshold else EMPTY_COLOR
		var offset_x: float = float(index) * (SEGMENT_SIZE.x + SEGMENT_GAP)
		draw_rect(Rect2(origin + Vector2(offset_x, 0.0), SEGMENT_SIZE), color)
