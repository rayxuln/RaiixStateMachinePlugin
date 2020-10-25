extends Object

class_name SMTCS



static func _eval(ast, agent:Node, built_in_lib:Reference):
	if ast == null:
		return null
	if ast.type in [SMTCSParser.AST_NODE_TYPE.NULL, SMTCSParser.AST_NODE_TYPE.NUMBER, SMTCSParser.AST_NODE_TYPE.STRING, SMTCSParser.AST_NODE_TYPE.BOOLEAN]:
		return ast.value
	if ast.type == SMTCSParser.AST_NODE_TYPE.IDENTITY:
		if ast.value in agent:
			return agent[ast.value]
		elif ast.value in built_in_lib:
			return built_in_lib[ast.value]
		else:
			printerr("Sematic error: unkown property " + ast.value)
			return null
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.FUNC:
		var use_agent = agent.has_method(ast.func_name)
		var use_built_in_lib = built_in_lib.has_method(ast.func_name)
		var arg_list_v = []
		if use_agent or use_built_in_lib:
			for arg in ast.arg_list:
				arg_list_v.append(_eval(arg, agent, built_in_lib))
		if use_agent:
			return agent.callv(ast.func_name, arg_list_v)
		elif use_built_in_lib:
			return built_in_lib.callv(ast.func_name, arg_list_v)
		else:
			printerr("Sematic error: unkown method " + ast.func_name)
			return null
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.OBJ_FUNC:
		var obj = _eval(ast.obj, agent, built_in_lib)
		var arg_list_v = []
		if obj.has_method(ast.func_name):
			for arg in ast.arg_list:
				arg_list_v.append(_eval(arg, agent, built_in_lib))
			return obj.callv(ast.func_name, arg_list_v)
		else:
			printerr("Sematic error: unkown method " + ast.func_name)
			return null
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.TERNARY:
		var cond = _eval(ast.children[0], agent, built_in_lib)
		var l = _eval(ast.children[1], agent, built_in_lib)
		var r = _eval(ast.children[2], agent, built_in_lib)
		return l if cond else r
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.BINARY:
		var op = ast.op
		var l = _eval(ast.children[0], agent, built_in_lib)
		match op:
			'||':
				return l or _eval(ast.children[1], agent, built_in_lib)
			'&&':
				return l and _eval(ast.children[1], agent, built_in_lib)
		if op == '.':
			if typeof(l) == TYPE_OBJECT or l is Dictionary or l is Array:
				return l[ast.children[1]]
			else:
				printerr("Sematic error: invalid index %s on %s" % [str(ast.children[1]), str(l)])
				return null
		var r = _eval(ast.children[1], agent, built_in_lib)
		match op:
			'+':
				if l is String :
					return l + str(r)
				if typeof(l) == TYPE_INT or typeof(l) == TYPE_REAL:
					if typeof(r) != TYPE_INT and typeof(r) != TYPE_REAL:
						r = float(r)
				return l + r
			'-':
				if typeof(l) == TYPE_INT or typeof(l) == TYPE_REAL:
					if typeof(r) != TYPE_INT and typeof(r) != TYPE_REAL:
						r = float(r)
				return l - r
			'*':
				if typeof(l) == TYPE_INT or typeof(l) == TYPE_REAL:
					if typeof(r) != TYPE_INT and typeof(r) != TYPE_REAL:
						r = float(r)
				return l * r
			'/':
				if typeof(l) == TYPE_INT or typeof(l) == TYPE_REAL:
					if typeof(r) != TYPE_INT and typeof(r) != TYPE_REAL:
						r = float(r)
				if r==0:
					printerr("Sematic error: r==0")
					return null
				return l / r
			'%':
				if typeof(l) == TYPE_INT or typeof(l) == TYPE_REAL:
					if typeof(r) != TYPE_INT and typeof(r) != TYPE_REAL:
						r = float(r)
				if r==0:
					printerr("Sematic error: r==0")
					return null
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
			var x = _eval(ast.children[0], agent, built_in_lib)
			return !x
		printerr("Sematic error: Unown operator " + op)
		return null
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.INDEX:
		var target = _eval(ast.target, agent, built_in_lib)
		var index = _eval(ast.index, agent, built_in_lib)
		return target[index]
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.ARRAY:
		var elements_v = []
		for c in ast.children:
			elements_v.append(_eval(c, agent, built_in_lib))
		return elements_v
	
	if ast.type == SMTCSParser.AST_NODE_TYPE.OBJECT:
		var object_v = {}
		for kv in ast.children:
			object_v[kv[0]] = _eval(kv[1], agent, built_in_lib)
		return object_v
	
	printerr("Sematic error: Unkown type " + ast.type)
	return null


static func eval_ast(ast:Dictionary, agent:Object=null):
	var is_agent_null = agent == null
	if is_agent_null:
		agent = Node.new()
	
	var res = _eval(ast, agent, preload('./build_in_lib.gd').new(agent))
	
	if is_agent_null:
		agent.free()
	
	return res

static func eval(cond:String, agent:Object=null):
	var ast = SMTCSParser.new(cond).parse()
	return eval_ast(ast, agent)
