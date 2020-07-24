local path = (...):sub(1, #(...) - #(".motion.MotionCurve"))
local Luaoop = require(path..".3p.Luaoop")

local MotionCurve = Luaoop.class("L2DF.MotionCurve")

function MotionCurve:__construct()
	self.type = "model"
	self.id = ""
	self.segmentCount = 0
	self.baseSegmentIndex = 0
	self.fadeInTime = 0
	self.fadeOutTime = 0
end

return MotionCurve
