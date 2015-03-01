local symbolic = {} -- package
local Symbol = {} -- Symbol metatable
Symbol.__index = Symbol

-- package global private variables
local symbols = {}
local constraints = {}

-- libraries
local table, string, tostring = table, string, tostring

local function issymbol(v)
    return getmetatable(v) == Symbol
end

local function gettype(v)
    return issymbol(v) and v.t or type(v)
end

-- package functions
function symbolic.eval (f)
    for k = 0, 100 do
        symbols = {}
        constraints = {}
        local r = pcall(f)
        if r then
            for i, v in ipairs(symbols) do
                print(string.format("v %s: %s", v, v.t))
            end
            for i, v in ipairs(constraints) do
                print(string.format("c %s", v))
            end
            break
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
    if issymbol(a) and not a.t then a:settype(gettype(b)) end
    if issymbol(b) and not b.t then b:settype(gettype(a)) end
    local i = math.random(2)
    local expr = string.format("%s%s%s",
            tostring(a), ({'==', '!='})[i], tostring(b))
    table.insert(constraints, expr)
    return ({true, false})[i]
end

-- Symbol methods
function Symbol:new ()
    local id = #symbols
    local v = setmetatable({ id = id }, self)
    table.insert(symbols, v)
    return v
end

function Symbol:__tostring ()
    return 'x' .. tostring(self.id)
end

function Symbol.__add (a, b)
    local newval = Symbol:new()
    if issymbol(a) then a:settype("number") end
    if issymbol(b) then b:settype("number") end
    newval:settype("number")
    local expr = string.format("%s=%s+%s", tostring(newval), tostring(a), tostring(b))
    table.insert(constraints, expr)
    return newval
end

function Symbol:settype (t)
    if self.t then
        assert(self.t == t)
    else
        self.t = t
    end
end

return symbolic
