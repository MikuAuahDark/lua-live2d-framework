local path = (...):sub(1, #(...) - #(".physics.PhysicsRig"))
local Luaoop = require(path..".3p.Luaoop")
local nvec = require(path..".3p.nvec") ---@type NVec

---@class L2DF.PhysicsRig
---@field public settings L2DF.PhysicsSubRig[]
---@field public inputs L2DF.PhysicsInput[]
---@field public outputs L2DF.PhysicsOutput[]
---@field public particles L2DF.PhysicsParticle[]
---@field public gravity NVec
---@field public wind NVec
local PhysicsRig = Luaoop.class("L2DF.PhysicsRig")

function PhysicsRig:__construct()
	self.settings = {}
	self.inputs = {}
	self.outputs = {}
	self.particles = {}
	self.gravity = nvec()
	self.wind = nvec()
end

return PhysicsRig
