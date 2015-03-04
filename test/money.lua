local symbolic = require 'symbolic'

local function main ()
    local Dollar = symbolic.value()
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
    local Franc = symbolic.value()

    local five = Dollar:new(5)
    local five_f = Franc:new(5)
    assert(symbolic.eq(five:amount(), 5))
    assert(symbolic.eq(five:times(2):amount(), 10))
    assert(symbolic.eq(five_f:amount(), 5))
    assert(five_f:equals(five:times(2)))
end

symbolic.eval(main)
