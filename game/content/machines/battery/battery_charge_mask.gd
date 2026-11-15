class_name BatteryChargeMask
extends Node2D

## Hides the amber bars of the battery art as the charge drops. The game art has
## three fixed bars; this node covers the missing part with the same dark navy as
## the gauge background, so the painted gauge matches the real charge.

const GAUGE_ORIGIN: Vector2 = Vector2(-14.0, -24.0)
const GAUGE_SIZE: Vector2 = Vector2(18.0, 48.0)
const EMPTY_COLOR: Color = Color("#1b2540")

var _ratio: float = 1.0


## Filled proportion in [0, 1]. Full charge draws nothing.
func set_ratio(value: float) -> void:
	_ratio = clampf(value, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var missing: float = 1.0 - _ratio
	if missing <= 0.0:
		return
	draw_rect(
		Rect2(GAUGE_ORIGIN, Vector2(GAUGE_SIZE.x, GAUGE_SIZE.y * missing)),
		EMPTY_COLOR
	)
