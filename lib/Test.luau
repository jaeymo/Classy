local Classy = require(script.Parent)

local KillPartClass = {}
KillPartClass.__index = KillPartClass

export type KillPartClass = typeof(setmetatable({} :: {}, KillPartClass))

function KillPartClass.new(): KillPartClass
    return setmetatable({}, KillPartClass)
end

print(Classy)

return {}