extends Control


func eval_cond(cond):
	$Label.text = str(SMTCS.eval(cond, self))

func print_func(s1):
	print(s1)

func add(a, b):
	return a+b

func _on_Button_pressed():
	eval_cond($LineEdit.text)
