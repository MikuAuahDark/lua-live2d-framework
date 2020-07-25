local path = (...):sub(1, #(...) - #(".physics.PhysicsSubRig"))
local Luaoop = require(path..".3p.Luaoop")

local PhysicsNormalization = require(path..".physics.PhysicsNormalization")

---@class L2DF.PhysicsSubRig
---@field public inputCount number
---@field public outputCount number
---@field public particleCount number
---@field public baseInputIndex number
---@field public baseOutputIndex number
---@field public baseParticleIndex number
---@field public normalizationPosition L2DF.PhysicsNormalization
---@field public normalizationAngle L2DF.PhysicsNormalization
local PhysicsSubRig = Luaoop.class("L2DF.PhysicsSubRig")

function PhysicsSubRig:__construct()
	self.inputCount = 0
	self.outputCount = 0
	self.particleCount = 0
	self.baseInputIndex = 0
	self.baseOutputIndex = 0
	self.baseParticleIndex = 0
	self.normalizationPosition = PhysicsNormalization()
	self.normalizationAngle = PhysicsNormalization()
end

return PhysicsSubRig
