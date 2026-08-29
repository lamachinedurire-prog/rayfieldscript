local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    name = "Punch Sim",
    subtitle = "Auto Farm",
    icon = 93364949241311
})

local tab = window:CreateTab({ name = "Home", icon = 93364949241311 })

local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

-- STATES
local autoPunch = false
local autoRun = false
local autoSprint = false
local lockPos = false
local tpOnReset = true

local punchDelay = 0.2
local savedPos = nil
local lockedCFramePos = nil

local normalSpeed = 16
local sprintSpeed = 28

local function getChar()
	local c = player.Character
	if not c then return nil, nil, nil end
	return c, c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

local function getTool()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Tool") or player:FindFirstChild("Backpack") and player.Backpack:FindFirstChildOfClass("Tool")
end

local function setSpeed(speed)
	local _, _, hum = getChar()
	if hum then hum.WalkSpeed = speed end
end

local function bindDeath(char)
	local hum = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")
	hum.Died:Connect(function()
		if root then savedPos = root.Position end
	end)
end

if player.Character then bindDeath(player.Character) end

player.CharacterAdded:Connect(function(char)
	bindDeath(char)
	local root = char:WaitForChild("HumanoidRootPart")
	local hum = char:WaitForChild("Humanoid")
	task.wait(0.5)
	
	if tpOnReset and savedPos then
		root.CFrame = CFrame.new(savedPos + Vector3.new(0,5,0))
		if lockPos then lockedCFramePos = root.Position end
	end
	
	if lockPos and not savedPos then lockedCFramePos = root.Position end
	
	-- re-apply walkspeed after reset
	if hum then
		hum.WalkSpeed = autoSprint and sprintSpeed or normalSpeed
	end
	
	if autoPunch then
		task.wait(0.3)
		local tool = getTool()
		if tool and hum then hum:EquipTool(tool) end
	end
end)

-- UI
tab:CreateToggle({
    name = "Auto Punch",
    flag = "AutoPunch",
    default = false,
    callback = function(v) autoPunch = v end,
})

tab:CreateSlider({
	name = "Punch Speed",
	flag = "PunchSpeed",
	default = 0.2, min = 0.05, max = 1, step = 0.05,
	callback = function(v) punchDelay = v end
})

tab:CreateSection({ name = "Movement" })

tab:CreateToggle({
    name = "Auto Run (Run in place if Locked)",
    flag = "AutoRun",
    default = false,
    callback = function(v) autoRun = v end,
})

tab:CreateToggle({
    name = "Auto Sprint",
    flag = "AutoSprint",
    default = false,
    callback = function(v)
		autoSprint = v
		setSpeed(v and sprintSpeed or normalSpeed)
    end,
})

tab:CreateSlider({
	name = "WalkSpeed",
	flag = "WalkSpeed",
	default = 16,
	min = 8,
	max = 100,
	step = 1,
	callback = function(v)
		normalSpeed = v
		if not autoSprint then
			setSpeed(normalSpeed)
		end
	end
})

tab:CreateSlider({
	name = "Sprint Speed",
	flag = "SprintSpeed",
	default = 28,
	min = 16,
	max = 150,
	step = 1,
	callback = function(v)
		sprintSpeed = v
		if autoSprint then
			setSpeed(sprintSpeed)
		end
	end
})

tab:CreateSection({ name = "Utility" })

tab:CreateToggle({
    name = "Lock Position",
    flag = "LockPos",
    default = false,
    callback = function(v)
		lockPos = v
		local _, root = getChar()
		if v and root then lockedCFramePos = root.Position else lockedCFramePos = nil end
    end,
})

tab:CreateToggle({
    name = "Teleport Back on Reset",
    flag = "TPOnReset",
    default = true,
    callback = function(v) tpOnReset = v end,
})

tab:CreateButton({
	name = "Save Current Pos as Lock Pos",
	callback = function()
		local _, root = getChar()
		if root then
			lockedCFramePos = root.Position
			Rayfield:Notify({ title = "Saved", content = "Locked position saved!" })
		end
	end
})

-- LOOPS
task.spawn(function()
	while true do
		if autoPunch then
			local tool = getTool()
			if tool then
				if tool.Parent == player.Backpack then
					local _, _, hum = getChar()
					if hum then hum:EquipTool(tool) end
				end
				tool:Activate()
			end
			task.wait(punchDelay)
		else
			task.wait(0.1)
		end
	end
end)

RunService.RenderStepped:Connect(function()
	local char, root, hum = getChar()
	if not char or not root or not hum then return end
	
	if autoRun then hum:Move(Vector3.new(0,0,-1), true) end
	
	if lockPos and lockedCFramePos then
		if autoRun or hum.MoveDirection.Magnitude > 0 then
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end
		local look = root.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.01 then
			root.CFrame = CFrame.new(lockedCFramePos, lockedCFramePos + flat)
		else
			root.CFrame = CFrame.new(lockedCFramePos)
		end
		root.AssemblyLinearVelocity = Vector3.zero
	end
end)
