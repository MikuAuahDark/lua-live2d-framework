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

local path = (...):sub(1, #(...) - #(".math.Math"))
local nvec = require(path..".3p.nvec")

---@class L2DF.Math
local KMath = {}

local min, max, atan2, sin, cos = math.min, math.max, (math.atan2 or math.atan), math.sin, math.cos
local pi = math.pi

---@param v number
---@param a number
---@param b number
---@return number
function KMath.range(v, a, b)
	return min(max(v, a), b)
end

---@param t number
function KMath.lerp(v1, v2, t)
	return v1 * (1 - t) + v2 * t
end

---@param v number
function KMath.getEasingSine(v)
	return v < 0 and 0 or (v > 1 and 1 or (0.5 - 0.5 * cos(v * pi)))
end

---@param from NVec
---@param to NVec
---@return number
function KMath.directionToRadian(from, to)
	return ((atan2(to.y, to.x) - atan2(from.y, from.x)) + pi) % (2 * pi) - pi
end

---@param from NVec
---@param to NVec
---@return number
function KMath.directionToDegrees(from, to)
	local deg = KMath.directionToRadian(from, to) * 180 / pi

	if (to.x - from.x) > 0 then
		return -deg
	else
		return deg
	end
end

---@param r number
---@return NVec
function KMath.radianToDirection(r)
	return nvec(sin(r), cos(r))
end

return KMath
