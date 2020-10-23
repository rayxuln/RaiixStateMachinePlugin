extends Reference

class_name SMTCSLexemer

# Lexeme Syntax
# q1_op => && | ||
# q2_op => == | >= | <= | != | > | <
# q3_op => + | -
# q4_op => * | / | %
# uni_op => !

# number => sign? integer (. integer)?
# sign => + | -
# integer => digit*
# digit => [0-9]

# string => " [^"]* | (\")?([^"] | \")* "

# boolean => false | true

# null => null

# identity => _? none_digit_or_op_char (digit | none_digit_or_op_char | _)*
# none_digit_or_op_char => [^opsdigit] 


enum LEXEME_TYPE {
	BIN_OP=0,
	UNI_OP,#1
	NUMBER,#2
	STRING,#3
	BOOLEAN,#4
	NULL,#5
	IDENTITY,#6
	CHAR#7
}

var source:String
var next:int
var current

var product_queue:Array

var error_cnt = 0

const BLANK_CHAR = [' ', '\n', '\t', '\r']

func _init(s):
	source = s
	next = 0
	current = null
	error_cnt = 0
	
	product_queue = []

func _iter_init(arg):
	current = get_next()
	return current != null

func _iter_next(arg):
	current = get_next()
	return current != null

func _iter_get(arg):
	return current

func _lexeme(t, v):
	return {
		"type": t,
		"value": v
	}
	
func _char(v):
	return _lexeme(LEXEME_TYPE.CHAR, v)

func _bin_op(v):
	return _lexeme(LEXEME_TYPE.BIN_OP, v)

func _uni_op(v):
	return _lexeme(LEXEME_TYPE.UNI_OP, v)

func _number(v):
	return _lexeme(LEXEME_TYPE.NUMBER, v)

func _boolean(v):
	return _lexeme(LEXEME_TYPE.BOOLEAN, v)

func _null(v):
	return _lexeme(LEXEME_TYPE.NULL, v)

func _identity(v):
	return _lexeme(LEXEME_TYPE.IDENTITY, v)

func _string(v):
	return _lexeme(LEXEME_TYPE.STRING, v)
	

func toast_raw_string(v:String):
	if v.empty():
		return v
	var id = v[0]
	if v.length() < 2:
		error("broken string")
		return ""
	v = v.substr(1, v.length()-2)
	return v.c_unescape()
	
func get_double_op(op):
	if next + 1 >= source.length() || source[next+1] != op:
		return null
	var res = null
	res = _bin_op(source.substr(next, 2))
	next += 2
	return res

func error(msg):
	printerr(msg + " at " + str(next) + "!")
	print(source)
	var indicator=''
	for i in next-1:
		indicator += '~'
	indicator += '^'
	print(indicator)
	error_cnt += 1

func check_next(v, n=0):
	if v is Array:
		return next+n >= 0 and next+n < source.length() and source[next+n] in v
	return next+n >= 0 and next+n < source.length() and source[next+n] == v
func check_next_not(v, n=0):
	if v is Array:
		return next+n >= 0 and next+n < source.length() and not (source[next+n] in v)
	return next+n >= 0 and next+n < source.length() and source[next+n] != v

func check_next_is_integer(n=0):
	return next+n >= 0 and next+n < source.length() and source[next+n].is_valid_integer()

func check_next_is_identity(n=0):
	return next+n >= 0 and next+n < source.length() and source[next+n].is_valid_identifier()

func view_next():
	if product_queue.empty():
		produce()
	if product_queue.empty():
		return null
	return product_queue[0]

func get_next():
	produce()
	return consume() 

func consume():
	if product_queue.empty():
		return null
	var product = product_queue.pop_front()
	return product

func produce():
	var product = _get_next()
	if product:
		product_queue.push_back(product)

func get_string(id):
	if check_next(id):
		var start = next
		next += 1
		var esc = false
		while next < source.length():
			if esc:
				esc	= false
				next += 1
				continue
			if not esc and check_next('\\'):
				esc = true
				next += 1
				continue
			if check_next(id):
				break
			next += 1
		if start+1 == next:
			next += 1
			return _string("")
		if not check_next(id):
			error("Expected %s" % id)
			return null
		next += 1
		var res = source.substr(start, next-start)
#		print("raw res: " + res)
		res = toast_raw_string(res)
#		print("res: " + res)
		
		return _string(res)

func _get_next():
	while check_next(BLANK_CHAR):
		next += 1
	
	if next >= source.length():
		return null
		
	var res = null
	
	# get double char bin op
	if check_next('&'):
		res = get_double_op('&')
	elif check_next('|'):
		res = get_double_op('|')
	elif check_next('>'):
		res = get_double_op('=')
	elif check_next('='):
		res = get_double_op('=')
	elif check_next('<'):
		res = get_double_op('=')
	elif check_next('!'):
		res = get_double_op('=')
	
	if res:
		return res
	
	# get single char bin op
	if check_next(['+', '-', '*', '/', '%', '>', '<']):
		res = _bin_op(source[next])
		next += 1
		return res
	
	# get uni op
	if check_next('!'):
		res = _uni_op(source[next])
		next += 1
		return res
	
	# get number
	if source[next].is_valid_integer():
		var start = next
		while check_next_is_integer():
			next += 1
		
		if check_next('.'):
			next += 1
			var temp = next
			while check_next_is_integer():
				next += 1
			if temp == next:
				error("Expected .")
				return null
		var number = source.substr(start, next-start)
		return _number(number)
	
	# get boolean
	if check_next('f', 0):
		if check_next('a', 1):
			if check_next('l', 2):
				if check_next('s', 3):
					if check_next('e', 4):
						res = _boolean(source.substr(next, 5))
						next += 5
						return res
	if check_next('t', 0):
		if check_next('r', 1):
			if check_next('u', 2):
				if check_next('e', 3):
					res = _boolean(source.substr(next, 4))
					next += 4
					return res
	
	# get null
	if check_next('n', 0):
		if check_next('u', 1):
			if check_next('l', 2):
				if check_next('l', 3):
					res = _null(source.substr(next, 4))
					next += 4
					return res
	
	# get identity
	if check_next('_') or check_next_is_identity():
		var start = next
		while check_next('_') or check_next_is_integer() or check_next_is_identity():
			next += 1
		var id = source.substr(start, next-start)
		return _identity(id)
	
	# get string
	res = get_string('"')
	if res:
		return res
	res = get_string("'")
	if res:
		return res
	
	
	
	# get char
	if next >= source.length():
		return null
	res = _char(source[next])
	if source[next] == '.' and check_next(BLANK_CHAR, -1):
		error("Unexpected %s before ." % _str_escape(source[next-1]))
		next += 1
		return null
	if source[next] == '.' and check_next(BLANK_CHAR, 1):
		next += 2
		error("Unexpected %s after ." % _str_escape(source[next-1]))
		return null
	next += 1
	return res

func _str_escape(c:String):
	if c == ' ':
		return 'space'
	return c.c_escape()
