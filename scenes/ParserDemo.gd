extends Node2D



	
	
	
func get_enum_name(enum_type, value):
	for k in enum_type:
		if enum_type[k] == value:
			return k
	return "<UnkownEnum>"

func print_lexemers(cond):
	var p = SMTCSLexemer.new(cond)
	print('[')
	for l in p:
		print("[%s, %s]" % [get_enum_name(SMTCSLexemer.LEXEME_TYPE, l.type), l.value])
	print(']')

func test_pure_number_cond():
	print_lexemers("1+1 \n")
	print_lexemers("2+ 33.0-4*6/51")
	print_lexemers("2+(3 3.0-4)*6/51")
	print_lexemers("!342 ")
	print_lexemers("3>=0. ")
	print_lexemers("4==3.1415936 ")
	print_lexemers("4>3.1415936 ")
	print_lexemers("4<3.1415936 ")

func test_pure_boolean_cond():
	print_lexemers("true == false ")
	print_lexemers("true && true null")
	print_lexemers("false == null ")

func test_pure_identity_cond():
	print_lexemers("_asdas655")
	print_lexemers("21sdas241")
	print_lexemers("21sdas 241")
	print_lexemers("21sdas_241")
	print_lexemers("_")
	print_lexemers("asdasd  _sad")

func test_pure_string_cond():
	print_lexemers('("66666")')
	print_lexemers('("66666)')
	print_lexemers('("')
	print_lexemers('"Hello" + "Wor\\"ld!" == "Hello Wor\\"ld!"')

func test_pure_dot_index():
	print_lexemers('a.b')
	print_lexemers('a.b.c.d')

func print_ast_tree(cond):
	var p = SMTCSParser.new(cond)
	print(JSON.print(p.parse(), "\t"))
	
func eval_cond(cond):
	print("[" + cond + "]: " + str(SMTCS.eval(cond, self)))

func _test_parsing_1():
	eval_cond("1 + 1")
	eval_cond("1 + 1 * 0")
	eval_cond("(1 + 1) * 0")
	eval_cond("1== 1.13")
	eval_cond("1== 1.13?")
	eval_cond("(1== 1.1 3)")
	eval_cond('1+1==2 ? "Gr\\"eat!" : "Oh no."')

	

func _test_parsing_2():
	eval_cond("name+'666'")
	eval_cond('{"name":name , "age": "mix"}')
	eval_cond('[name, 233/2]')

func test_parsing_3():
	eval_cond('1+1 + 2*2')
	eval_cond('1+(1 + 2)*2')
	eval_cond('1+1')
	eval_cond('1*2')
	eval_cond('1* 2*3')
	eval_cond('1+')

func test_parsing_false():
	eval_cond('false')
	eval_cond('true')

var a1 = {"type":666, "x":{"x":233}}
func test_dot_index():
	eval_cond('a1 . type+3')
	eval_cond('a1. x . x')
	eval_cond('a1.type+3')
	eval_cond('{"x":332}.x')

func _ready():
	var t = RaiixTester.new(self, "SMTCS Parsing Tester")
	t.run_tests()
