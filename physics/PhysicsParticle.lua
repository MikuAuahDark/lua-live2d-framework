local path = (...):sub(1, #(...) - #(".physics.PhysicsParticle"))
local Luaoop = require(path..".3p.Luaoop")
local nvec = require(path..".3p.nvec")

---@class L2DF.PhysicsParticle
---@field public initialPosition NVec
---@field public mobility number
---@field public delay number
---@field public acceleration number
---@field public radius number
---@field public position NVec
---@field public lastPosition NVec
---@field public lastGravity NVec
---@field public force NVec
---@field public velocity NVec
local PhysicsParticle = Luaoop.class("L2DF.PhysicsParticle")

function PhysicsParticle:__construct()
	self.initialPosition = nvec()
	self.mobility = 0
	self.delay = 0
	self.acceleration = 0
	self.radius = 0
	self.position = nvec()
	self.lastPosition = nvec()
	self.lastGravity = nvec()
	self.force = nvec()
	self.velocity = nvec()
end

return PhysicsParticle
