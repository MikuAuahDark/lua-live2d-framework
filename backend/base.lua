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

-- Base backend class
local path = (...):sub(1, #(...) - #(".backend.base"))
local Luaoop = require(path..".3p.Luaoop")

local BackendBase = Luaoop.class("Kareni.BackendBase")

-- luacheck: no unused args

function BackendBase:__construct()
	error("pure virtual method 'BackendBase'")
end

function BackendBase:allocateArray(type, size)
	error("pure virtual method 'allocateArray'")
end

-- Format: {{type1, name1}, {type2, name2}, ...}
function BackendBase:allocateStruct(typedef)
	error("pure virtual method 'allocateStruct'")
end

-- Returns backend-defined object for models
function BackendBase:loadModel(str)
	error("pure virtual method 'loadModel'")
end

function BackendBase:updateModel(model)
	error("pure virtual method 'update'")
end

function BackendBase:getModelDimensions(model)
	error("pure virtual method 'getModelDimensions'")
end

function BackendBase:getModelPartCount(model)
	error("pure virtual method 'getModelPartCount'")
end

-- 1-based index of model part, -length on not found
function BackendBase:getModelPartIndex(model, name)
	error("pure virtual method 'getModelPartIndex'")
end

function BackendBase:getModelPartOpacity(model, index)
	error("pure virtual method 'getModelPartOpacity'")
end

function BackendBase:setModelPartOpacity(model, index, value)
	error("pure virtual method 'setModelPartOpacity'")
end

function BackendBase:getModelParameterCount(model)
	error("pure virtual method 'getModelParameterCount'")
end

function BackendBase:getModelParameterIndex(model, name)
	error("pure virtual method 'getModelParameterIndex'")
end

function BackendBase:getModelParameterValue(model, index)
	error("pure virtual method 'getModelParameterValue'")
end

function BackendBase:setModelParameterValue(model, index, value)
	error("pure virtual method 'setModelParameterValue'")
end

function BackendBase:getModelDrawableNames(model)
	error("pure virtual method 'getModelDrawableNames'")
end

function BackendBase:getModelDrawableRenderOrders(model)
	error("pure virtual method 'getModelDrawableRenderOrders'")
end

function BackendBase:getModelDrawableTextureIndex(model)
	error("pure virtual method 'getModelDrawableTextureIndex'")
end

function BackendBase:getModelDrawableVertexMapCount(model, index)
	error("pure virtual method 'getModelDrawableVertexMapCount'")
end

function BackendBase:getModelDrawableVertexCount(model, index)
	error("pure virtual method 'getModelDrawableVertexCount'")
end

function BackendBase:getModelDrawableVertex(model, index, cast)
	error("pure virtual method 'getModelDrawableVertex'")
end

function BackendBase:getModelDrawableVertexMap(model, index)
	error("pure virtual method 'getModelDrawableVertexMap'")
end

function BackendBase:getModelDrawableUV(model, index)
	error("pure virtual method 'getModelDrawableUV'")
end

function BackendBase:getModelDrawableOpacity(model, index)
	error("pure virtual method 'getModelDrawableOpacity'")
end

function BackendBase:getModelDrawableFlagsSet(model, index, flag)
	error("pure virtual method 'getModelDrawableFlagsSet'")
end

function BackendBase:getModelDrawableDynFlagsSet(model, index, flag)
	error("pure virtual method 'getModelDrawableDynFlagsSet'")
end

function BackendBase:getModelDrawableClips(model, index)
	error("pure virtual method 'getModelDrawableClips'")
end

return BackendBase
