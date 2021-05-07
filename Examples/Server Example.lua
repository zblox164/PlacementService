local replicatedStorage = game:GetService("ReplicatedStorage")

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

local function checkBoundaries(plot, primary)
	local lowerXBound
	local upperXBound

	local lowerZBound
	local upperZBound

	local currentPos = primary.Position

	lowerXBound = plot.Position.X - (plot.Size.X*0.5) 
	upperXBound = plot.Position.X + (plot.Size.X*0.5)

	lowerZBound = plot.Position.Z - (plot.Size.Z*0.5)	
	upperZBound = plot.Position.Z + (plot.Size.Z*0.5)

	return currentPos.X > upperXBound or currentPos.X < lowerXBound or currentPos.Z > upperZBound or currentPos.Z < lowerZBound
end

local function place(plr, name, location, prefabs, cframe, c, plot)
	local item = prefabs:FindFirstChild(name):Clone()
	item.PrimaryPart.CanCollide = false
	item:SetPrimaryPartCFrame(cframe)

	if checkBoundaries(plot, item.PrimaryPart) then
		return
	end

	item.Parent = location

	if c then
		if not checkHitbox(plr.Character, item) then
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

replicatedStorage.remotes.functions.requestPlacement.OnServerInvoke = place
