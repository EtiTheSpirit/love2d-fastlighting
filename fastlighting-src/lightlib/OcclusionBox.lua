--[[
	Main occlusion box class by Brent "Xan the Dragon" D.
	This is an instance-based class.
	It is strongly advised to use the setGlobalUpdater function.
	
	Data type: occlusion
	
	API:
		occlusion OcclusionBox.new()		Creates a new occlusion box instance
		void setGlobalUpdater(function f)	See setUpdater below. When this function is used, all items created afterwards will have their updaters auto-set
		
	Object API:
		Properties:
			table Position					A 2-index array that stores the 2D position of the top-left corner of this area. Default: {0, 0}
			table Size						A 2-index array that stores the 2D size of this box. Default: {0, 0}
			
		Methods:
			void setUpdater(function f)		Set f to the occlusion update function of the lighting library. 
											When you change any property of the occlusion box, this will call the update function with a special set of arguments
											that allows the lighting library to specifically update this box instead of all of them.
--]]

local OcclusionBox = {}
local MainMeta = {}
local GlobalUpdater = nil
setmetatable(OcclusionBox, MainMeta)

local function setGlobalUpdater(f)
	GlobalUpdater = f
end

local function new()
	local Box = {}
	local Meta = {}
	local Position = {0, 0}
	local Size = {0, 0}
	local Updater = GlobalUpdater
	setmetatable(Box, Meta)
	
	local function setUpdater(f)
		Updater = f
	end
	
	Meta.__index = function (Table, Index)
		if Index == "Position" then
			return Position
		elseif Index == "Size" then
			return Size
		elseif Index == "setUpdater" then
			return setUpdater
		end
		return Light
	end
	
	Meta.__newindex = function (Table, Index, Value)
		--One of the major benefits of using metatables here is that I can detect when a variable is changed.
		if Index == "Position" then
			Position = Value
			if Updater then
				Updater(Box)
			end
		elseif Index == "Size" then
			Size = Value
			if Updater then
				Updater(Box)
			end
		end
	end
	
	return Box
end

MainMeta.__index = function (Table, Index)
	if Table == OcclusionBox then
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

return OcclusionBox
