_ENV.symbolic = require "symbolic"

local filename = arg[1]
local orig_filename = arg[2]
if not filename then
    print "usage: lua run.lua <filename>"
    os.exit(1)
end

local f = loadfile(filename)
if not f then
    print("error loading file: " .. filename)
    os.exit(1)
end
symbolic.eval(f, orig_filename)
