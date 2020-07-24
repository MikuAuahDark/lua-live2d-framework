local path = (...):sub(1, #(...) - #(".motion.MotionManager"))
local Luaoop = require(path..".3p.Luaoop")

local MotionQueueManager = require(path..".motion.MotionQueueManager") ---@type L2DF.MotionQueueManager

---@class L2DF.MotionManager: L2DF.MotionQueueManager
---@field private currentPriority number
---@field private reservePriority number
local MotionManager = Luaoop.class("L2DF.MotionManager")

function MotionManager:__construct()
	MotionQueueManager.__construct(self)
	self.currentPriority = 0
	self.reservePriority = 0
end

function MotionManager:getCurrentPriority()
	return self.currentPriority
end

function MotionManager:getReservePriority()
	return self.reservePriority
end

---@param v number
function MotionManager:setReservePriority(v)
	self.reservePriority = v
end

---@param motion L2DF.AMotion
---@param priority number
function MotionManager:startMotionPriority(motion, priority)
	if priority == self.reservePriority then
		self.reservePriority = 0
	end

	self.currentPriority = priority
	return self:startMotion(motion, self.userTimeSeconds)
end

---@param model L2DF.Model
---@param dt number
function MotionManager:updateMotion(model, dt)
	self.userTimeSeconds = self.userTimeSeconds + dt

	local updated = self:doUpdateMotion(model, self.userTimeSeconds)

	if self:isFinished() then
		self.currentPriority = 0
	end

	return updated
end

function MotionManager:reserveMotion(priority)
	if priority <= self.reservePriority or priority <= self.currentPriority then
		return false
	end

	self.reservePriority = priority
	return true
end

return MotionManager
