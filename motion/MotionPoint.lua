local path = (...):sub(1, #(...) - #(".motion.MotionPoint"))
local Luaoop = require(path..".3p.Luaoop")

---@class L2DF.MotionPoint
---@field public time number
---@field public value number
local MotionPoint = Luaoop.class("L2DF.MotionPoint")

-- TODO: Optimize with FFI

function MotionPoint:__construct()
	self.time = 0
	self.value = 0
end

return MotionPoint
