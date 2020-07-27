local path = (...):sub(1, #(...) - #(".model.Model"))
local Luaoop = require(path..".3p.Luaoop")
local Backend = require(path..".backend")
local KMath = require(path..".math.Math")

---@class L2DF.Model
local Model = Luaoop.class("L2DF.Model")

local type = type

function Model:__construct(str)
	self.model = Backend:loadModel(str) ---@type userdata

	-- Parts
	self.partCount = Backend:getModelPartCount(self.model) ---@type number
	self.notExistPartId = {} ---@type table<string, number>
	self.notExistPartOpacities = {} ---@type table<number, number>

	-- Parameter
	self.paramCount = Backend:getModelParameterCount(self.model) ---@type number
	self.notExistParam = {}
	self.savedParameters = {}
end

---@return void
function Model:update()
	return Backend:updateModel(self.model)
end

function Model:getModel()
	return self.model
end

---@return number
function Model:getCanvasWidth()
	return (Backend:getModelDimensions(self.model))
end

---@return number
function Model:getCanvasHeight()
	return select(2, Backend:getModelDimensions(self.model))
end

---@param name string
---@return number
function Model:getPartIndex(name)
	local index = Backend:getModelPartIndex(self.model, name)

	if index < 0 then
		for i = 1, #self.notExistPartId do
			if self.notExistPartId[i] == name then
				return i + self.partCount
			end
		end

		local notExistLength = #self.notExistPartId
		index = notExistLength + self.partCount + 1
		self.notExistPartId[notExistLength + 1] = name
		self.notExistPartOpacities[notExistLength + 1] = 0
	end

	return index
end

function Model:getPartCount()
	return self.partCount
end

---@param index number|string
function Model:getPartOpacity(index)
	local t = type(index)

	if t == "number" then
		if index > self.partCount then
			if self.notExistPartId[index - self.partCount] then
				return self.notExistPartOpacities[index - self.partCount]
			else
				return nil
			end
		else
			return Backend:getModelPartOpacity(self.model, index)
		end
	elseif t == "string" then
		return Model:getPartOpacity(self:getPartIndex(index))
	end
end

---@param index number|string
---@param value number
function Model:setPartOpacity(index, value)
	local t = type(index)

	if t == "number" then
		if index > self.partCount then
			if self.notExistPartId[index - self.partCount] then
				self.notExistPartOpacities[index - self.partCount] = value
			end
		else
			Backend:setModelPartOpacity(self.model, index, value)
		end
	elseif t == "string" then
		Model:setPartOpacity(self:getPartIndex(index), value)
	end
end

function Model:getParameterCount()
	return self.paramCount
end

---@param name string
---@return number
function Model:getParameterIndex(name)
	local index = Backend:getModelParameterIndex(self.model, name)

	if index < 0 then
		for i = 1, #self.notExistParam do
			if self.notExistParam[i] == name then
				return i + self.partCount
			end
		end

		local notExistLength = #self.notExistParam
		local object = {
			name,
			Backend:allocateStruct({
				{"double", "value"},
				{"double", "minValue"},
				{"double", "maxValue"},
				{"double", "defValue"}
			})
		}
		object[2].value = 0
		object[2].minValue = -math.huge
		object[2].maxValue = math.huge
		object[2].defValue = 0
		index = notExistLength + self.partCount + 1
		self.notExistParam[notExistLength + 1] = object
	end

	return index
end

---@param index number|string
---@return number
function Model:getParameterMaximumValue(index)
	local t = type(index)

	if t == "number" then
		if index > self.paramCount then
			if self.notExistParam[index - self.partCount] then
				return self.notExistParam[index - self.partCount][2].maxValue
			else
				return nil
			end
		else
			return (select(3, Backend:getModelParameterValue(self.model, index)))
		end
	elseif t == "string" then
		return Model:getParameterMaximumValue(self:getParameterIndex(index))
	end
end

---@param index number|string
---@return number
function Model:getParameterMinimumValue(index)
	local t = type(index)

	if t == "number" then
		if index > self.paramCount then
			if self.notExistParam[index - self.partCount] then
				return self.notExistParam[index - self.partCount][2].minValue
			else
				return nil
			end
		else
			return (select(2, Backend:getModelParameterValue(self.model, index)))
		end
	elseif t == "string" then
		return Model:getParameterMinimumValue(self:getParameterIndex(index))
	end
end

---@param index number|string
---@return number
function Model:getParameterDefaultValue(index)
	local t = type(index)

	if t == "number" then
		if index > self.paramCount then
			if self.notExistParam[index - self.partCount] then
				return self.notExistParam[index - self.partCount][2].defValue
			else
				return nil
			end
		else
			return (select(4, Backend:getModelParameterValue(self.model, index)))
		end
	elseif t == "string" then
		return Model:getParameterDefaultValue(self:getParameterIndex(index))
	end
end

---@param index number|string
---@return number
function Model:getParameterValue(index)
	local t = type(index)

	if t == "number" then
		if index > self.paramCount then
			if self.notExistParam[index - self.partCount] then
				return self.notExistParam[index - self.partCount][2].value
			else
				return nil
			end
		else
			return (select(1, Backend:getModelParameterValue(self.model, index)))
		end
	elseif t == "string" then
		return Model:getParameterValue(self:getParameterIndex(index))
	end
end

---@param index number|string
---@param value number
---@param weight number
function Model:setParameterValue(index, value, weight)
	weight = weight or 1
	local t = type(index)

	if t == "number" then
		if index > self.paramCount then
			if self.notExistParam[index - self.partCount] then
				local v = self.notExistParam[index - self.partCount][2]
				v.value = KMath.range(KMath.lerp(value, v.value, weight), v.minValue, v.maxValue)
			end
		else
			local v1, v2, v3 = Backend:getModelParameterValue(self.mode, index)
			Backend:setModelParameterValue(
				self.model,
				index,
				KMath.range(KMath.lerp(value, v1, weight), v2, v3)
			)
		end
	elseif t == "string" then
		Model:setParameterValue(self:getParameterIndex(index), value, weight)
	end
end

---@param index number|string
---@param value number
---@param weight number
function Model:addParameterValue(index, value, weight)
	weight = weight or 1
	return self:setParameterValue(index, self:getParameterValue(index) + value * weight)
end

---@param index number|string
---@param value number
---@param weight number
function Model:multiplyParameterValue(index, value, weight)
	weight = weight or 1
	return self:setParameterValue(index, self:getParameterValue(index) * (1 + (value - 1) * weight))
end

---@param id string
---@return number
function Model:getDrawableIndex(id)
	local names = Backend:getModelDrawableNames(self.model)

	for i = 1, #names do
		if names[i] == id then
			return i
		end
	end

	return -1
end

function Model:getDrawableCount()
	return #Backend:getModelDrawableNames(self.model)
end

---@param index number
---@return string
function Model:getDrawableId(index)
	local names = Backend:getModelDrawableNames(self.model)
	assert(index > 0 and index <= #names, "index out of range")
	return names[index]
end

-- When using LuaJIT, make sure not to access out-of-bounds index
function Model:getDrawableRenderOrders()
	return Backend:getModelDrawableRenderOrders(self.model)
end

function Model:getDrawableTextureIndices()
	return Backend:getModelDrawableTextureIndex(self.model)
end

function Model:getDrawableVertexIndexCount(index)
	return Backend:getModelDrawableVertexMapCount(self.model, index)
end

function Model:getDrawableVertexCount(index)
	return Backend:getModelDrawableVertexCount(self.model, index)
end

function Model:getDrawableVertices(index)
	return Backend:getModelDrawableVertex(self.model, index, true)
end

function Model:getDrawableVertexIndices(index)
	return Backend:getModelDrawableVertexMap(self.model, index)
end

function Model:getDrawableVertexPositions(index)
	return Backend:getModelDrawableVertex(self.model, index, false)
end

function Model:getDrawableVertexUVs(index)
	return Backend:getModelDrawableUV(self.model, index)
end

function Model:getDrawableOpacity(index)
	return Backend:getModelDrawableUV(self.model, index)
end

function Model:getDrawableCulling(index)
	-- csmIsDoubleSided = 0x4
	return Backend:getModelDrawableFlagsSet(self.model, index, 0x4)
end

---@param index number
---@return "'add' | 'multiply' | 'alpha'", "'alphamultiply' | 'premultiplied'"
function Model:getDrawableBlendMode(index)
	if Backend:getModelDrawableFlagsSet(self.model, index, 0x1) then
		return "add", "alphamultiply"
	elseif Backend:getModelDrawableFlagsSet(self.model, index, 0x2) then
		return "multiply", "premultiplied"
	else
		return "alpha", "alphamultiply"
	end
end

function Model:getDrawableDynamicFlagIsVisible(index)
	return Backend:getModelDrawableDynFlagsSet(self.model, index, 0x1)
end

function Model:getDrawableDynamicFlagVisibilityDidChange(index)
	return Backend:getModelDrawableDynFlagsSet(self.model, index, 0x2)
end

function Model:getDrawableDynamicFlagOpacityDidChange(index)
	return Backend:getModelDrawableDynFlagsSet(self.model, index, 0x4)
end

function Model:getDrawableDynamicFlagDrawOrderDidChange(index)
	return Backend:getModelDrawableDynFlagsSet(self.model, index, 0x8)
end

function Model:getDrawableDynamicFlagRenderOrderDidChange(index)
	return Backend:getModelDrawableDynFlagsSet(self.model, index, 0x10)
end

function Model:getDrawableDynamicFlagVertexPositionsDidChange(index)
	return Backend:getModelDrawableDynFlagsSet(self.model, index, 0x20)
end

function Model:getDrawableMasks()
	local count = #Backend:getModelDrawableNames(self.model)
	local result = {}

	for i = 1, count do
		local clip = Backend:getModelDrawableClips(self.model, i)
		local t = {}

		if clip then
			for j = 1, #clip do
				t[j] = clip[j]
			end
		end

		result[i] = t
	end

	return result
end

function Model:getDrawableMaskCounts()
	local count = #Backend:getModelDrawableNames(self.model)
	local result = {}

	for i = 1, count do
		local clip = Backend:getModelDrawableClips(self.model, i)
		result[i] = clip and #clip or 0
	end

	return result
end

function Model:isUsingMasking()
	local count = #Backend:getModelDrawableNames(self.model)

	for i = 1, count do
		if Backend:getModelDrawableClips(self.model, i) ~= nil then
			return true
		end
	end

	return false
end

function Model:loadParameters()
	local paramCount = self.paramCount
	local savedParamCount = #self.savedParameters

	if paramCount > savedParamCount then
		paramCount = savedParamCount
	end

	for i = 1, paramCount do
		if i > self.paramCount then
			self.notExistParam[i - self.paramCount] = self.savedParameters[i]
		else
			Backend:setModelParameterValue(self.model, i, self.savedParameters[i])
		end
	end
end

function Model:saveParameters()
	local paramCount = self.paramCount + #self.notExistParam

	for i = 1, paramCount do
		if i > self.paramCount then
			self.savedParameters[i] = self.notExistParam[i - self.paramCount]
		else
			self.savedParameters[i] = Backend:getModelParameterValue(self.model, i)
		end
	end
end

return Model
