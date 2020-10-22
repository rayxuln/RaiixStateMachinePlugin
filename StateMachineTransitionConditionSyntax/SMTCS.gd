extends Node

class_name SMTCS


static func _eval(ast, agent:Node):
	if ast == null:
		return null
	if ast.type in [SMTCSParser.AST_NODE_TYPE.NULL, SMTCSParser.AST_NODE_TYPE.NUMBER, SMTCSParser.AST_NODE_TYPE.STRING, SMTCSParser.AST_NODE_TYPE.BOOLEAN]:
		return ast.value
	if ast.type == SMTCSParser.AST_NODE_TYPE.IDENTITY:
		if not ast.value in agent:
			return null
		return agent[ast.value]
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.FUNC:
		if not agent.has_method(ast.func_name):
			return null
		var arg_list_v = []
		for arg in ast.arg_list:
			arg_list_v.append(_eval(arg, agent))
		return agent.callv(ast.func_name, arg_list_v)
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.TERNARY:
		var cond = _eval(ast.children[0], agent)
		var l = _eval(ast.children[1], agent)
		var r = _eval(ast.children[2], agent)
		return l if cond else r
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.BINARY:
		var op = ast.op
		var l = _eval(ast.children[0], agent)
		match op:
			'||':
				return l or _eval(ast.children[1], agent)
			'&&':
				return l and _eval(ast.children[1], agent)
		var r = _eval(ast.children[1], agent)
		match op:
			'+':
				if(l is String):
					return l + str(r)
				return l + r
			'-':
				return l - r
			'*':
				return l * r
			'/':
				return l / r
			'%':
				return int(l) % int(r)
			'>':
				return l > r
			'<':
				return l < r
			'>=':
				return l >= r
			'<=':
				return l <= r
			'==':
				return l == r
			'!=':
				return l != r
		printerr("Sematic error: Unown operator " + op)
		return null
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.UNITARY:
		var op = ast.op
		if op == '!':
			var x = _eval(ast.children[0], agent)
			return !x
		printerr("Sematic error: Unown operator " + op)
		return null
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.INDEX:
		var target = _eval(ast.target, agent)
		var index = _eval(ast.index, agent)
		return target[index]
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.ARRAY:
		var elements_v = []
		for c in ast.children:
			elements_v.append(_eval(c, agent))
		return elements_v
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.OBJECT:
		var object_v = {}
		for kv in ast.children:
			object_v[kv[0]] = _eval(kv[1], agent)
		return object_v
	
	printerr("Sematic error: Unkown type " + ast.type)
	return null
	

static func eval(cond:String, agent:Node=null):
	var is_agent_null = agent == null
	if is_agent_null:
		agent = Node.new()
	
	var ast = SMTCSParser.new(cond).parse()
	var res = _eval(ast, agent)
	
	if is_agent_null:
		agent.free()
	
	return res
