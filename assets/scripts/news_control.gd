extends Control

var texts = [
	"fun fact: this code was stolen from spc",
	"demo released!!",
	"all rights reserved to quntem studios",
	"don't steal my art?!",
	"this is NOT a mod",
	"godot on top",
	"unity is ass",
	"if you cant beat the tutorial, you have a skill issue.",
	"this game has a deadline of 2nd of april",
	"made with godot",
	"please feed the poor (us)",
	"let us pay our rent by buying the game for more money than it requires",
	"check out clatter, our chatting platform",
	"created by quntem !!",
	"directed by sabio the idiot",
	"yo mama",
	"check out cloud+ (coming soon)",
	"change x back to twitter (or die)",
	"mod our game (for free)",
	"this game is open sourced (wow, i didn't know)",
	"this game was made for juice.hackclub.com/jungle",
	"this game made me 400$ without selling a single copy",
	"go hackclub!",
	"not sponsored by elon musk",
	"hiring!!!!!!!!!! (not, we don't have money)",
	"fail the tutorial for a refund (joke)",
	"did you know that alt+f4 gives you 10,000 XP?",
	"no more arrays, please!!!!!!!!!!!!!!!!!!!!!!!!!!",
	"i love writing this shit for 20 minutes",
	":3",
	":(",
	":)",
	">:(",
	">:)",
	"^v^",
	"xvx",
	"86 949 36 968 9268 86 332633 69 6377243 84373 47 66 5673",
	"the above is not encoded, trust me",
	"there is a 1 in 38 chance you get this line!",
]

var last_text_index = -1

func _ready() -> void:
	$NewsLabel.text = get_random_text()
	$NewsControlTimer.start()

func get_random_text() -> String:
	var new_index = randi_range(0, texts.size() - 1)
	while new_index == last_text_index:
		new_index = randi_range(0, texts.size() - 1)
	last_text_index = new_index
	return texts[new_index]

func spawn_text():
	var text_scene = load("res://assets/scenes/subscene/news_label.tscn")
	var text = text_scene.instantiate()
	text.text = get_random_text()
	text.position.x = size.x  # Start just outside the right edge
	$".".add_child(text)

func _on_news_control_timer_timeout() -> void:
	spawn_text()
