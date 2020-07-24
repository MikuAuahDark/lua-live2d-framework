local path = (...):sub(1, #(...) - #(".motion.MotionEvent"))
local Luaoop = require(path..".3p.Luaoop")

local MotionEvent = Luaoop.class("L2DF.MotionEvent")

function MotionEvent:__construct()
	self.fireTime = 0
	self.value = nil
end

return MotionEvent
