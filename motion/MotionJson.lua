local path = (...):sub(1, #(...) - #(".motion.ExpressionMotion"))
local JSON = require(path..".3p.JSON").new() -- new instance
local Luaoop = require(path..".3p.Luaoop")

---@class L2DF.MotionJson
local MotionJson = Luaoop.class("L2DF.MotionJson")

local Meta = "Meta"
local Duration = "Duration"
local Loop = "Loop"
local CurveCount = "CurveCount"
local Fps = "Fps"
local TotalSegmentCount = "TotalSegmentCount"
local TotalPointCount = "TotalPointCount"
local Curves = "Curves"
local Target = "Target"
local Id = "Id"
local FadeInTime = "FadeInTime"
local FadeOutTime = "FadeOutTime"
local Segments = "Segments"
local UserData = "UserData"
local UserDataCount = "UserDataCount"
local TotalUserDataSize = "TotalUserDataSize"
local Time = "Time"
local Value = "Value"

local tonumber, floor = tonumber, math.floor

---@return boolean
local function toboolean(v)
	local t = type(v)
	return not(t == "nil" or v == false or v == 0 or (t == "string" and #v == 0))
end

function MotionJson:__construct(jsondata)
	self.json = JSON:decode(jsondata) ---@type table
	self.meta = self.json[Meta] or {} ---@type table
	self.curves = self.json[Curves] or {} ---@type table
	self.udata = self.json[UserData] or {} ---@type table
end

function MotionJson:getMotionDuration()
	return tonumber(self.meta[Duration]) or 0
end

function MotionJson:isMotionLoop()
	return toboolean(self.meta[Loop])
end

function MotionJson:getMotionCurveCount()
	return floor(tonumber(self.meta[CurveCount]) or 0)
end

function MotionJson:getMotionFps()
	return tonumber(self.meta[Fps]) or 0
end

function MotionJson:getMotionTotalSegmentCount()
	return floor(tonumber(self.meta[TotalSegmentCount]) or 0)
end

function MotionJson:getMotionTotalPointCount()
	return floor(tonumber(self.meta[TotalPointCount]) or 0)
end

---@return boolean
function MotionJson:hasMotionFadeInTime()
	return not(not(self.meta[FadeInTime]))
end

---@return boolean
function MotionJson:hasMotionFadeOutTime()
	return not(not(self.meta[FadeOutTime]))
end

function MotionJson:getMotionFadeInTime()
	return tonumber(self.meta[FadeInTime]) or 0
end

function MotionJson:getMotionFadeOutTime()
	return tonumber(self.meta[FadeOutTime]) or 0
end

---@param index number
function MotionJson:getMotionCurveTarget(index)
	local p = self.curves[index]
	return p and tostring(p[Target] or "") or ""
end

---@param index number
function MotionJson:getMotionCurveId(index)
	local p = self.curves[index]
	return p and tostring(p[Id] or "") or ""
end

---@param index number
---@return boolean
function MotionJson:hasMotionCurveFadeInTime(index)
	local p = self.curves[index]
	return not(not(p and p[FadeInTime]))
end

---@param index number
---@return boolean
function MotionJson:hasMotionCurveFadeOutTime(index)
	local p = self.curves[index]
	return not(not(p and p[FadeOutTime]))
end

---@param index number
function MotionJson:getMotionCurveFadeInTime(index)
	local p = self.curves[index]
	return tonumber(p and p[FadeOutTime]) or 1
end

---@param index number
function MotionJson:getMotionCurveSegmentCount(index)
	local p = self.curves[index]
	return p and p[Segments] and #p[Segments] or 0
end

---@param index number
---@param sindex number
function MotionJson:getMotionCurveSegment(index, sindex)
	local p = self.curves[index]
	return p and p[Segments] and tonumber(p[Segments][sindex]) or 0
end

function MotionJson:getEventCount()
	return tonumber(self.meta[UserDataCount]) or 0
end

function MotionJson:getTotalEventValueSize()
	return tonumber(self.meta[TotalUserDataSize]) or 0
end

---@param index number
function MotionJson:getEventTime(index)
	local p = self.udata[index]
	return p and tonumber(p[Time]) or 0
end

---@param index number
function MotionJson:getEventValue(index)
	local p = self.udata[index]
	return p and tostring(p[Value] or "") or ""
end

return MotionJson
