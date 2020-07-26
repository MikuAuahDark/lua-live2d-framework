local path = (...):sub(1, #(...) - #(".physics.Physics"))
local Luaoop = require(path..".3p.Luaoop")
local nvec = require(path..".3p.nvec") ---@type NVec

local KMath = require(path..".math.Math") ---@type L2DF.Math

local PhysicsInput = require(path..".physics.PhysicsInput") ---@type L2DF.PhysicsInput
local PhysicsJson = require(path..".physics.PhysicsJson") ---@type L2DF.PhysicsJson
local PhysicsParticle = require(path..".physics.PhysicsParticle") ---@type L2DF.PhysicsParticle
local PhysicsRig = require(path..".physics.PhysicsRig") ---@type L2DF.PhysicsRig
local PhysicsSubRig = require(path..".physics.PhysicsSubRig") ---@type L2DF.PhysicsSubRig

local PhysicsTypeTagX = "X"
local PhysicsTypeTagY = "Y"
local PhysicsTypeTagAngle = "Angle"

--- Constant of air resistance.
local AirResistance = 5

--- Constant of maximum weight of input and output ratio.
local MaximumWeight = 100

--- Constant of threshold of movement.
local MovementThreshold = 0.001

local function getRangeValue(a, b)
	return math.abs(math.max(a, b) - math.min(a, b))
end

local function sign(x)
	return x > 0 and 1 or (x < 0 and -1 or 0)
end

local function getDefaultValue(a, b)
	local c = math.min(a, b)
	return c + getRangeValue(a, b) * 0.5
end

---@param v number
---@param pMin number
---@param pMax number
---@param pDef number
---@param nMin number
---@param nMax number
---@param nDef number
---@param inv boolean
local function normalizeParameterValue(v, pMin, pMax, nMin, nMax, nDef, inv)
	local result = 0
	local maxValue = math.max(pMax, pMin)

	if maxValue < v then
		return result
	end

	local minValue = math.min(pMax, pMin)

	if minValue > v then
		return result
	end

	local minNormValue = math.min(nMin, nMax)
	local maxNormValue = math.max(nMin, nMax)
	local middleValue = getDefaultValue(minValue, maxValue)
	local paramValue = v - middleValue

	if paramValue > 0 then
		local nLen = maxNormValue - nDef
		local pLen = maxValue - middleValue

		if pLen ~= 0 then
			result = paramValue * nLen / pLen + nDef
		end
	elseif paramValue < 0 then
		local nLen = minNormValue - nDef
		local pLen = minValue - middleValue

		if pLen ~= 0 then
			result = paramValue * nLen / pLen + nDef
		end
	else
		result = nDef
	end

	return inv and result or -result
end

-- luacheck: push no unused args

---@param v number
---@param pMin number
---@param pMax number
---@param pDef number
---@param nP L2DF.PhysicsNormalization
---@param nA L2DF.PhysicsNormalization
---@param inv boolean
---@param w number
local function getInputTranslationXFromNormalizedParameterValue(v, pMin, pMax, pDef, nP, nA, inv, w)
	return nvec(normalizeParameterValue(v, pMin, pMax, pDef, nP.minimum, nP.maximum, nP.default, inv), 0) * w, 0
end

---@param v number
---@param pMin number
---@param pMax number
---@param pDef number
---@param nP L2DF.PhysicsNormalization
---@param nA L2DF.PhysicsNormalization
---@param inv boolean
---@param w number
local function getInputTranslationYFromNormalizedParameterValue(v, pMin, pMax, pDef, nP, nA, inv, w)
	return nvec(0, normalizeParameterValue(v, pMin, pMax, pDef, nP.minimum, nP.maximum, nP.default, inv)) * w, 0
end

---@param v number
---@param pMin number
---@param pMax number
---@param pDef number
---@param nP L2DF.PhysicsNormalization
---@param nA L2DF.PhysicsNormalization
---@param inv boolean
---@param w number
local function getInputAngleFromNormalizedParameterValue(v, pMin, pMax, pDef, nP, nA, inv, w)
	return nvec(), normalizeParameterValue(v, pMin, pMax, pDef, nA.minimum, nA.maximum, nA.default, inv) * w
end

---@param t NVec
---@param p L2DF.PhysicsParticle[]
---@param i number
---@param inv boolean
---@param gravity NVec
local function getOutputTranslationX(t, p, i, inv, gravity)
	return (inv and -1 or 1) * t.x
end

---@param t NVec
---@param p L2DF.PhysicsParticle[]
---@param i number
---@param inv boolean
---@param gravity NVec
local function getOutputTranslationY(t, p, i, inv, gravity)
	return (inv and -1 or 1) * t.y
end

---@param t NVec
---@param p L2DF.PhysicsParticle[]
---@param i number
---@param inv boolean
---@param gravity NVec
local function getOutputAngle(t, p, i, inv, gravity)
	if i > 2 then
		gravity = p[i - 1].position - p[i - 2].position
	else
		gravity = gravity * -1
	end

	return (inv and -1 or 1) * KMath.directionToRadian(gravity, t)
end

---@param t NVec
---@param a number
local function getOutputScaleTranslationX(t, a)
	return t.x
end

---@param t NVec
---@param a number
local function getOutputScaleTranslationY(t, a)
	return t.y
end

---@param t NVec
---@param a number
local function getOutputScaleAngle(t, a)
	return a
end

-- luacheck: pop

-- TODO: Optimize this function
--- Updates particles.
---@param strand L2DF.PhysicsParticle[] Target array of particle.
---@param totalTranslation NVec Total translation value.
---@param totalAngle number Total angle.
---@param windDirection NVec Direction of wind.
---@param thresholdValue number Threshold of movement.
---@param dt number Delta time.
---@param airResistance number Air resistance.
local function updateParticles(strand, totalTranslation, totalAngle, windDirection, thresholdValue, dt, airResistance)
	strand[1].position = totalTranslation

	local totalRadian = math.pi * totalAngle / 180
	local currentGravity = KMath.radianToDirection(totalRadian):normalizeInplace()

	for i = 2, #strand do
		local st = strand[i]

		st.force = currentGravity * st.acceleration
		st.lastPosition = st.position

		local delay = st.delay * dt * 30
		local direction = st.position - strand[i - 1].position
		local radian = KMath.directionToRadian(st.lastGravity, currentGravity) / airResistance
		local sinv = math.sin(radian)
		local cosv = math.cos(radian)

		-- Not sure if this is a mistake, really
		-- TODO: Rectify this in the future
		--[[
		direction.x = cosv * direction.x - direction.y * sinv
		direction.y = sinv * direction.x + direction.y * cosv
		]]
		direction.x, direction.y = cosv * direction.x - direction.y * sinv, sinv * direction.x + direction.y * cosv

		st.position = strand[i - 1].position + direction

		local velocity = st.velocity * delay
		local force = st.force * delay * delay
		st.position = st.position + velocity + force

		local newDirection = (st.position - strand[i - 1].position):normalizeInplace()

		st.position = strand[i - 1].position + newDirection * st.radius

		if math.abs(st.position.x) < thresholdValue then
			st.position.x = 0
		end

		if delay ~= 0 then
			st.velocity = (st.position - st.lastPosition) * st.mobility / delay
		end

		st.force = nvec()
		st.lastGravity = currentGravity
	end
end

--- Updates output parameter value.
---@param pValue number Target parameter value.
---@param pMin number Minimum of parameter value.
---@param pMax number Maximum of parameter value.
---@param translation number Translation value.
---@param output L2DF.PhysicsOutput
local function updateOutputParameterValue(pValue, pMin, pMax, translation, output)
	local outputScale = output.getScale(output.translationScale, output.angleScale)
	local value = translation * outputScale

	if value < pMin then
		if value < output.valueBelowMinimum then
			output.valueBelowMinimum = value
		end

		value = pMin
	elseif value > pMax then
		if value > output.valueExceededMaximum then
			output.valueExceededMaximum = value
		end

		value = pMax
	end

	local weight = output.weight / MaximumWeight

	if weight > 1 then
		return value
	else
		return pValue * (1 - weight) + value * weight
	end
end

---@class L2DF.Physics
---@field private physicsRig L2DF.PhysicsRig
---@field private options L2DF.Physics.Options
local Physics = Luaoop.class("L2DF.Physics")

function Physics:__construct()
	self.physicsRig = nil
	---@class L2DF.Physics.Options
	---@field public gravity NVec
	---@field public wind NVec
	---@type L2DF.Physics.Options
	self.options = {
		gravity = nvec(0, -1),
		wind = nvec()
	}
end

---@param jsondata string
function Physics.create(jsondata)
	local ret = Physics()

	ret:parse(jsondata)
	ret.physicsRig.gravity.y = 0

	return ret
end

---@param jsondata string
function Physics:parse(jsondata)
	local physicsRig = PhysicsRig()
	local json = PhysicsJson(jsondata)

	physicsRig.gravity = json:getGravity()
	physicsRig.wind = json:getWind()

	local subRigCount = json:getSubRigCount()
	local inputIndex, outputIndex = 1, 1

	for i = 1, subRigCount do
		local setting = PhysicsSubRig()
		physicsRig.settings[i] = setting

		setting.normalizationPosition.minimum = json:getNormalizationPositionMinimumValue(i)
		setting.normalizationPosition.maximum = json:getNormalizationPositionMaximumValue(i)
		setting.normalizationPosition.default = json:getNormalizationPositionDefaultValue(i)
		setting.normalizationAngle.minimum = json:getNormalizationAngleMinimumValue(i)
		setting.normalizationAngle.maximum = json:getNormalizationAngleMaximumValue(i)
		setting.normalizationAngle.default = json:getNormalizationAngleDefaultValue(i)

		-- Input
		setting.inputCount = json:getInputCount(i)
		setting.baseInputIndex = inputIndex

		for j = 1, setting.inputCount do
			local input = PhysicsInput()
			physicsRig.inputs[inputIndex + j - 1] = input
			-- TODO: Remove assert?
			assert(#physicsRig.inputs == inputIndex + j - 1)

			local inputType = json:getInputType(i, j)

			if inputType == PhysicsTypeTagX then
				input.type = "x"
				input.getNormalizedParameterValue = getInputTranslationXFromNormalizedParameterValue
			elseif inputType == PhysicsTypeTagY then
				input.type = "y"
				input.getNormalizedParameterValue = getInputTranslationYFromNormalizedParameterValue
			elseif inputType == PhysicsTypeTagAngle then
				input.type = "angle"
				input.getNormalizedParameterValue = getInputAngleFromNormalizedParameterValue
			end

			input.source.targetType = "parameter"
			input.source.id = json:getInputSourceID(i, j)
		end

		inputIndex = inputIndex + setting.inputCount

		-- Output
		setting.outputCount = json:getOutputCount(i)
		setting.baseOutputIndex = outputIndex

		for j = 1, setting.outputCount do
			-- TODO
		end
	end
end

return Physics
