local replicatedStorage = game:GetService("ReplicatedStorage")

-- Ignore the top three functions
local function checkHitbox(character, object)
	if not object then return false end	
	local collisionPoints = workspace:GetPartsInPart(object.PrimaryPart)

	-- Checks if there is collision on any object that is not a child of the object and is not a child of the player
	for i = 1, #collisionPoints, 1 do
		if not collisionPoints[i].CanTouch then continue end
		if not (not collisionPoints[i]:IsDescendantOf(object) and not collisionPoints[i]:IsDescendantOf(character)) then continue end

		return true
	end

	return false
end

-- Checks if the object exceeds the boundries given by the plot
local function checkBoundaries(plot: BasePart, primary: BasePart): boolean
	local pos: CFrame = plot.CFrame
	local size: Vector3 = CFrame.fromOrientation(0, primary.Orientation.Y*math.pi/180, 0)*primary.Size
	local currentPos: CFrame = pos:Inverse()*primary.CFrame

	local xBound: number = (plot.Size.X - size.X)
	local zBound: number = (plot.Size.Z - size.Z)

	return currentPos.X > xBound or currentPos.X < -xBound or currentPos.Z > zBound or currentPos.Z < -zBound
end

local function handleCollisions(character: Model, item, collisions: boolean): boolean
	if not collisions then item.PrimaryPart.Transparency = 1; return true end
	
	local collision = checkHitbox(character, item)
	if collision then item:Destroy(); return false end
	
	item.PrimaryPart.Transparency = 1
	return true
end

--Ignore above

-- Edit if you want to have a server check if collisions are enabled or disabled
local function getCollisions(name: string): boolean
	return true
end

local function place(player, name: string, location: Instance, prefabs: Instance, cframe: CFrame, plot: BasePart)
	local collisions = getCollisions(name)
	local item = prefabs:FindFirstChild(name):Clone()
	item.PrimaryPart.CanCollide = false
	item:PivotTo(cframe)
	
	if plot then
		if checkBoundaries(plot, item.PrimaryPart) then 
			return 
		end

		item.Parent = location

		return handleCollisions(player.Character, item, collisions)
	end
	
	return handleCollisions(player.Character, item, collisions)
end

replicatedStorage.remotes.functions.requestPlacement.OnServerInvoke = place
