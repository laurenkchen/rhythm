extends Area2D

signal missed

var lane:=0
var speed:=300.0
var miss_y := 640.0
var is_missed := false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.y += speed * delta
	if not is_missed and position.y > 610.0:
		is_missed = true
		missed.emit()
		modulate = Color(0.9, 0.2, 0.25, 0.8)
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.15)
		tween.tween_callback(queue_free)

		
