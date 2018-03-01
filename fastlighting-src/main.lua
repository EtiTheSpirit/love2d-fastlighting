--[[
	This template code goes over how to use the engine, and provides a runtime environment.
--]]

function love.load()
	Lighting = require("lightlib/Lighting")
	LightLib = require("lightlib/Light")
	OcclusionLib = require("lightlib/OcclusionBox")
	RunStats = require("util/RunStats")
		
	LightLib.setGlobalUpdater(Lighting.updateLight)
	OcclusionLib.setGlobalUpdater(Lighting.updateOcclusion)
	
	Lts = {}
	Occs = {}
end

function love.update(Delta)
	RunStats:Update(Delta)
end

function love.draw()
	love.graphics.clear()
	
	Lighting.activate()
		love.graphics.rectangle("fill", 0, 0, 800, 600)
	Lighting.deactivate()
	
	RunStats:Display()
	love.graphics.print("LEFT CLICK to create a light, RIGHT CLICK to create a 50x50 occlusion area.\nPress Q to delete all lights, and E to delete all occlusion.\n(I strongly encourage going into the code!)", 0, 12)
end

function love.mousepressed(x, y, b)
	if b == 1 then
		local Light = LightLib.new()
		Light.Position = {x, y}
		Light.Color = {255, 255, 255, 255}
		Light.Radius = 128
		Lighting.registerLight(Light)
		table.insert(Lts, Light)
	elseif b == 2 then
		local Occ = OcclusionLib.new()
		Occ.Position = {x - 25, y - 25}
		Occ.Size = {50, 50}
		Lighting.registerOcclusionArea(Occ)
		table.insert(Occs, Occ)
	end
end

function love.keypressed(k)
	if k == "q" then
		for Index, Light in ipairs(Lts) do
			Lighting.unregisterLight(Light)
		end
	elseif k == "e" then
		for Index, Occ in ipairs(Occs) do
			Lighting.unregisterOcclusionArea(Occ)
		end
	end
end
