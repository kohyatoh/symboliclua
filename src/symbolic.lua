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
local properties = {} -- symbol -> type
local constraints = {} -- list of constraints of an execution path

-- libraries
local table, string, tostring = table, string, tostring

local function issymbol(v)
    return getmetatable(v) == Symbol
end

local function gettype(v)
    return issymbol(v) and properties[v].t or type(v)
end

local function settype (v, t)
    if properties[v].t then
        assert(properties[v].t == t)
    else
        properties[v].t = t
    end
end

local function z3code(symbols, constraints)
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

local function z3execute(code)
    local f = io.open('z.py', 'w')
    f:write(code)
    f:close()
    local p = io.popen('python z.py')
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

-- package functions
function symbolic.eval (f)
    for k = 0, 100 do
        symbols = {}
        constraints = {}
        properties = {}
        local r, e = pcall(f)
        if r then
            local code = z3code(symbols, constraints)
            local s = z3execute(code)
            if s then
                print(table.concat(s, '\n'))
                break
            end
        else
                -- For debug
--            print(e)
        end
    end
end

function symbolic.value ()
    return Symbol:new()
end

function symbolic.eq (a, b)
    if not issymbol(a) and not issymbol(b) then
        return a == b
    end
    if issymbol(a) and not properties[a].t then settype(a, gettype(b)) end
    if issymbol(b) and not properties[b].t then settype(b, gettype(a)) end
    local i = math.random(2)
    local expr = string.format("%s%s%s",
            tostring(a), ({'==', '!='})[i], tostring(b))
    table.insert(constraints, expr)
    return ({true, false})[i]
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
    return 'x' .. tostring(properties[self].id)
end

function Symbol.__add (a, b)
    local newval = Symbol:new()
    if issymbol(a) then settype(a, "number") end
    if issymbol(b) then settype(b, "number") end
    settype(newval, "number")
    local expr = string.format("%s==%s+%s", tostring(newval), tostring(a), tostring(b))
    table.insert(constraints, expr)
    return newval
end

function Symbol.__index (a)
    local newval = Symbol:new()
    settype(a, "table")
    return newval
end

return symbolic
