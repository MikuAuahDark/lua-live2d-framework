-- Copyright(c) Live2D Inc. All rights reserved.
--
-- Use of this source code is governed by the Live2D Open Software license
-- that can be found at http://live2d.com/eula/live2d-open-software-license-agreement_en.html.

local path = (...):sub(1, #(...) - #(".motion.ExpressionMotion"))
local JSON = require(path..".3p.JSON").new() -- new instance
local Luaoop = require(path..".3p.Luaoop")

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
local function toboolean(v)
	local t = type(v)
	return not(t == "nil" or v == false or v == 0 or (t == "string" and #v == 0))
end

function MotionJson:__construct(jsondata)
	self.json = JSON:decode(jsondata)
	self.meta = self.json[Meta] or {}
	self.curves = self.json[Curves] or {}
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

function MotionJson:hasMotionFadeInTime()
	return not(not(self.meta[FadeInTime]))
end

function MotionJson:hasMotionFadeOutTime()
	return not(not(self.meta[FadeOutTime]))
end

function MotionJson:getMotionFadeInTime()
	return tonumber(self.meta[FadeInTime]) or 0
end

function MotionJson:getMotionFadeOutTime()
	return tonumber(self.meta[FadeOutTime]) or 0
end

function MotionJson:getMotionCurveTarget(index)
	local p = self.curves[index]
	return p and tostring(p[Target] or "") or ""
end

function MotionJson:getMotionCurveId(index)
	local p = self.curves[index]
	return p and tostring(p[Id] or "") or ""
end

function MotionJson:hasMotionCurveFadeInTime(index)
	local p = self.curves[index]
	return not(not(p and p[FadeInTime]))
end

function MotionJson:hasMotionCurveFadeOutTime(index)
	local p = self.curves[index]
	return not(not(p and p[FadeOutTime]))
end

return MotionJson
