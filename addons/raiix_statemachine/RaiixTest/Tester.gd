extends Reference

class_name RaiixTester

var target
var test_name

func _init(t, n):
	target = t
	test_name = n


func run_tests():
	print(">=====| Runing Tests of %s |=====<" % (test_name))
	var methods = []
	for m in target.get_method_list():
		if m.name.find("_test_") != -1:
			methods.append(m.name)
	print("Found total test num: " + str(methods.size()))
	var cnt = 0
	for m in methods:
		print("> Testing " + m + "[%d/%d]" % [cnt+1, methods.size()])
		target.call(m)
		cnt += 1
	print("Done!")
