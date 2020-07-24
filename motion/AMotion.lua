local path = (...):sub(1, #(...) - #(".motion.AMotion"))
local Luaoop = require(path..".3p.Luaoop")

local KMath = require(path..".math.Math") ---@type L2DF.Math

---@class L2DF.AMotion
---@field protected fadeInSeconds number
---@field protected fadeOutSeconds number
---@field protected weight number
---@field protected offsetSeconds number
---@field protected firedEventValues string[]
local AMotion = Luaoop.class("L2DF.AMotion")

function AMotion:__construct()
	self.fadeInSeconds = -1
	self.fadeOutSeconds = -1
	self.weight = 1
	self.offsetSeconds = 0
	self.firedEventValues = {}
end

---@param model L2DF.Model
---@param motionQueueEntry L2DF.MotionQueueEntry
---@param userTimeSeconds number
function AMotion:updateParameters(model, motionQueueEntry, userTimeSeconds)
	if not(motionQueueEntry:isAvailable()) or motionQueueEntry:isFinished() then
		return
	end

	if not(motionQueueEntry:isStarted()) then
		motionQueueEntry:setStarted(true)
		motionQueueEntry:setStartTime(userTimeSeconds - self.offsetSeconds)
		motionQueueEntry:setFadeInStartTime(userTimeSeconds)

		local duration = self:getDuration()

		if motionQueueEntry:getEndTime() < 0 then
			motionQueueEntry:setEndTime(duration <= 0 and -1 or (motionQueueEntry:getStartTime() + duration))
		end
	end

	local fadeIn = self.fadeInSeconds == 0 and 1 or
		KMath.getEasingSine((userTimeSeconds - motionQueueEntry:getFadeInStartTime()) / self.fadeInSeconds)
	local fadeOut = (self.fadeOutSeconds == 0 or motionQueueEntry:getEndTime()) and 1 or
		KMath.getEasingSine((motionQueueEntry:getEndTime() - userTimeSeconds) / self.fadeOutSeconds)
	local fadeWeight = self.weight * fadeIn * fadeOut

	motionQueueEntry:setState(userTimeSeconds, fadeWeight)
	assert(0 <= fadeWeight and fadeWeight <= 1)
	self:_doUpdateParameters(model, userTimeSeconds, fadeWeight, motionQueueEntry)

	if motionQueueEntry:getEndTime() > 0 and motionQueueEntry:getEndTime() < userTimeSeconds then
		motionQueueEntry:setFinished(true)
	end
end

---@param t number
function AMotion:setFadeInTime(t)
	self.fadeInSeconds = t
end

---@param t number
function AMotion:setFadeOutTime(t)
	self.fadeOutSeconds = t
end

function AMotion:getFadeInTime()
	return self.fadeInSeconds
end

function AMotion:getFadeOutTime()
	return self.fadeOutSeconds
end

---@param w number
function AMotion:setWeight(w)
	self.weight = w
end

function AMotion:getWeight()
	return self.weight
end

-- luacheck: push no unused args

function AMotion:getDuration()
	return -1
end

function AMotion:getLoopDuration()
	return -1
end

-- luacheck: pop

---@param t number
function AMotion:setOffsetTime(t)
	self.offsetSeconds = t
end

-- luacheck: push no unused args

---@param beforeCheckTimeSeconds number
---@param motionTimeSeconds number
function AMotion:getFiredEvents(beforeCheckTimeSeconds, motionTimeSeconds)
	return self.firedEventValues
end

---@param model L2DF.Model
---@param userTimeSeconds number
---@param weight number
---@param motionQueueEntry L2DF.MotionQueueEntry
function AMotion:_doUpdateParameters(model, userTimeSeconds, weight, motionQueueEntry)
	error("pure virtual method '_doUpdateParameters'")
end

-- luacheck: pop

return AMotion
