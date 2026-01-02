local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService") -- ✅ ARREGLADO: Faltaba esta línea

-- 1. CONFIGURACIÓN DE EVENTOS
local ClaimLevelRewardEvent = ReplicatedStorage:FindFirstChild("ClaimLevelReward")
if not ClaimLevelRewardEvent then
	ClaimLevelRewardEvent = Instance.new("RemoteEvent")
	ClaimLevelRewardEvent.Name = "ClaimLevelReward"
	ClaimLevelRewardEvent.Parent = ReplicatedStorage
end

local SaveSettingsEvent = ReplicatedStorage:FindFirstChild("SaveSettings")
if not SaveSettingsEvent then
	SaveSettingsEvent = Instance.new("RemoteEvent")
	SaveSettingsEvent.Name = "SaveSettings"
	SaveSettingsEvent.Parent = ReplicatedStorage
end

local SaveScoreEvent = ReplicatedStorage:FindFirstChild("SaveScore")
local AddCurrencyEvent = ReplicatedStorage:FindFirstChild("AddCurrency")
local AddFruitEvent = ReplicatedStorage:FindFirstChild("AddFruitPoint")
local PurchaseEvent = ReplicatedStorage:FindFirstChild("PurchaseItem")

-- NUEVO: Evento de Diamantes
local AddDiamondEvent = ReplicatedStorage:FindFirstChild("AddDiamond")
if not AddDiamondEvent then
	AddDiamondEvent = Instance.new("RemoteEvent")
	AddDiamondEvent.Name = "AddDiamond"
	AddDiamondEvent.Parent = ReplicatedStorage
end

-- Funciones Remotas
local GetTopScoresFunc = ReplicatedStorage:FindFirstChild("GetTopScores")
local GetStatsFunc = ReplicatedStorage:FindFirstChild("GetPlayerStats")
if not GetStatsFunc then
	GetStatsFunc = Instance.new("RemoteFunction")
	GetStatsFunc.Name = "GetPlayerStats"
	GetStatsFunc.Parent = ReplicatedStorage
end

-- VARIABLES DE DATASTORE (¡ESTA ES LA QUE FALTA!)
local PlayerDataStore = DataStoreService:GetDataStore("2048_PlayerData_V4_Stats")

-- VARIABLES DE LEADERBOARD (OrderedDataStore)
local LEADERBOARD_KEY_SCORE = "GlobalScore_V4"
local LEADERBOARD_KEY_TIME = "GlobalTime_V4"
local LEADERBOARD_KEY_STREAK = "GlobalStreak_V4"
local LEADERBOARD_KEY_SPENT = "GlobalSpent_V4"
-- ✅ NUEVAS CLAVES
local LEADERBOARD_KEY_LEVEL = "GlobalLevel_V4"
local LEADERBOARD_KEY_5X5 = "GlobalScore5x5_V4"

local HighScoreStore = DataStoreService:GetOrderedDataStore(LEADERBOARD_KEY_SCORE)
local TimePlayedStore = DataStoreService:GetOrderedDataStore(LEADERBOARD_KEY_TIME)
local StreakStore = DataStoreService:GetOrderedDataStore(LEADERBOARD_KEY_STREAK)
local RobuxSpentStore = DataStoreService:GetOrderedDataStore(LEADERBOARD_KEY_SPENT)
-- ✅ NUEVAS STORES
local LevelStore = DataStoreService:GetOrderedDataStore(LEADERBOARD_KEY_LEVEL)
local Score5x5Store = DataStoreService:GetOrderedDataStore(LEADERBOARD_KEY_5X5)

-- 3. TABLA DE PRECIOS 
local ITEM_PRICES = {
	-- BÁSICAS
	["Classic"] = {Price = 0, Currency = "Coins"},
	["Blue"] = {Price = 500, Currency = "Coins"},
	["Red"] = {Price = 1000, Currency = "Coins"},
	["Green"] = {Price = 2500, Currency = "Coins"},
	["Purple"] = {Price = 5000, Currency = "Coins"},
	["Dark"] = {Price = 90000, Currency = "Coins"},
	["Gold"] = {Price = 95000, Currency = "Coins"},
	["Rainbow"] = {Price = 100000, Currency = "Coins"}, 

	-- PRO SKINS (Con Relieve)
	["Blue Pro"] = {Price = 10000, Currency = "Coins"},
	["Red Pro"] = {Price = 15000, Currency = "Coins"},
	["Green Pro"] = {Price = 20000, Currency = "Coins"},
	["Purple Pro"] = {Price = 25000, Currency = "Coins"},
	["Orange Pro"] = {Price = 30000, Currency = "Coins"},
	["Pink Pro"] = {Price = 40000, Currency = "Coins"},
	["Cyan Pro"] = {Price = 50000, Currency = "Coins"},

	-- SPECIALS (DIAMANTES)
	["Neon"] = {Price = 1500, Currency = "Diamonds"},
	["Classic 2048"] = {Price = 500, Currency = "Diamonds"},
	["Fruit Mix"] = {Price = 2000, Currency = "Diamonds"},
	["Robot"] = {Price = 1000, Currency = "Diamonds"},
	["Volcanic"] = {Price = 2500, Currency = "Diamonds"},

	-- FRUIT SHOP (FRUIT GEMS) - ¡ESTO FALTABA!
	["Fruit Mix 2"] = {Price = 15000, Currency = "FruitGems"},
	["Fruit Mix 3"] = {Price = 35000, Currency = "FruitGems"},
	["Fruits Green"] = {Price = 75000, Currency = "FruitGems"},
	["Fruits Red"] = {Price = 150000, Currency = "FruitGems"}
}
local sessionJoinTime = {}

-------------------------------------------------------------------------
-- FUNCIÓN DE GUARDADO (Centralizada)
-------------------------------------------------------------------------
local function savePlayerData(player)
	if not player:FindFirstChild("leaderstats") then return end

	-- Evitar guardar dos veces si ya se procesó
	if player:GetAttribute("DataSaved") then return end
	player:SetAttribute("DataSaved", true)

	local leaderstats = player.leaderstats
	local sessionTime = os.time() - (sessionJoinTime[player.UserId] or os.time())
	local totalTime = (player:GetAttribute("TimePlayedSaved") or 0) + sessionTime

	-- Guardar Skins
	local ownedSkins = {}
	for name, _ in pairs(ITEM_PRICES) do
		local safeName = string.gsub(name, " ", "")
		if player:GetAttribute("OwnedSkin_" .. safeName) == true then table.insert(ownedSkins, name) end
	end

	-- Recompensas Reclamadas
	local claimedRewardsList = {}
	for i = 1, 50 do
		if player:GetAttribute("ClaimedLevelReward_" .. i) == true then
			table.insert(claimedRewardsList, i)
		end
	end

	-- ✅ RECOLECTAR GAMEPASSES (Para Player1/Studio)
	local savedPasses = {}
	for attrName, val in pairs(player:GetAttributes()) do
		if string.sub(attrName, 1, 10) == "PassOwned_" and val == true then
			local id = tonumber(string.sub(attrName, 11))
			if id then table.insert(savedPasses, id) end
		end
	end

	-- DATOS A GUARDAR
	local data = {
		SavedGamePasses = savedPasses, -- <--- ESTA LÍNEA GUARDA LOS PASES
		HighScore = leaderstats.HighScore.Value,
		Coins = leaderstats.Coins.Value,
		FruitGems = leaderstats.FruitGems.Value,
		Level = leaderstats.Level.Value,
		Diamonds = leaderstats.Diamonds.Value,
		CurrentXP = player:GetAttribute("CurrentXP") or 0,

		TotalFruitGems = player:GetAttribute("TotalFruitGems") or 0,
		TotalCoins = player:GetAttribute("TotalCoins") or 0,
		TotalRobuxSpent = player:GetAttribute("TotalRobuxSpent") or 0,
		GamesPlayed = player:GetAttribute("GamesPlayed") or 0,
		TimePlayed = totalTime,
		Undos = player:GetAttribute("Undos") or 0,

		-- ✅ AGREGA ESTA LÍNEA PARA QUE EL 5x5 SE GUARDE SIEMPRE:
		HighScore5x5 = player:GetAttribute("HighScore5x5") or 0,

		-- ... (El resto de tus datos: racha, skins, etc)
		CurrentStreak = player:GetAttribute("CurrentStreak") or 0,
		LastLoginDay = player:GetAttribute("LastLoginDay") or 0,
		LastClaimedDay = player:GetAttribute("LastClaimedDay") or 0,

		OwnedSkins = ownedSkins,
		ClaimedLevelRewards = claimedRewardsList,

		-- ✅ NUEVO: GUARDAR TÍTULOS OBTENIDOS
		UnlockedTitles = (function()
			local t = {}
			for attrName, val in pairs(player:GetAttributes()) do
				-- Guardamos cualquier atributo que empiece por "Title_"
				if string.sub(attrName, 1, 6) == "Title_" and val == true then
					table.insert(t, attrName)
				end
			end
			return t
		end)(),

		-- CONFIGURACIÓN (Settings)
		VolMusic = player:GetAttribute("SavedVolMusic"),
		VolSFX = player:GetAttribute("SavedVolSFX"),
		IsDarkMode = player:GetAttribute("SavedDarkMode")
	}

	-- Intentar guardar con reintentos
	local success, err
	for i = 1, 3 do
		success, err = pcall(function()
			PlayerDataStore:SetAsync(player.UserId, data)
		end)
		if success then break end
		task.wait(1)
	end

	if not success then warn("Error guardando datos de " .. player.Name .. ": " .. tostring(err)) end

	-- Leaderboards
	HighScoreStore:UpdateAsync(player.UserId, function(old) 
		return math.max(tonumber(old) or 0, leaderstats.HighScore.Value) 
	end)

	TimePlayedStore:UpdateAsync(player.UserId, function(old) 
		return math.max(tonumber(old) or 0, totalTime) 
	end)

	-- ✅ GUARDAR EN LEADERBOARD DE RACHAS
	StreakStore:UpdateAsync(player.UserId, function(old)
		return player:GetAttribute("CurrentStreak") or 0
	end)

	print("💾 Datos guardados para: " .. player.Name)
end

-------------------------------------------------------------------------
-- CARGA DE DATOS
-------------------------------------------------------------------------
local function playerAdded(player)
	sessionJoinTime[player.UserId] = os.time()

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local highScoreValue = Instance.new("IntValue", leaderstats); highScoreValue.Name = "HighScore"
	local coinsValue = Instance.new("IntValue", leaderstats); coinsValue.Name = "Coins"
	local fruitValue = Instance.new("IntValue", leaderstats); fruitValue.Name = "FruitGems"
	local levelValue = Instance.new("IntValue", leaderstats); levelValue.Name = "Level"
	local diamondsValue = Instance.new("IntValue", leaderstats); diamondsValue.Name = "Diamonds"

	local success, data = pcall(PlayerDataStore.GetAsync, PlayerDataStore, player.UserId)

	if success and data then
		highScoreValue.Value = data.HighScore or 0
		coinsValue.Value = data.Coins or 0
		fruitValue.Value = data.FruitGems or 0
		levelValue.Value = data.Level or 1
		diamondsValue.Value = data.Diamonds or 0

		player:SetAttribute("CurrentXP", data.CurrentXP or 0)
		player:SetAttribute("MaxXP", (data.Level or 1) * 500)
		player:SetAttribute("TotalFruitGems", data.TotalFruitGems or 0)
		player:SetAttribute("TotalCoins", data.TotalCoins or 0)
		player:SetAttribute("TotalRobuxSpent", data.TotalRobuxSpent or 0)
		player:SetAttribute("GamesPlayed", data.GamesPlayed or 0)
		player:SetAttribute("TimePlayedSaved", data.TimePlayed or 0)
		player:SetAttribute("HighScore5x5", data.HighScore5x5 or 0)
		player:SetAttribute("Undos", data.Undos or 0)

		-- ✅ LÓGICA DE RECOMPENSA DIARIA
		local currentStreak = data.CurrentStreak or 0
		local lastLoginDay = data.LastLoginDay or 0
		local today = math.floor(os.time() / 86400) -- Día actual (número entero)

		-- ⬇️ LÓGICA CORREGIDA: NO MARCAR COMO RECLAMADO AUTOMÁTICAMENTE ⬇️
		local lastClaimedDay = data.LastClaimedDay or 0 -- Cargamos cuándo reclamó por última vez

		if lastClaimedDay == today then
			player:SetAttribute("DailyClaimed", true) -- Ya cobró hoy
		else
			player:SetAttribute("DailyClaimed", false) -- Aún no cobra hoy
		end

		if lastLoginDay == today then
			-- Ya entró hoy, no sumamos racha pero mantenemos estado
		elseif lastLoginDay == (today - 1) then
			-- Nuevo día consecutivo
			currentStreak = currentStreak + 1
			player:SetAttribute("DailyClaimed", false) -- <--- AGREGAR ESTO (Permite reclamar)
			-- BORRA LA LÍNEA QUE DABA DINERO AUTOMÁTICO AQUÍ PARA QUE NO TE DE DOBLE
		else
			-- Perdió racha
			currentStreak = 1
			player:SetAttribute("DailyClaimed", false) -- <--- AGREGAR ESTO
			-- BORRA LA LÍNEA QUE DABA DINERO AUTOMÁTICO AQUÍ
		end

		player:SetAttribute("CurrentStreak", currentStreak)
		player:SetAttribute("LastLoginDay", today)

		local ownedSkins = data.OwnedSkins or {"Classic"}
		for _, skinName in ipairs(ownedSkins) do
			local safeName = string.gsub(skinName, " ", "")
			player:SetAttribute("OwnedSkin_" .. safeName, true)
		end

		-- ✅ NUEVO: CARGAR TÍTULOS
		if data.UnlockedTitles then
			for _, titleAttr in pairs(data.UnlockedTitles) do
				player:SetAttribute(titleAttr, true)
			end
		end

		-- ✅ CARGAR GAMEPASSES GUARDADOS (Fix Player1)
		if data.SavedGamePasses then
			for _, passId in ipairs(data.SavedGamePasses) do
				player:SetAttribute("PassOwned_" .. passId, true)
				print("💾 GamePass cargado: " .. passId)
			end
		end

		local claimedRewards = data.ClaimedLevelRewards or {}
		for _, levelId in ipairs(claimedRewards) do
			player:SetAttribute("ClaimedLevelReward_" .. levelId, true)
		end

		-- CARGAR SETTINGS
		player:SetAttribute("SavedVolMusic", data.VolMusic or 0.5)
		player:SetAttribute("SavedVolSFX", data.VolSFX or 0.5)
		player:SetAttribute("SavedDarkMode", data.IsDarkMode or false)

		-- ✅ LÓGICA CORREGIDA PARA XP DEFAULT:
		-- Si data.IsShowXP es nil, significa que nunca lo guardó -> Ponemos TRUE.
		-- Solo ponemos false si explícitamente guardó 'false'.
		if data.IsShowXP == nil then
			player:SetAttribute("SavedShowXP", true)
		else
			player:SetAttribute("SavedShowXP", data.IsShowXP)
		end
	else
		-- DEFAULT SETTINGS
		levelValue.Value = 1
		player:SetAttribute("MaxXP", 500)
		player:SetAttribute("OwnedSkin_Classic", true)
		player:SetAttribute("SavedVolMusic", 0.5)
		player:SetAttribute("SavedVolSFX", 0.5)
		player:SetAttribute("SavedDarkMode", false)
	end
end

-------------------------------------------------------------------------
-- CONEXIONES Y EVENTOS
-------------------------------------------------------------------------

-- 1. Compra de Skins (LÓGICA ARREGLADA)
if PurchaseEvent then
	PurchaseEvent.OnServerEvent:Connect(function(player, itemName)
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end

		-- Verificar si ya la tiene
		local safeName = string.gsub(itemName, " ", "")
		if player:GetAttribute("OwnedSkin_" .. safeName) then return end

		-- LÓGICA INTELIGENTE: Busca el precio en la tabla ITEM_PRICES
		local itemData = ITEM_PRICES[itemName]

		if itemData then
			local basePrice = itemData.Price
			local currency = itemData.Currency

			-- 💎 LÓGICA VIP (15% DE DESCUENTO)
			local hasVip = false
			local success, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1605082468) -- TU ID VIP
			end)
			if success and result then hasVip = true end

			-- Si es VIP, aplicamos el 15% de descuento
			local finalPrice = basePrice
			if hasVip and basePrice > 0 then
				finalPrice = math.floor(basePrice * 0.85)
			end

			local currencyStore = leaderstats:FindFirstChild(currency)

			-- Verificar dinero y cobrar (Usando finalPrice)
			if currencyStore and currencyStore.Value >= finalPrice then
				currencyStore.Value = currencyStore.Value - finalPrice
				player:SetAttribute("OwnedSkin_" .. safeName, true)
				print("✅ Compra exitosa: " .. itemName .. " por " .. finalPrice .. " " .. currency .. (hasVip and " (VIP -15%)" or ""))
			else
				warn("❌ No tienes suficiente dinero para: " .. itemName)
			end
		else
			warn("Item no encontrado en la tabla de precios: " .. tostring(itemName))
		end
	end)
end

-- 2. Guardar Score (SEPARADO: NORMAL vs 5x5)
if SaveScoreEvent then
	SaveScoreEvent.OnServerEvent:Connect(function(player, newScore, boardSize)
		if type(newScore) ~= "number" then return end
		local finalScore = newScore 

		local bSize = boardSize or 4 
		local leaderstats = player:FindFirstChild("leaderstats")

		local gp = player:GetAttribute("GamesPlayed") or 0
		player:SetAttribute("GamesPlayed", gp + 1)

		if bSize == 5 then
			-- === LÓGICA 5x5 ===
			local current5x5 = player:GetAttribute("HighScore5x5") or 0
			if finalScore > current5x5 then
				player:SetAttribute("HighScore5x5", finalScore)

				Score5x5Store:UpdateAsync(tostring(player.UserId), function(old) 
					local oldValue = tonumber(old) or 0
					-- ✅ FIX DEFINITIVO: Convertimos aquí dentro para que el editor no marque error
					local valueToSave = tonumber(finalScore) or 0
					return math.max(oldValue, valueToSave)
				end)
			end

		else
			-- === LÓGICA CLÁSICA (4x4) ===
			if leaderstats and finalScore > leaderstats.HighScore.Value then
				leaderstats.HighScore.Value = finalScore

				HighScoreStore:UpdateAsync(tostring(player.UserId), function(old) 
					local oldValue = tonumber(old) or 0
					-- ✅ FIX DEFINITIVO: Convertimos aquí dentro también
					local valueToSave = tonumber(finalScore) or 0
					return math.max(oldValue, valueToSave)
				end)
			end
		end
	end)
end

-- 3. Reclamar Nivel
if ClaimLevelRewardEvent then
	ClaimLevelRewardEvent.OnServerEvent:Connect(function(player, levelId)
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats or not leaderstats:FindFirstChild("Level") then return end
		if leaderstats.Level.Value < levelId then return end
		if player:GetAttribute("ClaimedLevelReward_" .. levelId) == true then return end

		local rewards = {
			[1] = {Type="Currency", Store="Coins", Amt=500},
			[2] = {Type="Currency", Store="FruitGems", Amt=100},
			[3] = {Type="Currency", Store="Coins", Amt=1500},
			[5] = {Type="Currency", Store="Diamonds", Amt=10},
			[10]= {Type="Title", Name="Title_Level10_Master"}
		}
		local r = rewards[levelId]
		if r then
			if r.Type == "Currency" then
				if leaderstats:FindFirstChild(r.Store) then leaderstats[r.Store].Value += r.Amt end
			elseif r.Type == "Title" then
				player:SetAttribute(r.Name, true)
			end
			player:SetAttribute("ClaimedLevelReward_" .. levelId, true)
		end
	end)
end

-- 4. Guardar Configuración al vuelo
if SaveSettingsEvent then
	SaveSettingsEvent.OnServerEvent:Connect(function(player, settingName, value)
		if settingName == "VolMusic" then player:SetAttribute("SavedVolMusic", value)
		elseif settingName == "VolSFX" then player:SetAttribute("SavedVolSFX", value)
		elseif settingName == "DarkMode" then player:SetAttribute("SavedDarkMode", value)
		elseif settingName == "SavedShowXP" then player:SetAttribute("SavedShowXP", value) -- ✅ Conectado
		end
	end)
end

-- 5. Leaderboard Request
if GetTopScoresFunc then
	GetTopScoresFunc.OnServerInvoke = function(player, category)
		local store = HighScoreStore -- Default

		if category == "TimePlayed" then store = TimePlayedStore 
		elseif category == "Streaks" then store = StreakStore
		elseif category == "RobuxSpent" then store = RobuxSpentStore
			-- ✅ NUEVAS CATEGORÍAS
		elseif category == "Level" then store = LevelStore
		elseif category == "Score5x5" then store = Score5x5Store
		end

		local topScores = {}
		local success, pages = pcall(store.GetSortedAsync, store, false, 50)
		if success and pages then
			local rank = 1
			for _, entry in ipairs(pages:GetCurrentPage()) do
				local name = "[Error]"
				pcall(function() name = Players:GetNameFromUserIdAsync(entry.key) end)
				table.insert(topScores, {name = name, value = entry.value, rank = rank, userId = entry.key})
				rank = rank + 1
			end
		end
		return topScores
	end
end

-- 6. Stats Request (CON ROBUX SPENT)
if GetStatsFunc then
	GetStatsFunc.OnServerInvoke = function(player)
		local sessionTime = os.time() - (sessionJoinTime[player.UserId] or os.time())
		local totalTime = (player:GetAttribute("TimePlayedSaved") or 0) + sessionTime

		return {
			GamesPlayed = player:GetAttribute("GamesPlayed") or 0,
			TimePlayed = totalTime,
			TotalCoins = player:GetAttribute("TotalCoins") or 0,
			TotalFruitGems = player:GetAttribute("TotalFruitGems") or 0,
			-- ✅ AGREGADO: Enviar Robux y conteo de títulos real
			TotalRobuxSpent = player:GetAttribute("TotalRobuxSpent") or 0,
			HighScore5x5 = player:GetAttribute("HighScore5x5") or 0,
			TitlesCount = (function() 
				local c = 0
				for n,v in pairs(player:GetAttributes()) do 
					if string.sub(n,1,6)=="Title_" and v==true then c+=1 end 
				end
				return c
			end)()
		}
	end
end

-- 7. LÓGICA DE MULTIPLICADORES (GAMEPASSES)
local PASS_IDS = {
	Coins = 1612413325,
	Gems = 1613811032,
	XP = 1609347878,
	Fruits = 1614668850
}

-- Detectar compra en el SERVIDOR para activarlo al instante
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if wasPurchased then
		print("🟢 SERVER: Compra detectada ID: " .. passId .. " para " .. player.Name)

		-- ✅ MARCAR PARA GUARDAR (Atributo permanente)
		player:SetAttribute("PassOwned_" .. passId, true)

		-- ✅ NUEVO: REGISTRAR GASTO DE ROBUX (GAMEPASS)
		-- Necesitamos saber el precio. Como no viene en el evento, lo buscamos en una tabla o usamos un valor estimado/fijo si no quieres hacer una llamada API lenta.
		-- Opción A (Rápida): Definir precios aquí manual
		local prices = { [1612413325]=149, [1613811032]=249, [1609347878]=249, [1614668850]=149, [1605082468]=199 } -- TUS IDs y Precios

		local price = prices[passId] or 0
		if price > 0 then
			local current = player:GetAttribute("TotalRobuxSpent") or 0
			player:SetAttribute("TotalRobuxSpent", current + price)
		else
			-- API CORREGIDA Y BLINDADA (Async + pcall)
			task.spawn(function()
				local success, info = pcall(function()
					return MarketplaceService:GetProductInfoAsync(passId, Enum.InfoType.GamePass)
				end)

				if success and info and info.PriceInRobux then
					local current = player:GetAttribute("TotalRobuxSpent") or 0
					player:SetAttribute("TotalRobuxSpent", current + info.PriceInRobux)
					print("💸 Robux (GamePass) registrados: +" .. info.PriceInRobux)
				else
					warn("⚠️ Error obteniendo precio del GamePass: " .. tostring(passId))
				end
			end)
		end
	end
end)

local function hasPass(player, passId)
	-- 1. Revisar si está guardado en DataStore (Para Player1/Studio)
	if player:GetAttribute("PassOwned_" .. passId) == true then
		return true
	end

	-- 2. Revisar base de datos de Roblox (Normal)
	local success, has = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	return success and has
end

-- 8. Sumar Diamantes (Gameplay)
if AddDiamondEvent then
	AddDiamondEvent.OnServerEvent:Connect(function(player, amount)
		if type(amount) ~= "number" or amount <= 0 then return end

		-- Verificar GamePass x2 Gems
		if hasPass(player, PASS_IDS.Gems) then 
			amount = amount * 2 
		end

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Diamonds") then
			leaderstats.Diamonds.Value = leaderstats.Diamonds.Value + amount
		end
	end)
end

-- 9. Sumar Monedas (Gameplay)
if AddCurrencyEvent then
	AddCurrencyEvent.OnServerEvent:Connect(function(player, amount)
		if type(amount) ~= "number" or amount <= 0 then return end

		-- Verificar GamePass x2 Coins
		if hasPass(player, PASS_IDS.Coins) then 
			amount = amount * 2 
		end

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Coins") then
			leaderstats.Coins.Value = leaderstats.Coins.Value + amount
			local t = player:GetAttribute("TotalCoins") or 0
			player:SetAttribute("TotalCoins", t + amount)
		end
	end)
end

-- 10. Sumar XP (Gameplay)
local AddXPEvent = ReplicatedStorage:FindFirstChild("AddXP")
if not AddXPEvent then 
	AddXPEvent = Instance.new("RemoteEvent", ReplicatedStorage); AddXPEvent.Name = "AddXP" 
end

AddXPEvent.OnServerEvent:Connect(function(player, amount)
	if type(amount) ~= "number" or amount <= 0 then return end

	-- Verificar GamePass x2 XP
	if hasPass(player, PASS_IDS.XP) then 
		amount = amount * 2 
	end

	local currentXP = player:GetAttribute("CurrentXP") or 0
	local maxXP = player:GetAttribute("MaxXP") or 500
	local leaderstats = player:FindFirstChild("leaderstats")

	currentXP = currentXP + amount

	-- Level Up Logic
	if leaderstats and leaderstats:FindFirstChild("Level") then
		while currentXP >= maxXP do
			currentXP = currentXP - maxXP
			leaderstats.Level.Value += 1
			maxXP = leaderstats.Level.Value * 500
		end
	end
	player:SetAttribute("CurrentXP", currentXP)
	player:SetAttribute("MaxXP", maxXP)
end)

-- 11. Sumar Frutas (Que faltaba)
if AddFruitEvent then
	AddFruitEvent.OnServerEvent:Connect(function(player, amount)
		if type(amount) ~= "number" or amount <= 0 then return end

		-- Verificar GamePass x2 Fruits
		if hasPass(player, PASS_IDS.Fruits) then amount = amount * 2 end

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("FruitGems") then
			leaderstats.FruitGems.Value = leaderstats.FruitGems.Value + amount
			local t = player:GetAttribute("TotalFruitGems") or 0
			player:SetAttribute("TotalFruitGems", t + amount)
		end
	end)
end

-- ... (otros eventos arriba)

-- ✅ NUEVO EVENTO: GASTAR UNDO (OPTIMIZADO)
local UseUndoEvent = ReplicatedStorage:FindFirstChild("UseUndo")
if not UseUndoEvent then
	UseUndoEvent = Instance.new("RemoteEvent", ReplicatedStorage)
	UseUndoEvent.Name = "UseUndo"
end

UseUndoEvent.OnServerEvent:Connect(function(player)
	local current = player:GetAttribute("Undos") or 0
	if current > 0 then
		player:SetAttribute("Undos", current - 1)
		-- Sin print aquí para evitar spam cada vez que usan el botón
	end
end)

-- INICIAR
Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(savePlayerData)

-- CIERRE DEL SERVIDOR
game:BindToClose(function()
	print("⚠️ Cerrando servidor, guardando datos...")
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(function() savePlayerData(player) end)
	end
	task.wait(2)
end)

-- ==========================================
-- SISTEMA DE DAILY REWARDS (SERVER SIDE)
-- ==========================================

-- Crear evento remoto si no existe
local claimEvent = ReplicatedStorage:FindFirstChild("ClaimDaily")
if not claimEvent then
	claimEvent = Instance.new("RemoteEvent")
	claimEvent.Name = "ClaimDaily"
	claimEvent.Parent = ReplicatedStorage
end

-- Función para dar el premio
claimEvent.OnServerEvent:Connect(function(player)
	-- Verificar si ya reclamó hoy (Seguridad)
	if player:GetAttribute("DailyClaimed") == true then
		print(player.Name .. " intentó reclamar doble.")
		return
	end

	local currentStreak = player:GetAttribute("CurrentStreak") or 1
	-- Calculamos el día del ciclo (1-30)
	local day = ((currentStreak - 1) % 30) + 1 

	-- CÁLCULO DE RECOMPENSA (IGUAL QUE EL CLIENTE)
	local rewardAmt = day * 1500 -- Buff masivo
	local rewardType = "Coins"

	if day % 7 == 0 then rewardType = "Gems"; rewardAmt = day * 50 end
	if day == 30 then rewardType = "Skin"; rewardAmt = 1 end

	-- Bonus VIP (ID CORREGIDO: 1605082468)
	local hasVip = false
	-- Usamos el ID correcto del VIP, no el de XP
	pcall(function() hasVip = MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1605082468) end) 

	if hasVip and rewardType ~= "Skin" then 
		rewardAmt = rewardAmt * 2 
		print("?? VIP BONUS APLICADO (x2 Daily)")
	end

	-- ENTREGAR PREMIO
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if rewardType == "Coins" then
			ls.Coins.Value = ls.Coins.Value + rewardAmt
			player:SetAttribute("TotalCoins", (player:GetAttribute("TotalCoins") or 0) + rewardAmt)
		elseif rewardType == "Gems" then
			ls.Diamonds.Value = ls.Diamonds.Value + rewardAmt
		elseif rewardType == "Skin" then
			-- Aquí iría la lógica de dar skin (pendiente)
			print("Skin entregada (Lógica pendiente)")
		end
	end

	-- Marcar como reclamado hoy Y GUARDAR EL DÍA
	player:SetAttribute("DailyClaimed", true)
	player:SetAttribute("LastClaimedDay", math.floor(os.time() / 86400)) -- Guardamos que hoy ya cobró

	print("✅ " .. player.Name .. " reclamó Día " .. day .. ": " .. rewardAmt .. " " .. rewardType)
end)

-- RESETEAR ESTADO DIARIO AL ENTRAR
local function checkDailyReset(player, data)
	local lastLogin = data.LastLoginDay or 0
	local today = math.floor(os.time() / 86400)
	
	if lastLogin ~= today then
		player:SetAttribute("DailyClaimed", false)
	else
		player:SetAttribute("DailyClaimed", true)
	end
end

-- ? BUCLE DE ACTUALIZACIÓN DE LEADERBOARDS (EFICIENTE)
-- Guarda Score, Tiempo, Rachas y Robux de TODOS los jugadores cada 60 segundos.
task.spawn(function()
	while true do
		task.wait(60) -- Espera 1 minuto

		for _, p in pairs(Players:GetPlayers()) do
			pcall(function()
				local userId = p.UserId

				-- 1. SCORE (GlobalScore_V4)
				-- Solo actualizamos si el score actual es mayor al guardado
				if p:FindFirstChild("leaderstats") then
					local currentScore = p.leaderstats.HighScore.Value
					HighScoreStore:UpdateAsync(userId, function(old) 
						return math.max(tonumber(old) or 0, currentScore) 
					end)
				end

				-- 2. TIEMPO JUGADO (GlobalTime_V4)
				-- Calculamos el tiempo total real incluyendo la sesión actual
				local savedTime = p:GetAttribute("TimePlayedSaved") or 0
				local sessionTime = 0
				if sessionJoinTime[userId] then
					sessionTime = os.time() - sessionJoinTime[userId]
				end
				TimePlayedStore:SetAsync(userId, savedTime + sessionTime)

				-- 3. RACHAS (GlobalStreak_V4)
				local streak = p:GetAttribute("CurrentStreak") or 1
				StreakStore:SetAsync(userId, streak)

				-- 4. ROBUX GASTADOS
				local spent = p:GetAttribute("TotalRobuxSpent") or 0
				RobuxSpentStore:SetAsync(userId, spent)

				-- 5. NIVEL (GlobalLevel_V4)
				if p:FindFirstChild("leaderstats") then
					local lvl = p.leaderstats.Level.Value
					LevelStore:SetAsync(userId, lvl)
				end

				-- ✅ 6. SCORE 5x5 (GlobalScore5x5_V4) - ¡ESTO FALTABA!
				local s5 = p:GetAttribute("HighScore5x5") or 0
				Score5x5Store:SetAsync(userId, s5)
			end)
		end

		-- Opcional: Imprimir en consola para saber que ocurrió el ciclo
		-- print("🔄 Leaderboards globales actualizados.")
	end
end)
