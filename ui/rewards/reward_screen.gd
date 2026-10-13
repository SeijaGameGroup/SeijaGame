extends Control

@onready var cards: Array[Button] = [$Panel/Cards/Card1, $Panel/Cards/Card2, $Panel/Cards/Card3]
@onready var heading: Label = $Panel/Heading

func _ready() -> void:
	hide()
	for index: int in cards.size():
		cards[index].pressed.connect(func() -> void: Game.rewards.choose(index))

func bind_rewards(controller: RewardController) -> void:
	controller.offered.connect(_offer)
	controller.closed.connect(hide)

func _offer(choices: Array[int], title: String) -> void:
	heading.text = title
	for index: int in choices.size():
		cards[index].present(choices[index], index)
	show()
	cards[0].grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	var index: int = event.physical_keycode - KEY_1
	if index >= 0 and index < 3:
		Game.rewards.choose(index)
		get_viewport().set_input_as_handled()
