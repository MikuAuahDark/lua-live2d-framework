local path = (...):sub(1, #(...) - #(".motion.Motion"))
local Luaoop = require(path..".3p.Luaoop")

local KMath = require(path..".math.Math") ---@type L2DF.Math

local AMotion = require(path..".motion.AMotion")
local MotionCurve = require(path..".motion.MotionCurve")
local MotionData = require(path..".motion.MotionData")
local MotionEvent = require(path..".motion.MotionEvent")
local MotionJson = require(path..".motion.MotionJson")
local MotionPoint = require(path..".motion.MotionPoint")
local MotionSegment = require(path..".motion.MotionSegment")

local max = math.max

---@param a L2DF.MotionPoint
---@param b L2DF.MotionPoint
---@param t number
local function lerpPoints(a, b, t)
	local l = MotionPoint() ---@type L2DF.MotionPoint
	l.time = a.time + (b.time - a.time) * t
	l.value = a.value + (b.value - a.value) * t
	return l
end

---@param points L2DF.MotionPoint[]
---@param time number
---@param index number
---@return number
local function linearEvaluate(points, time, index)
	local t = max((time - points[index].time) / (points[index + 1].time - points[index].time), 0)
	return points[index].value + (points[index + 1].value - points[index].value) * t
end

---@param points L2DF.MotionPoint[]
---@param time number
---@param index number
---@return number
local function bezierEvaluate(points, time, index)
	local t = max((time - points[index].time) / (points[4].time - points[index].time), 0)
	local p23 = lerpPoints(points[index + 1], points[index + 2], t)

	return lerpPoints(
		lerpPoints(lerpPoints(points[index], points[index + 1], t), p23, t),
		lerpPoints(p23, lerpPoints(points[index + 2], points[index + 3], t), t),
		t
	)
end

---@param points L2DF.MotionPoint[]
---@param index number
---@return number
local function steppedEvaluate(points, _, index)
	return points[index].value
end

---@param points L2DF.MotionPoint[]
---@param index number
---@return number
local function inverseSteppedEvaluate(points, _, index)
	return points[index + 1].value
end

---@param motionData L2DF.MotionData
---@param index number
---@param time number
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
	return segment.evaluate(motionData.points, time, segment.basePointIndex)
end

---@class L2DF.Motion: L2DF.AMotion
---@field public sourceFrameRate number
---@field public loopDurationSeconds number
---@field public isLoop boolean
---@field public isLoopFadeIn boolean
---@field public lastWeight number
---@field public motionData L2DF.MotionData
---@field public eyeBlinkParameterIds string[]
---@field public lipSyncParameterIds string[]
---@field public modelCurveIdEyeBlink string
---@field public modelCurveIdLipSync string
local Motion = Luaoop.class("L2DF.Motion", AMotion)

local EffectNameEyeBlink = "EyeBlink"
local EffectNameLipSync  = "LipSync"
local TargetNameModel = "Model"
local TargetNameParameter = "Parameter"
local TargetNamePartOpacity = "PartOpacity"

function Motion:__construct()
	AMotion.__construct(self)
	self.sourceFrameRate = 30
	self.loopDurationSeconds = -1
	self.loop = false
	self.loopFadeIn = true
	self.lastWeight = 0
	self.motionData = nil
	self.eyeBlinkParameterIds = {}
	self.lipSyncParameterIds = {}
	self.modelCurveIdEyeBlink = nil
	self.modelCurveIdLipSync = nil
end

---@param jsondata string
---@return L2DF.Motion
function Motion.create(jsondata)
	---@type L2DF.Motion
	local motion = Motion()

	motion:parse(jsondata)

	motion.sourceFrameRate = motion.motionData.fps
	motion.loopDurationSeconds = motion.motionData.duration
	return motion
end

---@param jsondata string
function Motion:parse(jsondata)
	-- Parse motion
	---@type L2DF.MotionJson
	local json = MotionJson(jsondata)

	---@type L2DF.MotionData
	local motionData = MotionData()
	motionData.duration = json:getMotionDuration()
	motionData.loop = json:isMotionLoop()
	motionData.fps = json:getMotionFps()

	self.motionData = motionData

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

	for i, curve in ipairs(motionData.curves) do
		local target = json:getMotionCurveTarget(i)

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

	for i, event in ipairs(motionData.events) do
        event.fireTime = json:getEventTime(i)
        event.value = json:getEventValue(i)
	end
end

function Motion:getDuration()
	return self.loop and -1 or self.loopDurationSeconds
end

---@param model L2DF.Model
---@param userTimeSeconds number
---@param weight number
---@param motionQueueEntry L2DF.MotionQueueEntry
function Motion:_doUpdateParameters(model, userTimeSeconds, weight, motionQueueEntry)
	self.modelCurveIdEyeBlink = self.modelCurveIdEyeBlink or EffectNameEyeBlink
	self.modelCurveIdLipSync = self.modelCurveIdLipSync or EffectNameLipSync

	local timeOffsetSeconds = math.max(userTimeSeconds - motionQueueEntry:getStartTime(), 0)
	local lipSyncValue, eyeBlinkValue = math.huge, math.huge
	---@type number[]
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
	if self.loop then
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

				local v ---@type number

				if curve.fadeInTime < 0 and curve.fadeOutTime < 0 then
					v = sourceValue + (value - sourceValue) * weight
				else
					---@type number
					local fin, fout

					if curve.fadeInTime < 0 then
						fin = tmpFadeIn
					else
						fin = curve.fadeInTime == 0 and 1 or
							KMath.getEasingSine((userTimeSeconds - motionQueueEntry:getFadeInStartTime()) / curve.fadeInTime)
					end

					if curve.fadeOutTime < 0 then
						fout = tmpFadeOut
					else
						fout = curve.fadeOutTime == 0 and 1 or
							KMath.getEasingSine((motionQueueEntry:getEndTime() - userTimeSeconds) / curve.fadeOutTime)
					end

					v = sourceValue + (value - sourceValue) * self.weight * fin * fout
				end

				model:setParameterValue(parameterIndex, v)
			end
		elseif curve.type == "partopacity" then
			-- Find parameter index.
			local parameterIndex = model:getParameterIndex(curve.id)

			if parameterIndex >= 0 then
				model:setParameterValue(parameterIndex, evaluateCurve(self.motionData, c, time))
			end
		end
	end

	if eyeBlinkValue ~= math.huge then
		for _, i in ipairs(eyeBlinkFlags) do
			local sourceValue = model:getParameterValue(i)
			model:setParameterValue(i, sourceValue + (eyeBlinkValue - sourceValue) * weight)
		end
	end

	if lipSyncValue ~= math.huge then
		for _, i in ipairs(lipSyncFlags) do
			local sourceValue = model:getParameterValue(i)
			model:setParameterValue(i, sourceValue + (lipSyncValue - sourceValue) * weight)
		end
	end
end

---@param parameterId string
---@param value number
function Motion:setParameterFadeInTime(parameterId, value)
	for _, curve in ipairs(self.motionData.curves) do
		if curve.id == parameterId then
			curve.fadeInTime = value
			break
		end
	end
end

---@param parameterId string
---@param value number
function Motion:setParameterFadeOutTime(parameterId, value)
	for _, curve in ipairs(self.motionData.curves) do
		if curve.id == parameterId then
			curve.fadeOutTime = value
			break
		end
	end
end

---@param parameterId string
function Motion:getParameterFadeInTime(parameterId)
	for _, curve in ipairs(self.motionData.curves) do
		if curve.id == parameterId then
			return curve.fadeInTime
		end
	end

	return -1
end

---@param parameterId string
function Motion:getParameterFadeOutTime(parameterId)
	for _, curve in ipairs(self.motionData.curves) do
		if curve.id == parameterId then
			return curve.fadeOutTime
		end
	end

	return -1
end

function Motion:isLoop()
	return self.loop
end

function Motion:setLoop(loop)
	self.loop = not(not(loop))
end

function Motion:isLoopFadeIn()
	return self.loopFadeIn
end

function Motion:setLoopFadeIn(loop)
	self.loopFadeIn = not(not(loop))
end

function Motion:getLoopDuration()
	return self.loopDurationSeconds
end

---@param eyeBlinkParams string[]
---@param lipSyncParams string[]
function Motion:setEffectIDs(eyeBlinkParams, lipSyncParams)
	self.eyeBlinkParameterIds = {}
	self.lipSyncParameterIds = {}

	for i = 1, #eyeBlinkParams do
		self.eyeBlinkParameterIds[i] = eyeBlinkParams[i]
	end

	for i = 1, #lipSyncParams do
		self.lipSyncParameterIds[i] = lipSyncParams[i]
	end
end

function Motion:getFiredEvent(beforeCheckTimeSeconds, motionTimeSeconds)
	local i = 1

	for _, event in ipairs(self.motionData.events) do
		if event.fireTime > beforeCheckTimeSeconds and event.fireTime < motionTimeSeconds then
			self.firedEventValues[i] = event.value
		end
	end

	for j = i, #self.firedEventValues do
		self.firedEventValues[j] = nil
	end

	return self.firedEventValues
end

return Motion
