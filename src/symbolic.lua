local symbolic = {} -- package
local Symbol = { next_id = 1 } -- symbol metatable
local constraints = {}

local table, string = table, string

-- package functions
function symbolic.eval (f)
    constraints = {}
    local r = pcall(f)
    print("result = " .. tostring(r))
    for i, v in ipairs(constraints) do
        print("c: " .. v)
    end
end

function symbolic.value ()
    return Symbol:new()
end

function symbolic.eq (a, b, id)
    local expr = string.format("%s==%s", tostring(a), tostring(b))
    table.insert(constraints, expr)
    return true
end

-- Symbol methods
function Symbol:new ()
    local id = self.next_id
    self.next_id = id + 1
    return setmetatable({ id = id }, self)
end

function Symbol:__tostring ()
    return 'x' .. tostring(self.id)
end

function Symbol.__add (a, b)
    local newval = Symbol:new()
    local expr = string.format("%s=%s+%s", tostring(newval), tostring(a), tostring(b))
    table.insert(constraints, expr)
    return newval
end

return symbolic
