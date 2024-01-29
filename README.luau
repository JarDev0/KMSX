 --// Services \\--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders \\--
local Shared = ReplicatedStorage.Modules.Shared
local Remotes = ReplicatedStorage.Remotes
local PetFolder = ReplicatedStorage.Pets
local Templates = ReplicatedStorage.Assets.Templates

--// Modules \\--
local GetStat = require(Shared.Stat.GetStat)
local WaitForLoad = require(Shared.WaitForLoad)
local NumberLib = require(Shared.NumberLib)
local SoundService = require(Shared.SoundsService)

--// Remotes \\--
local EquipRemote = Remotes.EquipPet

--// Variables \\--
local MultiDelete = false
local Player = Players.LocalPlayer
WaitForLoad(Player)
task.wait(3)
local Inventory = Player.PlayerGui.Main.Menus.Inventory.Frame
local Mode = Inventory.Mode
local Stats = ReplicatedStorage.Stats[Player.Name]
local Pets = Stats.Pets
local Storage = GetStat(Player, "Storage", "PlayerData")
local MaxEquip = GetStat(Player, "MaxEquip", "PlayerData")
local Equipped = GetStat(Player, "Equipped", "PlayerData")
local MaxStorage = GetStat(Player, "MaxStorage", "PlayerData")
local PetsSelected = {}
local Connections = {}
local Debounces = {}

Inventory.Pattern.TotalPets.Text = #Pets:GetChildren() .. " Pets"


function SortPets()
	Inventory.Pattern.TotalPets.Text = #Pets:GetChildren() .. "/" .. MaxStorage.Value .. " Pets"
	Inventory.Bar.Pattern.EquippedText.Text = Equipped.Value .. "/" .. MaxEquip.Value .. " Equipped"
	
	local Tab = {}

	for _, Pet in pairs(Pets:GetChildren()) do 
		table.insert(Tab, {Pet.Name, Pet:WaitForChild("Multi").Value, Pet:WaitForChild("Equipped").Value})
	end

	table.sort(Tab, function(a, b) 
		local aAdd,bAdd = a[3] and math.log10(a[2]) + 90 or math.log10(a[2]), b[3] and math.log10(b[2]) + 90 or math.log10(b[2])
		return aAdd > bAdd
	end)
	
	for order, Name in pairs(Tab) do 
		Inventory.ScrollingFrame:WaitForChild(Name[1]).LayoutOrder = order
	end
end

local function AddPet(Pet)
	local Connection1
	local Connection2
	local Connection3
	local Connection4

	local Frame = Templates.PetFrame:Clone()
	Frame.Parent = Inventory.ScrollingFrame

	Pet:WaitForChild("PetName")
	Frame.Name = Pet.Name
	local PetFrame = Frame.Frame
	local Settings = require(PetFolder[Pet.PetName.Value].Settings)
	
	if Pet.Tier.Value == 2 then
		PetFrame.Icon.Image = Settings.goldimage
	else
		PetFrame.Icon.Image = Settings.image
	end
	PetFrame.TextLabel.Text = NumberLib.Suffix(Pet.Multi.Value)
	
	local DebounceEquip = false
	Connection1 = PetFrame.Button.MouseButton1Click:Connect(function()
		if DebounceEquip then return end
		DebounceEquip = true
		SoundService.PlaySoundOnceDelete(Player, "Interaction")
		if Mode.Value == "Equip" then
			EquipRemote:FireServer(Pet.Name)
		elseif Mode.Value == "MultiDelete" then
			if table.find(PetsSelected, Pet.Name) then
				table.remove(PetsSelected, table.find(PetsSelected, Pet.Name))
				PetFrame.DeleteIcon.Visible = false
			else
				table.insert(PetsSelected, Pet.Name)
				PetFrame.DeleteIcon.Visible = true
			end
		end
		task.wait(0.25)
		DebounceEquip = false
	end)
	
	if Pet.Equipped.Value then
		PetFrame.BackgroundColor3 = Color3.fromRGB(63, 251, 59)
	else
		PetFrame.BackgroundColor3 = Color3.fromRGB(59, 177, 251)
	end

	Connection2 = Pet.Equipped.Changed:Connect(function()
		SortPets()
		if Pet.Equipped.Value then
			PetFrame.BackgroundColor3 = Color3.fromRGB(63, 251, 59)
		else
			PetFrame.BackgroundColor3 = Color3.fromRGB(59, 177, 251)
		end
	end)
	
	Connection3 = PetFrame.MouseEnter:Connect(function()
		PetFrame:TweenSize(UDim2.fromScale(0.95, 0.95), "InOut", "Quint", 0.1, true)
	end)
	
	Connection4 = PetFrame.MouseLeave:Connect(function()
		PetFrame:TweenSize(UDim2.fromScale(1, 1), "InOut", "Quint", 0.1, true)
	end)


	Connections[Pet.Name .. "1"] = Connection1
	Connections[Pet.Name .. "2"] = Connection2
	
end

local function DeletePet(ID)
	Inventory.ScrollingFrame[ID]:Destroy()
	Connections[ID .. "1"] = nil
	Connections[ID .. "2"] = nil
	Inventory.Pattern.TotalPets.Text = #Pets:GetChildren() .. "/" .. MaxStorage.Value .. " Pets"
	Inventory.Bar.Pattern.EquippedText.Text = Equipped.Value .. "/" .. MaxEquip.Value .. " Equipped"
end

for _, Pet in pairs(Pets:GetChildren()) do
	AddPet(Pet)
end

SortPets()

Pets.ChildAdded:Connect(function(Pet)
	AddPet(Pet)
	SortPets()
	Inventory.Pattern.TotalPets.Text = #Pets:GetChildren() .. "/" .. MaxStorage.Value .. " Pets"
	Inventory.Bar.Pattern.EquippedText.Text = Equipped.Value .. "/" .. MaxEquip.Value .. " Equipped"
end)

Pets.ChildRemoved:Connect(function(Pet)
	DeletePet(Pet.Name)
	SortPets()
	Inventory.Pattern.TotalPets.Text = #Pets:GetChildren() .. "/" .. MaxStorage.Value .. " Pets"
	Inventory.Bar.Pattern.EquippedText.Text = Equipped.Value .. "/" .. MaxEquip.Value .. " Equipped"
end)

Debounces[1] = false
Inventory.Bar.MultiDelete.Button.MouseButton1Click:Connect(function()
	if Debounces[1] then return end
	Debounces[1] = true
	MultiDelete = not MultiDelete
	SoundService.PlaySoundOnceDelete(Player, "Interaction")
	if MultiDelete then
		Mode.Value = "MultiDelete"
		Inventory.Confirm.Visible = true
		for _, v in pairs(Inventory.ScrollingFrame:GetChildren()) do
			if v:IsA("Frame") then
				v.Frame.Icon.ImageTransparency = 0.25
				Inventory.Bar.MultiDelete.BackgroundColor3 = Color3.fromRGB(252, 209, 59)
			end
		end
		
	else
		Mode.Value = "Equip"
		for k in pairs (PetsSelected) do
			PetsSelected[k] = nil
		end
		Inventory.Confirm.Visible = false
		for _, v in pairs(Inventory.ScrollingFrame:GetChildren()) do
			if v:IsA("Frame") then
				v.Frame.Icon.ImageTransparency = 0
				v.Frame.DeleteIcon.Visible = false
				Inventory.Bar.MultiDelete.BackgroundColor3 = Color3.fromRGB(59, 177, 251)
			end
		end
	end
	task.wait(0.1)
	Debounces[1] = false
end)

Debounces[2] = false
Inventory.Confirm.Button.MouseButton1Click:Connect(function()
	if Debounces[2] then return end
	Debounces[2] = true
	SoundService.PlaySoundOnceDelete(Player, "Interaction")
	print(PetsSelected)
	local Success = Remotes.MultiDelete:InvokeServer(PetsSelected)
	if Success then
		MultiDelete = false
		Inventory.Confirm.Visible = false
		Inventory.Bar.MultiDelete.BackgroundColor3 = Color3.fromRGB(59, 177, 251)
		
		for k in pairs (PetsSelected) do
			PetsSelected[k] = nil
		end
		for _, v in pairs(Inventory.ScrollingFrame:GetChildren()) do
			if v:IsA("Frame") then
				v.Frame.Icon.ImageTransparency = 0
				v.Frame.DeleteIcon.Visible = false
			end
		end
		Mode.Value = "Equip"
		SortPets()
	end
	
	task.wait(0.1)
	Debounces[2] = false
end)

Debounces[3] = false
Inventory.Bar.BestEquip.Button.MouseButton1Click:Connect(function()
	if Debounces[3] == true then return end
	Debounces[3] = true
	local Success = Remotes.UnequipAll:InvokeServer()
	if Success then
		SortPets()
	end

	local Success = Remotes.EquipBest:InvokeServer()
	if Success then
		SortPets()
		Inventory.Pattern.TotalPets.Text = #Pets:GetChildren() .. "/" .. MaxStorage.Value .. " Pets"
		Inventory.Bar.Pattern.EquippedText.Text = Equipped.Value .. "/" .. MaxEquip.Value .. " Equipped"
	end

	SoundService.PlaySoundOnceDelete(Player, "Interaction")
	task.wait(0.5)
	Debounces[3] = false
end)

Equipped.Changed:Connect(function()
	Inventory.Pattern.TotalPets.Text = #Pets:GetChildren() .. "/" .. MaxStorage.Value .. " Pets"
	Inventory.Bar.Pattern.EquippedText.Text = Equipped.Value .. "/" .. MaxEquip.Value .. " Equipped"
end)

Storage.Changed:Connect(function()
	Inventory.Pattern.TotalPets.Text = #Pets:GetChildren() .. "/" .. MaxStorage.Value .. " Pets"
	Inventory.Bar.Pattern.EquippedText.Text = Equipped.Value .. "/" .. MaxEquip.Value .. " Equipped"
end)

MaxEquip.Changed:Connect(function()
	Inventory.Pattern.TotalPets.Text = #Pets:GetChildren() .. "/" .. MaxStorage.Value .. " Pets"
	Inventory.Bar.Pattern.EquippedText.Text = Equipped.Value .. "/" .. MaxEquip.Value .. " Equipped"
end)

MaxStorage.Changed:Connect(function()
	Inventory.Pattern.TotalPets.Text = #Pets:GetChildren() .. "/" .. MaxStorage.Value .. " Pets"
	Inventory.Bar.Pattern.EquippedText.Text = Equipped.Value .. "/" .. MaxEquip.Value .. " Equipped"
end)
