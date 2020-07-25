local path = (...):sub(1, #(...) - #(".physics.PhysicsParameter"))
local Luaoop = require(path..".3p.Luaoop")

---@class L2DF.PhysicsParameter
---@field public id string
---@field public targetType string
local PhysicsParameter = Luaoop.class("L2DF.PhysicsParameter")

function PhysicsParameter:__construct()
	self.id = ""
	self.targetType = "parameter"
end

return PhysicsParameter
