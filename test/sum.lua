symbolic = require "symbolic"

local function main ()
    local sum = symbolic.value()

    assert(symbolic.eq(sum(1, 2, 3), 6))
    assert(symbolic.eq(sum(1, 10, 100, 1000), 1111))
    print(sum(1, 2, 3), sum(1, 10, 100, 1000))
end

symbolic.eval(main)
