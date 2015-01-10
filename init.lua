local momo = {}

local modules = {
    'util',
    'package',
    'log',
    'class',
    'event',
    'filesystem',
}

for _,v in ipairs(modules) do
  momo[v] = require('momo.' .. v)
end

return momo