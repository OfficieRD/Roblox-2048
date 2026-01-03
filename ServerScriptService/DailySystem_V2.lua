local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService") 

local DATA_KEY = "PlayerData_V4_CodesAndDaily"
local MyDataStore = DataStoreService:GetDataStore(DATA_KEY)
local VIP_ID = 1605082468

-- HELPER: Obtener ID del día actual
local function getCurrentDayID()
	return math.floor(os.time() / 86400)
end

local function getRemote(name, class)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then r = Instance.new(class); r.Name = name; r.Parent = ReplicatedStorage end
	return r
end
local ClaimEvent = getRemote("Daily_Claim", "RemoteEvent") 
local RedeemFunc = getRemote("Daily_Redeem", "RemoteFunction")

local CODES = {
	["START2025"] = {Coins = 500, Gems = 0},
	["RELEASE"] = {Coins = 1000, Gems = 10}, -- Cambiado POWERRANGERS por RELEASE
	["VIP2048"] = {Coins = 2000, Gems = 50}
}

-- 1. CARGAR DATOS E INCREMENTAR RACHA (SOLO SI ES UN NUEVO DÍA)
Players.PlayerAdded:Connect(function(player)
	local s, data = pcall(function() return MyDataStore:GetAsync(player.UserId) end)

	local streak = 1
	local lastClaimDay = 0
	local lastLoginDay = 0 -- Nuevo: Para controlar logins consecutivos sin reclamar
	local usedCodes = "[]"

	if s and data then
		streak = data.Streak or 1
		lastClaimDay = data.LastClaimDayID or 0
		lastLoginDay = data.LastLoginDayID or 0
		usedCodes = data.UsedCodes or "[]"
	end

	local currentDay = getCurrentDayID()

	-- LÓGICA DE LOGIN CONSECUTIVO (Entrar seguido)
	-- Solo actualizamos la racha si es la PRIMERA vez que entras hoy.
	if lastLoginDay ~= currentDay then
		if lastLoginDay == (currentDay - 1) then
			-- Entraste ayer -> Sumamos racha
			streak = streak + 1
		elseif lastLoginDay < (currentDay - 1) then
			-- No entraste ayer -> Racha rota, reinicio a 1
			-- (Excepción: si es jugador nuevo lastLoginDay es 0, streak se queda en 1)
			if lastLoginDay ~= 0 then streak = 1 end
		end
		-- Si lastLoginDay == currentDay, no hacemos nada (ya se calculó hoy)
	end

	-- LÓGICA DE RECLAMO (Daily Reward)
	local canClaim = false
	if lastClaimDay ~= currentDay then
		canClaim = true -- Si no has reclamado hoy, puedes hacerlo
	end

	-- Guardamos atributos para el Cliente
	player:SetAttribute("CurrentStreak", streak)
	player:SetAttribute("LastClaimDayID", lastClaimDay)
	player:SetAttribute("LastLoginDayID", currentDay) -- Marcamos que ya entraste hoy
	player:SetAttribute("DailyClaimed", not canClaim)
	player:SetAttribute("UsedCodes", usedCodes)
end)

-- 2. GUARDAR DATOS
local function saveData(player)
	local d = {
		Streak = player:GetAttribute("CurrentStreak") or 1, 
		LastClaimDayID = player:GetAttribute("LastClaimDayID") or 0, 
		LastLoginDayID = player:GetAttribute("LastLoginDayID") or 0, -- Guardamos el login de hoy
		UsedCodes = player:GetAttribute("UsedCodes") or "[]"
	}
	pcall(function() MyDataStore:SetAsync(player.UserId, d) end)
end
Players.PlayerRemoving:Connect(saveData)
game:BindToClose(function() for _, p in pairs(Players:GetPlayers()) do saveData(p) end end)

-- 3. RECLAMAR (YA NO SUBE LA RACHA AQUÍ)
ClaimEvent.OnServerEvent:Connect(function(player)
	if player:GetAttribute("DailyClaimed") == true then return end 

	local streak = player:GetAttribute("CurrentStreak") or 1
	local dayInCycle = ((streak - 1) % 30) + 1

	-- RECOMPENSAS
	local rewardAmt = 1500 + (dayInCycle * 500) -- BUFF
	local rewardType = "Coins"

	if dayInCycle % 7 == 0 then rewardType = "Gems"; rewardAmt = 50 + (dayInCycle * 10)
	elseif dayInCycle % 5 == 0 then rewardType = "Fruits"; rewardAmt = 300 + (dayInCycle * 50) end
	if dayInCycle == 30 then rewardType = "Skin"; rewardAmt = 1 end

	-- VIP BONUS
	local hasVip = false
	pcall(function() hasVip = MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_ID) end)
	if hasVip and rewardType ~= "Skin" then rewardAmt = rewardAmt * 2 end

	-- ENTREGAR
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if rewardType == "Coins" and ls:FindFirstChild("Coins") then ls.Coins.Value += rewardAmt
		elseif rewardType == "Gems" and ls:FindFirstChild("Diamonds") then ls.Diamonds.Value += rewardAmt
		elseif rewardType == "Fruits" and ls:FindFirstChild("FruitGems") then ls.FruitGems.Value += rewardAmt end
	end

	-- ACTUALIZAR ESTADO
	player:SetAttribute("DailyClaimed", true)
	player:SetAttribute("LastClaimDayID", getCurrentDayID())

	-- ¡CORRECCIÓN!: NO subimos la racha aquí.
	-- La racha se queda en el día actual (ej: 5) para que visualmente se vea "Día 5: Reclamado".
	-- Subirá a 6 automáticamente mañana cuando entre.

	saveData(player)
end)

-- CÓDIGOS (Sin cambios)
RedeemFunc.OnServerInvoke = function(player, codeText)
	if not codeText then return "Invalid" end
	local code = string.upper(codeText); local data = CODES[code]
	if not data then return "Invalid Code" end

	local usedStr = player:GetAttribute("UsedCodes") or "[]"
	local usedTable = HttpService:JSONDecode(usedStr)

	if table.find(usedTable, code) then return "Already Used!" end

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if ls:FindFirstChild("Coins") and data.Coins > 0 then ls.Coins.Value += data.Coins end
		if ls:FindFirstChild("Diamonds") and data.Gems > 0 then ls.Diamonds.Value += data.Gems end
	end

	table.insert(usedTable, code)
	player:SetAttribute("UsedCodes", HttpService:JSONEncode(usedTable))
	saveData(player)

	-- Crear mensaje detallado (Ej: "+2000 Coins, +50 Gems")
	local msgParts = {}
	if data.Coins > 0 then table.insert(msgParts, "+"..data.Coins.." Coins") end
	if data.Gems > 0 then table.insert(msgParts, "+"..data.Gems.." Gems") end

	return table.concat(msgParts, ", ") .. "!"
end