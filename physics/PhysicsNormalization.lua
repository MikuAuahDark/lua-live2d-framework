local path = (...):sub(1, #(...) - #(".physics.PhysicsNormalization"))
local Luaoop = require(path..".3p.Luaoop")

---@class L2DF.PhysicsNormalization
---@field public minimum number
---@field public maximum number
---@field public default number 
local PhysicsNormalization = Luaoop.class("L2DF.PhysicsNormalization")

function PhysicsNormalization:__construct()
	self.minimum = 0
	self.maximum = 0
	self.default = 0
end

return PhysicsNormalization
