extends Panel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal color_changed
var current_color = Color()

func update_display_color():
	$display.modulate = current_color
	$hex.text = current_color.to_html(false)
	emit_signal("color_changed", current_color)
	
func update_r(value):
	current_color = Color(value,current_color.g,current_color.b)
	update_display_color()
func update_g(value):
	current_color = Color(current_color.r,value,current_color.b)
	update_display_color()
func update_b(value):
	current_color = Color(current_color.r,current_color.g,value)
	update_display_color()

func set_color(color):
	current_color = color
	$r.value = current_color.r
	$g.value = current_color.g
	$b.value = current_color.b
	update_display_color()

func set_hex(hex):
	current_color = Color(hex)
	set_color(current_color)

func _ready():
	$hex.connect("text_changed", self, "set_hex")
	$r.connect("value_changed", self, "update_r")
	$g.connect("value_changed", self, "update_g")
	$b.connect("value_changed", self, "update_b") 
