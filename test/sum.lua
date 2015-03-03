symbolic = require "symbolic"

local function main ()
    local sum = symbolic.value()

    local a = {1, 2, 3}
    assert(symbolic.eq(sum(a), 6))
    local b = {1, 10, 100, 1000}
    assert(symbolic.eq(sum(b), 1111))
    print(sum(a), sum(b))
end

symbolic.eval(main)
