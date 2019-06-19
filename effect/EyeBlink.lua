-- Copyright(c) Live2D Inc. All rights reserved.
--
-- Use of this source code is governed by the Live2D Open Software license
-- that can be found at http://live2d.com/eula/live2d-open-software-license-agreement_en.html.

local path = (...):sub(1, #(...) - #(".effect.EyeBlink"))
local Luaoop = require(path..".3p.Luaoop")
local DefaultParameterId = require(path..".DefaultParameterId")

local EyeBlink = Luaoop.class("L2DF.EyeBlink")

function EyeBlink:__construct(parameters)
	self.blinkingState = "first"
	self.parameterIds = parameters or {DefaultParameterId.ParamEyeLOpen, DefaultParameterId.ParamEyeROpen}
	self.nextBlinkingTime = 0
	self.stateStartTimeSeconds = 0
	self.blinkingIntervalSeconds = 4
	self.closingSeconds = 0.1
	self.closedSeconds = 0.05
	self.openingSeconds = 0.15
	self.userTimeSeconds = 0
end

function EyeBlink:determineNextBlinkingTiming()
	local r = math.random()
	return self.userTimeSeconds + (r * (2 * self.blinkingIntervalSeconds - 1))
end

function EyeBlink:setBlinkingInterval(interval)
	self.blinkingIntervalSeconds = assert(type(interval) == "number" and interval, "invalid interval")
end

function EyeBlink:setBlinkingSettings(closing, closed, opening)
	self.closingSeconds = closing
	self.closedSeconds = closed
	self.openingSeconds = opening
end

function EyeBlink:setParameterIds(param)
	self.parameterIds = param
end

function EyeBlink:getParameterIds()
	return self.parameterIds
end

function EyeBlink:updateParameters(model, dt)
	local parameterValue

	self.userTimeSeconds = self.userTimeSeconds + dt

	if self.blinkingState == "closing" then
		local t = (self.userTimeSeconds - self.stateStartTimeSeconds) / self.closingSeconds

		if t >= 1 then
			t = 1
			self.blinkingState = "closed"
			self.stateStartTimeSeconds = self.userTimeSeconds
		end

		parameterValue = 1.0 - t
	elseif self.blinkingState == "closed" then
		local t = (self.userTimeSeconds - self.stateStartTimeSeconds) / self.closedSeconds

		if t >= 1 then
			self.blinkingState = "opening"
			self.stateStartTimeSeconds = self.userTimeSeconds
		end

		parameterValue = 0
	elseif self.blinkingState == "opening" then
		local t = (self.userTimeSeconds - self.stateStartTimeSeconds) / self.openingSeconds

		if t >= 1 then
			t = 1
			self.blinkingState = "interval"
			self.nextBlinkingTime = self:determineNextBlinkingTiming()
		end

		parameterValue = t
	elseif self.blinkingState == "interval" then
		if self.nextBlinkingTime < self.userTimeSeconds then
			self.blinkingState = "closed"
			self.stateStartTimeSeconds = self.userTimeSeconds
		end

		parameterValue = 1
	else
		self.blinkingState = "interval"
		self.nextBlinkingTime = self:determineNextBlinkingTiming()
		parameterValue = 1
	end

	for i = 1, #self.parameterIds do
		model:setParameterValue(self.parameterIds[i], parameterValue)
	end
end

return EyeBlink
