local path = (...):sub(1, #(...) - #(".motion.MotionData"))
local Luaoop = require(path..".3p.Luaoop")

---@class L2DF.MotionData
---@field public duration number
---@field public loop boolean
---@field public curves L2DF.MotionCurve[]
---@field public segments L2DF.MotionSegment[]
---@field public points L2DF.MotionPoint[]
---@field public events L2DF.MotionEvent[]
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
