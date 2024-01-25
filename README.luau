
--// Services \\-- 
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local Modules = ReplicatedStorage.Modules.Shared

--// Modules \\--
local WaitForLoad = require(Modules.WaitForLoad)
local SoundService = require(Modules.SoundsService)
local Short = require(Modules.NumberLib)
local GetStat = require(Modules.Stat.GetStat)

--// Variables \\--
local Remotes = ReplicatedStorage.Remotes
local Player = Players.LocalPlayer
local Main = Player.PlayerGui.Main

local TweenInf = TweenInfo.new(0.075, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, true)

local Debounce = false

--// Remotes \\--
local ClickRemote = Remotes.Click

WaitForLoad(Player)
task.wait(3)
--// Functions \\--

function PopUp(Amount, Crit)
	local Frame = ReplicatedStorage.Assets.Templates.KeyFrame:Clone()
	Frame.TextLabel.Text = "+"..Short.Suffix(Amount)

	Frame.Rotation = math.random(-25, 25)

	local Image = "rbxassetid://10937036278"
	if Crit then
		Frame.TextLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		Frame.Icon.ImageColor3 = Color3.fromRGB(255, 255, 0)
	end

	Frame.Icon.Image = Image
	local getX = math.random(250, 750) / 1e3
	local getY = math.random(700, 800) / 1e3

	Frame.Position = UDim2.fromScale(getX, getY)

	Debris:AddItem(Frame, 3)
	Frame.Parent = Main.Popups

	task.spawn(function()
		Frame:TweenPosition(UDim2.fromScale(getX, getY - math.random(300, 550) / 1e3), "InOut", "Quint", 0.75, true)
	end)

	task.wait(0.8)

	Frame:TweenSize(UDim2.fromScale(0, 0), "InOut", "Quint", 0.5, true)
end

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2 or input.UserInputType == Enum.UserInputType.Touch then
		if Debounce then return end
		Debounce = true
		
		SoundService.PlaySoundOnceDelete(Player, "Click")
		ClickRemote:FireServer()
		task.wait(0.125)
		
		Debounce = false
	end
end)

local HidePopups = GetStat(Player, "Popups", "Settings")
ClickRemote.OnClientEvent:Connect(function(Amount, Crit)
	if HidePopups.Value then
		PopUp(Amount, Crit)
	else
		
	end
end)
