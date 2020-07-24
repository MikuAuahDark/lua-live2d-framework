local path = (...):sub(1, #(...) - #(".physics.Physics"))
local Luaoop = require(path..".3p.Luaoop")

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

local function getInputFromNormalizedParameterValue(v, pMin, pMax, n, inv, weight)
	return normalizeParameterValue(v, pMin, pMax, n.minimum, n.maximum, n.default, inv) * weight
end

local Physics = Luaoop.class("L2DF.Physics")

function Physics.create(jsondata)

end

return Physics
