local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService") -- ? ARREGLADO: Faltaba esta línea

local MarketplaceService = game:GetService("MarketplaceService")

-- ? PEGAR AQUÍ LA TABLA PARA QUE FUNCIONE LA DETECCIÓN
local GAMEPASS_DATA = {
	{Id = 1612413325, Price = 149, Name = "x2 Coins"},
	{Id = 1613811032, Price = 249, Name = "x2 Gems"},
	{Id = 1609347878, Price = 249, Name = "x2 XP"},
	{Id = 1614668850, Price = 149, Name = "x2 Fruits"},
	{Id = 1605082468, Price = 199, Name = "VIP"}
}

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

local EquipSkinEvent = ReplicatedStorage:FindFirstChild("EquipSkin")
if not EquipSkinEvent then
	EquipSkinEvent = Instance.new("RemoteEvent")
	EquipSkinEvent.Name = "EquipSkin"
	EquipSkinEvent.Parent = ReplicatedStorage
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
-- ? NUEVAS CLAVES
local LEADERBOARD_KEY_LEVEL = "GlobalLevel_V4"
local LEADERBOARD_KEY_5X5 = "GlobalScore5x5_V4"

local HighScoreStore = DataStoreService:GetOrderedDataStore(LEADERBOARD_KEY_SCORE)
local TimePlayedStore = DataStoreService:GetOrderedDataStore(LEADERBOARD_KEY_TIME)
local StreakStore = DataStoreService:GetOrderedDataStore(LEADERBOARD_KEY_STREAK)
local RobuxSpentStore = DataStoreService:GetOrderedDataStore(LEADERBOARD_KEY_SPENT)
-- ? NUEVAS STORES
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
	-- FUNCIÓN DE GUARDADO (CORREGIDA Y CON DEBUG)
	-------------------------------------------------------------------------
	local function savePlayerData(player)
		if not player:FindFirstChild("leaderstats") then return end

		-- Evitar guardar dos veces
		if player:GetAttribute("DataSaved") then return end
		player:SetAttribute("DataSaved", true)

		print("?? Intentando guardar datos de: " .. player.Name)

		local leaderstats = player.leaderstats
		local sessionTime = os.time() - (sessionJoinTime[player.UserId] or os.time())
		local totalTime = (player:GetAttribute("TimePlayedSaved") or 0) + sessionTime

		-- 1. Recolectar Skins Compradas
		local ownedSkins = {}
		for name, _ in pairs(ITEM_PRICES) do
			local safeName = string.gsub(name, " ", "")
			if player:GetAttribute("OwnedSkin_" .. safeName) == true then table.insert(ownedSkins, name) end
		end

		-- 2. Recolectar GamePasses
		local savedPasses = {}
		for attrName, val in pairs(player:GetAttributes()) do
			if string.sub(attrName, 1, 10) == "PassOwned_" and val == true then
				local id = tonumber(string.sub(attrName, 11))
				if id then table.insert(savedPasses, id) end
			end
		end

	-- 3. DETECTAR SKIN ACTUAL (BLINDADO)
	-- Si el jugador tiene "CurrentSkin", ESE es el que vale.
	local current = player:GetAttribute("CurrentSkin")

	-- Validación extra: Si es nil o string vacío, intentamos recuperar el guardado anterior
	local skinToSave = (current and current ~= "") and current or player:GetAttribute("EquippedSkin") or "Classic"

		-- 4. DATOS A GUARDAR
		local data = {
			SavedGamePasses = savedPasses,

			-- Cosméticos
			EquippedSkin = skinToSave, -- Aquí guardamos el valor correcto
			EquippedTitle = player:GetAttribute("EquippedTitle") or "Novice",
			OwnedSkins = ownedSkins,

			-- Settings
			Setting_Music = player:GetAttribute("SavedVolMusic"),
			Setting_SFX = player:GetAttribute("SavedVolSFX"),
			Setting_DarkMode = player:GetAttribute("SavedDarkMode"),
			Setting_ShowXP = player:GetAttribute("SavedShowXP"),

			-- Estadísticas
			Coins = leaderstats.Coins.Value,
			FruitGems = leaderstats.FruitGems.Value,
			Diamonds = leaderstats.Diamonds.Value,
			HighScore = leaderstats.HighScore.Value,
			Level = leaderstats.Level.Value,

			-- Acumulados
			CurrentXP = player:GetAttribute("CurrentXP"),
			TotalFruitGems = player:GetAttribute("TotalFruitGems"),
			TotalCoins = player:GetAttribute("TotalCoins"),
			TotalRobuxSpent = player:GetAttribute("TotalRobuxSpent"),
			GamesPlayed = player:GetAttribute("GamesPlayed"),
			TimePlayed = totalTime,
			HighScore5x5 = player:GetAttribute("HighScore5x5"),
			Undos = player:GetAttribute("Undos"),

			-- Daily
			CurrentStreak = player:GetAttribute("CurrentStreak") or 1,
			LastLoginDay = player:GetAttribute("LastLoginDay") or 0,
			LastClaimedDay = player:GetAttribute("LastClaimedDay") or 0,

			-- Listas
			ClaimedLevelRewards = (function()
				local t = {}
				for i=1,50 do if player:GetAttribute("ClaimedLevelReward_"..i) then table.insert(t,i) end end
				return t
			end)(),

			UnlockedTitles = (function()
				local t = {}
				for n,v in pairs(player:GetAttributes()) do if string.sub(n,1,6)=="Title_" and v then table.insert(t,n) end end
				return t
			end)(),

			RedeemedCodes = (function()
				local t = {}
				for n,v in pairs(player:GetAttributes()) do if string.sub(n,1,13)=="CodeRedeemed_" and v then table.insert(t,n) end end
				return t
			end)(),
		}

		-- 5. INTENTO DE GUARDADO
		local success, err
		for i = 1, 3 do
			success, err = pcall(function()
				PlayerDataStore:SetAsync(player.UserId, data)
			end)
			if success then 
				break 
			end
			task.wait(1)
		end

		-- Actualizar Leaderboards (Sin cambios aquí)
		pcall(function()
			HighScoreStore:UpdateAsync(player.UserId, function(o) return math.max(tonumber(o)or 0, leaderstats.HighScore.Value) end)
			TimePlayedStore:UpdateAsync(player.UserId, function(o) return math.max(tonumber(o)or 0, totalTime) end)
			StreakStore:UpdateAsync(player.UserId, function(o) return player:GetAttribute("CurrentStreak") or 0 end)
		end)
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

		-- ? CARGAR COSMÉTICOS (Versión Final Blindada)
		-- Leemos EquippedSkin (donde guardamos al salir) o CurrentSkin (respaldo)
		local loadedSkin = data.EquippedSkin or data.CurrentSkin or "Classic"

		-- TRUCO: Seteamos a nil primero para forzar el evento de cambio si ya estaba puesto
		player:SetAttribute("CurrentSkin", nil) 
		task.wait() -- Pequeña pausa técnica
		player:SetAttribute("CurrentSkin", loadedSkin)

		-- También actualizamos EquippedSkin para mantener coherencia interna
		player:SetAttribute("EquippedSkin", loadedSkin)

		player:SetAttribute("EquippedTitle", data.EquippedTitle or "Novice")

		-- 2. CARGAR SETTINGS (NOMBRES CORREGIDOS)
		-- Usamos los nombres nuevos (Setting_...) y si no existen, probamos los viejos por compatibilidad
		player:SetAttribute("SavedVolMusic", data.Setting_Music or data.VolMusic or 0.5)
		player:SetAttribute("SavedVolSFX", data.Setting_SFX or data.VolSFX or 0.5)

		-- Para el modo oscuro, cuidado con el 'false', usamos nil check
		if data.Setting_DarkMode ~= nil then
			player:SetAttribute("SavedDarkMode", data.Setting_DarkMode)
		elseif data.IsDarkMode ~= nil then
			player:SetAttribute("SavedDarkMode", data.IsDarkMode)
		else
			player:SetAttribute("SavedDarkMode", false) -- Default apagado
		end

		-- 3. CARGAR SHOW XP
		if data.Setting_ShowXP ~= nil then
			player:SetAttribute("SavedShowXP", data.Setting_ShowXP)
		else
			player:SetAttribute("SavedShowXP", true) -- Default encendido
		end

		

		player:SetAttribute("CurrentXP", data.CurrentXP or 0)
		player:SetAttribute("MaxXP", (data.Level or 1) * 1500) -- Dificultad x3
		player:SetAttribute("TotalFruitGems", data.TotalFruitGems or 0)
		player:SetAttribute("TotalCoins", data.TotalCoins or 0)

		-- ? CORRECCIÓN: Migración de Diamantes
		-- Si el jugador ya tiene diamantes (data.Diamonds) pero el Total es 0 o nil,
		-- igualamos el Total a los actuales para no perder el historial.
		local savedTotal = data.TotalDiamonds or 0
		local currentDiamonds = data.Diamonds or 0

		if savedTotal < currentDiamonds then
			savedTotal = currentDiamonds
		end
		player:SetAttribute("TotalDiamonds", savedTotal)

		player:SetAttribute("TotalRobuxSpent", data.TotalRobuxSpent or 0)
		player:SetAttribute("GamesPlayed", data.GamesPlayed or 0)
		player:SetAttribute("TimePlayedSaved", data.TimePlayed or 0)
		player:SetAttribute("HighScore5x5", data.HighScore5x5 or 0)
		player:SetAttribute("Undos", data.Undos or 0)

		-- ? LÓGICA DE RECOMPENSA DIARIA
		if not player:GetAttribute("CurrentStreak") then
			player:SetAttribute("CurrentStreak", data.CurrentStreak or 1)
		end

		local ownedSkins = data.OwnedSkins or {"Classic"}
		for _, skinName in ipairs(ownedSkins) do
			local safeName = string.gsub(skinName, " ", "")
			player:SetAttribute("OwnedSkin_" .. safeName, true)
		end

		-- ? NUEVO: CARGAR TÍTULOS
		if data.UnlockedTitles then
			for _, titleAttr in pairs(data.UnlockedTitles) do player:SetAttribute(titleAttr, true) end
		end

		-- ? CARGAR CÓDIGOS CANJEADOS
		if data.RedeemedCodes then
			for _, codeAttr in pairs(data.RedeemedCodes) do player:SetAttribute(codeAttr, true) end
		end

		-- ? CARGAR GAMEPASSES GUARDADOS
		if data.SavedGamePasses then
			for _, passId in ipairs(data.SavedGamePasses) do
				player:SetAttribute("PassOwned_" .. passId, true)
			end
		end

		-- ? [NUEVO] VERIFICACIÓN DE COMPRAS EXTERNAS (WEB/APP)
		task.spawn(function()
			for _, passInfo in ipairs(GAMEPASS_DATA) do
				-- Solo verificamos si el juego NO sabe que lo tiene
				if not player:GetAttribute("PassOwned_" .. passInfo.Id) then
					local success, owns = pcall(function()
						return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passInfo.Id)
					end)

					if success and owns then
						-- ¡Lo compró fuera del juego!
						print("? Compra externa detectada: " .. passInfo.Name .. " (" .. player.Name .. ")")

						-- 1. Marcar como poseído
						player:SetAttribute("PassOwned_" .. passInfo.Id, true)

						-- 2. Sumar al Total Robux Spent (Retroactivo)
						local currentSpent = player:GetAttribute("TotalRobuxSpent") or 0
						player:SetAttribute("TotalRobuxSpent", currentSpent + passInfo.Price)
					end
				end
				task.wait(0.1) -- Pequeña pausa para no saturar
			end
		end)

		local claimedRewards = data.ClaimedLevelRewards or {}

		local claimedRewards = data.ClaimedLevelRewards or {}
		for _, levelId in ipairs(claimedRewards) do
			player:SetAttribute("ClaimedLevelReward_" .. levelId, true)
		end

		-- 2. CARGAR SETTINGS (CORREGIDO)
		-- Intentamos leer el nombre nuevo (Setting_...) y si no está, el viejo
		player:SetAttribute("SavedVolMusic", data.Setting_Music or data.VolMusic or 0.5)
		player:SetAttribute("SavedVolSFX", data.Setting_SFX or data.VolSFX or 0.5)

		-- Lógica robusta para el Modo Oscuro
		if data.Setting_DarkMode ~= nil then
			player:SetAttribute("SavedDarkMode", data.Setting_DarkMode)
		elseif data.IsDarkMode ~= nil then
			player:SetAttribute("SavedDarkMode", data.IsDarkMode)
		else
			player:SetAttribute("SavedDarkMode", false) -- Default apagado
		end

		-- 3. CARGAR XP (Corregido el nombre de la variable: Setting_ShowXP)
		-- Si data.Setting_ShowXP es nil, es usuario nuevo -> true.
		if data.Setting_ShowXP == nil then
			player:SetAttribute("SavedShowXP", true)
		else
			player:SetAttribute("SavedShowXP", data.Setting_ShowXP)
		end
	else
		-- DEFAULT SETTINGS
		levelValue.Value = 1
		player:SetAttribute("MaxXP", 500)
		player:SetAttribute("OwnedSkin_Classic", true)
		player:SetAttribute("SavedVolMusic", 0.5)
		player:SetAttribute("SavedVolSFX", 0.5)
		player:SetAttribute("SavedDarkMode", false)

		-- ? CORRECCIÓN IMPORTANTE: INICIALIZAR RACHA
		-- Si no ponemos esto, al guardar será nil/0 y se reiniciará siempre
		local today = math.floor(os.time() / 86400)
		player:SetAttribute("CurrentStreak", 1)
		player:SetAttribute("LastLoginDay", today)
		player:SetAttribute("DailyClaimed", false) -- Para que pueda reclamar el día 1
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

			-- ?? LÓGICA VIP (15% DE DESCUENTO)
			local hasVip = player:GetAttribute("PassOwned_1605082468") == true -- Check rápido

			local finalPrice = basePrice
			if hasVip and basePrice > 0 then
				finalPrice = math.floor(basePrice * 0.85)
			end

			local currencyStore = leaderstats:FindFirstChild(currency)

			-- Verificar dinero y cobrar
			if currencyStore and currencyStore.Value >= finalPrice then
				currencyStore.Value = currencyStore.Value - finalPrice
				player:SetAttribute("OwnedSkin_" .. safeName, true)
				print("? Compra exitosa: " .. itemName)
			else
				warn("? No tienes dinero suficiente.")
			end
		end
	end)
end

-- ? EVENTO EQUIPAR SKIN (DEBUGGING)
local EquipSkinEvent = ReplicatedStorage:FindFirstChild("EquipSkin")
if not EquipSkinEvent then
	EquipSkinEvent = Instance.new("RemoteEvent")
	EquipSkinEvent.Name = "EquipSkin"
	EquipSkinEvent.Parent = ReplicatedStorage
end

EquipSkinEvent.OnServerEvent:Connect(function(player, skinName)
	local safeName = string.gsub(skinName, " ", "")
	-- Validar propiedad
	if skinName == "Classic" or player:GetAttribute("OwnedSkin_" .. safeName) == true then
		-- ACTUALIZAR AMBOS (Para visualización Y guardado)
		player:SetAttribute("CurrentSkin", skinName)  -- Lo ve el Cliente
		player:SetAttribute("EquippedSkin", skinName) -- Lo usa el Guardado

		print("? SERVER: Skin cambiada a " .. skinName)
	else
		warn("? SERVER: Intento de equipar skin no comprada: " .. skinName)
	end
end)

-- 4. Guardar Configuración (BLINDADO)
if SaveSettingsEvent then
	SaveSettingsEvent.OnServerEvent:Connect(function(player, settingName, value)
		-- Convertimos a string y forzamos el guardado
		local sName = tostring(settingName)

		-- Filtro inteligente: Si el nombre contiene "VolMusic", guardamos "SavedVolMusic"
		if string.find(sName, "VolMusic") then
			player:SetAttribute("SavedVolMusic", value)
		elseif string.find(sName, "VolSFX") then
			player:SetAttribute("SavedVolSFX", value)
		elseif string.find(sName, "DarkMode") then
			player:SetAttribute("SavedDarkMode", value)
		elseif string.find(sName, "ShowXP") then
			player:SetAttribute("SavedShowXP", value)
		end
	end)
end

-- 4. Guardar Score (SEPARADO: NORMAL vs 5x5)
if SaveScoreEvent then
	SaveScoreEvent.OnServerEvent:Connect(function(player, newScore, boardSize)
		-- Verificación de tipo estricta para el editor
		if type(newScore) ~= "number" then return end

		local finalScore = newScore 
		local bSize = boardSize or 4 
		local leaderstats = player:FindFirstChild("leaderstats")

		-- Contar partida jugada
		local gp = player:GetAttribute("GamesPlayed") or 0
		player:SetAttribute("GamesPlayed", gp + 1)

		if bSize == 5 then
			-- === LÓGICA 5x5 ===
			local current5x5 = player:GetAttribute("HighScore5x5") or 0
			if finalScore > current5x5 then
				player:SetAttribute("HighScore5x5", finalScore)

				pcall(function()
					Score5x5Store:UpdateAsync(tostring(player.UserId), function(old) 
						local oldVal = tonumber(old) or 0
						local newVal = tonumber(finalScore) or 0 -- Forzamos conversión dentro

						if newVal > oldVal then
							return newVal
						else
							return oldVal
						end
					end)
				end)
			end

		else
			-- === LÓGICA CLÁSICA (4x4) ===
			if leaderstats and finalScore > leaderstats.HighScore.Value then
				leaderstats.HighScore.Value = finalScore

				pcall(function()
					HighScoreStore:UpdateAsync(tostring(player.UserId), function(old) 
						local oldVal = tonumber(old) or 0
						local newVal = tonumber(finalScore) or 0 -- Forzamos conversión dentro

						if newVal > oldVal then
							return newVal
						else
							return oldVal
						end
					end)
				end)
			end
		end
	end)
end

-- 5. Reclamar Nivel
if ClaimLevelRewardEvent then
	ClaimLevelRewardEvent.OnServerEvent:Connect(function(player, levelId)
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end
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

-- 6. Leaderboard Request
if GetTopScoresFunc then
	GetTopScoresFunc.OnServerInvoke = function(player, category)
		local store = HighScoreStore -- Default

		-- ? CORRECCIÓN: Usamos las variables correctas (Store) y revisamos el espacio en el nombre
		if category == "TimePlayed" or category == "Time Played" then 
			store = TimePlayedStore 
		elseif category == "Streaks" then 
			store = StreakStore
		elseif category == "RobuxSpent" or category == "Robux Spent" then -- Aceptamos con y sin espacio
			store = RobuxSpentStore -- ? AQUÍ ESTABA EL ERROR (Antes decía ODS)
		elseif category == "Level" then 
			store = LevelStore
		elseif category == "Score5x5" or category == "5x5 Score" then 
			store = Score5x5Store
		end

		local topScores = {}
		local success, pages = pcall(store.GetSortedAsync, store, false, 50)
		if success and pages then
			local rank = 1
			for _, entry in ipairs(pages:GetCurrentPage()) do
				local name = "[Error]"
				pcall(function() name = Players:GetNameFromUserIdAsync(entry.key) end)

				local userIdNum = tonumber(entry.key) or 0

				-- Filtro para ocultar errores y al dueño
				if name ~= "[Error]" and name ~= "OFFICIE_ROBLOX" and userIdNum > 0 then
					table.insert(topScores, {name = name, value = entry.value, rank = rank, userId = entry.key})
					rank = rank + 1
				end
			end
		end
		return topScores
	end
end

-- 7. Stats Request
if GetStatsFunc then
	GetStatsFunc.OnServerInvoke = function(player)
		local sessionTime = os.time() - (sessionJoinTime[player.UserId] or os.time())
		local totalTime = (player:GetAttribute("TimePlayedSaved") or 0) + sessionTime

		return {
			GamesPlayed = player:GetAttribute("GamesPlayed") or 0,
			TimePlayed = totalTime,
			TotalCoins = player:GetAttribute("TotalCoins") or 0,
			TotalDiamonds = player:GetAttribute("TotalDiamonds") or 0, -- ¡AGREGADO!
			TotalFruitGems = player:GetAttribute("TotalFruitGems") or 0,
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
-- Agregamos los precios para poder sumar al "Total Spent" si lo compran desde la web
local GAMEPASS_DATA = {
	{Id = 1612413325, Price = 149, Name = "x2 Coins"},
	{Id = 1613811032, Price = 249, Name = "x2 Gems"},
	{Id = 1609347878, Price = 249, Name = "x2 XP"},
	{Id = 1614668850, Price = 149, Name = "x2 Fruits"},
	{Id = 1605082468, Price = 199, Name = "VIP"}
}

-- Mantenemos referencia rápida para el gameplay
local PASS_IDS = {
	Coins = 1612413325,
	Gems = 1613811032,
	XP = 1609347878,
	Fruits = 1614668850,
	VIP = 1605082468
}

-- Detectar compra en el SERVIDOR para activarlo al instante
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if wasPurchased then
		print("?? SERVER: Compra detectada ID: " .. passId .. " para " .. player.Name)

		-- ? MARCAR PARA GUARDAR (Atributo permanente)
		player:SetAttribute("PassOwned_" .. passId, true)

		-- ? NUEVO: REGISTRAR GASTO DE ROBUX (GAMEPASS)
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
					print("?? Robux (GamePass) registrados: +" .. info.PriceInRobux)
				else
					warn("?? Error obteniendo precio del GamePass: " .. tostring(passId))
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

			-- ? NUEVO: Actualizar el Total Histórico en tiempo real
			local t = player:GetAttribute("TotalDiamonds") or 0
			player:SetAttribute("TotalDiamonds", t + amount)
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
			maxXP = leaderstats.Level.Value * 1500 -- Dificultad x3
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

-- ? 12. SISTEMA DE CÓDIGOS ACTUALIZADO
local RedeemCodeEvent = ReplicatedStorage:FindFirstChild("RedeemCode")
if not RedeemCodeEvent then RedeemCodeEvent = Instance.new("RemoteEvent", ReplicatedStorage); RedeemCodeEvent.Name = "RedeemCode" end

-- Tabla configurada para aceptar múltiples premios por código
local ACTIVE_CODES = {
	["START2025"] = {
		Rewards = { {Type="Coins", Amt=500} }
	},
	["RELEASE"] = { -- Reemplaza a POWERRANGERS
		Rewards = { {Type="Coins", Amt=1000}, {Type="Diamonds", Amt=10} }
	},
	["VIP2048"] = {
		Rewards = { {Type="Coins", Amt=2000}, {Type="Diamonds", Amt=50} }
	},
	["WELCOME"] = {
		Rewards = { {Type="Coins", Amt=1000} }
	},
	["FRUITS"] = {
		Rewards = { {Type="FruitGems", Amt=500} }
	}
	-- Eliminados LIKE y FAVORITE para evitar confusión
}

RedeemCodeEvent.OnServerEvent:Connect(function(player, code)
	code = string.upper(code) -- Convertir a mayúsculas
	local codeData = ACTIVE_CODES[code]

	if not codeData then return end -- Código inválido
	if player:GetAttribute("CodeRedeemed_" .. code) == true then return end -- Ya usado

	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	
	-- Mensaje de lo que ganó (Para consola o futuro UI)
	local rewardsText = ""

	-- Procesar TODOS los premios del código
	for _, reward in pairs(codeData.Rewards) do
		if reward.Type == "Coins" then
			ls.Coins.Value += reward.Amt
			player:SetAttribute("TotalCoins", (player:GetAttribute("TotalCoins")or 0) + reward.Amt)
			rewardsText = rewardsText .. "+" .. reward.Amt .. " Coins "
			
		elseif reward.Type == "Diamonds" then
			ls.Diamonds.Value += reward.Amt
			
			rewardsText = rewardsText .. "+" .. reward.Amt .. " Diamonds "
			
		elseif reward.Type == "FruitGems" then
			ls.FruitGems.Value += reward.Amt
			player:SetAttribute("TotalFruitGems", (player:GetAttribute("TotalFruitGems")or 0) + reward.Amt)
			rewardsText = rewardsText .. "+" .. reward.Amt .. " Fruits "
		end
	end

	-- Marcar como usado y guardar
	player:SetAttribute("CodeRedeemed_" .. code, true)
	print("? Código canjeado: " .. code .. " | Premios: " .. rewardsText)
	
	-- NOTA: Para que salga el texto "+2000 Coins" en la pantalla del jugador, 
	-- necesitarías editar el script LOCAL (Client) que envía el código, ya que el servidor 
	-- no controla la UI directamente. Pero con este cambio, los premios se suman correctamente.
end)

-- ? NUEVO EVENTO: GASTAR UNDO (OPTIMIZADO)
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
	print("?? Cerrando servidor, guardando datos...")
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

	print("? " .. player.Name .. " reclamó Día " .. day .. ": " .. rewardAmt .. " " .. rewardType)
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

				-- ? 6. SCORE 5x5 (GlobalScore5x5_V4) - ¡ESTO FALTABA!
				local s5 = p:GetAttribute("HighScore5x5") or 0
				Score5x5Store:SetAsync(userId, s5)
			end)
		end

		-- Opcional: Imprimir en consola para saber que ocurrió el ciclo
		-- print("?? Leaderboards globales actualizados.")
	end
end)