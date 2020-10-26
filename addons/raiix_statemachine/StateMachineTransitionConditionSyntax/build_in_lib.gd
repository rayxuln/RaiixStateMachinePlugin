extends Reference

#var agent

var _OS setget ,_on_get_OS
func _on_get_OS():
	return OS

var _Input setget ,_on_get_Input
func _on_get_Input():
	return Input

func _init(a=null):
	pass

func _printf(s, f=[]):
	print(str(s) % f)

func _str(v):
	return str(v)

func _int(v):
	return int(v)

func _float(v):
	return float(v)

func _floor(v):
	return floor(v)

func _ceil(v):
	return ceil(v)

func _max(a, b):
	return max(a, b)

func _min(a, b):
	return min(a, b)

func _round(v):
	return round(v)

func _pow(a, x):
	return pow(a, x)

func _sqrt(v):
	return sqrt(v)

func _randi():
	return randi()

func _randf():
	return randf()

func _choose(v):
	if v is Array and v.size() > 0:
		return v[randi()%v.size()]
	return null

