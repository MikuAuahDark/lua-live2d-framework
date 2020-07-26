local path = (...):sub(1, #(...) - #(".physics.PhysicsInput"))
local Luaoop = require(path..".3p.Luaoop")

local PhysicsParameter = require(path..".physics.PhysicsParameter") ---@type L2DF.PhysicsParameter

-- luacheck: push no max line length
---@alias L2DF.NormalizedPhysicsParameterValueGetter fun(value: number, pMin: number, pMax: number, pDef: number, nPos: L2DF.PhysicsNormalization, nAngle: L2DF.PhysicsNormalization, inv: boolean, weight: number): NVec,number
-- luacheck: pop

---@class L2DF.PhysicsInput
---@field public source L2DF.PhysicsParameter
---@field public sourceParameterIndex number
---@field public weight number
---@field public type L2DF.PhysicsSource
---@field public reflect number
---@field public getNormalizedParameterValue L2DF.NormalizedPhysicsParameterValueGetter
local PhysicsInput = Luaoop.class("L2DF.PhysicsInput")

function PhysicsInput:__construct()
	self.source = PhysicsParameter()
	self.sourceParameterIndex = 0
	self.weight = 0
	self.type = "x"
	self.reflect = 0
	self.getNormalizedParameterValue = nil
end
