local path = (...):sub(1, #(...) - #(".motion.MotionQueueEntry"))
local Luaoop = require(path..".3p.Luaoop")

---@class L2DF.MotionQueueEntry
---@field private motion L2DF.AMotion
---@field private available boolean
---@field private finished boolean
---@field private started boolean
---@field private startTimeSeconds number
---@field private fadeInStartTimeSeconds number
---@field private endTimeSeconds number
---@field private stateTimeSeconds number
---@field private stateWeight number
---@field private lastEventCheckSeconds number
local MotionQueueEntry = Luaoop.class("L2DF.MotionQueueEntry")

function MotionQueueEntry:__construct()
	self.motion = nil
	self.available = true
	self.finished = false
	self.started = false
	self.startTimeSeconds = -1
	self.fadeInStartTimeSeconds = 0
	self.endTimeSeconds = -1
	self.stateTimeSeconds = 0
	self.stateWeight = 0
	self.lastEventCheckSeconds = 0
end

---@param fadeOutSeconds number
---@param userTimeSeconds number
function MotionQueueEntry:startFadeout(fadeOutSeconds, userTimeSeconds)
	local newEndTimeSeconds = userTimeSeconds + fadeOutSeconds

	if self.endTimeSeconds < 0 or newEndTimeSeconds < self.endTimeSeconds then
		self.endTimeSeconds = newEndTimeSeconds
	end
end

function MotionQueueEntry:isFinished()
	return self.finished
end

function MotionQueueEntry:isStarted()
	return self.started
end

function MotionQueueEntry:getStartTime()
	return self.startTimeSeconds
end

function MotionQueueEntry:getFadeInStartTime()
	return self.fadeInStartTimeSeconds
end

function MotionQueueEntry:getEndTime()
	return self.endTimeSeconds
end

---@param startTime number
function MotionQueueEntry:setStartTime(startTime)
	self.startTimeSeconds = startTime
end

---@param startTime number
function MotionQueueEntry:setFadeInStartTime(startTime)
	self.fadeInStartTimeSeconds = startTime
end

---@param endTime number
function MotionQueueEntry:setEndTime(endTime)
	self.endTimeSeconds = endTime
end

function MotionQueueEntry:setFinished(f)
	self.finished = not(not(f))
end

function MotionQueueEntry:setStarted(f)
	self.started = not(not(f))
end

function MotionQueueEntry:isAvailable()
	return self.available
end

function MotionQueueEntry:setAvailable(f)
	self.available = not(not(f))
end

---@param timeSeconds number
---@param weight number
function MotionQueueEntry:setState(timeSeconds, weight)
	self.stateTimeSeconds = timeSeconds
	self.stateWeight = weight
end

function MotionQueueEntry:getStateTime()
	return self.stateTimeSeconds
end

function MotionQueueEntry:getStateWeight()
	return self.stateWeight
end

function MotionQueueEntry:getLastCheckedEventTime()
	return self.lastEventCheckSeconds
end

---@param checkTime number
function MotionQueueEntry:setLastCheckEventTime(checkTime)
	self.lastEventCheckSeconds = checkTime
end

return MotionQueueEntry
