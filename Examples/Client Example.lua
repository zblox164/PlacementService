-- Placement module variables
local placementModule = require(modules:WaitForChild("PlacementModuleV3")) -- Assume this location is valid
local placement = placementModule.new(
	grid,
	models,
	Enum.KeyCode.R, Enum.KeyCode.X, Enum.KeyCode.U, Enum.KeyCode.L,
	Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonX, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown
)

local function hasPlaced()
	print("Placed object")
	-- Whatever you want to do after placement
end

local function clientPlacement()
	placement:requestPlacement(place, hasPlaced)
	
	if placement:getCurrentState() == "inactive" then
		contextActionService:UnbindAction("place")
	end
end

local function startPlacement()	
	contextActionService:BindAction("place", clientPlacement, false, Enum.UserInputType.MouseButton1)
	placement:activate(model.Name, itemHolder, plot, true, true, false) -- assume variables are set
	
  if userOwnsIgnoreCollisions then -- Assume this code is valid. Example of if you toggled collisions to false if a player owns a gamepass
	  placement:editAttribute("Collisions", false)
	else
		placement:editAttribute("Collisions", true)
	end
end

startPlacement()
