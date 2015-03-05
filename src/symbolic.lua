local symbolic = {} -- package
--[[
    Symbol metatable.
    Symbol objects must not have any properties
    in order to protect properties from user code.
    Instead `properties` tables should be used.
--]]
local Symbol = {}

-- package global private variables
local symbols = {} -- list of symbols
local properties = {} -- symbol -> properties
local constraints = {} -- list of constraints of an execution path
local user_stubs = {} -- symbolic.value()s
local solution = nil -- solution for constraints

-- libraries
local table, string, tostring = table, string, tostring

local timelimit = 5
local print_error = false

print = function (...)
    local t = {...}
    for i, v in ipairs(t) do
        if i > 1 then io.stdout:write("\t") end
        io.stdout:write(tostring(v))
    end
    io.stdout:write("\n")
end

-- random int generator
local randomizer = { x = 0, mod = 2^32 }

function randomizer:setseed (x)
    self.x = x
    for i = 1,10 do self:int() end
end

function randomizer:int (n)
    self.x = (self.x * 16654525 + 1013904223) % self.mod
    return n and self.x % n or self.x
end

-- object identifier
local identifier = { c = 0, table = {} }

function identifier:get (v)
    if not self.table[v] then
        self.c = self.c + 1
        self.table[v] = self.c
    end
    return self.table[v]
end

function identifier:shallowhash (t)
    local h = {}
    for k, v in pairs(t) do
        table.insert(h, tostring(self:get(k)) .. "=" .. tostring(self:get(v)))
    end
    return table.concat(h, ",")
end

local function issymbol (v)
    return getmetatable(v) == Symbol
end

local function gettype (v)
    return issymbol(v) and properties[v].t or type(v)
end

local function settype (v, t)
    if properties[v].t then
        assert(properties[v].t == t)
    else
        properties[v].t = t
    end
end

local function z3code (symbols, constraints)
    local lines = {}
    table.insert(lines, "from z3 import *")
    table.insert(lines, "solver = Solver()")
    for i, v in ipairs(symbols) do
        if properties[v].t == "number" then
            table.insert(lines, string.format("%s = Real('%s')", v, v))
        end
        -- ignore table here
    end
    for i, v in ipairs(constraints) do
        table.insert(lines, string.format("solver.add(%s)", v))
    end
    table.insert(lines, "r = solver.check()")
    table.insert(lines, "print(r)")
    table.insert(lines, "if repr(r) == 'sat':")
    table.insert(lines, "   m = solver.model()")
    table.insert(lines, "   for i in range(len(m)):")
    table.insert(lines, "       print('%s,%s' % (m[i], m[m[i]]))")
    table.insert(lines, "")
    return table.concat(lines, "\n")
end

local function z3execute (code)
    local f = io.open('../tmp/z.py', 'w')
    f:write(code)
    f:close()
    local p = io.popen('python ../tmp/z.py')
    local status = p:read()
    if status == 'sat' then
        local ret = {}
        for line in p:lines() do
            table.insert(ret, line)
        end
        p:close()
        return ret
    else
        p:close()
        return nil
    end
end

local function readnumber (v)
    local p = v:find("/")
    if p then
        return tonumber(v:sub(1, p-1)) / tonumber(v:sub(p+1))
    else
        return tonumber(v)
    end
end

-- package functions
function symbolic.eval (f, filename)
    local sol = nil
    local seed = 0
    local lines = {}
    if filename then
        for line in io.lines(filename) do
            table.insert(lines, line)
        end
    end
    print "thinking..."
    local start = os.time()
    while true do
        local t = os.time() - start
        if t > timelimit then break end
        symbols = {}
        constraints = {}
        properties = {}
        user_stubs = {}
        path = {}
        seed = seed + 1
        randomizer:setseed(seed)
        local stdout = io.stdout
        io.stdout = io.open('/dev/null', 'w')
        local r, e = pcall(f)
        io.stdout:flush()
        io.stdout:close()
        io.stdout = stdout
        if r then
            local code = z3code(symbols, constraints)
            local s = z3execute(code)
            if s then
                sol = {}
                for i, w in ipairs(s) do
                    local k, v = w:match("(%w+),([0-9\\/]+)")
                    sol[tonumber(k:sub(2))] = readnumber(v)
                end
                break
            end
        else
            -- For debug
            if print_error then
                print(e)
            end
        end
    end
    if sol then
        print "solution found."
        for i, sym in ipairs(symbols) do
            break -- skip solution printing
            if properties[sym].t == "table" then
                print(string.format("  %s = <table>", sym))
                sol[i] = {}
            elseif properties[sym].t == "function" then
                print(string.format("  %s = <function>", sym))
                sol[i] = function() end
            elseif properties[sym].t == "number" then
                print(string.format("  %s = %f", sym, sol[i]))
            else
                sol[i] = nil
            end
        end
        for i, v in ipairs(user_stubs) do
            local sym = v.symbol
            local id = properties[sym].id
            print(string.format("line %d: %s", v.line, lines[v.line]))
            if properties[sym].t == "table" then
                local props = {}
                for name, val in pairs(properties[sym].props) do
                    table.insert(props,
                            string.format("%s = <%s>", name, gettype(val)))
                end
                local props_str = table.concat(props, ", ")
                if #props_str > 0 then
                    print(string.format("  ? =: { %s }", props_str))
                else
                    print(string.format("  ? =: {}"))
                end
            elseif properties[sym].t == "function" then
                print(string.format("  ? = <function>"))
            elseif properties[sym].t == "number" then
                print(string.format("  ? = %f", sol[id]))
            end
        end
        print "running with stubs..."
        solution = sol
        randomizer:setseed(seed)
        symbols = {}
        local r, e = pcall(f)
        if r then
            print "Test passed."
        else
            print "Test Failed."
            print(e)
        end
    else
        print "no solution."
        print "Test failed."
    end
end

function symbolic.value ()
    local v = Symbol:new()
    local line = debug.getinfo(2).currentline
    table.insert(user_stubs, { symbol = v, line = line })
    return v
end

function symbolic.eq (a, b)
    if not issymbol(a) and not issymbol(b) then return a == b end
    return symbolic.test(a, b, {"==", "!="})
end

function symbolic.ne (a, b)
    if not issymbol(a) and not issymbol(b) then return a ~= b end
    return symbolic.test(a, b, {"!=", "=="})
end

function symbolic.lt (a, b)
    if not issymbol(a) and not issymbol(b) then return a < b end
    return symbolic.test(a, b, {"<", ">="})
end

function symbolic.le (a, b)
    if not issymbol(a) and not issymbol(b) then return a <= b end
    return symbolic.test(a, b, {"<=", ">"})
end

function symbolic.gt (a, b)
    if not issymbol(a) and not issymbol(b) then return a > b end
    return symbolic.test(a, b, {">", "<="})
end

function symbolic.ge (a, b)
    if not issymbol(a) and not issymbol(b) then return a >= b end
    return symbolic.test(a, b, {">=", "<"})
end

function symbolic.test (a, b, operators)
    if issymbol(a) and not properties[a].t then settype(a, gettype(b)) end
    if issymbol(b) and not properties[b].t then settype(b, gettype(a)) end
    local r = randomizer:int(2) + 1
    local expr = string.format("%s%s%s", tostring(a), operators[r], tostring(b))
    table.insert(constraints, expr)
    return r == 1
end

function symbolic.arith (a, b, operator)
    local newval = Symbol:new()
    if issymbol(a) then settype(a, "number") end
    if issymbol(b) then settype(b, "number") end
    settype(newval, "number")
    local expr = string.format("%s==%s%s%s",
            tostring(newval), tostring(a), operator, tostring(b))
    table.insert(constraints, expr)
    return newval
end

-- Symbol methods
function Symbol:new ()
    local id = #symbols + 1
    local v = setmetatable({}, self)
    symbols[id] = v
    properties[v] = { id = id, t = False }
    return v
end

function Symbol:__tostring ()
    if solution then
        local id = properties[self].id
        return tostring(solution[id] or nil)
    end
    return 'x' .. tostring(properties[self].id)
end

function Symbol.__add (a, b)
    return symbolic.arith(a, b, "+")
end

function Symbol.__sub (a, b)
    return symbolic.arith(a, b, "-")
end

function Symbol.__mul (a, b)
    return symbolic.arith(a, b, "*")
end

function Symbol.__div (a, b)
    return symbolic.arith(a, b, "/")
end

function Symbol.__index (a, k)
    local newval = Symbol:new()
    settype(a, "table")
    properties[a].props = properties[a].props or {}
    properties[a].props[k] = newval
    rawset(a, k, newval)
    return newval
end

function Symbol.__newindex (a, k, v)
    settype(a, "table")
    properties[a].props = properties[a].props or {}
    rawset(a, k, v)
end

function Symbol.__call (a, ...)
    settype(a, "function")
    properties[a].ret = properties[a].ret or {}
    local args = {...}
    local h = identifier:shallowhash(args)
    if not properties[a].ret[h] then
        local newval = Symbol:new()
        properties[a].ret[h] = newval
    end
    return properties[a].ret[h]
end

return symbolic

