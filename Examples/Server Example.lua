local replicatedStorage = game:GetService("ReplicatedStorage")

-- Ignore the top three functions

-- Credit EgoMoose
local function checkHitbox(character, object)
	if object then
		local collided = false

		local collisionPoint = object.PrimaryPart.Touched:Connect(function() end)
		local collisionPoints = object.PrimaryPart:GetTouchingParts()

		for i = 1, #collisionPoints do
			if not collisionPoints[i]:IsDescendantOf(object) and not collisionPoints[i]:IsDescendantOf(character) then
				collided = true

				break
			end
		end

		collisionPoint:Disconnect()

		return collided
	end
end

local function checkBoundaries(plt, primary) : boolean
	local pos = plt.CFrame
	local size = CFrame.new(primary.Size)*CFrame.fromOrientation(0, primary.Orientation.Y, 0)
	local currentPos = pos:Inverse()*primary.CFrame

	local xBound = (plt.Size.X - size.X)*0.5
	local zBound = (plt.Size.Z - size.Z)*0.5

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
