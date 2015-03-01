local symbolic = require 'symbolic'

local function main ()
    a = symbolic.value() + 2
    b = symbolic.value()
    if symbolic.eq(a, 3) then
        assert(not symbolic.eq(a, b.c.d))
    else
        assert(false)
    end
end

symbolic.eval(main)
