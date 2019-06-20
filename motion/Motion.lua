-- Copyright(c) Live2D Inc. All rights reserved.
--
-- Use of this source code is governed by the Live2D Open Software license
-- that can be found at http://live2d.com/eula/live2d-open-software-license-agreement_en.html.

local path = (...):sub(1, #(...) - #(".motion.ExpressionMotion"))
local JSON = require(path..".3p.JSON").new() -- new instance
local Luaoop = require(path..".3p.Luaoop")
local AMotion = require(path..".motion.AMotion")
local Backend = require(path..".backend")

local max = math.max

local function lerpPoints(a, b, t)
	return {
		time = a.time + (b.time - a.time) * t,
		value = a.value + (b.value - a.value) * t,
	}
end

local function linearEvaluate(points, time)
	local t = max((time - points[1].time) / (points[2].time - points[1].time), 0)
	return points[1].value + (points[2].value - points[1].value) * t
end

local function bezierEvaluate(points, time)
	local t = max((time - points[1].time) / (points[4].time - points[1].time), 0)
	local p23 = lerpPoints(points[2], points[3], t)

	return lerpPoints(
		lerpPoints(lerpPoints(points[1], points[2], t), p23, t),
		lerpPoints(p23, lerpPoints(points[3], points[4], t), t),
		t
	)
end

local function steppedEvaluate(points)
	return points[1].value
end

local function inverseSteppedEvaluate(points)
	return points[2].value
end

local function evaluateCurve(motionData, index, time)
	local curve = motionData.curves[index]
	local target = -1
	-- baseSegmentIndex is 1-based so subtract by 1
	local totalSegmentCount = curve.baseSegmentIndex + curve.segmentCount - 1
	local pointPosition = 0

	for i = curve.baseSegmentIndex, totalSegmentCount do
		local segment = motionData.segments[i]
		pointPosition = segment.basePointIndex + (segment.type == "bezier" and 3 or 1)

		if motionData.points[pointPosition].time > time then
			target = i
			break
		end
	end

	if target == -1 then
		return motionData.points[pointPosition].value
	end

	local segment = motionData.segments[target]
	return segment.evaluate(motionData.points[segment.basePointIndex], time)
end

local Motion = Luaoop.class("L2DF.Motion", AMotion)

local EffectNameEyeBlink = "EyeBlink"
local EffectNameLipSync  = "LipSync"
local TargetNameModel = "Model"
local TargetNameParameter = "Parameter"
local TargetNamePartOpacity = "PartOpacity"

function Motion:__construct(jsondata)
	--[[
	: _sourceFrameRate(30.0f)
    , _loopDurationSeconds(-1.0f)
    , _isLoop(false)                // trueから false へデフォルトを変更
    , _isLoopFadeIn(true)           // ループ時にフェードインが有効かどうかのフラグ
    , _lastWeight(0.0f)
    , _motionData(NULL)
    , _modelCurveIdEyeBlink(NULL)
	, _modelCurveIdLipSync(NULL)]]
end

return Motion
