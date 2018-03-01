--[[
	Lighting library by Brent "Xan the Dragon" D.
	
	Limitations:
		Only up to 128 lights can be registered at one time.
		
		* A good method is to make an amount of lights, this amount will be the most lights you think you'll use at one point.
		* From then, have those lights ready to go. You should store them in your own way.
		* When you want to use a light, register it. When you don't want to use it, unregister.
		* Also, make sure to recycle lights. If one screen has 10 lights but the next has 6, only unregister 4 and then change the rest.
	
	API:
		Properties:
			float Brightness					Determines the default luminescense of drawn elements. 0 = pitch black, 1 = fully bright
			
		Methods:
			void activate()						Activates the shader. While the shader is active, any calls to drawing functions will be affected by lighting.
			void deactivate()					Deactivates the shader.
			void register(Light)				Register a light object, adding it to the list of lights to draw. (See Light.lua)
			void unregister(Light)				Unregister a light object, removing it from the list of lights to draw.
			void updateLights()*				Tells the lighting engine that some registered light has changed, causing it to update the corresponding values.
			void updateOcclusion()*				Tells the lighting engine that some registered occlusion area has changed, causing it to update the corresponding values.
			void registerOcclusionArea(box)		Creates an area of occlusion where lights will not draw.
			void unregisterOcclusionArea(box)	Destroys the area of occlusion given.
	
				* DO NOT get these confused for a frame update function!!! They should not be called in love.update unless you like lag + crashing.
	API Notes:
		Occlusion areas (Areas marked that do not permit light to go through) do not draw anything!
		It is up to you to draw any visual cues that mark a wall or any other obstruction that would block light.
		Without doing this, it appears to be an area that simply is unlit (spooooooky)
--]]

local LightCount = 0
local OcclusionCount = 0
local Brightness = 0.05 --0 = black, 1 = no lighting
local reg_Shader = nil
local SHADER_ACTIVE = false
local success, err = pcall(function ()
	reg_Shader = love.graphics.newShader("lightlib/shader.glsl")
end)
if not success then
	--Shader file not found?
	error("Something errored when trying to load the shader! Did you move the file from (root)/lightlib/?\n\nLua error: " .. err, 0)
end

reg_Shader:send("ambient_color", {Brightness * 255, Brightness * 255, Brightness * 255, 255})

local Lighting = {}
local Lights = {}
local Occlusions = {}
local Meta = {}

local cPos = {} --All light positions
local cCol = {} --All light colors
local cRad = {} --All light radius.. radiuses? radii?
local cStx = {} --All light states
local cOcl = {} --All light occlusion boxes.

local cRef = {} --All light references. The indices in this table are light objects, and their values are the index of the light's value in the 4 tables above
local cOrf = {} --All occlusion references. The index here is an occlusion object, and the value is the index in cOcl

setmetatable(Lighting, Meta)

local function registerLight(light)
	if not light then return end
	if Lights[light] then return end --Light already registered.
	Lights[light] = light; --This is weird but nice to have
	cPos = {}
	cCol = {}
	cRad = {}
	cStx = {}
	cRef = {}
	for Index, v in pairs(Lights) do
		if v ~= nil then
			table.insert(cPos, v.Position)
			table.insert(cCol, v.Color)
			table.insert(cRad, v.Radius)
			table.insert(cStx, v.Enabled) --Fun fact: This is how you do a ternary operator in lua. The catch is that the thing between "and" and "or" must not be false or nil.
			cRef[v] = #cPos --I cound do the length of any of the above.
		end
	end
	LightCount = LightCount + 1
	reg_Shader:send("light_pos", unpack(cPos))
	reg_Shader:send("light_colors", unpack(cCol))
	reg_Shader:send("light_radius", unpack(cRad))
	reg_Shader:send("light_state", unpack(cStx))
	reg_Shader:send("light_count", LightCount)
end

local function unregisterLight(light)
	if not light then return end
	if not Lights[light] then return end --Light already unregistered.
	Lights[light] = nil;
	cPos = {}
	cCol = {}
	cRad = {}
	cStx = {}
	cRef = {}
	for Index, v in pairs(Lights) do
		if v ~= nil then
			table.insert(cPos, v.Position)
			table.insert(cCol, v.Color)
			table.insert(cRad, v.Radius)
			table.insert(cStx, v.Enabled)
			cRef[v] = #cPos --I cound do the length of any of the above.
		end
	end
	LightCount = LightCount - 1
	if LightCount > 0 then
		reg_Shader:send("light_pos", unpack(cPos))
		reg_Shader:send("light_colors", unpack(cCol))
		reg_Shader:send("light_radius", unpack(cRad))
		reg_Shader:send("light_state", unpack(cStx))
		reg_Shader:send("light_count", LightCount)
	else
		--Do not send the data. Instead, send the 0 count only.
		--Cannot send nil / empty data.
		reg_Shader:send("light_count", LightCount)
	end
end

local function activate()
	if SHADER_ACTIVE then
		--tf2_heavy_tinyhead_hold_the_fuck_up.png
		--We called this while the shader was already active.
		--This means that somewhere we forgot to call deactivate and have called activate again
		--There's no way that I have implemented at the moment to tell if this is a separate call.
		--However, regardless, this should not be done and will cause extreme impacts if deactivate() is never called.
		error("Error: Lighting.activate() was called a second time before a deactivate call was made!", 0)
	end
	SHADER_ACTIVE = true
	love.graphics.setShader(reg_Shader)
end

local function deactivate()
	SHADER_ACTIVE = false
	love.graphics.setShader()
end

local function updateLights(light)
	if light then
		local idx = cRef[light]
		if idx then
			cPos[idx] = light.Position
			cCol[idx] = light.Color
			cRad[idx] = light.Radius
			cStx[idx] = light.Enabled
			reg_Shader:send("light_pos", unpack(cPos))
			reg_Shader:send("light_colors", unpack(cCol))
			reg_Shader:send("light_radius", unpack(cRad))
			reg_Shader:send("light_state", unpack(cStx))
			--If the index for the light was nil, it means we set some property (and the updater) of a light before registering it.
			--In this instance we will do nothing.
		end
	else
		cPos = {}
		cCol = {}
		cRad = {}
		cStx = {}
		cRef = {}
		LightCount = 0
		for Index, v in pairs(Lights) do
			if v ~= nil then
				table.insert(cPos, v.Position)
				table.insert(cCol, v.Color)
				table.insert(cRad, v.Radius)
				table.insert(cStx, v.Enabled)
				cRef[v] = #cPos --I cound do the length of any of the above.
				LightCount = LightCount + 1
			end
		end
		if LightCount > 0 then
			reg_Shader:send("light_pos", unpack(cPos))
			reg_Shader:send("light_colors", unpack(cCol))
			reg_Shader:send("light_radius", unpack(cRad))
			reg_Shader:send("light_state", unpack(cStx))
			reg_Shader:send("light_count", LightCount)
		else
			reg_Shader:send("light_count", LightCount)
		end
	end
end

local function updateOcclusion(box)
	if box then
		local idx = cOrf[box]
		if idx then
			cOcl[idx] = {box.Position[1], box.Position[2], box.Size[1], box.Size[2]}
			reg_Shader:send("light_nodraw_area", unpack(cOcl))
		end
	else
		cOcl = {}
		cOrf = {}
		OcclusionCount = 0
		for Index, v in pairs(Occlusions) do
			if v ~= nil then
				table.insert(cOcl, {box.Position[1], box.Position[2], box.Size[1], box.Size[2]})
				cOrf[v] = #cOcl
				OcclusionCount = OcclusionCount + 1
			end
		end
		if OcclusionCount > 0 then
			reg_Shader:send("light_nodraw_area", unpack(cOcl))
			reg_Shader:send("nodraw_count", OcclusionCount)
		else
			reg_Shader:send("nodraw_count", OcclusionCount)
		end
	end
end

local function registerOcclusionArea(box)
	if not box then return end
	if Occlusions[box] then return end --Already registered
	Occlusions[box] = box;
	cOcl = {}
	cOrf = {}
	for Index, v in pairs(Occlusions) do
		if v ~= nil then
			table.insert(cOcl, {v.Position[1], v.Position[2], v.Size[1], v.Size[2]})
			cOrf[v] = #cOcl
		end
	end
	OcclusionCount = OcclusionCount + 1
	reg_Shader:send("light_nodraw_area", unpack(cOcl))
	reg_Shader:send("nodraw_count", OcclusionCount)
end

local function unregisterOcclusionArea(box)
	if not box then return end
	if not Occlusions[box] then return end --Already unregistered
	Occlusions[box] = nil;
	cOcl = {}
	cOrf = {}
	for Index, v in pairs(Occlusions) do
		if v ~= nil then
			table.insert(cOcl, {v.Position[1], v.Position[2], v.Size[1], v.Size[2]})
			cOrf[v] = #cOcl
		end
	end
	OcclusionCount = OcclusionCount - 1
    if OcclusionCount > 0 then
		reg_Shader:send("light_nodraw_area", unpack(cOcl))
		reg_Shader:send("nodraw_count", OcclusionCount)
	else
		reg_Shader:send("nodraw_count", OcclusionCount)
	end
end

Meta.__index = function (Table, Index)
	if Table == Lighting then
		if Index == "registerLight" then
			return registerLight
		elseif Index == "unregisterLight" then
			return unregisterLight
		elseif Index == "activate" then
			return activate
		elseif Index == "deactivate" then
			return deactivate
		elseif Index == "updateLights" then
			return updateLights
		elseif Index == "updateOcclusion" then
			return updateOcclusion
		elseif Index == "registerOcclusionArea" then
		    return registerOcclusionArea
		elseif Index == "unregisterOcclusionArea" then
		    return unregisterOcclusionArea
		elseif Index == "Brightness" then
			return Brightness
		end
	end
end

Meta.__newindex = function (Table, Index, Value)
	if Table == Lighting then
		if Index == "Brightness" then
			Brightness = Value
			local v = Brightness * 255;
			reg_Shader:send("ambient_color", {v, v, v, 255})
		end
	end
end

return Lighting
