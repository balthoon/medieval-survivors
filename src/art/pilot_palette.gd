## Palette and drawing flags for one visual-direction pilot.
##
## The three mockups share one cast renderer, so the palette is where most of
## their difference is declared: ink, paper, body hues, rim colour, line weight,
## hatching, glow. The arena files carry their own scenery palette because the
## ground is where the three directions diverge the most.
class_name PilotPalette
extends RefCounted

const STYLE_STORYBOOK := 1
const STYLE_WOODCUT := 2
const STYLE_MIST := 3

## Which direction this palette belongs to. The cast and arena renderers branch
## on it for effects that a colour alone cannot express.
var style: int = STYLE_STORYBOOK
var label: String = "Encre de conte, édition enluminée"

## Outline and interior-detail ink.
var ink := Color(0.1647, 0.1255, 0.0902)
var ink_soft := Color(0.1647, 0.1255, 0.0902)
## Paper/bone highlight used for woodcut cuts and empty space.
var paper := Color(0.9529, 0.9020, 0.7686)
var bone := Color(0.9216, 0.8510, 0.6902)
var bone_dark := Color(0.7529, 0.6588, 0.4706)
var steel := Color(0.4549, 0.5137, 0.5608)
var steel_dark := Color(0.2745, 0.3216, 0.3608)
var tabard := Color(0.6627, 0.2039, 0.1647)
var cloak := Color(0.2902, 0.2078, 0.1451)
var wood := Color(0.4784, 0.3294, 0.2000)
var danger := Color(0.7686, 0.2275, 0.1686)
## Cold or warm highlight painted along the upper-left edges.
var rim_colour := Color(0.9608, 0.8902, 0.6902)
## Colour of the soft ground shadow.
var shadow := Color(0.1647, 0.1255, 0.0902)
## Colour of the hatch strokes.
var hatch_colour := Color(0.2275, 0.1725, 0.1137)
## Eye colour for the undead, used only when [member glow_eyes] is true.
var eye_colour := Color(0.1647, 0.1255, 0.0902)

var outline: float = 2.0
var detail: float = 1.1
var actor_scale: float = 1.42
var hatch: bool = true
var glow_eyes: bool = false
## Saturation multiplier applied to an enemy's data colour. 1 keeps it as is.
var tint_saturation: float = 1.0
## Value multiplier applied to an enemy's data colour.
var tint_value: float = 1.0


func _init(style_id: int = STYLE_STORYBOOK) -> void:
	style = style_id
	match style_id:
		STYLE_WOODCUT:
			_configure_woodcut()
		STYLE_MIST:
			_configure_mist()
		_:
			_configure_storybook()


func _configure_storybook() -> void:
	label = "Encre de conte, édition enluminée"
	ink = Color(0.1647, 0.1255, 0.0902)
	ink_soft = Color(0.1647, 0.1255, 0.0902)
	paper = Color(0.9529, 0.9020, 0.7686)
	bone = Color(0.9216, 0.8510, 0.6902)
	bone_dark = Color(0.7529, 0.6588, 0.4706)
	steel = Color(0.4549, 0.5137, 0.5608)
	steel_dark = Color(0.2745, 0.3216, 0.3608)
	tabard = Color(0.6627, 0.2039, 0.1647)
	cloak = Color(0.2902, 0.2078, 0.1451)
	wood = Color(0.4784, 0.3294, 0.2000)
	danger = Color(0.7686, 0.2275, 0.1686)
	rim_colour = Color(0.9608, 0.8902, 0.6902)
	shadow = _alpha(Color(0.1647, 0.1255, 0.0902), 0.18)
	hatch_colour = _alpha(Color(0.2275, 0.1725, 0.1137), 0.22)
	eye_colour = Color(0.1647, 0.1255, 0.0902)
	outline = 2.0
	detail = 1.1
	actor_scale = 1.42
	hatch = true
	glow_eyes = false
	tint_saturation = 1.0
	tint_value = 1.0


func _configure_woodcut() -> void:
	label = "Gravure sur bois"
	ink = Color(0.0902, 0.0745, 0.0588)
	ink_soft = Color(0.0902, 0.0745, 0.0588)
	paper = Color(0.9137, 0.8706, 0.7608)
	bone = Color(0.9137, 0.8706, 0.7608)
	bone_dark = Color(0.7176, 0.6392, 0.4863)
	steel = Color(0.5412, 0.5216, 0.4706)
	steel_dark = Color(0.2902, 0.2745, 0.2353)
	tabard = Color(0.5569, 0.1686, 0.1373)
	cloak = Color(0.1412, 0.1216, 0.1020)
	wood = Color(0.2275, 0.1647, 0.1137)
	danger = Color(0.6392, 0.1412, 0.1098)
	rim_colour = Color(0.9686, 0.9373, 0.8471)
	shadow = _alpha(Color(0.0902, 0.0745, 0.0588), 0.22)
	hatch_colour = _alpha(Color(0.0902, 0.0745, 0.0588), 0.40)
	eye_colour = Color(0.0902, 0.0745, 0.0588)
	outline = 3.0
	detail = 1.2
	actor_scale = 1.38
	hatch = true
	glow_eyes = false
	## Woodcut keeps enemy colours almost monochrome: bone for the undead, ink
	## for the beasts. The cast renderer does the rest with the style flag.
	tint_saturation = 0.25
	tint_value = 0.98


func _configure_mist() -> void:
	label = "Clair-obscur, aube de brume"
	ink = Color(0.0627, 0.0902, 0.0824)
	ink_soft = Color(0.0627, 0.0902, 0.0824)
	paper = Color(0.6627, 0.7216, 0.6745)
	bone = Color(0.7804, 0.7765, 0.6745)
	bone_dark = Color(0.4863, 0.5216, 0.4549)
	steel = Color(0.3569, 0.4235, 0.4471)
	steel_dark = Color(0.1843, 0.2314, 0.2510)
	tabard = Color(0.5412, 0.1804, 0.2000)
	cloak = Color(0.1098, 0.1216, 0.1137)
	wood = Color(0.2275, 0.1961, 0.1490)
	danger = Color(0.7608, 0.2902, 0.2275)
	rim_colour = Color(0.7333, 0.8392, 0.8078)
	shadow = _alpha(Color(0.0235, 0.0392, 0.0353), 0.28)
	hatch_colour = _alpha(Color(0.0235, 0.0392, 0.0353), 0.0)
	eye_colour = Color(0.6235, 0.8784, 0.8392)
	outline = 2.2
	detail = 1.0
	actor_scale = 1.44
	hatch = false
	glow_eyes = true
	tint_saturation = 0.65
	tint_value = 0.72


## A copy of [param colour] with [param opacity] replacing its alpha.
static func _alpha(colour: Color, opacity: float) -> Color:
	return Color(colour.r, colour.g, colour.b, opacity)


## Blends a data colour toward this palette so the cast still belongs to the
## world. Woodcut desaturates almost to ink; mist darkens and cools.
func body_tint(tint: Color) -> Color:
	if style == STYLE_WOODCUT:
		var grey := tint.get_luminance()
		return Color(grey, grey, grey).lerp(ink, 0.35)
	var desaturated := Color(tint.r, tint.g, tint.b).lerp(
		Color(tint.get_luminance(), tint.get_luminance(), tint.get_luminance()),
		1.0 - tint_saturation
	)
	var valued := desaturated * tint_value
	valued.a = 1.0
	if style == STYLE_MIST:
		valued = valued.lerp(Color(0.2275, 0.2902, 0.2706), 0.18)
	return valued
