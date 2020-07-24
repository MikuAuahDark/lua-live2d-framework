local path = (...):sub(1, #(...) - #(".motion.MotionQueueManager"))
local Luaoop = require(path..".3p.Luaoop")

local MotionQueueEntry = require(path..".motion.MotionQueueEntry")

---@alias L2DF.MotionEventFunction fun(caller: L2DF.MotionQueueManager, eventValue: string, customData)

---@class L2DF.MotionQueueManager
---@field protected userTimeSeconds number
---@field private motions L2DF.MotionQueueEntry[]
---@field private eventCallback L2DF.MotionEventFunction
---@field private eventCustomData any
local MotionQueueManager = Luaoop.class("L2DF.MotionQueueManager")

function MotionQueueManager:__construct()
	self.userTimeSeconds = 0
	self.motions = {}
	self.eventCallback = nil
	self.eventCustomData = nil
end

---@param motion L2DF.AMotion
---@param userTimeSeconds number
function MotionQueueManager:startMotion(motion, userTimeSeconds)
	if motion == nil then
		return nil
	end

	for _, mqe in ipairs(self.motions) do
		mqe:startFadeout(mqe.motion:getFadeOutTime(), userTimeSeconds)
	end

	local mqe = MotionQueueEntry() ---@type L2DF.MotionQueueEntry
	mqe.motion = motion

	self.motions[#self.motions + 1] = mqe
	return mqe
end

---@param model L2DF.Model
---@param userTimeSeconds number
function MotionQueueManager:doUpdateMotion(model, userTimeSeconds)
	local updated = false
	local markedForDeletion = {} ---@type number[]

	for i, mqe in ipairs(self.motions) do
		local motion = mqe.motion

		if motion then
			motion:updateParameters(model, mqe, userTimeSeconds)
			updated = true

			local firedList = motion:getFiredEvents(mqe:getLastCheckedEventTime() - mqe:getStartTime(), userTimeSeconds - mqe:getStartTime())
			for _, f in ipairs(firedList) do
				self.eventCallback(self, f, self.eventCustomData)
			end

			mqe:setLastCheckEventTime(userTimeSeconds)

			if mqe:isFinished() then
				markedForDeletion[#markedForDeletion + 1] = i
			end
		else
			markedForDeletion[#markedForDeletion + 1] = i
		end
	end

	-- Remove from backward
	for i = #markedForDeletion, 1, -1 do
		table.remove(self.motions, markedForDeletion[i])
	end

	return updated
end

function MotionQueueManager:isFinished()
	for _, mqe in ipairs(self.motions) do
		if mqe.motion and mqe:isFinished() == false then
			return false
		end
	end

	return true
end

function MotionQueueManager:stopAllMotions()
	for i = #self.motions, 1, -1 do
		self.motions[i] = nil
	end
end

---@param callback L2DF.MotionEventFunction
function MotionQueueManager:setEventCallback(callback, customData)
	self.eventCallback = callback
	self.eventCustomData = customData
end

return MotionQueueManager
