extends AudioStreamPlayer

const home_music = preload("res://assets/audio/songs/midnight-forest.mp3")
const FADE_OUT_TIME = 4.0

func _play_music(music: AudioStream, volume = 0.0):
	if stream == music:
		return
	
	stream = music
	volume_db = volume
	play()

func _end_music(music: AudioStream, volume = 0.0):
	if stream == music:
		var tween = create_tween()
		tween.tween_property(self, "volume_db", -80, FADE_OUT_TIME)
		tween.play()
		await tween.finished
		stream = null
	else:
		stream = null

func play_home_music():
	_play_music(home_music)

func end_home_music():
	_end_music(home_music)
