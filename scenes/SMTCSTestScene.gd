extends Control

var a
var pi = PI

func eval_cond(cond):
	$Label.text = str(SMTCS.eval(cond, self))

func print_func(s1):
	print(s1)

func print_something_fun():
	print('fun')

func add(a, b):
	return a+b

func _on_Button_pressed():
	eval_cond($LineEdit.text)
