lua-live2d-framework
====================

[CubismNativeFramework](https://github.com/Live2D/CubismNativeFramework/tree/934c194f1eb29cdc7ff39dc4836bb79b076e5c24) but in Lua.

Provides both CubismNativeFramework-like API and [Live2LOVE](https://github.com/MikuAuahDark/Live2LOVE)-compatible API.

Differences
-----------

C++ and Lua are completely different thing. Here are some differences between CubismNativeFramework and
lua-live2d-framework:

* lua-live2d-framework uses `lowerCamelCase` naming while CubismNativeFramework uses `UpperCamelCase`.

* `CubismId` and `CubismIdHandle` does not exist. Lua string is used instead.

* Anything that uses numeric index ID are assumed to use 1-based indexing.

* There's no `Delete` function. Lua has automatic garbage collection.

* `CubismModel::GetDrawableVertexUvs` is `Model:getDrawableVertexUVs` (notice the uppercase `V`)

* `Model:getDrawableBlendMode` returns 2 strings, which maps to LOVE [BlendMode](https://love2d.org/wiki/BlendMode) and [BlendAlphaMode](https://love2d.org/wiki/BlendAlphaMode) respectively.

* `CubismModel::GetModel` returns backend-specific model object.

* `CubismMoc` equivalent class does not exist. Moc data string is passed directly to `Model` object constructor.

* In `MotionJson` (`CubismMotionJson` equivalent), any `IsExist*` method is replaced by `has*` method instead.

* All `is*` or `has*` method doesn't accept additional value to set the value. Use `set*` function respectively to set it.

* Addition of `Model:getAllParameterValue` which returns 4 values: current parameter value, min, max, and default value.

Third-party Libraries
---------------------

Here's list of 3rd-party libraries used:

* [JSON.lua](http://regex.info/blog/lua/json) - CC-BY license.

* [Luaoop](https://github.com/ImagicTheCat/Luaoop) - MIT license.

* [nvec](https://github.com/MikuAuahDark/NPad93/blob/master/nvec.lua) - zLib license.

License
-------

Most portion of the code falls into [Live2D Open Software License](http://live2d.com/eula/live2d-open-software-license-agreement_en.html)
which is incompatible with **GPL** and its friends. However, some part of the program like backend
and third-party libraries are licensed under permissive license. See each file for more information.

Here are list of files (exclude `3p` folder) which falls under MIT license:

* `init.lua`

* Any files at `backend` folder.

* `math/Math.lua`

* `Live2LOVE.lua`

Anything not stated, with exception of `dummy.lua` falls into Live2D Open Software License.

This thread also worth checking: https://community.live2d.com/discussion/666/re-implementing-cubismnativeframework-is-it-allowed
