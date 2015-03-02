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
local solution = nil -- solution for constraints

-- libraries
local table, string, tostring = table, string, tostring

print = function (...)
    io.stdout:write(table.concat({...}, "\t"))
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
    local solution = nil
    local seed = nil
    print "thinking..."
    for k = 1, 1000 do
        symbols = {}
        constraints = {}
        properties = {}
        path = {}
        randomizer:setseed(k)
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
                solution = {}
                seed = k
                for i, w in ipairs(s) do
                    local k, v = w:match("(%w+),(%w+)")
                    solution[tonumber(k:sub(2))] = tonumber(v)
                end
                break
            end
        else
                -- For debug
--            print(e)
        end
    end
    if solution then
        print "solution found."
        for i, sym in ipairs(symbols) do
            if properties[sym].t == "table" then
                print(string.format("%s : {}", sym))
                solution[i] = {}
            elseif properties[sym].t == "number" then
                print(string.format("%s : %f", sym, solution[i]))
            end
        end
        print "running with stubs..."
        _ENV.solution = solution
        randomizer:setseed(seed)
        symbols = {}
        f()
    else
        print "no solution."
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
    local i = randomizer:int(2) + 1
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
    if solution then
        return tostring(solution[properties[self].id])
    end
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

function Symbol.__index (a, k)
    local newval = Symbol:new()
    settype(a, "table")
    rawset(a, k, newval)
    return newval
end

return symbolic

