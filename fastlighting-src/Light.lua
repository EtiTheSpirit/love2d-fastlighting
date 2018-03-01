--[[
	Main light class by Brent "Xan the Dragon" D.
	
	Data type: light
	
	API:
		light LightLib.new()				Creates a new Light object
		void setGlobalUpdater(function)		See setUpdater below. When this function is used, all lights created afterwards will have their updaters auto-set
		
	Light object API:
		Properties:
			table Position					A 2-index array that stores the 2D position. {0, 0}
			float Radius					The radius, in pixels, that the light takes
			table Color						A 4-index array that stores the R, G, B, and A color of the light. Alpha is unused.
			
		Methods:
			void setUpdater(function)		Set "function" to the update function of the lighting library. 
											When you change any property of the light, this will call the update function with a special set of arguments
											that allows the lighting library to specifically update this light instead of all of them.
--]]

local MainLight = {}
local MainMeta = {}
local GlobalUpdater = nil
setmetatable(MainLight, MainMeta)

local function setGlobalUpdater(f)
	GlobalUpdater = f
end

local function new()
	local Light = {}
	local Meta = {}
	local Enabled = true
	local Position = {0, 0}
	local Radius = 64
	local Color = {255, 255, 255, 255}
	local Updater = GlobalUpdater
	setmetatable(Light, Meta)
	
	local function setUpdater(f)
		Updater = f
	end
	
	Meta.__index = function (Table, Index)
		if Index == "Enabled" then
			return Enabled
		elseif Index == "Position" then
			return Position
		elseif Index == "Radius" then
			return Radius
		elseif Index == "Color" then
			return Color
		elseif Index == "setUpdater" then
			return setUpdater
		end
		return Light
	end
	
	Meta.__newindex = function (Table, Index, Value)
		--One of the major benefits of using metatables here is that I can detect when a variable is changed.
		if Index == "Enabled" then
			Enabled = Value
			if Updater then
				Updater(Light)
			end
		elseif Index == "Position" then
			Position = Value
			if Updater then
				Updater(Light)
			end
		elseif Index == "Radius" then
			Radius = Value
			if Updater then
				Updater(Light)
			end
		elseif Index == "Color" then
			Color = Value
			if Updater then
				Updater(Light)
			end
		end
	end
	
	return Light
end

MainMeta.__index = function (Table, Index)
	if Table == MainLight then
		if Index == "new" then
			return new
		elseif Index == "setGlobalUpdater" then
			return setGlobalUpdater
		end
	end
	return nil
end

MainMeta.__newindex = function (Table, Index, Value)
	--Do nothing. No new indices can be created.
end

return MainLight
