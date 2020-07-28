local path = (...):sub(1, #(...) - #(".physics.Physics"))
local Luaoop = require(path..".3p.Luaoop")
local nvec = require(path..".3p.nvec") ---@type NVec

local KMath = require(path..".math.Math") ---@type L2DF.Math

local PhysicsInput = require(path..".physics.PhysicsInput") ---@type L2DF.PhysicsInput
local PhysicsJson = require(path..".physics.PhysicsJson") ---@type L2DF.PhysicsJson
local PhysicsOutput = require(path..".physics.PhysicsOutput") ---@type L2DF.PhysicsOutput
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
---@param i number
---@param strandCount number Count of particle.
---@param totalTranslation NVec Total translation value.
---@param totalAngle number Total angle.
---@param windDirection NVec Direction of wind.
---@param thresholdValue number Threshold of movement.
---@param dt number Delta time.
---@param airResistance number Air resistance.
local function updateParticles(strand, i, strandCount, totalTranslation, totalAngle, windDirection, thresholdValue, dt, airResistance)
	strand[i].position = totalTranslation

	local totalRadian = math.pi * totalAngle / 180
	local currentGravity = KMath.radianToDirection(totalRadian):normalizeInplace()

	for j = i + 1, i + strandCount do
		local st = strand[j]

		st.force = currentGravity * st.acceleration
		st.lastPosition = st.position

		local delay = st.delay * dt * 30
		local direction = st.position - strand[j - 1].position
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

		st.position = strand[j - 1].position + direction

		local velocity = st.velocity * delay
		local force = st.force * delay * delay
		st.position = st.position + velocity + force

		local newDirection = (st.position - strand[j - 1].position):normalizeInplace()

		st.position = strand[j - 1].position + newDirection * st.radius

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
	local inputIndex, outputIndex, particleIndex = 1, 1, 1

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

			input.sourceParameterIndex = -1
			input.weight = json:getInputWeight(i, j)
			input.reflect = json:getInputReflect(i, j)

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
			local output = PhysicsOutput()
			physicsRig.outputs[outputIndex + j - 1] = output
			-- TODO: Remove assert?
			assert(#physicsRig.outputs == outputIndex + j - 1)

			output.destinationParameterIndex = -1
			output.vertexIndex = json:getOutputVertexIndex(i, j)
			output.angleScale = json:getOutputAngleScale(i, j)
			output.weight = json:getOutputWeight(i, j)
			output.destination.id = json:getOutputDestinationID(i, j)
			output.reflect = json:getOutputReflect(i, j)

			local outputType = json:getOutputType(i, j)

			if outputType == PhysicsTypeTagX then
				output.type = "x"
				output.getValue = getOutputTranslationX
				output.getScale = getOutputScaleTranslationX
			elseif outputType == PhysicsTypeTagY then
				output.type = "y"
				output.getValue = getOutputTranslationY
				output.getScale = getOutputScaleTranslationY
			elseif outputType == PhysicsTypeTagAngle then
				output.type = "angle"
				output.getValue = getOutputAngle
				output.getScale = getOutputScaleAngle
			end
		end

		outputIndex = outputIndex + setting.outputCount

		-- Particle
		setting.particleCount = json:getParticleCount(i)
		setting.baseParticleIndex = particleIndex

		for j = 1, setting.particleCount do
			local particle = PhysicsParticle()
			physicsRig.particles[particleIndex + j - 1] = particle
			-- TODO: Remove assert?
			assert(#physicsRig.particles == particleIndex + j - 1)

			particle.mobility = json:getParticleMobility(i, j)
			particle.delay = json:getParticleDelay(i, j)
			particle.acceleration = json:getParticleAcceleration(i, j)
			particle.radius = json:getParticleRadius(i, j)
			particle.position = json:getParticlePosition(i, j)
		end

		particleIndex = particleIndex + setting.particleCount
	end

	return self:initialize()
end

function Physics:initialize()
	local strand = self.physicsRig.particles

	for i, v in ipairs(self.physicsRig.settings) do
		local st0 = strand[v.baseParticleIndex]

		-- Initialize the top of particle.
		st0.initialPosition = nvec()
		st0.lastPosition = nvec()
		st0.lastGravity = nvec(0, 1)
		st0.velocity = nvec()
		st0.force = nvec()

		-- Initialize paritcles.
		for j = 2, v.particleCount do
			local st = strand[v.baseParticleIndex + j - 1]

			st.initialPosition = strand[v.baseParticleIndex + j - 2].initialPosition + nvec(0, st.radius)
			st.position = st.initialPosition:clone()
			st.lastPosition = st.initialPosition:clone()
			st.lastGravity = nvec(0, 1)
			st.velocity = nvec()
			st.force = nvec()
		end
	end
end

---@param model L2DF.Model
---@param dt number
function Physics:evaluate(model, dt)
	local particles = self.physicsRig.particles

	for i, setting in ipairs(self.physicsRig.settings) do
		local totalAngle = 0
		local totalTranslation = nvec()
		local baseInputIndex = setting.baseInputIndex
		local baseOutputIndex = setting.baseOutputIndex
		local baseParticleIndex = setting.baseParticleIndex

		-- Load input parameters
		for j, input in ipairs(self.physicsRig.inputs) do
			local weight = input.weight / MaximumWeight

			if input.sourceParameterIndex == -1 then
				input.sourceParameterIndex = model:getParameterIndex(input.source.id)
			end

			local pv, pmin, pmax, pdef = model:getAllParameterValue(input.sourceParameterIndex)
			local a, b = input.getNormalizedParameterValue(
				pv, pmin, pmax, pdef,
				setting.normalizationPosition,
				setting.normalizationAngle,
				input.reflect,
				weight
			)
			totalTranslation = totalTranslation + a
			totalAngle = totalAngle + b
		end

		local radAngle = -totalAngle * math.pi / 180
		local cosv = math.cos(radAngle)
		local sinv = math.sin(radAngle)
		-- Not sure if this is a mistake, really
		-- TODO: Rectify this in the future
		--[[
		totalTranslation.x = cosv * totalTranslation.x - totalTranslation.y * sinv
		totalTranslation.y = sinv * totalTranslation.x + totalTranslation.y * cosv
		]]
		totalTranslation.x, totalTranslation.y = cosv * totalTranslation.x - totalTranslation.y * sinv, sinv * totalTranslation.x + totalTranslation.y * cosv

		-- Calculate particles position.
		updateParticles(
			self.physicsRig.particles,
			baseParticleIndex,
			setting.particleCount,
			totalTranslation,
			totalAngle,
			self.options.wind,
			MovementThreshold * setting.normalizationPosition.maximum,
			dt,
			AirResistance
		)

		-- Update output parameters.
		for j, output in ipairs(self.physicsRig.outputs) do
			local particleIndex = output.vertexIndex

			if particleIndex < 1 or particleIndex >= setting.particleCount then
				break
			end

			if output.destinationParameterIndex == -1 then
				output.destinationParameterIndex = model:getParameterIndex(output.destination.id)
			end

			local translation = particles[baseParticleIndex + particleIndex].position - particles[baseParticleIndex + particleIndex - 1]
			local outputValue = output.getValue(
				translation,
				particles,
				baseParticleIndex + particleIndex,
				output.reflect,
				self.options.gravity
			)

			-- TODO
		end
	end
end

return Physics
