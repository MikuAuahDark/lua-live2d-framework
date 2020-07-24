local path = (...):sub(1, #(...) - #(".motion.MotionSegment"))
local Luaoop = require(path..".3p.Luaoop")

---@class L2DF.MotionSegment
---@field public evaluate fun(points: L2DF.MotionPoint[], time: number): number
---@field public basePointIndex number
---@field public segmentType number
local MotionSegment = Luaoop.class("L2DF.MotionSegment")

function MotionSegment:__construct()
	self.evaluate = nil
	self.basePointIndex = 0
	self.segmentType = 0
end

return MotionSegment
