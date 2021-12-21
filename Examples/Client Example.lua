--[[
Written by zblox164
2021
]]

-- Assume non defined variables are pre defined
-- Placement module variables
local placementModule = require(modules:WaitForChild("PlacementModuleV3")) -- Assume this location is valid
local placementInfo = placementModule.new(
	grid,
	models,
	Enum.KeyCode.R, Enum.KeyCode.X, Enum.KeyCode.U, Enum.KeyCode.L,
	Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonX, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown
)

-- Signals
placementInfo.Placed:Connect(function()
	print("placed")
end)

placementInfo.Collided:Connect(function(hit)
	print("collided: " .. hit.Name)
end)

placementInfo.Rotated:Connect(function()
	print("Rotated")
end)

placementInfo.ChangedFloors:Connect(function(upDown)
	print(upDown)
end)

placementInfo.Terminated:Connect(function()
	print("terminated")
end)

placementInfo.Activated:Connect(function()
	print("Activated")
end)

-- Mobile actions
local function raise()
	placementInfo:raise()
end

local function cancel()
	placementInfo:terminate()
end

local function rotate()
	placementInfo:rotate()
end

local function lower()
	placementInfo:lower()
end

-- Placement function
local function clientPlacement()
	placementInfo:requestPlacement(place)
	
	if placementInfo:getCurrentState() == "inactive" and not placementInfo:getPlatform() == "Mobile" then
		contextActionService:UnbindAction("place")
	end
end

local function startPlacement()	
	-- Handle platforms
	if placementInfo:getPlatform() ~= "Mobile" then
		contextActionService:BindAction("place", clientPlacement, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR1)
	else
		placementInfo.MobileUI.place.MouseButton1Click:Connect(clientPlacement)
		placementInfo.MobileUI.raise.MouseButton1Click:Connect(raise)
		placementInfo.MobileUI.lower.MouseButton1Click:Connect(lower)
		placementInfo.MobileUI.cancel.MouseButton1Click:Connect(cancel)
		placementInfo.MobileUI.rotate.MouseButton1Click:Connect(rotate)
	end
	
	placementInfo:activate(model.Name, itemHolder, plot, true, true, false) -- assume variables are set
	
	if userOwnsIgnoreCollisions then -- Assume this code is valid. Example of if you toggled collisions to false if a player owns a gamepass
		placementInfo:editAttribute("Collisions", false)
	else
		placementInfo:editAttribute("Collisions", true)
	end
end

wait(5)

startPlacement()
