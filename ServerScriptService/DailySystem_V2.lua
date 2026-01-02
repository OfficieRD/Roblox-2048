local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

-- NOMBRE DE LA BASE DE DATOS (Cambia la versión si quieres reiniciar datos de todos)
local DATA_KEY = "PlayerData_V3_CodesAndDaily"
local MyDataStore = DataStoreService:GetDataStore(DATA_KEY)

-- 1. CREAR O CORREGIR REMOTOS
local function getRemote(name, class)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end

local ClaimEvent = getRemote("Daily_Claim", "RemoteEvent") 
local RedeemFunc = getRemote("Daily_Redeem", "RemoteFunction")

-- 2. CONFIGURACIÓN DE CÓDIGOS
local CODES = {
	["START2025"] = {Coins = 500, Gems = 0},
	["POWERRANGERS"] = {Coins = 1000, Gems = 10},
	["VIP2048"] = {Coins = 2000, Gems = 50}
}

-- 3. CARGAR DATOS AL ENTRAR
Players.PlayerAdded:Connect(function(player)
	local success, data = pcall(function()
		return MyDataStore:GetAsync(player.UserId)
	end)

	if success and data then
		-- Cargar datos guardados
		player:SetAttribute("CurrentStreak", data.Streak or 1)
		player:SetAttribute("LastDailyClaim", data.LastClaim or 0)
		player:SetAttribute("UsedCodes", data.UsedCodes or "[]")

		-- Verificar si ya reclamó hoy (Visual)
		local now = os.time()
		local canClaim = (now - (data.LastClaim or 0)) >= 72000 -- 20 horas
		player:SetAttribute("DailyClaimed", not canClaim)
	else
		-- Datos nuevos
		player:SetAttribute("CurrentStreak", 1)
		player:SetAttribute("LastDailyClaim", 0)
		player:SetAttribute("UsedCodes", "[]")
		player:SetAttribute("DailyClaimed", false)
	end
end)

-- 4. GUARDAR DATOS AL SALIR
local function saveData(player)
	local dataToSave = {
		Streak = player:GetAttribute("CurrentStreak") or 1,
		LastClaim = player:GetAttribute("LastDailyClaim") or 0,
		UsedCodes = player:GetAttribute("UsedCodes") or "[]"
	}

	local success, err = pcall(function()
		MyDataStore:SetAsync(player.UserId, dataToSave)
	end)

	if success then
		print("?? Datos guardados para: " .. player.Name)
	else
		warn("? Error guardando datos: " .. tostring(err))
	end
end

Players.PlayerRemoving:Connect(saveData)

-- Guardado automático en caso de cierre del servidor
game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		saveData(player)
	end
end)

-- 5. LÓGICA DE RECOMPENSAS DIARIAS
ClaimEvent.OnServerEvent:Connect(function(player)
	local lastClaim = player:GetAttribute("LastDailyClaim") or 0
	local streak = player:GetAttribute("CurrentStreak") or 1
	local now = os.time()

	-- Verificar tiempo (aprox 20h)
	if (now - lastClaim) < 72000 then return end

	-- Reiniciar racha si pasa mucho tiempo (48h)
	if (now - lastClaim) > 172800 and lastClaim ~= 0 then streak = 1 end

	-- Calcular premio
	local day = ((streak - 1) % 30) + 1
	local rewardCoins = day * 1500
	local rewardGems = 0
	if day % 7 == 0 then rewardGems = day * 50 end

	-- Chequeo VIP (Usando atributo o pase)
	local isVip = false -- Aquí puedes conectar tu chequeo real
	if isVip then rewardCoins = rewardCoins * 2 end

	-- ENTREGAR PREMIO
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if ls:FindFirstChild("Coins") then ls.Coins.Value += rewardCoins end
		if ls:FindFirstChild("Diamonds") then ls.Diamonds.Value += rewardGems end
	end

	-- Guardar estado en memoria
	player:SetAttribute("LastDailyClaim", now)
	player:SetAttribute("CurrentStreak", streak + 1)
	player:SetAttribute("DailyClaimed", true)

	-- Guardar en DataStore inmediatamente por seguridad
	saveData(player) 
	print("? Daily Reward entregado a " .. player.Name)
end)

-- 6. LÓGICA DE CÓDIGOS (AHORA GUARDA PERMANENTE)
RedeemFunc.OnServerInvoke = function(player, codeText)
	if not codeText then return "Error" end
	local code = string.upper(codeText)
	local data = CODES[code]

	if not data then return "Code Invalid" end

	-- Verificar historial
	local usedCodesStr = player:GetAttribute("UsedCodes") or "[]"
	local usedCodes = {}
	pcall(function() usedCodes = HttpService:JSONDecode(usedCodesStr) end)

	if table.find(usedCodes, code) then return "Already Used" end

	-- Dar premio
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if ls:FindFirstChild("Coins") then ls.Coins.Value += data.Coins end
		if ls:FindFirstChild("Diamonds") then ls.Diamonds.Value += data.Gems end
	end

	-- Guardar uso
	table.insert(usedCodes, code)
	player:SetAttribute("UsedCodes", HttpService:JSONEncode(usedCodes))

	saveData(player) -- Guardar inmediatamente

	return "Success! +"..data.Coins
end