local DailyRewardsManager = {}

-- Servicios
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- Variables Internas
local UIUtils, DailyScroll, DailyFrame, DailyButton, ToggleButtonsFunc
local VIP_ID = 1605082468

-- COLORES
local COLORS = {
	Locked = Color3.fromRGB(30, 30, 35),
	Ready = Color3.fromRGB(255, 215, 0), -- Dorado
	Claimed = Color3.fromRGB(20, 20, 20),
	ClaimedText = Color3.fromRGB(100, 255, 100),
	VipBorder = Color3.fromRGB(255, 170, 0),
	NormalBorder = Color3.fromRGB(80, 80, 100)
}

function DailyRewardsManager.init(utils, scroll, frame, btn, vipId, toggleFunc)
	UIUtils = utils
	DailyScroll = scroll
	DailyFrame = frame
	DailyButton = btn
	VIP_ID = vipId
	ToggleButtonsFunc = toggleFunc

	print("? DailyRewardsManager: Inicializado correctamente")
end

local function formatNumber(n)
	return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function createDayButton(day, displayDay, alreadyClaimed, isVip)
	local frame = Instance.new("TextButton")
	frame.Text = ""
	frame.AutoButtonColor = false
	frame.ClipsDescendants = true

	-- Lógica de Estado
	local isPastDay = day < displayDay
	local isToday = day == displayDay

	if isPastDay then 
		frame.BackgroundColor3 = COLORS.Claimed
	elseif isToday then
		if alreadyClaimed then 
			frame.BackgroundColor3 = COLORS.Claimed 
		else 
			frame.BackgroundColor3 = COLORS.Ready 
		end
	else 
		frame.BackgroundColor3 = COLORS.Locked 
	end

	-- Borde
	local stroke = Instance.new("UIStroke", frame)
	stroke.Thickness = (isToday and not alreadyClaimed) and 3 or 2
	stroke.Color = (isVip and COLORS.VipBorder) or COLORS.NormalBorder
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	-- Texto "DAY X"
	local dayLbl = Instance.new("TextLabel", frame)
	dayLbl.Text = "DAY " .. day
	dayLbl.Size = UDim2.new(1, 0, 0.25, 0)
	dayLbl.Position = UDim2.new(0,0,0.05,0)
	dayLbl.BackgroundTransparency = 1
	dayLbl.TextColor3 = (isToday and not alreadyClaimed) and Color3.new(0,0,0) or Color3.new(1,1,1)
	dayLbl.Font = Enum.Font.GothamBlack
	dayLbl.TextSize = 14
	dayLbl.Parent = frame

	-- Icono y Premio
	local rewardAmt = day * 1500
	local iconId = "rbxassetid://108796514719654"
	if day % 7 == 0 then rewardAmt = day * 50; iconId = "rbxassetid://111308733495717" end
	if isVip then rewardAmt = rewardAmt * 2 end

	local icon = Instance.new("ImageLabel", frame)
	icon.Image = iconId
	icon.Size = UDim2.new(0.5, 0, 0.5, 0)
	icon.Position = UDim2.new(0.25, 0, 0.25, 0)
	icon.BackgroundTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = frame

	-- Estado visual "CLAIMED"
	local txtContent = formatNumber(rewardAmt)
	if isPastDay or (isToday and alreadyClaimed) then
		txtContent = "CLAIMED"
		icon.ImageColor3 = Color3.fromRGB(100,100,100)
	end

	local amtLbl = Instance.new("TextLabel", frame)
	amtLbl.Text = txtContent
	amtLbl.Size = UDim2.new(1, 0, 0.2, 0)
	amtLbl.Position = UDim2.new(0, 0, 0.75, 0)
	amtLbl.BackgroundTransparency = 1
	amtLbl.TextColor3 = (isToday and not alreadyClaimed) and Color3.new(0,0,0) or Color3.new(1,1,1)
	amtLbl.Font = Enum.Font.FredokaOne
	amtLbl.TextScaled = true
	amtLbl.Parent = frame

	-- CLICK EVENT
	if isToday and not alreadyClaimed then
		frame.MouseButton1Click:Connect(function()
			if frame:GetAttribute("Processing") then return end
			frame:SetAttribute("Processing", true)

			-- Sonido
			local s = Instance.new("Sound", workspace); s.SoundId="rbxassetid://2865227271"; s:Play(); Debris:AddItem(s, 2)

			-- Visual Instantáneo
			frame.BackgroundColor3 = COLORS.Claimed
			amtLbl.Text = "CLAIMED"
			amtLbl.TextColor3 = COLORS.ClaimedText
			dayLbl.TextColor3 = Color3.new(1,1,1)

			-- Enviar al servidor
			local event = ReplicatedStorage:WaitForChild("Daily_Claim", 5)
			if event then event:FireServer() end
		end)
	end

	return frame
end

function DailyRewardsManager.open()
	if not DailyScroll then return end

	-- ? LIMPIAR BOTONES ANTERIORES
	for _, child in pairs(DailyScroll:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Generar botones (Asegúrate de que el resto del código siga igual)
	local rawStreak = player:GetAttribute("CurrentStreak") or 1
	local displayDay = ((rawStreak - 1) % 30) + 1
	local claimed = player:GetAttribute("DailyClaimed") == true

	for i = 1, 30 do
		local btn = createDayButton(i, displayDay, claimed, false)
		btn.Parent = DailyScroll
	end

	if ToggleButtonsFunc then ToggleButtonsFunc(false) end
	UIUtils.openMenuWithAnim(DailyFrame)
end

return DailyRewardsManager