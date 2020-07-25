local path = (...):sub(1, #(...) - #(".physics.PhysicsJsonEffectiveForces"))
local Luaoop = require(path..".3p.Luaoop")
local nvec = require(path..".3p.nvec")

---@class L2DF.PhysicsJsonEffectiveForces
---@field public gravity NVec
---@field public wind NVec
local PhysicsJsonEffectiveForces = Luaoop.class("L2DF.PhysicsJsonEffectiveForces")

function PhysicsJsonEffectiveForces:__construct()
	self.gravity = nvec()
	self.wind = nvec()
end

return PhysicsJsonEffectiveForces
