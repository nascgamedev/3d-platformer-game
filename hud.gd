extends CanvasLayer

var timer = null
var cooldown := 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CoinsLabel.text = str(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# $CoinsLabel.text = str(Global.coins)
	#pass
	if timer != null:
		$Dash.get_node("HudDashProgresso").value = timer.get_time_left() * 100
		if timer.get_time_left() == 0.0:
			timer = null

func updateDash(up: bool):
	$Dash.get_node("HudDashUp").set_visible(up)
	
	if not up and timer == null:
		timer = get_tree().create_timer(cooldown)
