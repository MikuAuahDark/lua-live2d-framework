local path = (...):sub(1, #(...) - #(".motion.Motion"))
local Luaoop = require(path..".3p.Luaoop")

local KMath = require(path..".math.Math")

local AMotion = require(path..".motion.AMotion")
local MotionCurve = require(path..".motion.MotionCurve")
local MotionData = require(path..".motion.MotionData")
local MotionEvent = require(path..".motion.MotionEvent")
local MotionJson = require(path..".motion.MotionJson")
local MotionPoint = require(path..".motion.MotionPoint")
local MotionSegment = require(path..".motion.MotionSegment")

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

---@class L2DF.Motion:L2DF.AMotion
local Motion = Luaoop.class("L2DF.Motion", AMotion)

local EffectNameEyeBlink = "EyeBlink"
local EffectNameLipSync  = "LipSync"
local TargetNameModel = "Model"
local TargetNameParameter = "Parameter"
local TargetNamePartOpacity = "PartOpacity"
local MaxTargetSize = 64

function Motion:__construct()
	AMotion.__construct(self)
	self.sourceFrameRate = 30
	self.loopDurationSeconds = -1
	self.isLoop = false
	self.isLoopFadeIn = true
	self.lastWeight = 0
	self.motionData = nil
	self.eyeBlinkParameterIds = {}
	self.lipSyncParameterIds = {}
	self.modelCurveIdEyeBlink = nil
	self.modelCurveIdLipSync = nil
end

function Motion.create(jsondata)
	local motion = Motion()

	-- Parse motion
	local json = MotionJson(jsondata)

	local motionData = MotionData()
	motionData.duration = json:getMotionDuration()
	motionData.loop = json:isMotionLoop()
	motionData.fps = json:getMotionFps()

	motion.motionData = MotionData()
	motion.sourceFrameRate = motionData.fps
	motion.loopDurationSeconds = motionData.duration

	-- pre-allocate stuff

	-- curves
	for i = 1, json:getMotionCurveCount() do
		motionData.curves[i] = MotionCurve()
	end

	-- segments
	for i = 1, json:getMotionTotalSegmentCount() do
		motionData.segments[i] = MotionSegment()
	end

	-- points
	for i = 1, json:getMotionTotalPointCount() do
		motionData.points[i] = MotionPoint()
	end

	-- events
	for i = 1, json:getEventCount() do
		motionData.events[i] = MotionEvent()
	end

	if json:hasMotionFadeInTime() then
		local v = json:getMotionFadeInTime()
		motion.fadeInSeconds = v < 0 and 1 or v
	else
		motion.fadeInSeconds = 1
	end

	if json:hasMotionFadeOutTime() then
		local v = json:getMotionFadeOutTime()
		motion.fadeOutSeconds = v < 0 and 1 or v
	else
		motion.fadeOutSeconds = 1
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
			curve.type = "partopacity"
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

	return motion
end

function Motion:getDuration()
	return self.isLoop and -1 or self.loopDurationSeconds
end

function Motion:_doUpdateParameters(model, userTimeSeconds, weight, motionQueueEntry)
	self.modelCurveIdEyeBlink = self.modelCurveIdEyeBlink or EffectNameEyeBlink
	self.modelCurveIdLipSync = self.modelCurveIdLipSync or EffectNameLipSync

	local timeOffsetSeconds = math.max(userTimeSeconds - motionQueueEntry:getStartTime(), 0)
	local lipSyncValue, eyeBlinkValue = math.huge, math.huge
	local lipSyncFlags, eyeBlinkFlags = {}, {}

	--[[
	if #self.eyeBlinkParameterIds > MaxTargetSize then
		-- log("too many eye blink targets "..#self.eyeBlinkParameterIds)
	end

	if #self.lipSyncParameterIds > MaxTargetSize then
		-- log("too many eye blink targets "..#self.eyeBlinkParameterIds)
	end
	]]

	local tmpFadeIn = self.fadeInSeconds < 0 and 1 or
		KMath.getEasingSine((userTimeSeconds - motionQueueEntry:getFadeInStartTime()) / self.fadeInSeconds)
	local tmpFadeOut = (self.fadeOutSeconds < 0 or motionQueueEntry:getEndTime() < 0) and 1 or
		KMath.getEasingSine((motionQueueEntry:getEndTime() - userTimeSeconds) / self.fadeOutSeconds)

	local time = timeOffsetSeconds

	-- 'Repeat' time as necessary.
	if self.isLoop then
		time = time % self.motionData.duration
	end

	local curves = self.motionData.curves
	local parameterMotionCurveCount = 0

	-- Evaluate curves.
	for c, curve in ipairs(curves) do
		if curve.type == "model" then
			-- Evaluate curve and call handler.
			local value = evaluateCurve(self.motionData, c, time)

			if curve.id == self.modelCurveIdEyeBlink then
				eyeBlinkValue = value
			elseif curve.id == self.modelCurveIdLipSync then
				lipSyncValue = value
			end
		elseif curve.type == "parameter" then
			parameterMotionCurveCount = parameterMotionCurveCount + 1

			-- Find parameter index.
			local parameterIndex = model:getParameterIndex(curve.id)

			if parameterIndex >= 0 then
				local sourceValue = model:getParameterValue(parameterIndex)
				local value = evaluateCurve(self.motionData, c, time)

				if eyeBlinkValue ~= math.huge then
					for i, eyeParam in ipairs(self.eyeBlinkParameterIds) do
						if eyeParam == curve.id then
							value = value * eyeBlinkValue
							eyeBlinkFlags[#eyeBlinkFlags + 1] = i
							break
						end
					end
				end

				if lipSyncValue ~= math.huge then
					for i, lipSync in ipairs(self.lipSyncParameterIds) do
						if lipSync == curve.id then
							value = value + lipSyncValue
							lipSyncFlags[#lipSyncFlags + 1] = i
							break
						end
					end
				end

				local v = 0
				-- TODO complete
			end
		else
			break
		end
	end

end

return Motion
