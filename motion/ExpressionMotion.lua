-- Copyright(c) Live2D Inc. All rights reserved.
--
-- Use of this source code is governed by the Live2D Open Software license
-- that can be found at http://live2d.com/eula/live2d-open-software-license-agreement_en.html.

local path = (...):sub(1, #(...) - #(".motion.ExpressionMotion"))
local JSON = require(path..".3p.JSON").new() -- new instance
local Luaoop = require(path..".3p.Luaoop")
local AMotion = require(path..".motion.AMotion")

local ExpressionMotion = Luaoop.class("L2DF.ExpressionMotion", AMotion)

-- exp3.jsonのキーとデフォルト値
local ExpressionKeyFadeIn = "FadeInTime"
local ExpressionKeyFadeOut = "FadeOutTime"
local ExpressionKeyParameters = "Parameters"
local ExpressionKeyId = "Id"
local ExpressionKeyValue = "Value"
local ExpressionKeyBlend = "Blend"
local BlendValueAdd = "Add"
local BlendValueMultiply = "Multiply"
local BlendValueOverwrite = "Overwrite"
local DefaultFadeTime = 1

function ExpressionMotion:__construct(jsondata)
	AMotion.__construct(self) -- parent constructor
	self.parameters = {}

	local json = JSON:decode(jsondata)
	self:setFadeInTime(tonumber(json[ExpressionKeyFadeIn] or DefaultFadeTime) or DefaultFadeTime)
	self:setFadeOutTime(tonumber(json[ExpressionKeyFadeOut] or DefaultFadeTime) or DefaultFadeTime)

	local parameterCount = #json[ExpressionKeyParameters]
	for i = 1, parameterCount do
		local param = json[ExpressionKeyParameters][i]
		local id = param[ExpressionKeyId]
		local value = assert(tonumber(param[ExpressionKeyValue]), "missing parameter value")

		local blendType
		local blendString = param[ExpressionKeyBlend]
		if blendString == BlendValueAdd then
			blendType = BlendValueAdd
		elseif blendString == BlendValueMultiply then
			blendType = BlendValueMultiply
		elseif blendString == BlendValueOverwrite then
			blendType = BlendValueOverwrite
		else
			blendType = BlendValueAdd
		end

		self.parameters[i] = {
			id = id,
			blend = blendType,
			value = value
		}
	end
end

-- Backward compatibility
function ExpressionMotion.create(jsondata)
	return ExpressionMotion(jsondata)
end

function ExpressionMotion:_doUpdateParameters(model, userTimeSeconds, weight, motionQueueEntry)
	for i = 1, #self.parameters do
		local parameter = self.parameters[i]

		if parameter.blend == BlendValueAdd then
			model:addParameterValue(parameter.id, parameter.value, weight)
		elseif parameter.blend == BlendValueMultiply then
			model:multiplyParameterValue(parameter.id, parameter.value, weight)
		elseif parameter.blend == BlendValueOverwrite then
			model:setParameterValue(parameter.id, parameter.value, weight)
		end
	end
end

return ExpressionMotion
