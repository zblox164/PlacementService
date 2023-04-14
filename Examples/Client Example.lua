--[[
Written by zblox164
2023
]]

-- Assume non defined variables are pre defined
-- Placement module variables
local placementService = require(modules:WaitForChild("PlacementService")) -- Assume this location is valid
local placementInfo = placementService.new(
	grid,
	models,
	Enum.KeyCode.R, Enum.KeyCode.X, Enum.KeyCode.U, Enum.KeyCode.L,
	Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonX, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown
)

local connection1
local connection2
local connection3
local connection4
local connection5

-- Signals
placementInfo.Placed:Connect(function(objectName)
	print("placed " .. objectName)
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
	elseif placementInfo:getCurrentState() == "inactive" and placementInfo:getPlatform() == "Mobile"
		connection1:Disconnect()
		connection2:Disconnect()
		connection3:Disconnect()
		connection4:Disconnect()
		connection5:Disconnect()
	end
end

local function startPlacement()	
	-- Handle platforms
	if placementInfo:getPlatform() ~= "Mobile" then
		contextActionService:BindAction("place", clientPlacement, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR1)
	else
		connection1 = placementInfo.MobileUI.place.MouseButton1Click:Connect(clientPlacement)
		connection2 = placementInfo.MobileUI.raise.MouseButton1Click:Connect(raise)
		connection3 = placementInfo.MobileUI.lower.MouseButton1Click:Connect(lower)
		connection4 = placementInfo.MobileUI.cancel.MouseButton1Click:Connect(cancel)
		connection5 = placementInfo.MobileUI.rotate.MouseButton1Click:Connect(rotate)
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
