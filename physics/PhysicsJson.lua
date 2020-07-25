local path = (...):sub(1, #(...) - #(".physics.PhysicsJson"))
local JSON = require(path..".3p.JSON").new() -- new instance
local Luaoop = require(path..".3p.Luaoop")
local nvec = require(path..".3p.nvec") ---@type NVec

---@class L2DF.PhysicsJson
local PhysicsJson = Luaoop.class("L2DF.PhysicsJson")

-- JSON keys
local Position = "Position"
local X = "X"
local Y = "Y"
local Angle = "Angle"
local Type = "Type"
local Id = "Id"

-- Meta
local Meta = "Meta"
local EffectiveForces = "EffectiveForces"
local TotalInputCount = "TotalInputCount"
local TotalOutputCount = "TotalOutputCount"
local PhysicsSettingCount = "PhysicsSettingCount"
local Gravity = "Gravity"
local Wind = "Wind"
local VertexCount = "VertexCount"

-- PhysicsSettings
local PhysicsSettings = "PhysicsSettings"
local Normalization = "Normalization"
local Minimum = "Minimum"
local Maximum = "Maximum"
local Default = "Default"
local Reflect = "Reflect"
local Weight = "Weight"

-- Input
local Input = "Input"
local Source = "Source"

-- Output
local Output = "Output"
local Scale = "Scale"
local VertexIndex = "VertexIndex"
local Destination = "Destination"

-- Particle
local Vertices = "Vertices"
local Mobility = "Mobility"
local Delay = "Delay"
local Radius = "Radius"
local Acceleration = "Acceleration"

function PhysicsJson:__construct(jsondata)
	self.json = JSON:decode(jsondata)
	self.meta = self.json[Meta]
	self.effectiveForces = self.meta[EffectiveForces]
	self.setting = self.json[PhysicsSettings]
end

function PhysicsJson:getGravity()
	return nvec(
		assert(tonumber(self.effectiveForces[Gravity][X])),
		assert(tonumber(self.effectiveForces[Gravity][Y]))
	)
end

function PhysicsJson:getWind()
	return nvec(self.effectiveForces[Wind][X], self.effectiveForces[Wind][Y])
end

---@return number
function PhysicsJson:getSubRingCount()
	return assert(tonumber(self.meta[PhysicsSettingCount]))
end

---@return number
function PhysicsJson:getTotalInputCount()
	return assert(tonumber(self.meta[TotalInputCount]))
end

---@return number
function PhysicsJson:getTotalOutputCount()
	return assert(tonumber(self.meta[TotalOutputCount]))
end

---@return number
function PhysicsJson:getVertexCount()
	return assert(tonumber(self.meta[VertexCount]))
end

--
-- Input
--

---@param i number
---@return number
function PhysicsJson:getNormalizationPositionMinimumValue(i)
	return assert(tonumber(self.setting[i][Normalization][Position][Minimum]))
end

---@param i number
---@return number
function PhysicsJson:getNormalizationPositionMaximumValue(i)
	return assert(tonumber(self.setting[i][Normalization][Position][Maximum]))
end

---@param i number
---@return number
function PhysicsJson:getNormalizationPositionDefaultValue(i)
	return assert(tonumber(self.setting[i][Normalization][Position][Default]))
end

---@param i number
---@return number
function PhysicsJson:getNormalizationAngleMinimumValue(i)
	return assert(tonumber(self.setting[i][Normalization][Angle][Minimum]))
end

---@param i number
---@return number
function PhysicsJson:getNormalizationAngleMaximumValue(i)
	return assert(tonumber(self.setting[i][Normalization][Angle][Maximum]))
end

---@param i number
---@return number
function PhysicsJson:getNormalizationAngleDefaultValue(i)
	return assert(tonumber(self.setting[i][Normalization][Angle][Default]))
end

---@param i number
function PhysicsJson:getInputCount(i)
	return #self.setting[i][Input]
end

---@param i number
---@param j number
---@return number
function PhysicsJson:getInputWeight(i, j)
	return assert(tonumber(self.setting[i][Input][j][Weight]))
end

---@param i number
---@param j number
---@return boolean
function PhysicsJson:getInputReflect(i, j)
	return not(not(self.setting[i][Input][j][Reflect]))
end

---@param i number
---@param j number
---@return string
function PhysicsJson:getInputType(i, j)
	return self.setting[i][Input][j][Type]
end

---@param i number
---@param j number
function PhysicsJson:getInputSourceID(i, j)
	return tostring(assert(self.setting[i][Input][j][Source][Id]))
end

--
-- Output
--

---@param i number
function PhysicsJson:getOutputCount(i)
	return #self.setting[i][Output]
end

---@param i number
---@param j number
---@return number
function PhysicsJson:getOutputVertexIndex(i, j)
	return assert(tonumber(self.setting[i][Output][j][VertexIndex]))
end

---@param i number
---@param j number
---@return number
function PhysicsJson:getOutputAngleScale(i, j)
	return assert(tonumber(self.setting[i][Output][j][Scale]))
end

---@param i number
---@param j number
---@return number
function PhysicsJson:getOutputWeight(i, j)
	return assert(tonumber(self.setting[i][Output][j][Weight]))
end

---@param i number
---@param j number
function PhysicsJson:getOutputDestinationID(i, j)
	return tostring(assert(self.setting[i][Output][j][Destination][Id]))
end

---@param i number
---@param j number
---@return boolean
function PhysicsJson:getOutputReflect(i, j)
	return not(not(self.setting[i][Output][j][Reflect]))
end

--
-- Particle
--

---@param i number
function PhysicsJson:getParticleCount(i)
	return #self.setting[i][Vertices]
end

---@param i number
---@param j number
---@return number
function PhysicsJson:getParticleMobility(i, j)
	return assert(tonumber(self.setting[i][Vertices][j][Mobility]))
end

---@param i number
---@param j number
---@return number
function PhysicsJson:getParticleDelay(i, j)
	return assert(tonumber(self.setting[i][Vertices][j][Delay]))
end

---@param i number
---@param j number
---@return number
function PhysicsJson:getParticleAcceleration(i, j)
	return assert(tonumber(self.setting[i][Vertices][j][Acceleration]))
end

---@param i number
---@param j number
---@return number
function PhysicsJson:getParticleRadius(i, j)
	return assert(tonumber(self.setting[i][Vertices][j][Radius]))
end

---@param i number
---@param j number
function PhysicsJson:getParticleRadius(i, j)
	return nvec(
		assert(tonumber(self.setting[i][Vertices][j][Position][X])),
		assert(tonumber(self.setting[i][Vertices][j][Position][Y]))
	)
end

return PhysicsJson
