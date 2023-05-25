--!nonstrict

--[[

Thank you for using Placement Service!

Current Version - V1.6.2
Written by zblox164. Initial release (V1.0.0) on 2020-05-22

]]--

-- IT IS RECOMMENDED NOT TO EDIT PAST THIS POINT

local PlacementInfo = {__type = "PlacementInfo"}
PlacementInfo.__index = PlacementInfo

-- SETTINGS (DO NOT EDIT SETTINGS IN THE SCRIPT. USE THE ATTRIBUTES INSTEAD)

-- Bools
local angleTilt: boolean = script:GetAttribute("AngleTilt") -- Toggles if you want the object to tilt when moving (based on speed)
local audibleFeedback: boolean = script:GetAttribute("AudibleFeedback") -- Toggles sound feedback on placement
local buildModePlacement: boolean = script:GetAttribute("BuildModePlacement") -- Toggles "build mode" placement
local charCollisions: BoolValue = script:GetAttribute("CharacterCollisions") -- Toggles character collisions (Requires "Collisions" to be set to true)
local collisions: boolean = script:GetAttribute("Collisions") -- Toggles collisions
local displayGridTexture: boolean = script:GetAttribute("DisplayGridTexture") -- Toggles the grid texture to be shown when placing
local enableFloors: boolean = script:GetAttribute("EnableFloors") -- Toggles if the raise and lower keys will be enabled
local gridFadeIn: boolean = script:GetAttribute("GridFadeIn") -- If you want the grid to fade in when activating placement
local gridFadeOut: boolean = script:GetAttribute("GridFadeOut") -- If you want the grid to fade out when ending placement
local includeSelectionBox: boolean = script:GetAttribute("IncludeSelectionBox") -- Toggles if a selection box will be shown while placing
local instantActivation: boolean = script:GetAttribute("InstantActivation") -- Toggles if the model will appear at the mouse position immediately when activating placement
local interpolation: boolean = script:GetAttribute("Interpolation") -- Toggles interpolation (smoothing)
local invertAngleTilt: boolean = script:GetAttribute("InvertAngleTilt") -- Inverts the direction of the angle tilt
local moveByGrid: boolean = script:GetAttribute("MoveByGrid") -- Toggles grid system
local preferSignals: boolean = script:GetAttribute("PreferSignals") -- Controls if you want to use signals or callbacks
local removeCollisionsIfIgnored: boolean = script:GetAttribute("RemoveCollisionsIfIgnored") -- Toggles if you want to remove collisions on objects that are ignored by the mouse
local smartDisplay: boolean = script:GetAttribute("SmartDisplay") -- Toggles smart display for the grid. If true, it will rescale the grid texture to match your gridsize
local transparentModel: boolean = script:GetAttribute("TransparentModel") -- Toggles if the model itself will be transparent
local useHighlights: boolean = script:GetAttribute("UseHighlights") -- Toggles whether the selection box will be a highlight object or a selection box (TransparencyDelta must be 0)

-- Color3
local collisionColor: Color3 = script:GetAttribute("CollisionColor3") -- Color of the hitbox when colliding
local hitboxColor: Color3 = script:GetAttribute("HitboxColor3") -- Color of the hitbox while not colliding
local selectionCollisionColor: Color3 = script:GetAttribute("SelectionBoxCollisionColor3") -- Color of the selectionBox lines when colliding (includeSelectionBox much be set to true)
local selectionColor: Color3 = script:GetAttribute("SelectionBoxColor3") -- Color of the selectionBox lines (includeSelectionBox much be set to true)

-- Integers (Will round to nearest unit if given float)
local floorStep: number = script:GetAttribute("FloorStep") -- The step (in studs) that the object will be raised or lowered
local gridTextureScale: number = script:GetAttribute("GridTextureScale") -- How large the StudsPerTileU/V is displayed (smartDisplay must be set to false)
local maxHeight: number = script:GetAttribute("MaxHeight") -- Max height you can place objects (in studs)
local maxRange: number = script:GetAttribute("MaxRange") -- Max range for the model (in studs)
local rotationStep: number = script:GetAttribute("RotationStep") -- Rotation step

-- Numbers/Floats
local angleTiltAmplitude: number = script:GetAttribute("AngleTiltAmplitude") -- How much the object will tilt when moving. 0 = min, 10 = max
local audioVolume: number = script:GetAttribute("AudioVolume") -- Volume of the sound feedback
local hitboxTransparency: number = script:GetAttribute("HitboxTransparency") -- Hitbox transparency when placing
local lerpSpeed: number = script:GetAttribute("LerpSpeed") -- Speed of interpolation. 0 = no interpolation, 0.9 = major interpolation
local lineThickness: number = script:GetAttribute("LineThickness") -- How thick the line of the selection box is (includeSelectionBox much be set to true)
local lineTransparency: number = script:GetAttribute("LineTransparency") -- How transparent the line of the selection box is (includeSelectionBox must be set to true)
local placementCooldown: number = script:GetAttribute("PlacementCooldown") -- How quickly the user can place down objects (in seconds)
local targetFPS: number = script:GetAttribute("TargetFPS") -- The target constant FPS
local transparencyDelta: number = script:GetAttribute("TransparencyDelta") -- Transparency of the model itself (transparentModel must equal true)

-- Other
local gridTexture: string = script:GetAttribute("GridTextureID") -- ID of the grid texture shown while placing (requires DisplayGridTexture == true)
local soundID: string = script:GetAttribute("SoundID") -- ID of the sound played on Placement (requires audibleFeedback == true)

-- Cross Platform
local hapticFeedback: boolean = script:GetAttribute("HapticFeedback") -- If you want a controller to vibrate when placing objects (only works if the user has a controller with haptic support)
local vibrateAmount: number = script:GetAttribute("HapticVibrationAmount") -- How large the vibration is when placing objects. Choose a value from 0, 1. hapticFeedback must be set to true.

-- Essentials
local runService: RunService = game:GetService("RunService")
local contextActionService: ContextActionService = game:GetService("ContextActionService")
local userInputService: UserInputService = game:GetService("UserInputService")
local hapticService: HapticService = game:GetService("HapticService")
local guiService: GuiService = game:GetService("GuiService")
local tweenService: TweenService = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera: Camera = workspace.CurrentCamera
local mouse: Mouse = player:GetMouse()

-- math/cframe functions
local clamp: (number, number, number) -> number = math.clamp
local floor: (number) -> number = math.floor
local abs: (number) -> number = math.abs
local min: (number, ...number) -> number = math.min
local pi: number = math.pi
local round: (number) -> number = math.round
local cframe = CFrame.new
local anglesXYZ: (number, number, number) -> CFrame = CFrame.fromEulerAnglesXYZ
local fromOrientation: (number, number, number) -> CFrame = CFrame.fromOrientation

-- states
local states: {} = {"movement", "placing", "colliding", "inactive", "out-of-range"}

local currentState: number = 4
local lastState: number = 4

-- Constructor variables
local GRID_UNIT: number
local rotateKey: Enum.KeyCode
local terminateKey: Enum.KeyCode
local raiseKey: Enum.KeyCode
local lowerKey: Enum.KeyCode
local xboxRotate: Enum.KeyCode
local xboxTerminate: Enum.KeyCode
local xboxRaise: Enum.KeyCode
local xboxLower: Enum.KeyCode
local mobileUI: ScreenGui = script:FindFirstChildOfClass("ScreenGui")

-- signals
local placed: BindableEvent
local collided: BindableEvent
local outOfRange: BindableEvent
local rotated: BindableEvent
local terminated: BindableEvent
local changeFloors: BindableEvent
local activated: BindableEvent

-- bools
local autoPlace: boolean?
local canActivate: boolean? = true
local isMobile: boolean? = false
local isXbox: boolean? = false
local currentRot: boolean? = false
local removePlotDependencies: boolean?
local setup: boolean? = false

local running: boolean? = false
local canPlace: boolean?
local stackable: boolean?
local smartRot: boolean?
local range: boolean?

-- values used for calculations
local speed: number = 1
local rangeOfRay: number = 10000
local y: number
local dirX: number
local dirZ: number
local initialY: number
local floorHeight: number = 0

-- Placement Variables
local hitbox
local object
local primary
local selection
local plot
local target
local placementSFX
local rotation
local mobileUI
local placedObjects
local amplitude

-- other
local lastPlacement: {} = {}
local humanoid: Humanoid = character:WaitForChild("Humanoid")
local raycastParams: RaycastParams = RaycastParams.new()
local messages: {} = {
	["101"] = "[Placement Service] Your trying to activate placement too fast! Please slow down.",
	["201"] = "[Placement Service] Error code 201: The object that the model is moving on is not scaled correctly. Consider changing it.",
	["301"] = "[Placement Service] Error code 301: You have improperly setup your callback function. Please input a valid callback.",
	["401"] = "[Placement Service] Error code 401: Grid size is too close to the plot size. To fix this, try lowering the grid size.",
	["501"]	= "[Placement Service] Error code 501: Cannot find a surface to place on. Please make sure one is available."
}

-- Tween Info
local fade: TweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0)

-- Sets the current state depending on input of function
local function setCurrentState(state: number)
	currentState = clamp(state, 1, 5)
	lastState = currentState
end

-- Changes the color of the hitbox depending on the current state
local function editHitboxColor()
	if not primary then return end
	local color = hitboxColor
	local color2 = selectionColor
	
	if currentState >= 3 then
		color = collisionColor
		color2 = selectionCollisionColor
	end
	
	primary.Color = color

	if includeSelectionBox then 
		if useHighlights then 
			selection.OutlineColor = color2
		else
			selection.Color3 = color2 
		end
	end
end

-- Checks for collisions on the hitbox
local function checkHitbox()
	if not (hitbox:IsDescendantOf(workspace) and collisions) then return end
	if range then setCurrentState(5) else setCurrentState(1) end
	character = player.Character

	local collisionPoints: {BasePart} = workspace:GetPartsInPart(hitbox)

	-- Checks if there is collision on any object that is not a child of the object and is not a child of the player
	for i: number = 1, #collisionPoints, 1 do
		if not collisionPoints[i].CanTouch then continue end
		if (not charCollisions and collisionPoints[i]:IsDescendantOf(character)) then continue end
		if not ((not collisionPoints[i]:IsDescendantOf(object)) and collisionPoints[i] ~= plot) then continue end
		
		setCurrentState(3)
		if preferSignals then collided:Fire(collisionPoints[i]) end; break
	end

	return
end

-- (Raise and Lower functions) Edits the floor based on the floor step
local function raiseFloor(actionName: string, inputState: Enum.UserInputState, inputObj: InputObject?)
	if not (currentState ~= 4 and inputState == Enum.UserInputState.Begin) then return end
	if not (enableFloors and not stackable) then return end	
	floorHeight += floor(abs(floorStep))
	floorHeight = math.clamp(floorHeight, 0, maxHeight)
		
	if preferSignals then changeFloors:Fire(true) end
end

local function lowerFloor(actionName: string, inputState:Enum.UserInputState, inputObj: InputObject?)
	if not (currentState ~= 4 and inputState == Enum.UserInputState.Begin) then return end
	if not (enableFloors and not stackable) then return end
	floorHeight -= floor(abs(floorStep))
	floorHeight = math.clamp(floorHeight, 0, maxHeight)
	
	if preferSignals then changeFloors:Fire(false) end
end

-- Handles scaling of the grid texture on placement activation
local function displayGrid()
	local gridTex: Texture = Instance.new("Texture")
	gridTex.Name = "GridTexture"
	gridTex.Texture = gridTexture
	gridTex.Face = Enum.NormalId.Top
	gridTex.Transparency = 1
	gridTex.StudsPerTileU = gridTextureScale
	gridTex.StudsPerTileV = gridTextureScale
	
	if smartDisplay then
		gridTex.StudsPerTileU = GRID_UNIT
		gridTex.StudsPerTileV = GRID_UNIT
	end

	if gridFadeIn then
		local tween: Tween = tweenService:Create(gridTex, fade, {Transparency = 0})
		tween:Play()
	else
		gridTex.Transparency = 0
	end

	gridTex.Parent = plot
end

local function displaySelectionBox()
	local selectionBox
	
	if useHighlights then
		selectionBox = Instance.new("Highlight")
		selectionBox.OutlineColor = selectionColor
		selectionBox.OutlineTransparency = lineTransparency
		selectionBox.FillTransparency = 1
		selectionBox.DepthMode = Enum.HighlightDepthMode.Occluded
		selectionBox.Adornee = object
	else
		selectionBox = Instance.new("SelectionBox")
		selectionBox.LineThickness = lineThickness
		selectionBox.Color3 = selectionColor
		selectionBox.Transparency = lineTransparency
		selectionBox.Adornee = primary
	end
	
	selectionBox.Parent = player.PlayerGui
	selectionBox.Name = "outline"
	selection = selectionBox
end

-- Removes any textures/grids
local function removeTexture()
	for i, texture: Instance in ipairs(plot:GetChildren()) do
		if not (texture.Name == "GridTexture" and texture:IsA("Texture")) then continue end
		if not gridFadeOut then texture:Destroy(); break end	

		local tween = tweenService:Create(texture, fade, {Transparency = 1})
		tween:Play()

		local connection = tween.Completed:Connect(function() texture:Destroy() end)
		connection:Disconnect()
	end
end

local function createAudioFeedback()
	local audio = Instance.new("Sound")
	audio.Name = "placementFeedback"
	audio.Volume = audioVolume
	audio.SoundId = soundID
	audio.Parent = player.PlayerGui
	placementSFX = audio
end

local function playAudio()
	if audibleFeedback and placementSFX then placementSFX:Play() end
end

-- Checks to see if the model is in range of the maxRange
local function getRange(): number
	character = player.Character
	return (primary.Position - character.PrimaryPart.Position).Magnitude
end

-- Handles rotation of the model
local function ROTATE(actionName: string, inputState: Enum.UserInputState, inputObj: InputObject?)
	if not (currentState ~= 4 and currentState ~= 2 and inputState == Enum.UserInputState.Begin) then return end
	if smartRot then
		-- Rotates the model depending on if currentRot is true/false
		if currentRot then rotation += rotationStep; else rotation -= rotationStep end
	else
		rotation += rotationStep
	end

	-- Toggles currentRot
	local rotateAmount = round(rotation/90)
	currentRot = rotateAmount%2 == 0 and true or false
	if rotation >= 360 then rotation = 0 end
	if preferSignals then rotated:Fire() end
end

-- Calculates the Y position to be ontop of the plot (all objects) and any object (when stacking)
local function calculateYPos(tp: number, ts: number, o: number, normal: number): number
	if normal == 0  then
		return (tp + ts*0.5) - o*0.5
	end
	
	return (tp + ts*0.5) + o*0.5
end

-- Clamps the x and z positions so they cannot leave the plot
local function bounds(c: CFrame, offsetX: number, offsetZ: number): CFrame
	local pos: CFrame = plot.CFrame
	local xBound: number = (plot.Size.X*0.5) - offsetX
	local zBound: number = (plot.Size.Z*0.5) - offsetZ

	local newX: number = clamp(c.X, -xBound, xBound)
	local newZ: number = clamp(c.Z, -zBound, zBound)

	local newCFrame: CFrame = cframe(newX, 0, newZ)

	return newCFrame
end

-- Returns a rounded cframe to the nearest grid unit
local function snapCFrame(c: CFrame): CFrame
	local offsetX: number = (plot.Size.X % (2*GRID_UNIT))*0.5
	local offsetZ: number = (plot.Size.Z % (2*GRID_UNIT))*0.5	
	local newX: number = round(c.X/GRID_UNIT)*GRID_UNIT - offsetX
	local newZ: number = round(c.Z/GRID_UNIT)*GRID_UNIT - offsetZ
	local newCFrame: CFrame = cframe(newX, 0, newZ)

	return newCFrame
end

 -- Calculates the "tilt" angle
local function calcAngle(last: CFrame, current: CFrame): CFrame
	if not angleTilt then return anglesXYZ(0, 0, 0) end
	
	-- Calculates and clamps the proper angle amount
	local tiltX = (clamp((last.X - current.X), -10, 10)*pi/180)*amplitude
	local tiltZ = (clamp((last.Z - current.Z), -10, 10)*pi/180)*amplitude
	local preCalc = (rotation + plot.Orientation.Y)*pi/180

	-- Returns the proper angle based on rotation
	return (anglesXYZ(dirZ*tiltZ, 0, dirX*tiltX):Inverse()*anglesXYZ(0, preCalc, 0)):Inverse()*anglesXYZ(0, preCalc, 0)		
end

-- Calculates the position of the object
local function calculateItemLocation(last, final: boolean): CFrame
	local x: number, z: number
	local sizeX: number, sizeZ: number = primary.Size.X*0.5, primary.Size.Z*0.5
	local offsetX: number, offsetZ: number = sizeX, sizeZ
	local finalC: CFrame

	if not currentRot then sizeX = primary.Size.Z*0.5; sizeZ = primary.Size.X*0.5 end

	if moveByGrid then
		offsetX = sizeX - floor(sizeX/GRID_UNIT)*GRID_UNIT
		offsetZ = sizeZ - floor(sizeZ/GRID_UNIT)*GRID_UNIT
	end

	local cam: Camera = workspace.CurrentCamera
	local ray
	local nilRay
	local target

	if isMobile then
		local camPos: Vector3 = cam.CFrame.Position
		ray = workspace:Raycast(camPos, cam.CFrame.LookVector*rangeOfRay, raycastParams)
		nilRay = camPos + cam.CFrame.LookVector*(maxRange + plot.Size.X*0.5 + plot.Size.Z*0.5)
	else
		local unit: Ray = cam:ScreenPointToRay(mouse.X, mouse.Y, 1)
		ray = workspace:Raycast(unit.Origin, unit.Direction*rangeOfRay, raycastParams)
		nilRay = unit.Origin + unit.Direction*(maxRange + plot.Size.X*0.5 + plot.Size.Z*0.5)
	end

	if ray then
		x, z = ray.Position.X - offsetX, ray.Position.Z - offsetZ

		if stackable then target = ray.Instance; else target = plot end
	else
		x, z = nilRay.X - offsetX, nilRay.Z - offsetZ
		target = plot
	end
	
	target = target

	local pltCFrame: CFrame = plot.CFrame
	local positionCFrame = cframe(x, 0, z)*cframe(offsetX, 0, offsetZ)
	
	y = calculateYPos(plot.Position.Y, plot.Size.Y, primary.Size.Y, 1) + floorHeight

	-- Changes y depending on mouse target
	if stackable and target and (target:IsDescendantOf(placedObjects) or target == plot) then
		if ray and ray.Normal then
			local normal = cframe(ray.Normal):VectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Top)):Dot(ray.Normal)
			y = calculateYPos(target.Position.Y, target.Size.Y, primary.Size.Y, normal)
		end	
	end

	if moveByGrid then
		-- Calculates the correct position
		local rel: CFrame = pltCFrame:Inverse()*positionCFrame
		local snappedRel: CFrame = snapCFrame(rel)*cframe(offsetX, 0, offsetZ)

		if not removePlotDependencies then snappedRel = bounds(snappedRel, sizeX, sizeZ) end
		finalC = pltCFrame*snappedRel
	else
		finalC = pltCFrame:Inverse()*positionCFrame

		if not removePlotDependencies then finalC = bounds(finalC, sizeX, sizeZ) end
		finalC = pltCFrame*finalC
	end
	
	-- Clamps y to a max height above the plot position
	y = clamp(y, initialY, maxHeight + initialY)
	
	-- For placement or no intepolation
	if final or not interpolation then
		return (finalC*cframe(0, y - plot.Position.Y, 0))*anglesXYZ(0, rotation*pi/180, 0)
	end

	return (finalC*cframe(0, y - plot.Position.Y, 0))*anglesXYZ(0, rotation*pi/180, 0)*calcAngle(last, finalC)
end

-- Used for sending a final CFrame to the server when using interpolation.
local function getFinalCFrame(): CFrame
	return calculateItemLocation(nil, true)
end

-- Finds a surface for non plot dependant placements
local function findPlot(): BasePart
	local cam: Camera = workspace.CurrentCamera
	local ray
	local nilRay

	if isMobile then
		local camPos: Vector3 = cam.CFrame.Position
		ray = workspace:Raycast(camPos, cam.CFrame.LookVector*maxRange, raycastParams)
		nilRay = camPos + cam.CFrame.LookVector*maxRange
	else
		local unit: Ray = cam:ScreenPointToRay(mouse.X, mouse.Y, 1)
		ray = workspace:Raycast(unit.Origin, unit.Direction*maxRange, raycastParams)
		nilRay = unit.Origin + unit.Direction*maxRange
	end

	if ray then target = ray.Instance end

	return target
end

-- Sets the position of the object
local function translateObj(dt)
	if not (currentState ~= 2 and currentState ~= 4) then return end
	
	range = false
	setCurrentState(1)

	if getRange() > maxRange then
		setCurrentState(5)

		if preferSignals then outOfRange:Fire() end

		range = true
	end

	checkHitbox()
	editHitboxColor()

	if removePlotDependencies then plot = findPlot() or plot end

	if interpolation and not setup then
		object:PivotTo(primary.CFrame:Lerp(calculateItemLocation(primary.CFrame.Position, false), speed*dt*targetFPS))
		hitbox:PivotTo(calculateItemLocation(hitbox.CFrame.Position, true))	
	else
		object:PivotTo(calculateItemLocation(primary.CFrame.Position, false))
		hitbox:PivotTo(calculateItemLocation(hitbox.CFrame.Position, true))	
	end
end

-- Unbinds all inputs
local function unbindInputs()
	contextActionService:UnbindAction("Rotate")
	contextActionService:UnbindAction("Terminate")
	contextActionService:UnbindAction("Pause")

	if enableFloors then
		contextActionService:UnbindAction("Raise")
		contextActionService:UnbindAction("Lower")
	end
end

-- Resets variables on termination
local function reset()
	if selection then selection:Destroy() end
	mobileUI.Parent = script
	
	stackable = nil
	canPlace = nil
	smartRot = nil
	hitbox:Destroy()
	object:Destroy()
	object = nil
	canActivate = true
end

-- Sets up variables for activation
local function set()
	hitbox = object.PrimaryPart:Clone()
	hitbox.Transparency	= 1
	hitbox.Name = "Hitbox"
	hitbox.Parent = object
	rotation = 0
	dirX = -1
	dirZ = 1
	amplitude = clamp(angleTiltAmplitude, 0, 10)
	currentRot = true

	if invertAngleTilt then dirX = 1; dirZ = -1 end

	-- Sets up interpolation speed
	speed = 1
end

-- Terminates the current placement
local function TERMINATE_PLACEMENT()
	if not hitbox then return end
	setCurrentState(4)

	-- Removes grid texture from plot
	if displayGridTexture and not removePlotDependencies then removeTexture() end

	if audibleFeedback and placementSFX then
		task.spawn(function()
			if currentState == 2 then placementSFX.Ended:Wait() end
			placementSFX:Destroy()
		end)
	end

	reset()
	unbindInputs()
	if preferSignals then terminated:Fire() end
end

-- Binds all inputs for PC and Xbox
local function bindInputs()
	contextActionService:BindAction("Rotate", ROTATE, false, rotateKey, xboxRotate)
	contextActionService:BindAction("Terminate", TERMINATE_PLACEMENT, false, terminateKey, xboxTerminate)

	if enableFloors and not stackable then
		contextActionService:BindAction("Raise", raiseFloor, false, raiseKey, xboxRaise)
		contextActionService:BindAction("Lower", lowerFloor, false, lowerKey, xboxLower)
	end
end

-- Makes sure that you cannot place objects too fast.
local function coolDown(plr: Player, cd: number): boolean
	if lastPlacement[plr.UserId] == nil then
		lastPlacement[plr.UserId] = tick()

		return true
	elseif tick() - lastPlacement[plr.UserId] >= cd then
		lastPlacement[plr.UserId] = tick()

		return true
	else
		return false
	end
end

-- Generates vibrations on placement if the player is using a controller
local function createHapticFeedback()
	local isVibrationSupported = hapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1)
	local largeSupported

	coroutine.resume(coroutine.create(function()
		if not isVibrationSupported then return end
		largeSupported = hapticService:IsMotorSupported(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large)

		if largeSupported then
			hapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, vibrateAmount)

			task.wait(0.2)	

			hapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 0)
		else
			hapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, vibrateAmount)

			task.wait(0.2)	

			hapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
		end	
	end))
end

local function updateAttributes()
	angleTilt = script:GetAttribute("AngleTilt")
	audibleFeedback = script:GetAttribute("AudibleFeedback")
	buildModePlacement = script:GetAttribute("BuildModePlacement")
	charCollisions = script:GetAttribute("CharacterCollisions")
	collisions = script:GetAttribute("Collisions")
	displayGridTexture = script:GetAttribute("DisplayGridTexture")
	enableFloors = script:GetAttribute("EnableFloors")
	gridFadeIn = script:GetAttribute("GridFadeIn")
	gridFadeOut = script:GetAttribute("GridFadeOut")
	includeSelectionBox = script:GetAttribute("IncludeSelectionBox")
	instantActivation = script:GetAttribute("InstantActivation")
	interpolation = script:GetAttribute("Interpolation")
	invertAngleTilt = script:GetAttribute("InvertAngleTilt")
	moveByGrid = script:GetAttribute("MoveByGrid")
	preferSignals = script:GetAttribute("PreferSignals")
	smartDisplay = script:GetAttribute("SmartDisplay")
	transparentModel = script:GetAttribute("TransparentModel")
	removeCollisionsIfIgnored = script:GetAttribute("RemoveCollisionsIfIgnored")
	useHighlights = script:GetAttribute("UseHighlights")

	-- Color3
	collisionColor = script:GetAttribute("CollisionColor3")
	hitboxColor = script:GetAttribute("HitboxColor3")
	selectionCollisionColor = script:GetAttribute("SelectionBoxCollisionColor3")
	selectionColor = script:GetAttribute("SelectionBoxColor3")

	-- Integers (Will round to nearest unit if given float)
	floorStep = script:GetAttribute("FloorStep")
	gridTextureScale = script:GetAttribute("GridTextureScale")
	maxHeight = script:GetAttribute("MaxHeight")
	maxRange = script:GetAttribute("MaxRange")
	rotationStep = script:GetAttribute("RotationStep")

	-- Numbers/Floats
	angleTiltAmplitude = script:GetAttribute("AngleTiltAmplitude")
	audioVolume = script:GetAttribute("AudioVolume")
	hitboxTransparency = script:GetAttribute("HitboxTransparency")
	lerpSpeed = script:GetAttribute("LerpSpeed")
	lineThickness = script:GetAttribute("LineThickness")
	lineTransparency = script:GetAttribute("LineTransparency")
	placementCooldown = script:GetAttribute("PlacementCooldown")
	targetFPS = script:GetAttribute("TargetFPS")
	transparencyDelta = script:GetAttribute("TransparencyDelta")

	-- Other
	gridTexture = script:GetAttribute("GridTextureID")
	soundID = script:GetAttribute("SoundID")

	-- Cross Platform
	hapticFeedback = script:GetAttribute("HapticFeedback")
	vibrateAmount = script:GetAttribute("HapticVibrationAmount")
	
	speed = interpolation and clamp(abs(1 - lerpSpeed), 0, 0.9) or 1
end

-- Rounds all integer attributes to the nearest whole number (int)
local function roundInts()
	script:SetAttribute("MaxHeight", round(script:GetAttribute("MaxHeight")))
	script:SetAttribute("FloorStep", round(script:GetAttribute("FloorStep")))
	script:SetAttribute("RotationStep", round(script:GetAttribute("RotationStep")))
	script:SetAttribute("GridTextureScale", round(script:GetAttribute("GridTextureScale")))
	script:SetAttribute("MaxRange", round(script:GetAttribute("MaxRange")))

	updateAttributes()
end

local function placementFeedback(objectName, callback)
	if preferSignals then
		placed:Fire(objectName)
	else
		xpcall(function()
			if callback then callback() end
		end, function(err)
			warn(messages["301"] .. "\n\n" .. err)
		end)
	end
end

local function PLACEMENT(self, Function: RemoteFunction, callback:() -> ()?)
	if not (currentState ~= 3 and currentState ~= 4 and currentState ~= 5 and object) then return end
	
	local cf: CFrame
	local objectName = tostring(object)

	-- Makes sure you have waited the cooldown period before placing
	if not coolDown(player, placementCooldown) then return end
	if not (currentState == 2 or currentState == 1) then return end
	cf = getFinalCFrame()
	checkHitbox()

	print(objectName, placedObjects, self.Prefabs, Function, plot)
	if not Function:InvokeServer(objectName, placedObjects, self.Prefabs, cf, plot) then return end	
	if buildModePlacement then setCurrentState(1) else TERMINATE_PLACEMENT() end
	if hapticFeedback and guiService:IsTenFootInterface() then createHapticFeedback() end

	playAudio()
	placementFeedback(objectName, callback)
end

-- Returns the current platform
local function GET_PLATFORM(): string
	isXbox = userInputService.GamepadEnabled
	isMobile = userInputService.TouchEnabled

	if isMobile then
		return "Mobile"
	elseif isXbox then
		return "Console"
	else
		return "PC"
	end
end

-- Verifys that the plane which the object is going to be placed upon is the correct size
local function verifyPlane(): boolean
	return plot.Size.X%GRID_UNIT == 0 and plot.Size.Z%GRID_UNIT == 0
end

-- Checks if there are any problems with the users setup
local function approveActivation()
	if not verifyPlane() then warn(messages["201"]) end
	assert(not (GRID_UNIT >= min(plot.Size.X, plot.Size.Z)), messages["401"])
end

-- Methods

-- Constructor function
function PlacementInfo.new(GridUnit: number, Prefabs: Instance, 
	RotateKey: Enum.KeyCode, TerminateKey: Enum.KeyCode, RaiseKey: Enum.KeyCode, LowerKey: Enum.KeyCode, 
	XboxRotate: Enum.KeyCode, XboxTerminate: Enum.KeyCode, XboxRaise: Enum.KeyCode, XboxLower: Enum.KeyCode, 
	...: Instance?)
	
	local self = setmetatable({}, PlacementInfo)

	-- Sets variables needed
	GRID_UNIT = abs(round(GridUnit))
	rotateKey = RotateKey or Enum.KeyCode.R
	terminateKey = TerminateKey or Enum.KeyCode.X
	raiseKey = RaiseKey or Enum.KeyCode.E
	lowerKey = LowerKey or Enum.KeyCode.Q
	xboxRotate = XboxRotate or Enum.KeyCode.ButtonX
	xboxTerminate = XboxTerminate or Enum.KeyCode.ButtonB
	xboxRaise = XboxRaise or Enum.KeyCode.ButtonY
	xboxLower = XboxLower or Enum.KeyCode.ButtonA

	self.GridUnit = GRID_UNIT
	self.Items = Prefabs
	self.ROTATE_KEY = rotateKey
	self.CANCEL_KEY = terminateKey
	self.RAISE_KEY = raiseKey
	self.LOWER_KEY = lowerKey
	self.XBOX_ROTATE = xboxRotate
	self.XBOX_TERMINATE = xboxTerminate
	self.XBOX_RAISE = xboxRaise
	self.Version = "1.6.2"
	self.Creator = "zblox164"
	self.MobileUI = script:FindFirstChildOfClass("ScreenGui")
	self.IgnoredItems = {...}
	self.Prefabs = Prefabs
	mobileUI = script:FindFirstChildOfClass("ScreenGui")

	if not mobileUI then
		warn("[Placement Service]: Failed to locate a ScreenGui for mobile compatibility.")
	end

	placed = Instance.new("BindableEvent")
	collided = Instance.new("BindableEvent")
	outOfRange = Instance.new("BindableEvent")
	rotated = Instance.new("BindableEvent")
	terminated = Instance.new("BindableEvent")
	changeFloors = Instance.new("BindableEvent")
	activated = Instance.new("BindableEvent")

	self.Placed = placed.Event
	self.Collided = collided.Event
	self.OutOfRange = outOfRange.Event
	self.Rotated = rotated.Event
	self.Terminated = terminated.Event
	self.ChangedFloors = changeFloors.Event
	self.Activated = activated.Event

	return self
end

function PlacementInfo:getPlatform(): string
	return GET_PLATFORM()
end

-- returns the current state when called
function PlacementInfo:getCurrentState(): string
	return states[currentState]
end

-- Pauses the current state
function PlacementInfo:pauseCurrentState()
	lastState = currentState

	if object then
		currentState = 4
	end
end

-- Resumes the current state if paused
function PlacementInfo:resume()
	if object then setCurrentState(lastState) end
end

function PlacementInfo:raise()
	raiseFloor("Raise", Enum.UserInputState.Begin)
end

function PlacementInfo:lower()
	lowerFloor("Lower", Enum.UserInputState.Begin)
end

function PlacementInfo:rotate()
	ROTATE("Rotate", Enum.UserInputState.Begin)
end

function PlacementInfo:terminate()
	TERMINATE_PLACEMENT()
end

function PlacementInfo:haltPlacement()
	if not autoPlace then return end
	if running then running = false end
end

function PlacementInfo:editAttribute(attribute: string, input: any)
	if script:GetAttribute(attribute) ~= nil then
		script:SetAttribute(attribute, input)
		roundInts()
		updateAttributes()
		
		return
	end
	
	warn("Attribute " .. attribute .. "does not exist.")
end

-- Requests to place down the object
function PlacementInfo:requestPlacement(func: RemoteFunction, callback: (...any?) -> ())
	if not autoPlace then PLACEMENT(self, func, callback); return end
	running = true

	repeat
		PLACEMENT(self, func, callback)

		task.wait(placementCooldown)
	until not running
end

-- Activates placement
function PlacementInfo:activate(ID: string, PlacedObjects: Instance, Plot: BasePart, 
	Stackable: boolean, SmartRotation: boolean, AutoPlace: boolean)

	if currentState ~= 4 then TERMINATE_PLACEMENT() end
	if GET_PLATFORM() == "Mobile" then mobileUI.Parent = player.PlayerGui end
	
	-- Sets necessary variables for placement 
	character = player.Character or player.CharacterAdded:Wait()
	plot = Plot
	object = self.Prefabs:FindFirstChild(tostring(ID)):Clone()
	placedObjects = PlacedObjects
	primary = object.PrimaryPart

	approveActivation()
	
	if displayGridTexture then displayGrid() end
	if includeSelectionBox then	displaySelectionBox() end
	if audibleFeedback then createAudioFeedback() end

	-- Sets properties of the model (CanCollide, Transparency)
	for i, inst in ipairs(object:GetDescendants()) do
		if not inst:IsA("BasePart") then continue end
		if transparentModel then inst.Transparency = inst.Transparency + transparencyDelta end
		
		inst.CanCollide = false
		inst.Anchored = true
	end

	if removeCollisionsIfIgnored then
		for i, v: Instance in ipairs(self.IgnoredItems) do 
			if v:IsA("BasePart") then v.CanTouch = false end
		end
	end

	object.PrimaryPart.Transparency = hitboxTransparency
	stackable = Stackable
	smartRot = SmartRotation

	-- Allows stackable objects depending on stk variable given by the user
	raycastParams.FilterDescendantsInstances = {placedObjects, character, unpack(self.IgnoredItems)}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	if Stackable then
		raycastParams.FilterDescendantsInstances = {object, character, unpack(self.IgnoredItems)}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	end

	-- Toggles buildmode placement (infinite placement) depending on if set true by the user
	canActivate = false
	if buildModePlacement then
		canActivate = true
	end

	-- Gets the initial y pos and gives it to y
	initialY = calculateYPos(Plot.Position.Y, Plot.Size.Y, object.PrimaryPart.Size.Y, 1)
	y = initialY
	removePlotDependencies = false
	autoPlace = AutoPlace
	local preSpeed = 1
	
	set()
	editHitboxColor()
	roundInts()
	bindInputs()

	if interpolation then
		preSpeed = clamp(abs(tonumber(1 - lerpSpeed)::number), 0, 0.9)
		speed = preSpeed
		
		if instantActivation then
			setup = true
			speed = 1
		end
	end

	-- Parents the object to the location given
	if not object then TERMINATE_PLACEMENT(); warn(messages["101"]) end
	setCurrentState(1)

	if instantActivation then translateObj() end
	object.Parent = PlacedObjects

	task.wait()	

	speed = preSpeed
	if preferSignals then activated:Fire() end
	setup = false
end

-- REMOVE THIS FUNCTION IF YOU ARE NOT GOING TO USE IT
function PlacementInfo:noPlotActivate(ID: string, PlacedObjects: Instance, SmartRotation: boolean, AutoPlace: boolean)
	if currentState ~= 4 then TERMINATE_PLACEMENT() end
	if GET_PLATFORM() == "Mobile" then mobileUI.Parent = player.PlayerGui end

	-- Sets necessary variables for placement 
	character = player.Character or player.CharacterAdded:Wait()
	plot = findPlot()
	object = self.Prefabs:FindFirstChild(tostring(ID)):Clone()
	placedObjects = PlacedObjects
	primary = object.PrimaryPart

	if not plot then error(messages["501"]) end

	-- Sets properties of the model (CanCollide, Transparency)
	for i, inst in ipairs(object:GetDescendants()) do
		if not inst:IsA("BasePart") then continue end
		if transparentModel then inst.Transparency = inst.Transparency + transparencyDelta end

		inst.CanCollide = false
		inst.Anchored = true
	end

	if removeCollisionsIfIgnored then
		for i, v: Instance in ipairs(self.IgnoredItems) do 
			if v:IsA("BasePart") then v.CanTouch = false end
		end
	end

	if includeSelectionBox then	displaySelectionBox() end
	if audibleFeedback then createAudioFeedback() end

	object.PrimaryPart.Transparency = hitboxTransparency
	stackable = true
	smartRot = SmartRotation
	removePlotDependencies = true
	mouse.TargetFilter = object
	raycastParams.FilterDescendantsInstances = {object, character, unpack(self.IgnoredItems)}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	-- Toggles buildmode placement (infinite placement) depending on if set true by the user
	canActivate = false
	if buildModePlacement then
		canActivate = true
	end

	-- Gets the initial y pos and gives it to y
	initialY = 0
	y = initialY
	autoPlace = AutoPlace
	local preSpeed = 1
	
	set()
	editHitboxColor()
	roundInts()
	bindInputs()
	
	if interpolation then
		preSpeed = clamp(abs(tonumber(1 - lerpSpeed)::number), 0, 0.9)
		speed = preSpeed

		if instantActivation then
			setup = true
			speed = 1
		end
	end

	-- Parents the object to the location given
	if not object then TERMINATE_PLACEMENT(); warn(messages["101"]) end
	setCurrentState(1)

	if instantActivation then translateObj() end
	object.Parent = PlacedObjects

	task.wait()	

	speed = preSpeed
	if preferSignals then activated:Fire() end
	setup = false
end

runService:BindToRenderStep("Input", Enum.RenderPriority.Input.Value, translateObj)

return PlacementInfo

-- Created and written by zblox164 (2020-2022)
