-- Copyright(c) Live2D Inc. All rights reserved.
--
-- Use of this source code is governed by the Live2D Open Software license
-- that can be found at http://live2d.com/eula/live2d-open-software-license-agreement_en.html.

local path = (...):sub(1, #(...) - #(".motion.ExpressionMotion"))
local Luaoop = require(path..".3p.Luaoop")
local AMotion = require(path..".motion.AMotion")
local MotionJson = require(path..".motion.MotionJson")
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
	AMotion.__construct(self)
	self.sourceFrameRate = 30
	self.loopDurationSeconds = -1
	self.isLoop = false
	self.isLoopFadeIn = true
	self.lastWeight = 0
	self.modelCurveIdEyeBlink = nil
	self.modelCurveIdLipSync = nil

	local json = MotionJson(jsondata)
	local motionData = {
		duration = json:getMotionDuration(),
		loop = json:isMotionLoop(),
		fps = json:getMotionFps(),
		curves = {},
		segments = {},
		points = {},
		events = {}
	}
	self.motionData = motionData
	self.sourceFrameRate = motionData.fps
	self.loopDurationSeconds = motionData.duration

	-- pre-allocate stuff
	-- curves
	for i = 1, json:getMotionCurveCount() do
		motionData.curves[i] = {
			type = nil,
			id = nil,
			segmentCount = 0,
			baseSegmentIndex = 0,
			fadeInTime = 1,
			fadeOutTime = 1
		}
	end
	-- segments
	for i = 1, json:getMotionTotalSegmentCount() do
		motionData.segments[i] = {
			evaluate = nil,
			basePointIndex = 0,
			type = nil
		}
	end
	-- points
	for i = 1, json:getMotionTotalPointCount() do
		motionData.points[i] = {
			time = 0,
			value = 0
		}
	end
	-- events
	for i = 1, json:getEventCount() do
		motionData.events[i] = {
			fireTime = 0,
			value = nil
		}
	end

	if json:hasMotionFadeInTime() then
		local v = json:getMotionFadeInTime()
		self.fadeInSeconds = v < 0 and 1 or v
	else
		self.fadeInSeconds = 1
	end

	if json:hasMotionFadeOutTime() then
		local v = json:getMotionFadeOutTime()
		self.fadeOutSeconds = v < 0 and 1 or v
	else
		self.fadeOutSeconds = 1
	end

	local totalPointCount = 0
	local totalSegmentCount = 0

	for i = 1, motionData.curveCount do
		local target = json:getMotionCurveTarget(i)
		local curve = motionData.curves[i]

		if target == TargetNameModel then
			curve.type = "model"
		elseif target == TargetNameParameter then
			curve.type = "parameter"
		elseif target == TargetNamePartOpacity then
			curve.type = "part opacity"
		end

		curve.id = json:getMotionCurveId(i)
		curve.baseSegmentIndex = totalSegmentCount + 1
		curve.fadeInTime = json:hasMotionCurveFadeInTime(i) and json:getMotionCurveFadeInTime(i) or -1
		curve.fadeOutTime = json:hasMotionCurveFadeOutTime(i) and json:getMotionCurveFadeOutTime(i) or -1

		-- segments
		local j = 1
		local segmentCount = json:getMotionCurveSegmentCount(i)
		while j <= segmentCount do
			if j == 1 then
				local point = motionData.points[totalPointCount + 1]
				point.time = json:getMotionCurveSegment(i, j)
				point.value = json:getMotionCurveSegment(i, j + 1)
				motionData.segments[totalSegmentCount + 1].basePointIndex = totalPointCount + 1

				totalPointCount = totalPointCount + 1
				j = j + 2
			else
				motionData.segments[totalSegmentCount + 1].basePointIndex = totalPointCount
			end

			local segmentInt = json:getMotionCurveSegment(i, j)
			if segmentInt == 0 then
				-- linear
                motionData.segments[totalSegmentCount + 1].type = "linear"
                motionData.segments[totalSegmentCount + 1].evaluate = linearEvaluate
                motionData.points[totalPointCount + 1].time = json:getMotionCurveSegment(i, j + 1)
                motionData.points[totalPointCount + 1].value = json:getMotionCurveSegment(i, j + 2)
                totalPointCount = totalPointCount + 1
                j = j + 3
			elseif segmentInt == 1 then
				-- bezier
                motionData.segments[totalSegmentCount + 1].type = "bezier"
                motionData.segments[totalSegmentCount + 1].evaluate = bezierEvaluate
                motionData.points[totalPointCount + 1].time = json:getMotionCurveSegment(i, j + 1)
                motionData.points[totalPointCount + 1].value = json:getMotionCurveSegment(i, j + 2)
                motionData.points[totalPointCount + 2].time = json:getMotionCurveSegment(i, j + 3)
                motionData.points[totalPointCount + 2].value = json:getMotionCurveSegment(i, j + 4)
                motionData.points[totalPointCount + 3].time = json:getMotionCurveSegment(i, j + 5)
                motionData.points[totalPointCount + 4].value = json:getMotionCurveSegment(i, j + 6)
                totalPointCount = totalPointCount + 3
                j = j + 7
			elseif segmentInt == 2 then
				-- stepped
                motionData.segments[totalSegmentCount + 1].type = "stepped"
                motionData.segments[totalSegmentCount + 1].evaluate = steppedEvaluate
                motionData.points[totalPointCount + 1].time = json:getMotionCurveSegment(i, j + 1)
                motionData.points[totalPointCount + 1].value = json:getMotionCurveSegment(i, j + 2)
                totalPointCount = totalPointCount + 1
                j = j + 3
			elseif segmentInt == 3 then
				-- inverse stepped
                motionData.segments[totalSegmentCount + 1].type = "invstepped"
                motionData.segments[totalSegmentCount + 1].evaluate = inverseSteppedEvaluate
                motionData.points[totalPointCount + 1].time = json:getMotionCurveSegment(i, j + 1)
                motionData.points[totalPointCount + 1].value = json:getMotionCurveSegment(i, j + 2)
                totalPointCount = totalPointCount + 1
                j = j + 3
			else
				error("unknown segment type "..tostring(segmentInt))
			end

			curve.segmentCount = curve.segmentCount + 1
			totalSegmentCount = totalSegmentCount + 1
		end
	end

	for i = 1, json:getEventCount() do
        motionData.events[i].fireTime = json:getEventTime(i)
        motionData.events[i].value = json:getEventValue(i)
	end
end

function Motion:getDuration()
	return self.isLoop and -1 or self.loopDurationSeconds
end

return Motion
