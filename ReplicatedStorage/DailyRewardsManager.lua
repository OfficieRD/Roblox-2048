local DailyRewardsManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local UIUtils, DailyScroll, DailyFrame, DailyButton, ToggleButtonsFunc
local VIP_ID = 1605082468

local COLORS = {
	Locked = Color3.fromRGB(35, 35, 40),
	Ready = Color3.fromRGB(0, 170, 255),
	Claimed = Color3.fromRGB(0, 220, 100),
	VipBorder = Color3.fromRGB(255, 215, 0),
	NormalBorder = Color3.fromRGB(80, 80, 100)
}

function DailyRewardsManager.init(utils, scroll, frame, btn, vipId, toggleFunc)
	UIUtils = utils; DailyScroll = scroll; DailyFrame = frame; DailyButton = btn; VIP_ID = vipId; ToggleButtonsFunc = toggleFunc
end

local function formatNumber(n) return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "") end

local function createDayButton(day, displayDay, alreadyClaimed, isVip)
	local frame = Instance.new("TextButton")
	frame.Name = "Day_" .. day
	frame.AutoButtonColor = false
	frame.ClipsDescendants = true
	frame.LayoutOrder = day
	frame.ZIndex = 3006 -- ZINDEX MUY ALTO

	local isPast = day < displayDay
	local isToday = day == displayDay

	if isPast then frame.BackgroundColor3 = COLORS.Claimed
	elseif isToday then frame.BackgroundColor3 = alreadyClaimed and COLORS.Claimed or COLORS.Ready
	else frame.BackgroundColor3 = COLORS.Locked end

	local stroke = Instance.new("UIStroke", frame)
	stroke.Thickness = (isToday and not alreadyClaimed) and 3 or 2
	stroke.Color = (day % 5 == 0) and COLORS.VipBorder or COLORS.NormalBorder
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local dayLbl = Instance.new("TextLabel", frame)
	dayLbl.Text = "DAY " .. day
	dayLbl.Size = UDim2.new(1, 0, 0.25, 0); dayLbl.Position = UDim2.new(0,0,0.05,0)
	dayLbl.BackgroundTransparency = 1
	dayLbl.TextColor3 = Color3.new(1,1,1)
	dayLbl.Font = Enum.Font.GothamBlack; dayLbl.TextScaled = true; dayLbl.Parent = frame; dayLbl.ZIndex = 3007

	-- CALCULO NERFEADO
	local rewardAmt = 500 + (day * 200) 
	local rewardType = "Coins"
	local iconId = "rbxassetid://108796514719654"

	if day == 30 then rewardType = "Skin"; rewardAmt = 1; iconId = "rbxassetid://100737380049446"
	elseif day % 7 == 0 then rewardType = "Gems"; rewardAmt = 20 + (day * 5); iconId = "rbxassetid://111308733495717"
	elseif day % 5 == 0 then rewardType = "Fruits"; rewardAmt = 50 + (day * 10); iconId = "rbxassetid://128100423386205" end

	if isVip and rewardType ~= "Skin" then rewardAmt = rewardAmt * 2 end

	local icon = Instance.new("ImageLabel", frame)
	icon.Image = iconId; icon.Size = UDim2.new(0.5, 0, 0.45, 0); icon.Position = UDim2.new(0.25, 0, 0.3, 0); icon.BackgroundTransparency = 1; icon.ScaleType = Enum.ScaleType.Fit; icon.Parent = frame; icon.ZIndex = 3007

	local labelText = formatNumber(rewardAmt)
	if rewardType == "Skin" then labelText = "SKIN" end
	if isPast or (isToday and alreadyClaimed) then labelText = "CLAIMED"; icon.ImageColor3 = Color3.fromRGB(100,100,100) end

	local amtLbl = Instance.new("TextLabel", frame)
	amtLbl.Text = labelText; amtLbl.Size = UDim2.new(1, 0, 0.2, 0); amtLbl.Position = UDim2.new(0, 0, 0.75, 0); amtLbl.BackgroundTransparency = 1
	amtLbl.TextColor3 = Color3.new(1,1,1); amtLbl.Font = Enum.Font.FredokaOne; amtLbl.TextScaled = true; amtLbl.Parent = frame; amtLbl.ZIndex = 3007

	if isToday and not alreadyClaimed then
		frame.MouseButton1Click:Connect(function()
			if frame:GetAttribute("Processing") then return end
			frame:SetAttribute("Processing", true)
			if UIUtils then UIUtils.playClick() end
			local event = ReplicatedStorage:FindFirstChild("Daily_Claim")
			if event then event:FireServer() end
			frame.BackgroundColor3 = COLORS.Claimed
			amtLbl.Text = "CLAIMED"
		end)
	end
	return frame
end

function DailyRewardsManager.open()
	if not DailyScroll then return end

	-- LIMPIEZA ABSOLUTA DE HIJOS (Anti Duplicados dentro del scroll)
	for _, child in pairs(DailyScroll:GetChildren()) do 
		if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end 
	end

	-- FORZAR TAMAÑO DEL SCROLL (Para que baje sí o sí)
	DailyScroll.CanvasSize = UDim2.new(0, 0, 0, 2000) 
	DailyScroll.ScrollingEnabled = true

	local rawStreak = player:GetAttribute("CurrentStreak") or 1
	local displayDay = ((rawStreak - 1) % 30) + 1
	local claimed = player:GetAttribute("DailyClaimed") == true
	local isVip = false
	if VIP_ID > 0 then isVip = player:GetAttribute("PassOwned_"..VIP_ID) == true end

	for i = 1, 30 do
		local btn = createDayButton(i, displayDay, claimed, isVip)
		if btn then btn.Parent = DailyScroll end
	end

	if UIUtils then UIUtils.openMenuWithAnim(DailyFrame) end
end

return DailyRewardsManager