--!nonstrict

--[[

Thank you for using Placement Service!

As of version 1.5.6, this module was renamed from "Placement Module V3" to "Placement Service".

Current Version - V1.5.9
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
local states: {} = {
	"movement",
	"placing",
	"colliding",
	"inactive",
	"out-of-range"
}

local currentState: number = 4
local lastState: number = 4

-- Constructor variables
local GRID_UNIT: number
local itemLocation: Instance
local rotateKey: Enum.KeyCode
local terminateKey: Enum.KeyCode
local raiseKey: Enum.KeyCode
local lowerKey: Enum.KeyCode
local xboxRotate: Enum.KeyCode
local xboxTerminate: Enum.KeyCode
local xboxRaise: Enum.KeyCode
local xboxLower: Enum.KeyCode
local ignored: {} = {}

-- Activation variables
local plot: BasePart
local placedObjects: Instance
local object
local autoPlace: boolean?

-- bools
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
local preSpeed: number = 1
local rangeOfRay: number = 10000
local y: number
local amplitude: number
local dirX: number
local dirZ: number
local rot: number
local initialY: number

-- other
local loc: Instance
local primary: Part
local hitbox: BasePart
local selection
local audio: Sound
local lastPlacement: {} = {}
local humanoid: Humanoid = character:WaitForChild("Humanoid")
local raycastParams: RaycastParams = RaycastParams.new()
local mobileUI: ScreenGui = script:FindFirstChildOfClass("ScreenGui")
local target: BasePart
local messages: {} = {
	["101"] = "Placement Service: Your trying to activate placement too fast! Please slow down.",
	["201"] = "Placement Service: Error code 201: The object that the model is moving on is not scaled correctly. Consider changing it.",
	["301"] = "Placement Service: Error code 301: You have improperly setup your callback function. Please input a valid callback.",
	["401"] = "Placement Service: Error code 401: Grid size is too close to the plot size. To fix this, try lowering the grid size.",
	["501"]	= "Placement Service: Error code 501: Cannot find a surface to place on. Please make sure one is available."
}

-- Tween Info
local fade: TweenInfo = TweenInfo.new(
	0.3,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.Out,
	0,
	false,
	0
)

-- signals
local placed: BindableEvent
local collided: BindableEvent
local outOfRange: BindableEvent
local rotated: BindableEvent
local terminated: BindableEvent
local changeFloors: BindableEvent
local activated: BindableEvent

-- Sets the current state depending on input of function
local function setCurrentState(state: number)
	currentState = clamp(state, 1, 5)
	lastState = currentState
end

-- Changes the color of the hitbox depending on the current state
local function editHitboxColor()
	if primary then
		if currentState >= 3 then
			primary.Color = collisionColor

			if includeSelectionBox then
				selection.Color3 = selectionCollisionColor
			end
		else
			primary.Color = hitboxColor

			if includeSelectionBox then
				selection.Color3 = selectionColor
			end
		end
	end
end

-- Checks for collisions on the hitbox
local function checkHitbox()
	if hitbox:IsDescendantOf(workspace) and collisions then
		if range then
			setCurrentState(5)
		else
			setCurrentState(1)
		end
		
		local collisionPoints: {BasePart} = workspace:GetPartsInPart(hitbox)

		-- Checks if there is collision on any object that is not a child of the object and is not a child of the player
		for i: number = 1, #collisionPoints, 1 do
			if collisionPoints[i].CanTouch and not collisionPoints[i]:IsDescendantOf(object) and not ((not charCollisions) and collisionPoints[i]:IsDescendantOf(character)) and collisionPoints[i] ~= plot then
				setCurrentState(3)

				if preferSignals then
					collided:Fire(collisionPoints[i])
				end

				break
			end
		end

		return
	end
end

-- (Raise and Lower functions) Edits the floor based on the floor step
local function raiseFloor(actionName: string, inputState: Enum.UserInputState, inputObj: InputObject?)
	if currentState ~= 4 and inputState == Enum.UserInputState.Begin then
		if enableFloors and not stackable then
			y += floor(abs(floorStep))

			if preferSignals then
				changeFloors:Fire(true)
			end
		end
	end
end

local function lowerFloor(actionName: string, inputState:Enum.UserInputState, inputObj: InputObject?)
	if currentState ~= 4 and inputState == Enum.UserInputState.Begin then
		if enableFloors and not stackable then
			y -= floor(abs(floorStep))

			if preferSignals then
				changeFloors:Fire(false)
			end
		end
	end
end

-- Handles scaling of the grid texture on placement activation
local function displayGrid()
	local gridTex: Texture = Instance.new("Texture")

	gridTex.Name = "GridTexture"
	gridTex.Texture = gridTexture
	gridTex.Face = Enum.NormalId.Top
	gridTex.Transparency = 1

	if smartDisplay then
		gridTex.StudsPerTileU = GRID_UNIT
		gridTex.StudsPerTileV = GRID_UNIT
	else
		gridTex.StudsPerTileU = gridTextureScale
		gridTex.StudsPerTileV = gridTextureScale
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
	selection = Instance.new("SelectionBox")
	selection.Name = "outline"
	selection.LineThickness = lineThickness
	selection.Color3 = selectionColor
	selection.Transparency = lineTransparency
	selection.Parent = player.PlayerGui
	selection.Adornee = object.PrimaryPart
end

local function createAudioFeedback()
	audio = Instance.new("Sound")
	audio.Name = "placementFeedback"
	audio.Volume = audioVolume
	audio.SoundId = soundID
	audio.Parent = player.PlayerGui
end

local function playAudio()
	if audibleFeedback and audio then
		audio:Play()
	end
end

-- Checks to see if the model is in range of the maxRange
local function getRange(): number
	character = player.Character
	return (primary.Position - character.PrimaryPart.Position).Magnitude
end

-- Handles rotation of the model
local function ROTATE(actionName: string, inputState: Enum.UserInputState, inputObj: InputObject?)
	if currentState ~= 4 and currentState ~= 2 and inputState == Enum.UserInputState.Begin then
		if smartRot then
			-- Rotates the model depending on if currentRot is true/false
			if currentRot then
				rot += rotationStep
			else 
				rot -= rotationStep
			end
		else
			rot += rotationStep
		end
		
		-- Toggles currentRot
		if rot%90 == 0 then
			currentRot = not currentRot
		end
		
		if rot >= 360 then
			rot = 0
		end

		if preferSignals then
			rotated:Fire()
		end
	end
end

-- Calculates the Y position to be ontop of the plot (all objects) and any object (when stacking)
local function calculateYPos(tp: number, ts: number, o: number): number
	return (tp + ts*0.5) + o*0.5
end

-- Clamps the x and z positions so they cannot leave the plot
local function bounds(c: CFrame, cx: number, cz: number): CFrame
	local pos: CFrame = plot.CFrame
	local xBound: number = (plot.Size.X*0.5) - cx
	local zBound: number = (plot.Size.Z*0.5) - cz
	
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
	if angleTilt then
		-- Calculates and clamps the proper angle amount
		local tiltX = (clamp((last.X - current.X), -10, 10)*pi/180)*amplitude
		local tiltZ = (clamp((last.Z - current.Z), -10, 10)*pi/180)*amplitude

		-- Returns the proper angle based on rotation
		return (anglesXYZ(dirZ*tiltZ, 0, dirX*tiltX):Inverse()*anglesXYZ(0, (rot + plot.Orientation.Y)*pi/180, 0)):Inverse()*anglesXYZ(0, (rot + plot.Orientation.Y)*pi/180, 0)
	else
		return anglesXYZ(0, 0, 0)
	end
end

-- Calculates the position of the object
local function calculateItemLocation(last, final: boolean): CFrame
	local x: number, z: number
	local cx: number, cz: number
	local sizeX: number, sizeZ: number = primary.Size.X*0.5, primary.Size.Z*0.5
	local finalC: CFrame
	
	if not currentRot then
		sizeX = primary.Size.Z*0.5
		sizeZ = primary.Size.X*0.5
	end
	
	if moveByGrid then
		cx = sizeX - floor(sizeX/GRID_UNIT)*GRID_UNIT
		cz = sizeZ - floor(sizeZ/GRID_UNIT)*GRID_UNIT
	else
		cx = sizeX
		cz = sizeZ
	end
	
	local cam: Camera = workspace.CurrentCamera
	local camPos: Vector3 = cam.CFrame.Position
	local unit: Ray
	local ray
	local nilRay

	if isMobile then
		ray = workspace:Raycast(camPos, cam.CFrame.LookVector*rangeOfRay, raycastParams)
		nilRay = camPos + cam.CFrame.LookVector*(maxRange + plot.Size.X*0.5 + plot.Size.Z*0.5)
	else
		unit = cam:ScreenPointToRay(mouse.X, mouse.Y, 1)
		ray = workspace:Raycast(unit.Origin, unit.Direction*rangeOfRay, raycastParams)
		nilRay = unit.Origin + unit.Direction*(maxRange + plot.Size.X*0.5 + plot.Size.Z*0.5)
	end

	if ray then
		x, z = ray.Position.X - cx, ray.Position.Z - cz
		
		if stackable then
			target = ray.Instance
		else
			target = plot
		end
	else
		x, z = nilRay.X - cx, nilRay.Z - cz
		target = plot
	end
	
	y = calculateYPos(plot.Position.Y, plot.Size.Y, primary.Size.Y)
	
	-- Changes y depending on mouse target
	if stackable and target and (target:IsDescendantOf(placedObjects) or target == plot) then
		if ray and ray.Normal then
			if not isMobile and cframe(ray.Normal):VectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Top)):Dot(ray.Normal) > 0 then
				y = calculateYPos(target.Position.Y, target.Size.Y, primary.Size.Y)
			elseif isMobile then
				y = calculateYPos(target.Position.Y, target.Size.Y, primary.Size.Y)
			else
				y = ray.Instance.Position.Y
			end
		end	
	end
	
	-- Clamps y to a max height above the plot position
	y = clamp(y, initialY, maxHeight + initialY)
	
	local pltCFrame: CFrame = plot.CFrame
	
	if moveByGrid then
		-- Calculates the correct position
		local rel: CFrame = pltCFrame:Inverse()*cframe(x, 0, z)*cframe(cx, 0, cz)
		local snappedRel: CFrame = snapCFrame(rel)*cframe(cx, 0, cz)
		
		if not removePlotDependencies then
			snappedRel = bounds(snappedRel, sizeX, sizeZ)
		end
		
		finalC = pltCFrame*snappedRel
	else
		finalC = pltCFrame:Inverse()*cframe(x, 0, z)*cframe(cx, 0, cz)
		
		if not removePlotDependencies then
			finalC = bounds(finalC, sizeX, sizeZ)
		end
		
		finalC = pltCFrame*finalC
	end
	
	-- For placement or no intepolation
	if final or not interpolation then
		return (finalC*cframe(0, y - plot.Position.Y, 0))*anglesXYZ(0, rot*pi/180, 0)
	end
	
	return (finalC*cframe(0, y - plot.Position.Y, 0))*anglesXYZ(0, rot*pi/180, 0)*calcAngle(last, finalC)
end

-- Used for sending a final CFrame to the server when using interpolation.
local function getFinalCFrame(): CFrame
	return calculateItemLocation(nil, true)
end

-- Finds a surface for non plot dependant placements
local function findPlot(): BasePart
	local cam: Camera = workspace.CurrentCamera
	local camPos: Vector3 = cam.CFrame.Position
	local unit:Ray
	local ray
	local nilRay

	if isMobile then
		ray = workspace:Raycast(camPos, cam.CFrame.LookVector*maxRange, raycastParams)
		nilRay = camPos + cam.CFrame.LookVector*maxRange
	else
		unit = cam:ScreenPointToRay(mouse.X, mouse.Y, 1)
		ray = workspace:Raycast(unit.Origin, unit.Direction*maxRange, raycastParams)
		nilRay = unit.Origin + unit.Direction*maxRange
	end

	if ray then
		target = ray.Instance
	end

	return target
end

-- Sets the position of the object
local function translateObj(dt)
	if currentState ~= 2 and currentState ~= 4 then
		if getRange() > maxRange then
			setCurrentState(5)

			if preferSignals then
				outOfRange:Fire()
			end

			range = true
		else
			range = false
			setCurrentState(1)
		end

		checkHitbox()
		editHitboxColor()

		if removePlotDependencies then
			plot = findPlot() or plot
		end

		if interpolation and not setup then
			object:PivotTo(primary.CFrame:Lerp(calculateItemLocation(primary.CFrame.Position, false), speed*dt*targetFPS))
			hitbox:PivotTo(calculateItemLocation(hitbox.CFrame.Position, true))	
		else
			object:PivotTo(calculateItemLocation(primary.CFrame.Position, false))
			hitbox:PivotTo(calculateItemLocation(hitbox.CFrame.Position, true))	
		end
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

-- Terminates the current placement
local function TERMINATE_PLACEMENT()
	if object then
		setCurrentState(4)

		mobileUI.Parent = script

		if selection then
			selection:Destroy()
			selection = nil
		end

		stackable = nil
		canPlace = nil
		smartRot = nil

		hitbox:Destroy()
		object:Destroy()
		object = nil

		-- removes grid texture from plot
		if displayGridTexture and not removePlotDependencies then
			for i, v: Instance in ipairs(plot:GetChildren()) do
				if v.Name == "GridTexture" and v:IsA("Texture") then
					if gridFadeOut then
						local tween = tweenService:Create(v, fade, {Transparency = 1})
						tween:Play()

						local connection = tween.Completed:Connect(function()
							v:Destroy()
						end)

						connection:Disconnect()
					else
						v:Destroy()
					end	
				end
			end
		end

		if audibleFeedback and audio then
			task.spawn(function()
				if currentState == 2 then
					audio.Ended:Wait()
				end

				audio:Destroy()
			end)
		end

		canActivate = true

		unbindInputs()

		if preferSignals then
			terminated:Fire()
		end

		return
	end
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
	else
		if tick() - lastPlacement[plr.UserId] >= cd then
			lastPlacement[plr.UserId] = tick()

			return true
		else
			return false
		end
	end
end

-- Generates vibrations on placement if the player is using a controller
local function createHapticFeedback()
	local isVibrationSupported = hapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1)
	local largeSupported

	coroutine.resume(coroutine.create(function()
		if isVibrationSupported then
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

	if not interpolation then
		speed = 1
	else
		speed = clamp(abs(1 - lerpSpeed), 0, 0.9)
	end
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

local function PLACEMENT(Function: RemoteFunction, callback)
	if currentState ~= 3 and currentState ~= 4 and currentState ~= 5 and object then
		local cf: CFrame

		-- Makes sure you have waited the cooldown period before placing
		if coolDown(player, placementCooldown) then
			-- Buildmode placement is when you can place multiple objects in one session
			if buildModePlacement then
				cf = getFinalCFrame()

				checkHitbox()
				-- Sends information to the server, so the object can be placed
				if currentState == 2 or currentState == 1 then
					setCurrentState(2)

					local i = Function:InvokeServer(object.Name, placedObjects, loc, cf, plot)

					if preferSignals then
						placed:Fire()
					else
						xpcall(function()
							callback()
						end, function(err)
							warn(messages["301"] .. "\n\n" .. err)
						end)
					end

					setCurrentState(1)
					
					if i then
						playAudio()
					end
					
					if hapticFeedback and guiService:IsTenFootInterface() then
						createHapticFeedback()
					end
				end
			else
				cf = getFinalCFrame()

				checkHitbox()

				if currentState == 2 or currentState == 1 then
					-- Same as above
					if Function:InvokeServer(object.Name, placedObjects, loc, cf, plot) then
						TERMINATE_PLACEMENT()
						playAudio()

						if preferSignals then
							placed:Fire()
						else
							xpcall(function()
								callback()
							end, function(err)
								warn(messages["301"] .. "\n\n" .. err)
							end)
						end

						if hapticFeedback and guiService:IsTenFootInterface() then
							createHapticFeedback()
						end
					end
				end
			end
		end
	end
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
	if not verifyPlane() then
		warn(messages["201"])
	end

	if GRID_UNIT >= min(plot.Size.X, plot.Size.Z) then 
		error(messages["401"])
	end
end

-- Constructor function
function PlacementInfo.new(GridUnit: number, Prefabs: Instance, 
	RotateKey: Enum.KeyCode, TerminateKey: Enum.KeyCode, RaiseKey: Enum.KeyCode, LowerKey: Enum.KeyCode, 
	xbr: Enum.KeyCode, xbt: Enum.KeyCode, xbu: Enum.KeyCode, xbl: Enum.KeyCode, ...: Instance?)
	
	local placementInfo = {}
	setmetatable(placementInfo, PlacementInfo)

	-- Sets variables needed
	GRID_UNIT = abs(round(GridUnit))
	itemLocation = Prefabs
	rotateKey = RotateKey or Enum.KeyCode.R
	terminateKey = TerminateKey or Enum.KeyCode.X
	raiseKey = RaiseKey or Enum.KeyCode.E
	lowerKey = LowerKey or Enum.KeyCode.Q
	xboxRotate = xbr or Enum.KeyCode.ButtonX
	xboxTerminate = xbt or Enum.KeyCode.ButtonB
	xboxRaise = xbu or Enum.KeyCode.ButtonY
	xboxLower = xbl or Enum.KeyCode.ButtonA
	ignored = {...}

	placementInfo.GridUnit = GRID_UNIT
	placementInfo.Items = Prefabs
	placementInfo.ROTATE_KEY = rotateKey
	placementInfo.CANCEL_KEY = terminateKey
	placementInfo.RAISE_KEY = raiseKey
	placementInfo.LOWER_KEY = lowerKey
	placementInfo.XBOX_ROTATE = xboxRotate
	placementInfo.XBOX_TERMINATE = xboxTerminate
	placementInfo.XBOX_RAISE = xboxRaise
	placementInfo.XBOX_LOWER = xboxLower
	placementInfo.Version = "1.5.9"
	placementInfo.Creator = "zblox164"
	placementInfo.MobileUI = script:FindFirstChildOfClass("ScreenGui")
	placementInfo.IgnoredItems = {...}
	
	if not placementInfo.MobileUI then
		warn("Placement Service: Failed to locate a ScreenGui for mobile compatibility.")
	end

	placed = Instance.new("BindableEvent")
	collided = Instance.new("BindableEvent")
	outOfRange = Instance.new("BindableEvent")
	rotated = Instance.new("BindableEvent")
	terminated = Instance.new("BindableEvent")
	changeFloors = Instance.new("BindableEvent")
	activated = Instance.new("BindableEvent")

	placementInfo.Placed = placed.Event
	placementInfo.Collided = collided.Event
	placementInfo.OutOfRange = outOfRange.Event
	placementInfo.Rotated = rotated.Event
	placementInfo.Terminated = terminated.Event
	placementInfo.ChangedFloors = changeFloors.Event
	placementInfo.Activated = activated.Event

	return placementInfo
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

		print("Set state to: " .. states[currentState])
	end
end

-- Resumes the current state if paused
function PlacementInfo:resume()
	if object then
		setCurrentState(lastState)
	end
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
	if autoPlace then
		if running then
			running = false
		end
	end
end

function PlacementInfo:editAttribute(attribute: string, input: any)
	if script:GetAttribute(attribute) ~= nil then
		script:SetAttribute(attribute, input)
		roundInts()
		updateAttributes()
	else
		warn("Attribute " .. attribute .. "does not exist.")
	end
end

-- Requests to place down the object
function PlacementInfo:requestPlacement(func: RemoteFunction, callback: (...any?) -> ()) 
	if autoPlace then
		running = true

		repeat
			PLACEMENT(func, callback)

			task.wait(placementCooldown)
		until not running
	else
		PLACEMENT(func, callback)
	end
end

-- Activates placement
function PlacementInfo:activate(ID: string, PlacedObjects: Instance, Plot: BasePart, 
	Stackable: boolean, SmartRotation: boolean, AutoPlace: boolean)
	
	if currentState ~= 4 then
		TERMINATE_PLACEMENT()
	end
	
	if GET_PLATFORM() == "Mobile" then
		mobileUI.Parent = player.PlayerGui
	end

	character = player.Character or player.CharacterAdded:Wait()

	-- Sets necessary variables for placement 
	plot = Plot
	object = itemLocation:FindFirstChild(tostring(ID)):Clone()
	placedObjects = PlacedObjects
	loc = itemLocation

	approveActivation()

	-- Sets properties of the model (CanCollide, Transparency)
	for i, o: Instance in ipairs(object:GetDescendants()) do
		if o:IsA("BasePart") then
			o.CanCollide = false
			o.Anchored = true

			if transparentModel then
				o.Transparency = o.Transparency + transparencyDelta
			end
		end
	end
	
	if removeCollisionsIfIgnored then
		for i, v: Instance in ipairs(ignored) do
			if v:IsA("BasePart") then
				v.CanTouch = false
			end
		end
	end
	
	hitbox = object.PrimaryPart:Clone()
	hitbox.Transparency	= 1
	hitbox.Name = "Hitbox"
	hitbox.Parent = object

	if displayGridTexture then
		displayGrid()
	end

	if includeSelectionBox then	
		displaySelectionBox()
	end

	if audibleFeedback then
		createAudioFeedback()
	end

	object.PrimaryPart.Transparency = hitboxTransparency
	stackable = Stackable
	smartRot = SmartRotation

	-- Allows stackable objects depending on stk variable given by the user
	if not Stackable then
		raycastParams.FilterDescendantsInstances = {placedObjects, character, unpack(ignored)}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	else
		raycastParams.FilterDescendantsInstances = {object, character, unpack(ignored)}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	end

	-- Toggles buildmode placement (infinite placement) depending on if set true by the user
	if buildModePlacement then
		canActivate = true
	else
		canActivate = false
	end

	-- Gets the initial y pos and gives it to y
	initialY = calculateYPos(Plot.Position.Y, Plot.Size.Y, object.PrimaryPart.Size.Y)
	y = initialY
	rot = 0
	dirX = -1
	dirZ = 1
	amplitude = clamp(angleTiltAmplitude, 0, 10)
	currentRot = true
	removePlotDependencies = false
	autoPlace = AutoPlace
	
	editHitboxColor()
	bindInputs()
	roundInts()

	-- Sets up interpolation speed
	speed = 1
	
	if invertAngleTilt then
		dirX = 1
		dirZ = -1
	end

	if interpolation then
		preSpeed = clamp(abs(tonumber(1 - lerpSpeed)::number), 0, 0.9)

		if instantActivation then
			setup = true
			speed = 1
		else
			speed = preSpeed
		end
	end

	-- Parents the object to the location given
	if object then
		primary = object.PrimaryPart
		setCurrentState(1)
		
		if instantActivation then
			translateObj()
		end
		
		object.Parent = PlacedObjects

		task.wait()	

		speed = preSpeed
	else
		TERMINATE_PLACEMENT()

		warn(messages["101"])
	end

	if preferSignals then
		activated:Fire()
	end

	setup = false
end

-- REMOVE THIS FUNCTION IF YOU ARE NOT GOING TO USE IT
function PlacementInfo:noPlotActivate(ID: string, PlacedObjects: Instance, SmartRotation: boolean, AutoPlace: boolean)
	if currentState ~= 4 then
		TERMINATE_PLACEMENT()
	end
	
	if GET_PLATFORM() == "Mobile" then
		mobileUI.Parent = player.PlayerGui
	end

	character = player.Character or player.CharacterAdded:Wait()

	-- Sets necessary variables for placement 
	object = itemLocation:FindFirstChild(tostring(ID)):Clone()
	plot = findPlot()
	placedObjects = PlacedObjects
	loc = itemLocation
	hitbox = object.PrimaryPart:Clone()
	hitbox.Transparency	= 1
	hitbox.Name = "Hitbox"
	hitbox.Parent = object
	
	if not plot then
		error(messages["501"])
	end

	-- Sets properties of the model (CanCollide, Transparency)
	for i, o: Instance in ipairs(object:GetDescendants()) do
		if o:IsA("BasePart") then
			o.CanCollide = false
			o.Anchored = true

			if transparentModel then
				o.Transparency = o.Transparency + transparencyDelta
			end
		end
	end
	
	if removeCollisionsIfIgnored then
		for i, v: Instance in ipairs(ignored) do
			if v:IsA("BasePart") then
				v.CanTouch = false
			end
		end
	end

	if includeSelectionBox then	
		displaySelectionBox()
	end

	if audibleFeedback then
		createAudioFeedback()
	end

	object.PrimaryPart.Transparency = hitboxTransparency
	stackable = true
	smartRot = SmartRotation
	removePlotDependencies = true
	mouse.TargetFilter = object
	raycastParams.FilterDescendantsInstances = {object, character, unpack(ignored)}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	-- Toggles buildmode placement (infinite placement) depending on if set true by the user
	if buildModePlacement then
		canActivate = true
	else
		canActivate = false
	end
	
	-- Gets the initial y pos and gives it to y
	initialY = 0
	y = initialY
	rot = 0
	dirX = -1
	dirZ = 1
	amplitude = clamp(angleTiltAmplitude, 0, 10)
	currentRot = true
	autoPlace = AutoPlace

	editHitboxColor()
	bindInputs()
	roundInts()

	-- Sets up interpolation speed
	speed = 1
	
	if invertAngleTilt then
		dirX = 1
		dirZ = -1
	end

	if interpolation then
		preSpeed = clamp(abs(tonumber(1 - lerpSpeed)::number), 0, 0.9)

		if instantActivation then
			setup = true
			speed = 1
		else
			speed = preSpeed
		end
	end

	-- Parents the object to the location given
	if object then
		primary = object.PrimaryPart
		setCurrentState(1)
		
		if instantActivation then
			translateObj()
		end
		
		object.Parent = PlacedObjects

		task.wait()

		speed = preSpeed
	else
		TERMINATE_PLACEMENT()

		warn(messages["101"])
	end

	if preferSignals then
		activated:Fire()
	end

	setup = false
end

runService:BindToRenderStep("Input", Enum.RenderPriority.Input.Value, translateObj)

return PlacementInfo

-- Created and written by zblox164 (2020-2022)
