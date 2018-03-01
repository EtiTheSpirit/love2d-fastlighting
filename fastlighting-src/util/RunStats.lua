--[[
	Easy run stats library.
	Prints FPS and delta-time.
	
	Methods:
		void Update(DeltaTime)					Send an update. Should be called every love.update()
		
		void Display(x, y)						Display pre-formatted text at (x, y) via love.graphics.print
		
		void DisplayCustom(format_text, x, y)	Display custom-formatted text at (x, y)
			Formatting is the same as lua's system.
			The default for this function: 
											FPS: %d | dt: %d ms
--]]

local RunStats = {}

local DELTA = 0
local TICKS = 0
local AVG_FPS = 0
local TIMER = 0

function RunStats:Update(Delta)
	DELTA = Delta
	AVG_FPS = AVG_FPS + (1/DELTA)
	TICKS = TICKS + 1
	TIMER = TIMER + Delta
	if TIMER >= 1 then
		TIMER = TIMER - 1
		AVG_FPS = 0
		TICKS = 0
	end
end

function RunStats:DisplayCustom(Text, x, y)
	local Text = Text or "FPS: %d | dt: %dms"
	local x = x or 0
	local y = y or 0
	
	love.graphics.print(string.format(Text, math.floor(AVG_FPS / TICKS), math.floor(DELTA * 1000)), x, y)
end

function RunStats:Display(x, y)
	RunStats:DisplayCustom(nil, x, y)
end

return RunStats
