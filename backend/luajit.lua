-- Copyright (C) 2019 Miku AuahDark
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- LuaJIT backend of lua-live2d using FFI pointers.

-- There are 2 methods:
-- 1. Using lua-live2d library
-- 2. Using Live2DCubismCore directly
-- When using the former, FFI pointers are stored as
-- string (4-byte or 8-byte) to workaround 48-bit address
-- limitation of lightuserdata.

local path = (...):sub(1, #(...) - #(".backend.luajit"))
local hasLive2D, live2d = pcall(require, "lualive2d.core")
local bit = require("bit")
local ffi = require("ffi")

local Luaoop = require(path..".3p.Luaoop")
local nvec = require(path..".3p.nvec")
local BackendBase = require(path..".backend.base")

if not(hasLive2D) then
	live2d = ffi.load("Live2DCubismCore")
end

local funcs = {}

ffi.cdef[[
	typedef struct KVec2
	{
		float x, y;
	} KVec2;
]]

do
-- Setup function pointer
local regFunc

if hasLive2D then
	-- Using lua-live2d library
	function regFunc(name, ret, ...)
		local strptr = live2d.ptr[name]
		if strptr == nil then
			error("missing function '"..name.."'")
		end

		local sign = string.format("%s(**)%s", ret, table.concat({...}, ","))
		funcs[name] = ffi.cast(sign, strptr)[0]
	end
else
	-- Using Live2DCubismCore directly. Cache namespace instead
	funcs = live2d

	function regFunc(name, ret, ...)
		local signature = string.format("%s %s(%s)", ret, name, table.concat({...}, ","))
		ffi.cdef(signature)
		return live2d[name] -- error if it's not found
	end
end

regFunc("csmGetVersion"                , "uint32_t"                                                    )
regFunc("csmGetLatestMocVersion"       , "uint32_t"                                                    )
regFunc("csmGetMocVersion"             , "uint32_t"       , "const void*", "uint32_t"                  )
regFunc("csmReviveMocInPlace"          , "void*"          , "void*"      , "uint32_t"                  )
regFunc("csmGetSizeofModel"            , "uint32_t"       , "void*"                                    )
regFunc("csmInitializeModelInPlace"    , "const void*"    , "void*"      , "uint32_t"                  )
regFunc("csmUpdateModel"               , "void"           , "void*"                                    )
regFunc("csmReadCanvasInfo"            , "void"           , "const void*", "KVec2*", "KVec2*", "float*")
regFunc("csmGetParameterCount"         , "int32_t"        , "const void*"                              )
regFunc("csmGetParameterIds"           , "const char**"   , "const void*"                              )
regFunc("csmGetParameterMinimumValues" , "const float*"   , "const void*"                              )
regFunc("csmGetParameterMaximumValues" , "const float*"   , "const void*"                              )
regFunc("csmGetParameterDefaultValues" , "const float*"   , "const void*"                              )
regFunc("csmGetParameterValues"        , "float*"         , "void*"                                    )
regFunc("csmGetPartCount"              , "int32_t"        , "const void*"                              )
regFunc("csmGetPartIds"                , "const char**"   , "const void*"                              )
regFunc("csmGetPartOpacities"          , "float*"         , "void*"                                    )
regFunc("csmGetPartParentPartIndices"  , "const int32_t*" , "const void*"                              )
regFunc("csmGetDrawableCount"          , "int32_t"        , "const void*"                              )
regFunc("csmGetDrawableIds"            , "const char**"   , "const void*"                              )
regFunc("csmGetDrawableConstantFlags"  , "const int32_t*" , "const void*"                              )
regFunc("csmGetDrawableDynamicFlags"   , "const int32_t*" , "const void*"                              )
regFunc("csmGetDrawableTextureIndices" , "const int32_t*" , "const void*"                              )
regFunc("csmGetDrawableDrawOrders"     , "const int32_t*" , "const void*"                              )
regFunc("csmGetDrawableRenderOrders"   , "const int32_t*" , "const void*"                              )
regFunc("csmGetDrawableOpacities"      , "const float*"   , "const void*"                              )
regFunc("csmGetDrawableMaskCounts"     , "const int32_t*" , "const void*"                              )
regFunc("csmGetDrawableMasks"          , "const int32_t**", "const void*"                              )
regFunc("csmGetDrawableVertexCounts"   , "const int32_t*" , "const void*"                              )
regFunc("csmGetDrawableVertexPositions", "const KVec2**"  , "const void*"                              )
regFunc("csmGetDrawableVertexUvs"      , "const KVec2**"  , "const void*"                              )
regFunc("csmGetDrawableIndexCounts"    , "const int32_t*" , "const void*"                              )
regFunc("csmGetDrawableIndices"        , "const uint16_t*", "const void*"                              )
regFunc("csmResetDrawableDynamicFlags" , "void"           , "void*"                                    )
end

local function KVec2ToNVec(kv2)
	return nvec(kv2.x, kv2.y)
end

local LJBackend = Luaoop.class("Backend.LuaJIT", BackendBase)

-- luacheck: push ignore self

function LJBackend:__construct()
	self.objectCache = {}
end

function LJBackend:allocateStruct(typedef)
	local structdef = {"struct {"}

	for i = 1, #typedef do
		local info = typedef[i]
		structdef[i + 1] = string.format("%s %s;", info[1], info[2])
	end

	local structString = table.concat(structdef)
	if self.objectCache[structString] then
		return self.objectCache[structString]()
	else
		local objectConstructor = ffi.typeof(structString)
		self.objectCache[structString] = objectConstructor
		return objectConstructor()
	end
end

function LJBackend:allocateArray(type, size)
	return ffi.new(type, size + 1) -- Lua arrays start at 1
end

function LJBackend:loadModel(str)
	-- Load moc. Thanks for the alignment support LuaJIT.
	local mocstr = ffi.cast("const char*", str)
	local moc = ffi.new("__declspec(align(64)) char[?]", #str)
	ffi.copy(moc, mocstr, #str)

	local mocObject = funcs.csmReviveMocInPlace(moc)
	if mocObject == nil then
		error("failed to revive moc")
	end

	local modelSize = funcs.csmGetSizeofModel(mocObject)
	if modelSize == 0 then
		error("failed to get model size")
	end

	-- Load model. Thanks for the alignment support LuaJIT.
	local model = ffi.new("__declspec(align(16)) char[?]", modelSize)
	local modelObject = funcs.csmInitializeModelInPlace(mocObject, model, modelSize)
	if modelObject == nil then
		error("failed to initialize model")
	end

	-- Read canvas info
	local tempCanvasInfo = ffi.new("KVec2[3]")
	funcs.csmReadCanvasInfo(modelObject, tempCanvasInfo, tempCanvasInfo + 1, ffi.cast("float*", tempCanvasInfo + 2))

	-- Part info
	local partCount = funcs.csmGetPartCount(modelObject)
	local partNamesRaw = funcs.csmGetPartIds(modelObject)
	local partNames = {}

	for i = 0, partCount - 1 do
		partNames[i + 1] = ffi.string(partNamesRaw[i])
	end

	-- Parameter info
	local paramCount = funcs.csmGetParameterCount(modelObject)
	local paramNamesRaw = funcs.csmGetParameterIds(modelObject)
	local paramNames = {}

	for i = 0, paramCount - 1 do
		paramNames[i + 1] = ffi.string(paramNamesRaw[i])
	end

	-- Drawable
	local drawCount = funcs.csmGetDrawableCount(modelObject)
	local drawNamesRaw = funcs.csmGetDrawableIds(modelObject)
	local drawClipCount = funcs.csmGetDrawableMaskCounts(modelObject)
	local drawClip = funcs.csmGetDrawableMasks(modelObject)
	local drawNames = {}
	local drawClipIDs = {}

	for i = 1, drawCount do
		drawNames[i] = ffi.string(drawNamesRaw[i - 1])
	end

	for i = 0, drawCount - 1 do
		if drawClipCount[i] > 0 then
			local t = self:allocateArray("uint32_t", drawClipCount[i] + 1)

			for j = 0, drawClipCount[i] - 1 do
				t[j + 1] = drawClip[j] + 1
			end

			drawClipIDs[i + 1] = t
		end
	end

	return {
		-- Base
		mocMemory = moc, -- Memory must be keep around or LuaJIT will free it
		mocObject = mocObject,
		modelMemory = model, -- Memory must be keep around or LuaJIT will free it
		modelObject = modelObject,

		-- Model sizes. Only these are public.
		modelDimensions = KVec2ToNVec(tempCanvasInfo[0]),
		modelOffset = KVec2ToNVec(tempCanvasInfo[1]),
		modelDPI = tempCanvasInfo[2].x, -- only the first one is filled

		-- Parts
		partNames = partNames,
		partOpacity = funcs.csmGetPartOpacities(modelObject),

		-- Parameters
		paramNames = paramNames,
		paramMinValue = funcs.csmGetParameterMinimumValues(modelObject),
		paramMaxValue = funcs.csmGetParameterMaximumValues(modelObject),
		paramDefValue = funcs.csmGetParameterDefaultValues(modelObject),
		paramValue = funcs.csmGetParameterValues(modelObject),

		-- Drawable
		drawNames = drawNames,
		drawClips = drawClipIDs,
		drawFlags = funcs.csmGetDrawableConstantFlags(modelObject),
		drawDynFlags = funcs.csmGetDrawableDynamicFlags(modelObject),
		drawIndexMapCount = funcs.csmGetDrawableIndexCounts(modelObject),
		drawIndexMap = funcs.csmGetDrawableIndices(modelObject),
		drawTextures = funcs.csmGetDrawableTextureIndices(modelObject),
		drawVertexCount = funcs.csmGetDrawableVertexCounts(modelObject),
		drawUV = funcs.csmGetDrawableVertexUvs(modelObject),
		drawVertex = funcs.csmGetDrawableVertexPositions(modelObject),
		drawRenderOrder = funcs.csmGetDrawableRenderOrders(modelObject),
		drawOpacity = funcs.csmGetDrawableOpacities(modelObject)
	}
end

function LJBackend:updateModel(model)
	funcs.csmUpdateModel(model.modelObject)
	funcs.csmResetDrawableDynamicFlags(model.modelObject)
end

function LJBackend:getModelDimensions(model)
	return model.modelDimensions:unpack()
end

function LJBackend:getModelPartCount(model)
	return #model.partNames
end

function LJBackend:getModelPartIndex(model, name)
	local p = model.partNames
	for i = 1, #p do
		if p[i] == name then
			return i
		end
	end

	return -#p
end

function LJBackend:getModelPartOpacity(model, index)
	assert(index > 0 and index <= #model.partNames, "model part index out of bounds")
	return model.partOpacity[index - 1]
end

function LJBackend:setModelPartOpacity(model, index, value)
	assert(index > 0 and index <= #model.partNames, "model part index out of bounds")
	model.partOpacity[index - 1] = value
end

function LJBackend:getModelParameterCount(model)
	return model.paramCount
end

function LJBackend:getModelParameterIndex(model, name)
	local p = model.paramNames
	for i = 1, #p do
		if p[i] == name then
			return i
		end
	end

	return -#p
end

function LJBackend:getModelParameterValue(model, index)
	assert(index > 0 and index <= #model.paramNames, "model parameter index out of bounds")
	return
		model.paramValue[index - 1],
		model.paramMinValue[index - 1],
		model.paramMaxValue[index - 1],
		model.paramDefValue[index - 1]
end

function LJBackend:setModelParameterValue(model, index, value)
	assert(index > 0 and index <= #model.paramNames, "model parameter index out of bounds")
	model.paramValue[index - 1] = value
end

function LJBackend:getModelDrawableNames(model)
	return model.drawNames
end

function LJBackend:getModelDrawableRenderOrders(model)
	-- so it starts at index 1
	return model.drawRenderOrder - 1
end

function LJBackend:getModelDrawableTextureIndex(model)
	return model.drawTextures - 1
end

function LJBackend:getModelDrawableVertexMapCount(model, index)
	assert(index > 0 and index <= #model.drawNames, "model drawable index out of bounds")
	return model.drawIndexMapCount[index - 1] - 1
end

function LJBackend:getModelDrawableVertexCount(model, index)
	assert(index > 0 and index <= #model.drawNames, "model drawable index out of bounds")
	return model.drawVertexCount[index - 1] - 1
end

function LJBackend:getModelDrawableVertex(model, index, cast)
	assert(index > 0 and index <= #model.drawNames, "model drawable index out of bounds")

	if cast then
		return ffi.cast("const float*", model.drawVertex[index - 1]) - 1
	else
		return model.drawVertex[index - 1] - 1
	end
end

function LJBackend:getModelDrawableVertexMap(model, index)
	assert(index > 0 and index <= #model.drawNames, "model drawable index out of bounds")
	return model.drawIndexMap[index - 1] - 1
end

function LJBackend:getModelDrawableUV(model, index)
	assert(index > 0 and index <= #model.drawNames, "model drawable index out of bounds")
	return model.drawUV[index - 1] - 1
end

function LJBackend:getModelDrawableOpacity(model, index)
	assert(index > 0 and index <= #model.drawNames, "model drawable index out of bounds")
	return model.drawOpacity[index - 1]
end

function LJBackend:getModelDrawableFlagsSet(model, index, flag)
	assert(index > 0 and index <= #model.drawNames, "model drawable index out of bounds")
	return bit.band(model.drawFlags[index - 1], flag) ~= 0
end

function LJBackend:getModelDrawableDynFlagsSet(model, index, flag)
	assert(index > 0 and index <= #model.drawNames, "model drawable index out of bounds")
	return bit.band(model.drawDynFlags[index - 1], flag) ~= 0
end

function LJBackend:getModelDrawableClips(model, index)
	assert(index > 0 and index <= #model.drawNames, "model drawable index out of bounds")
	if model.drawClipCount[index - 1] > 0 then
		return model.drawClips[index]
	else
		return nil
	end
end

-- luacheck: pop

return LJBackend
