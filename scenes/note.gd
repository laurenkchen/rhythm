extends Area2D

signal missed

var lane:=0
var speed:=300.0
var miss_y := 640.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.y += speed * delta
	if position.y>miss_y:
		missed.emit()
		queue_free()
		
