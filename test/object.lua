local symbolic = require 'symbolic'

local function main ()
    local obj = symbolic.value()
    function obj:a ()
        return 1
    end
    assert (symbolic.eq(obj.b(), 2))
end

symbolic.eval(main)

