local symbolic = require 'symbolic'

local function main ()
    a = symbolic.value() + 2
    b = symbolic.value()
    assert(not symbolic.eq(a, b, 1))
end

symbolic.eval(main)
