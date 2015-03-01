local symbolic = {} -- package
local Symbol = {} -- symbol metatable
local next_id = 1
local constraints = {}

local table, string = table, string

-- package functions
function symbolic.eval (f)
    for k = 0, 100 do
        next_id = 1
        constraints = {}
        local r = pcall(f)
        if r then
            for i, v in ipairs(constraints) do
                print("c: " .. v)
            end
            break
        end
    end
end

function symbolic.value ()
    return Symbol:new()
end

function symbolic.eq (a, b)
    local i = math.random(2)
    local expr = string.format("%s%s%s",
            tostring(a), ({'==', '!='})[i], tostring(b))
    table.insert(constraints, expr)
    return ({true, false})[i]
end

-- Symbol methods
function Symbol:new ()
    local id = next_id
    next_id = id + 1
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
