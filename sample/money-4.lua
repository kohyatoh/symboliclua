local Dollar = {}
Dollar.__index = Dollar
function Dollar:new (amount)
    return setmetatable({_amount = amount}, Dollar)
end
function Dollar:amount ()
    return self._amount
end
function Dollar:times (t)
    return Dollar:new(self._amount * t)
end
local Franc = ?

local five = Dollar:new(5)
local five_f = Franc:new(5)
assert(five:amount() == 5)
assert(five:times(2):amount() == 10)
assert(five_f:amount() == 5)
assert(five_f:equals(five:times(2)))
