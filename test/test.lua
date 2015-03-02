local symbolic = require 'symbolic'

local function main ()
    a = symbolic.value() + 2
    b = symbolic.value()
    if symbolic.eq(a, 3) then
        assert(not symbolic.eq(a, b.c.d))
    else
        assert(false)
    end
    print(string.format("a = %s", tostring(a)))
    print(string.format("a + 1 = %s", tostring(a + 1)))
    print(string.format("b = %s", tostring(b)))
    print(string.format("b.c.d = %s", tostring(b.c.d)))
end

symbolic.eval(main)
