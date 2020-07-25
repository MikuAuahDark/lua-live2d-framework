local path = (...):sub(1, #(...) - #(".physics.PhysicsOutput"))
local Luaoop = require(path..".3p.Luaoop")
local nvec = require(path..".3p.nvec") ---@type NVec

local PhysicsParameter = require(path..".physics.PhysicsParameter") ---@type L2DF.PhysicsParameter

-- luacheck: push no max line length
---@alias L2DF.PhysicsSource "\"x\" | \"y\" | \"angle\""
---@alias L2DF.PhysicsValueGetter fun(translation: NVec, particles: L2DF.PhysicsParticle[], i: number, inv: boolean, parentGravity: NVec): number
---@alias L2DF.PhysicsScaleGetter fun(translationScale: NVec, angleScale: number): number
-- luacheck: pop

---@class L2DF.PhysicsOutput
---@field public destination L2DF.PhysicsParameter
---@field public destinationParameterIndex number
---@field public vertexIndex number
---@field public translationScale NVec
---@field public angleScale number
---@field public weight number
---@field public type L2DF.PhysicsSource
---@field public reflect number
---@field public valueBelowMinimum number
---@field public valueExceededMaximum number
---@field public getValue L2DF.PhysicsValueGetter
---@field public getScale L2DF.PhysicsScaleGetter
local PhysicsOutput = Luaoop.class("L2DF.PhysicsOutput")

function PhysicsOutput:__construct()
	self.destination = PhysicsParameter()
	self.destinationParameterIndex = 0
	self.vertexIndex = 0
	self.translationScale = nvec()
	self.angleScale = 0
	self.weight = 0
	self.type = "x"
	self.reflect = 0
	self.valueBelowMinimum = 0
	self.valueExceededMaximum = 0
	self.getValue = nil
	self.getScale = nil
end

return PhysicsOutput
