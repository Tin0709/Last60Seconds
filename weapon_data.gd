extends RefCounted

# The available single-shot recordings are rifle calibers. Pitch/level distinguish
# the smaller guns; a launcher/explosion recording is still pending.
const RIFLE_SHOT = preload("res://assets/Snake's Authentic Gun Sounds/Isolated/5.56/WAV/556 Single Isolated WAV.wav")
const HEAVY_SHOT = preload("res://assets/Snake's Authentic Gun Sounds/Isolated/7.62x39/WAV/762x39 Single Isolated WAV.wav")
const SNIPER_SHOT = preload("res://assets/Snake's Authentic Gun Sounds/Isolated/7.62x54R/WAV/762x54r Single Isolated WAV.wav")
const GUNS = {
	&"pistol": {"texture": preload("res://assets/FreePixelGunPack/Guns/7.png"), "sound": HEAVY_SHOT,
		"interval": 0.38, "speed": 800.0, "count": 1, "spread": 0.0, "volume": -21.0, "pitch": 1.18, "scale": 2.0, "explosive": false},
	&"smg": {"texture": preload("res://assets/FreePixelGunPack/Guns/27.png"), "sound": RIFLE_SHOT,
		"interval": 0.09, "speed": 850.0, "count": 1, "spread": 0.0, "volume": -25.0, "pitch": 1.08, "scale": 1.0, "explosive": false},
	&"gun": {"texture": preload("res://assets/FreePixelGunPack/Guns/47.png"), "sound": RIFLE_SHOT,
		"interval": 0.22, "speed": 900.0, "count": 1, "spread": 0.0, "volume": -18.0, "pitch": 1.0, "scale": 1.0, "explosive": false},
	&"shotgun": {"texture": preload("res://assets/FreePixelGunPack/Guns/40.png"), "sound": HEAVY_SHOT,
		"interval": 0.7, "speed": 780.0, "count": 5, "spread": 20.0, "volume": -19.0, "pitch": 0.78, "scale": 1.0, "explosive": false},
	&"sniper": {"texture": preload("res://assets/FreePixelGunPack/Guns/50.png"), "sound": SNIPER_SHOT,
		"interval": 1.0, "speed": 1500.0, "count": 1, "spread": 0.0, "volume": -19.0, "pitch": 1.0, "scale": 1.0, "explosive": false},
	&"launcher": {"texture": preload("res://assets/FreePixelGunPack/Guns/45.png"), "sound": null,
		"interval": 1.25, "speed": 420.0, "count": 1, "spread": 0.0, "volume": -20.0, "pitch": 1.0, "scale": 1.0, "explosive": true},
}
