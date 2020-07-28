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

-- Lua 5.1 backend of lua-live2d

local path = (...):sub(1, #(...) - #(".backend.luapure"))
local live2d = require("lualive2d.core")

local Luaoop = require(path..".3p.Luaoop")
local nvec = require(path..".3p.nvec")
local BackendBase = require(path..".backend.base")

local tableConstructorMt = {
	__index = function(t, n)
		if type(n) == "number" then
			local v = loadstring(string.format("return {%s}", string.rep("nil,", n)), "newtable "..n)
			rawset(t, n, v)
			return v
		else
			return rawget(t, n)
		end
	end
}

local LuaBackend = Luaoop.class("Backend.Lua51", BackendBase)

-- luacheck: push ignore self

function LuaBackend:__construct()
	self.tableConstructor = setmetatable({}, tableConstructorMt)
end

function LuaBackend:loadModel(modelString)
	local model = live2d.loadModelFromString(modelString)
	local width, height, centerX, centerY, pixelPerUnit = model:readCanvasInfo()

	return {
		object = model,
		-- Only these three is consistent
		modelDimensions = nvec(width, height),
		modelOffset = nvec(centerX, centerY),
		modelDPI = pixelPerUnit,

		-- Parameters
		paramDef = model:getParameterDefault(),
		paramValue = model:getParameterValues(),
		paramValueDirty = false,

		-- Parts
		partData = model:getPartsData(),
		partOpacity = model:getPartsOpacity(),

		-- Drawable
		drawData = model:getDrawableData(),
		drawDynData = model:getDynamicDrawableData(),
	}
end

function LuaBackend:updateModel(model)
	if model.paramValueDirty then
		model.object:setParameterValues(model.paramValue)
		model.paramValueDirty = false
	end

	model.object:update()
	model.object:resetDynamicDrawableFlags()
	model:getDrawableData(model.drawData)
	model:getDynamicDrawableData(model.drawDynData)
end

-- luacheck: pop

return LuaBackend
