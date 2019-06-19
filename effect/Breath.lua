-- Copyright(c) Live2D Inc. All rights reserved.
--
-- Use of this source code is governed by the Live2D Open Software license
-- that can be found at http://live2d.com/eula/live2d-open-software-license-agreement_en.html.

local path = (...):sub(1, #(...) - #(".effect.Breath"))
local Luaoop = require(path..".3p.Luaoop")

local Breath = Luaoop.class("L2DF.Breath")
local TWOPI = 2 * math.pi
local sin = math.sin

function Breath:__construct(breathParams)
	self.breathParams = breathParams

	if breathParams then
		self:_initializeBreathParams()
	else
		self._internalBreathParams = nil
	end
end

function Breath:setParameters(breathParams)
	self.breathParams = breathParams

	if breathParams then
		self:_initializeBreathParams()
	else
		self._internalBreathParams = nil
	end
end

function Breath:_initializeBreathParams()
	local params = {}

	for i, v in ipairs(self.breathParams) do
		assert(
			type(v.parameterID) == "string" and
			type(v.offset) == "number" and
			type(v.peak) == "number" and
			type(v.cycle) == "number" and
			type(v.weight) == "number",
			"invalid breath parameters passed"
		)

		params[i] = {v.parameterID, v.offset, v.peak, v.cycle, v.weight, 0}
	end

	self._internalBreathParams = params
end

function Breath:updateParameters(model, dt)
	for i = 1, #self._internalBreathParams do
		local v = self._internalBreathParams[i]

		v[6] = (v[6] + dt) % v[4]
		model:addParameterValue(v[1], v[2] + (v[3] * sin(v[4] / v[6] * TWOPI)), v[5])
	end
end

return Breath
