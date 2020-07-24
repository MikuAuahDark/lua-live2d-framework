local path = (...):sub(1, #(...) - #(".motion.MotionData"))
local Luaoop = require(path..".3p.Luaoop")

local MotionData = Luaoop.class("L2DF.MotionData")

function MotionData:__construct()
	self.duration = 0
	self.loop = false
	self.fps = 0
	self.curves = {}
	self.segments = {}
	self.points = {}
	self.events = {}
end

return MotionData
