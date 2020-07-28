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

---@class Backend.Base
local BackendBase = Luaoop.class("Backend.Base")

-- luacheck: no unused args

function BackendBase:__construct()
	error("pure virtual method 'BackendBase'")
end

--- Returns backend-defined object for models
---@param str string
---@return userdata
function BackendBase:loadModel(str)
	error("pure virtual method 'loadModel'")
end

---@param model userdata
function BackendBase:updateModel(model)
	error("pure virtual method 'update'")
end

---@param model userdata
function BackendBase:getModelDimensions(model)
	error("pure virtual method 'getModelDimensions'")
end

---@param model userdata
function BackendBase:getModelPartCount(model)
	error("pure virtual method 'getModelPartCount'")
end

--- 1-based index of model part, -length on not found
---@param model userdata
---@param name string
---@return number
function BackendBase:getModelPartIndex(model, name)
	error("pure virtual method 'getModelPartIndex'")
end

---@param model userdata
---@param index number
---@return number
function BackendBase:getModelPartOpacity(model, index)
	error("pure virtual method 'getModelPartOpacity'")
end

---@param model userdata
---@param index number
---@param value number
function BackendBase:setModelPartOpacity(model, index, value)
	error("pure virtual method 'setModelPartOpacity'")
end

---@param model userdata
function BackendBase:getModelParameterCount(model)
	error("pure virtual method 'getModelParameterCount'")
end

---@param model userdata
---@param name string
function BackendBase:getModelParameterIndex(model, name)
	error("pure virtual method 'getModelParameterIndex'")
end

---@param model userdata
---@param index number
---@return number
function BackendBase:getModelParameterValue(model, index)
	error("pure virtual method 'getModelParameterValue'")
end

---@param model userdata
---@param index number
---@param value number
function BackendBase:setModelParameterValue(model, index, value)
	error("pure virtual method 'setModelParameterValue'")
end

---@param model userdata
---@return string[]
function BackendBase:getModelDrawableNames(model)
	error("pure virtual method 'getModelDrawableNames'")
end

---@param model userdata
---@return number
function BackendBase:getModelDrawableRenderOrders(model)
	error("pure virtual method 'getModelDrawableRenderOrders'")
end

---@param model userdata
---@return number
function BackendBase:getModelDrawableTextureIndex(model)
	error("pure virtual method 'getModelDrawableTextureIndex'")
end

---@param model userdata
---@param index number
---@return number
function BackendBase:getModelDrawableVertexMapCount(model, index)
	error("pure virtual method 'getModelDrawableVertexMapCount'")
end

---@param model userdata
---@param index number
---@return number
function BackendBase:getModelDrawableVertexCount(model, index)
	error("pure virtual method 'getModelDrawableVertexCount'")
end

---@param model userdata
---@param index number
---@param cast boolean
---@return NVec[]|number[]
function BackendBase:getModelDrawableVertex(model, index, cast)
	error("pure virtual method 'getModelDrawableVertex'")
end

---@param model userdata
---@param index number
---@return number[]
function BackendBase:getModelDrawableVertexMap(model, index)
	error("pure virtual method 'getModelDrawableVertexMap'")
end

---@param model userdata
---@param index number
---@return NVec[]
function BackendBase:getModelDrawableUV(model, index)
	error("pure virtual method 'getModelDrawableUV'")
end

---@param model userdata
---@param index number
---@return number
function BackendBase:getModelDrawableOpacity(model, index)
	error("pure virtual method 'getModelDrawableOpacity'")
end

---@param model userdata
---@param index number
---@param flag number
---@return boolean
function BackendBase:getModelDrawableFlagsSet(model, index, flag)
	error("pure virtual method 'getModelDrawableFlagsSet'")
end

---@param model userdata
---@param index number
---@param flag number
---@return boolean
function BackendBase:getModelDrawableDynFlagsSet(model, index, flag)
	error("pure virtual method 'getModelDrawableDynFlagsSet'")
end

---@param model userdata
---@param index number
---@return number[]
function BackendBase:getModelDrawableClips(model, index)
	error("pure virtual method 'getModelDrawableClips'")
end

return BackendBase
