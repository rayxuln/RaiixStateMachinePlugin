extends Reference

class_name SMTCSParser

# State Machine Transition Condition Syntax

# Gramar Syntax
# expr => term1 ? term1 : term1
# term1 => term2 | term1 q1_op term2
# term2 => term3 | term2 q2_op term3
# term3 => term4 | term3 q3_op term4
# term4 => term5 | term4 q4_op term5
# term5 => uni_op term6
# term6 => term7 [ expr ]
# term7 => term8 | term7.identity | term7.identity ( args )
# term8 => null | number | string | boolean | array | object | ( expr ) | identity | identity ( args )
# args => expr | args , expr

# array => [ elements ]
# elements => expr | elements , expr

# object => { key_values }
# key_values => key_value | key_values , key_values
# key_value => key : expr
# key => number | string

var lexemer:SMTCSLexemer

var max_error_cnt:int = 1

enum AST_NODE_TYPE {
	TERNARY,
	BINARY,
	UNITARY,
	INDEX,
	ARRAY,
	OBJECT,
	FUNC,
	OBJ_FUNC,
	NULL,
	NUMBER,
	STRING,
	BOOLEAN,
	IDENTITY
}

func _init(source):
	lexemer = SMTCSLexemer.new(source)
	
func parse():
	var ast = _expr()
	if lexemer.error_cnt > 0:
		return null
	return ast

func is_stop_parsing():
	return lexemer.error_cnt >= max_error_cnt

func check_is_char(n, v):
	if v is Array:
		return n != null and n.type == SMTCSLexemer.LEXEME_TYPE.CHAR && n.value in v
	return n != null and n.type == SMTCSLexemer.LEXEME_TYPE.CHAR && n.value == v

func check_is_not_char(n, v):
	if v is Array:
		return n != null and n.type == SMTCSLexemer.LEXEME_TYPE.CHAR && not (n.value in v)
	return n != null and n.type == SMTCSLexemer.LEXEME_TYPE.CHAR && n.value != v


func check_is_bin_op(n, v):
	if v is Array:
		return n != null and n.type == SMTCSLexemer.LEXEME_TYPE.BIN_OP && n.value in v
	return n != null and n.type == SMTCSLexemer.LEXEME_TYPE.BIN_OP && n.value == v

func check_is_uni_op(n, v):
	if v is Array:
		return n != null and n.type == SMTCSLexemer.LEXEME_TYPE.UNI_OP && n.value in v
	return n != null and n.type == SMTCSLexemer.LEXEME_TYPE.UNI_OP && n.value == v

func check_is_null(n):
	return n != null and n.type == SMTCSLexemer.LEXEME_TYPE.NULL

func check_is_number(n):
	return n != null and n.type == SMTCSLexemer.LEXEME_TYPE.NUMBER

func check_is_string(n):
	return n != null and n.type == SMTCSLexemer.LEXEME_TYPE.STRING

func check_is_boolean(n):
	return n != null and n.type == SMTCSLexemer.LEXEME_TYPE.BOOLEAN

func check_is_identity(n):
	return n != null and n.type == SMTCSLexemer.LEXEME_TYPE.IDENTITY

func check_is_literal(n):
	return check_is_null(n) || check_is_number(n) || check_is_string(n) || check_is_boolean(n) || check_is_identity(n)

func gen_ast_node(t):
	return {
		"children": [],
		"type": t,
		"op": null,
		"value": null
	}

func gen_ast_node_ternary(cond, l, r):
	var res = gen_ast_node(AST_NODE_TYPE.TERNARY)
	res.children = [cond, l, r]
	return res

func gen_ast_node_binary(l, r, op):
	var res = gen_ast_node(AST_NODE_TYPE.BINARY)
	res.children = [l, r]
	res.op = op
	return res

func gen_ast_node_unitary(x, op):
	var res = gen_ast_node(AST_NODE_TYPE.UNITARY)
	res.children = [x]
	res.op = op
	return res

func gen_ast_node_index(t, i):
	var res = gen_ast_node(AST_NODE_TYPE.INDEX)
	res.target = t
	res.index = i
	return res

func gen_ast_node_array(values):
	var res = gen_ast_node(AST_NODE_TYPE.ARRAY)
	res.children = values
	return res

func gen_ast_node_object(key_values):
	var res = gen_ast_node(AST_NODE_TYPE.OBJECT)
	res.children = key_values
	return res

func gen_ast_node_func(func_name, arg_list):
	var res = gen_ast_node(AST_NODE_TYPE.FUNC)
	res.func_name = func_name
	res.arg_list = arg_list
	return res

func gen_ast_node_obj_func(obj, func_name, arg_list):
	var res = gen_ast_node_func(func_name, arg_list)
	res.type = AST_NODE_TYPE.OBJ_FUNC
	res.obj = obj
	return res

func gen_ast_node_literal(type=AST_NODE_TYPE.NULL, value=null):
	var res = gen_ast_node(type)
	res.value = value
	return res

func _expr():
	if is_stop_parsing():
		return null
	var cond = _term1()
	
	var next = lexemer.view_next()
	if next == null:
		return cond
	
	if check_is_char(next, '?'):
		lexemer.get_next()
		var l = _term1()
		next = lexemer.get_next()
		if check_is_char(next, ':'):
			var r = _term1()
			return gen_ast_node_ternary(cond, l, r)
		else:
			lexemer.error("Syntax error: expected :")
			return null
	else:
		return cond

func _term1():
	if is_stop_parsing():
		return null
	var l = _term2()
	
	while true:
		var next = lexemer.view_next()
		if next == null:
			return l
		if check_is_bin_op(next, ['&&', '||']):
			lexemer.get_next()
			var op = next.value
			var r = _term2()
			if r == null:
				lexemer.error("Syntax error: something missing on the right of " + op)
				return null
			l = gen_ast_node_binary(l, r, op)
		else:
			break
	
	return l


func _term2():
	if is_stop_parsing():
		return null
	var l = _term3()
	
	while true:
		var next = lexemer.view_next()
		if next == null:
			return l
		if check_is_bin_op(next, ['==', '>=', '<=', '!=', '>', '<']):
			lexemer.get_next()
			var op = next.value
			var r = _term3()
			if r == null:
				lexemer.error("Syntax error: something missing on the right of " + op)
				return null
			l = gen_ast_node_binary(l, r, op)
		else:
			break
	
	return l

func _term3():
	if is_stop_parsing():
		return null
	var l = _term4()
	
	while true:
		var next = lexemer.view_next()
		if next == null:
			return l
		if check_is_bin_op(next, ['+', '-']):
			lexemer.get_next()
			var op = next.value
			var r = _term4()
			if r == null:
				lexemer.error("Syntax error: something missing on the right of " + op)
				return null
			l = gen_ast_node_binary(l, r, op)
		else:
			break
	
	return l

func _term4():
	if is_stop_parsing():
		return null
	var l = _term5()
	
	while true:
		var next = lexemer.view_next()
		if next == null:
			return l
		if check_is_bin_op(next, ['*', '/', '%']):
			lexemer.get_next()
			var op = next.value
			var r = _term5()
			if r == null:
				lexemer.error("Syntax error: something missing on the right of " + op)
				return null
			l = gen_ast_node_binary(l, r, op)
		else:
			break
	
	return l

func _term5():
	if is_stop_parsing():
		return null
	var v_next = lexemer.view_next()
	if v_next == null:
		return null
	var op = null
	if check_is_uni_op(v_next, '!'):
		lexemer.get_next()
		op = v_next.value
	
	var x = _term6()
	if op:
		return gen_ast_node_unitary(x, op)
	return x

func _term6():
	if is_stop_parsing():
		return null
	var target = _term7()
	
	var next = lexemer.view_next()
	if next == null:
		return target
	if check_is_char(next, '['):
		lexemer.get_next()
		var index = _expr()
		
		next = lexemer.get_next()
		if check_is_char(next, ']'):
			if check_is_literal(lexemer.view_next()):
				lexemer.error("Syntax error: redundant literal " + lexemer.view_next().value)
				return null
			return gen_ast_node_index(target, index)
		else:
			lexemer.error("Syntax error: expected ]")
			return null
	return target

func _term7():
	if is_stop_parsing():
		return null
	var l = _term8()
	
	while true:
		var next = lexemer.view_next()
		if next == null:
			return l
		if check_is_char(next, '.'):
			lexemer.get_next()
			var op = next.value
			
			next = lexemer.get_next()
			if check_is_identity(next):
				
				# check if a func call
				if check_is_char(lexemer.view_next(), '('):
					var func_name = next.value
					
					lexemer.get_next()
					var arg_list = []
					next = lexemer.view_next()
					if next and not check_is_char(next, ')'):
						arg_list = _args()
					next = lexemer.get_next()
					if check_is_char(next, ')'):
						if check_is_literal(lexemer.view_next()):
							lexemer.error("Syntax error: redundant literal " + lexemer.view_next().value)
							return null
						l = gen_ast_node_obj_func(l, func_name, arg_list)
					else:
						lexemer.error("Syntax error: expected )")
						return null
				else:
					l = gen_ast_node_binary(l, next.value, op)
			else:
				lexemer.error("Syntax error: something missing on the right of " + op)
				return null
		else:
			break
		
	
	return l

func _term8():
	if is_stop_parsing():
		return null
	var next = lexemer.view_next()
	
	if check_is_null(next):
		lexemer.get_next()
		if check_is_literal(lexemer.view_next()):
			lexemer.error("Syntax error: redundant literal " + lexemer.view_next().value)
			return null
		return gen_ast_node_literal()
	if check_is_number(next):
		lexemer.get_next()
		if check_is_literal(lexemer.view_next()):
			lexemer.error("Syntax error: redundant literal " + lexemer.view_next().value)
			return null
		return gen_ast_node_literal(AST_NODE_TYPE.NUMBER, float(next.value))
	if check_is_string(next):
		lexemer.get_next()
		if check_is_literal(lexemer.view_next()):
			lexemer.error("Syntax error: redundant literal " + lexemer.view_next().value)
			return null
		return gen_ast_node_literal(AST_NODE_TYPE.STRING, next.value)
	if check_is_boolean(next):
		lexemer.get_next()
		if check_is_literal(lexemer.view_next()):
			lexemer.error("Syntax error: redundant literal " + lexemer.view_next().value)
			return null
		var b = false
		if next.value == 'true':
			b = true
		elif next.value == 'false':
			b = false
		else:
			lexemer.error("Syntax error: broken boolean literal " + next.value)
			return null
		return gen_ast_node_literal(AST_NODE_TYPE.BOOLEAN, b)
	
	if check_is_identity(next):
		var func_name = next.value
		lexemer.get_next()
		next = lexemer.view_next()
		if check_is_char(next, '('):
			lexemer.get_next()
			var arg_list = []
			next = lexemer.view_next()
			if next and not check_is_char(next, ')'):
				arg_list = _args()
			next = lexemer.get_next()
			if check_is_char(next, ')'):
				if check_is_literal(lexemer.view_next()):
					lexemer.error("Syntax error: redundant literal " + lexemer.view_next().value)
					return null
				return gen_ast_node_func(func_name, arg_list)
			else:
				lexemer.error("Syntax error: expected )")
				return null
		else:
			if check_is_literal(lexemer.view_next()):
				lexemer.error("Syntax error: redundant literal " + lexemer.view_next().value)
				return null
			return gen_ast_node_literal(AST_NODE_TYPE.IDENTITY, func_name)
	
	if check_is_char(next, '('):
		lexemer.get_next()
		var expr = _expr()
		next = lexemer.get_next()
		if check_is_char(next, ')'):
			return expr
		else:
			lexemer.error("Syntax error: expected )")
			return null
	
	if check_is_char(next, '['):
		var array = _array()
		return array
	
	if check_is_char(next, '{'):
		var object = _object()
		return object
	
	return null

func _args():
	if is_stop_parsing():
		return []
	var arg_list = []
	
	var expr = _expr()
	arg_list.append(expr)
	
	while check_is_char(lexemer.view_next(), ','):
		lexemer.get_next()
		expr = _expr()
		arg_list.append(expr)
	
	return arg_list

func _array():
	if is_stop_parsing():
		return null
	var next = lexemer.get_next()
	if check_is_char(next, '['):
		var elements = _elements()
		next = lexemer.get_next()
		if check_is_char(next, ']'):
			return gen_ast_node_array(elements)
		else:
			lexemer.error("Syntax error: expected ]")
			return null
	else:
		lexemer.error("Syntax error: expected [")
		return null

func _elements():
	if is_stop_parsing():
		return []
	var elements = []
	var e = _expr()
	elements.append(e)
	
	while check_is_char(lexemer.view_next(), ','):
		lexemer.get_next()
		e = _expr()
		elements.append(e)
		
	return elements

func _object():
	if is_stop_parsing():
		return null
	var next = lexemer.get_next()
	if check_is_char(next, '{'):
		var key_values = _key_values()
		next = lexemer.get_next()
		if check_is_char(next, '}'):
			return gen_ast_node_object(key_values)
		else:
			lexemer.error("Syntax error: expected }")
			return null
	else:
		lexemer.error("Syntax error: expected {")
		return null
		
func _key_values():
	if is_stop_parsing():
		return []
	
	var kv = _key_value()
	var key_values = [kv]
	
	while check_is_char(lexemer.view_next(), ','):
		lexemer.get_next()
		kv = _key_value()
		key_values.append(kv)
	
	return key_values

func _key_value():
	if is_stop_parsing():
		return null

	var kv = []
	kv.resize(2)
	var k = _key()
	kv[0] = k
	
	var next = lexemer.get_next()
	if check_is_char(next, ':'):
		kv[1] = _expr()
		return kv
	else:
		lexemer.error("Syntax error: expected :")
		return null

func _key():
	if is_stop_parsing():
		return null
		
	var next = lexemer.get_next()
	if check_is_number(next):
		return int(next.value)
	elif check_is_string(next):
		return next.value
	else:
		lexemer.error("Syntax error: expected number or string")
		return null
