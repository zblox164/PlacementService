local replicatedStorage = game:GetService("ReplicatedStorage")

-- Ignore the top three functions
local function checkHitbox(character, object)
	if object then
		local collided = false	
		local collisionPoints = workspace:GetPartsInPart(object.PrimaryPart)

		for i = 1, #collisionPoints, 1 do
			if collisionPoints[i].CanTouch and not collisionPoints[i]:IsDescendantOf(object) and not collisionPoints[i]:IsDescendantOf(character) then
				collided = true

				break
			end
		end

		return collided
	end
end

local function checkBoundaries(plt: BasePart, primary: BasePart): boolean
	local pos = plt.CFrame
	local size = CFrame.fromOrientation(0, primary.Orientation.Y, 0)*primary.Size
	local currentPos = pos:Inverse()*primary.CFrame

	local xBound = (plt.Size.X - size.X)
	local zBound = (plt.Size.Z - size.Z)

	return currentPos.X > xBound or currentPos.X < -xBound or currentPos.Z > zBound or currentPos.Z < -zBound
end

local function handleCollisions(char, item, c)
	if c then
		if not checkHitbox(char, item) then
			item.PrimaryPart.Transparency = 1

			return true
		else
			item:Destroy()

			return false
		end
	else
		item.PrimaryPart.Transparency = 1

		return true
	end
end

--Ignore above

local function place(plr, name, location, prefabs, cframe, c, plot)
	local item = prefabs:FindFirstChild(name):Clone()
	item.PrimaryPart.CanCollide = false
	item:PivotTo(cframe)
	
	if plot then
		if checkBoundaries(plot, item.PrimaryPart) then
			return
		end

		item.Parent = location

		return handleCollisions(plr.Character, item, c)
	else
		return handleCollisions(plr.Character, item, c)
	end
end

replicatedStorage.remotes.functions.requestPlacement.OnServerInvoke = place
