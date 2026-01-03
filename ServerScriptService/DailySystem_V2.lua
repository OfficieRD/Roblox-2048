local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService") -- Importante para VIP

local DATA_KEY = "PlayerData_V4_CodesAndDaily"
local MyDataStore = DataStoreService:GetDataStore(DATA_KEY)
local VIP_ID = 1605082468

-- REMOTOS
local function getRemote(name, class)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then r = Instance.new(class); r.Name = name; r.Parent = ReplicatedStorage end
	return r
end
local ClaimEvent = getRemote("Daily_Claim", "RemoteEvent") 
local RedeemFunc = getRemote("Daily_Redeem", "RemoteFunction")

-- CÓDIGOS
local CODES = {
	["START2025"] = {Coins = 500, Gems = 0},
	["POWERRANGERS"] = {Coins = 1000, Gems = 10},
	["VIP2048"] = {Coins = 2000, Gems = 50},
	["LIKE"] = {Coins = 1000, Gems = 0},
	["FAVORITE"] = {Coins = 1000, Gems = 0}
}

-- CARGAR
Players.PlayerAdded:Connect(function(player)
	local s, data = pcall(function() return MyDataStore:GetAsync(player.UserId) end)
	if s and data then
		player:SetAttribute("CurrentStreak", data.Streak or 1)
		player:SetAttribute("LastDailyClaim", data.LastClaim or 0)
		player:SetAttribute("UsedCodes", data.UsedCodes or "[]")
		local canClaim = (os.time() - (data.LastClaim or 0)) >= 72000 
		player:SetAttribute("DailyClaimed", not canClaim)
	else
		player:SetAttribute("CurrentStreak", 1); player:SetAttribute("LastDailyClaim", 0)
		player:SetAttribute("UsedCodes", "[]"); player:SetAttribute("DailyClaimed", false)
	end
end)

-- GUARDAR
local function saveData(player)
	local d = {Streak = player:GetAttribute("CurrentStreak") or 1, LastClaim = player:GetAttribute("LastDailyClaim") or 0, UsedCodes = player:GetAttribute("UsedCodes") or "[]"}
	pcall(function() MyDataStore:SetAsync(player.UserId, d) end)
end
Players.PlayerRemoving:Connect(saveData)
game:BindToClose(function() for _, p in pairs(Players:GetPlayers()) do saveData(p) end end)

-- RECLAMAR (NERFEADO + VIP x2)
ClaimEvent.OnServerEvent:Connect(function(player)
	if player:GetAttribute("DailyClaimed") then return end

	local streak = player:GetAttribute("CurrentStreak") or 1
	local day = ((streak - 1) % 30) + 1

	-- CALCULO BASE (NERFEADO)
	local rewardAmt = 500 + (day * 200) 
	local rewardType = "Coins"

	if day % 7 == 0 then rewardType = "Gems"; rewardAmt = 20 + (day * 5)
	elseif day % 5 == 0 then rewardType = "Fruits"; rewardAmt = 50 + (day * 10) end
	if day == 30 then rewardType = "Skin"; rewardAmt = 1 end

	-- BONUS VIP x2
	local hasVip = false
	pcall(function() hasVip = MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_ID) end)
	if hasVip and rewardType ~= "Skin" then rewardAmt = rewardAmt * 2 end

	-- DAR PREMIO
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if rewardType == "Coins" and ls:FindFirstChild("Coins") then ls.Coins.Value += rewardAmt
		elseif rewardType == "Gems" and ls:FindFirstChild("Diamonds") then ls.Diamonds.Value += rewardAmt
		elseif rewardType == "Fruits" and ls:FindFirstChild("FruitGems") then ls.FruitGems.Value += rewardAmt end
	end

	player:SetAttribute("DailyClaimed", true)
	player:SetAttribute("LastDailyClaim", os.time())
	player:SetAttribute("CurrentStreak", streak + 1)
	saveData(player)
end)

RedeemFunc.OnServerInvoke = function(player, codeText)
	if not codeText then return "Error" end
	local code = string.upper(codeText); local data = CODES[code]
	if not data then return "Invalid Code" end
	local usedStr = player:GetAttribute("UsedCodes") or "[]"; local usedTable = HttpService:JSONDecode(usedStr)
	if table.find(usedTable, code) then return "Already Used!" end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if ls:FindFirstChild("Coins") then ls.Coins.Value += data.Coins end
		if ls:FindFirstChild("Diamonds") then ls.Diamonds.Value += data.Gems end
	end
	table.insert(usedTable, code)
	player:SetAttribute("UsedCodes", HttpService:JSONEncode(usedTable))
	saveData(player)
	return "Success! +"..data.Coins
end