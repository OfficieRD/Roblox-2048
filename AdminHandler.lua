--[[ 
    LISTA DE CÓDIGOS PARA DESBLOQUEAR TÍTULOS (ADMIN PANEL):
    (Copia el texto de la derecha y pégalo en el cuadro "Attribute Name")

    --- HIGH SCORE SEASON 1 ---
    Top 1 Score:    Title_S1_HS_1
    Top 2 Score:    Title_S1_HS_2
    Top 3 Score:    Title_S1_HS_3
    Top 10 Score:   Title_S1_HS_10
    Top 100 Score:  Title_S1_HS_100

    --- TIME PLAYED SEASON 1 ---
    Top 1 Time:     Title_S1_TM_1
    Top 2 Time:     Title_S1_TM_2
    Top 3 Time:     Title_S1_TM_3
    Top 10 Time:    Title_S1_TM_10
    Top 100 Time:   Title_S1_TM_100
]]
 	
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local AdminEvent = ReplicatedStorage:WaitForChild("AdminAction")
local DATASTORE_NAME = "2048_PlayerData_V4_Stats" -- Asegúrate de que coincida con tu DataHandler
local PlayerDataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

-- ?? PON TU NOMBRE AQUÍ
local ADMINS = {
	["OFFICIE_ROBLOX"] = true
}

AdminEvent.OnServerEvent:Connect(function(player, action, targetName, value)
	-- Seguridad: Verificar si es admin
	if not ADMINS[player.Name] then 
		warn(player.Name .. " intentó usar admin panel sin permiso.")
		return 
	end

	-- Encontrar jugador objetivo
	local targetPlayer
	if targetName == "" or targetName == "Me" or targetName == nil then
		targetPlayer = player
	else
		targetPlayer = Players:FindFirstChild(targetName)
	end

	if not targetPlayer then 
		warn("Admin: Jugador no encontrado - " .. tostring(targetName))
		return 
	end

	local leaderstats = targetPlayer:FindFirstChild("leaderstats")

	print("?? ADMIN ACTION:", action, "on", targetPlayer.Name, "val:", value)

	if action == "AddCoins" then
		if leaderstats then
			leaderstats.Coins.Value = leaderstats.Coins.Value + (tonumber(value) or 0)
			local current = targetPlayer:GetAttribute("TotalCoins") or 0
			targetPlayer:SetAttribute("TotalCoins", current + (tonumber(value) or 0))
		end

	elseif action == "AddDiamonds" then
		if leaderstats and leaderstats:FindFirstChild("Diamonds") then
			leaderstats.Diamonds.Value = leaderstats.Diamonds.Value + (tonumber(value) or 0)
		end

	elseif action == "SetScore" then -- ASEGURAMOS QUE ESTÉ AQUÍ
		if leaderstats then
			leaderstats.HighScore.Value = (tonumber(value) or 0)
		end

	elseif action == "AddFruits" then
		if leaderstats and leaderstats:FindFirstChild("FruitGems") then
			local amount = tonumber(value) or 0
			leaderstats.FruitGems.Value = leaderstats.FruitGems.Value + amount
			-- IMPORTANTE: Actualizar el histórico para los títulos
			local currentTotal = targetPlayer:GetAttribute("TotalFruitGems") or 0
			targetPlayer:SetAttribute("TotalFruitGems", currentTotal + amount)
		end

		-- ? NUEVO: LÓGICA PARA "SET LEVEL" (Esto faltaba)
	elseif action == "SetLevel" then
		if leaderstats then
			local newLvl = tonumber(value) or 1
			leaderstats.Level.Value = newLvl

			-- Ajustar la XP Máxima para que la barra no se rompa visualmente
			targetPlayer:SetAttribute("CurrentXP", 0) 
			targetPlayer:SetAttribute("MaxXP", newLvl * 500) 

			print("?? Admin: Nivel cambiado a " .. newLvl .. " para " .. targetPlayer.Name)
		end

	elseif action == "ResetLevel" then
		if leaderstats then
			leaderstats.Level.Value = 1
			targetPlayer:SetAttribute("CurrentXP", 0)
			targetPlayer:SetAttribute("MaxXP", 500) 
			print("?? Nivel reseteado a 1 para " .. targetPlayer.Name)
		end

		-- ? NUEVO: CONTROL DE RACHAS
	elseif action == "SetStreak" then
		local days = tonumber(value) or 1
		targetPlayer:SetAttribute("CurrentStreak", days)
		-- Ajustamos el "LastLoginDay" a hoy para que no se rompa sola mañana
		targetPlayer:SetAttribute("LastLoginDay", math.floor(os.time() / 86400))
		print("?? Racha establecida a " .. days .. " días para " .. targetPlayer.Name)

	elseif action == "BreakStreak" then
		-- Para romper la racha, ponemos el último login en el año 2000
		targetPlayer:SetAttribute("LastLoginDay", 0)
		print("?? Racha ROTA para " .. targetPlayer.Name .. " (Simulando inactividad)")

	elseif action == "GiveAttribute" then
		-- ESTA ES LA FUNCIÓN PARA DAR TÍTULOS DE SEASON
		-- value debe ser el nombre del atributo, ej: "Title_S1_HS_1"
		if value and value ~= "" then
			targetPlayer:SetAttribute(value, true)
			print("? Atributo otorgado: " .. value)

			-- Feedback visual simple (opcional, enviamos mensaje al chat del target)
			-- Esto es solo para que sepas que funcionó
			-- Feedback visual simple
		end

	elseif action == "UnlockAllTitles" then
		print("?? Desbloqueando TODOS los títulos para: " .. targetPlayer.Name)

		-- 1. Lista de Atributos de Season 1
		local allAttributes = {
			"Title_S1_HS_1", "Title_S1_HS_2", "Title_S1_HS_3", "Title_S1_HS_10", "Title_S1_HS_100",
			"Title_S1_TM_1", "Title_S1_TM_2", "Title_S1_TM_3", "Title_S1_TM_10", "Title_S1_TM_100"
		}

		-- Dar todos los atributos de Season
		for _, attr in ipairs(allAttributes) do
			targetPlayer:SetAttribute(attr, true)
		end

		-- 2. Dar Skin "Fruit Mix" (Para título Tutti Frutti)
		targetPlayer:SetAttribute("OwnedSkin_FruitMix", true)

		-- 3. Dar Gemas Totales (Para título Golden Orchard - requiere 10k)
		-- Solo subimos el histórico, no las monedas gastables actuales
		local currentGems = targetPlayer:GetAttribute("TotalFruitGems") or 0
		if currentGems < 10000 then
			targetPlayer:SetAttribute("TotalFruitGems", 10000)
		end

		-- 4. Setear High Score suficiente (Para título Hacker - requiere 16384)
		if leaderstats then
			if leaderstats.HighScore.Value < 16384 then
				leaderstats.HighScore.Value = 16384
			end
		end

	elseif action == "Reset" then
		if leaderstats then
			leaderstats.Coins.Value = 0
			leaderstats.HighScore.Value = 0
			leaderstats.Level.Value = 1 -- Resetear nivel también
			if leaderstats:FindFirstChild("FruitGems") then leaderstats.FruitGems.Value = 0 end
			if leaderstats:FindFirstChild("Diamonds") then leaderstats.Diamonds.Value = 0 end
		end

		-- Resetear Skins y Atributos
		local attributes = targetPlayer:GetAttributes()
		for name, _ in pairs(attributes) do
			if string.find(name, "OwnedSkin_") or string.find(name, "Title_") or string.find(name, "ClaimedLevel") then
				targetPlayer:SetAttribute(name, nil) 
			end
		end

		targetPlayer:SetAttribute("GamesPlayed", 0)
		targetPlayer:SetAttribute("TotalCoins", 0)
		targetPlayer:SetAttribute("TotalFruitGems", 0)
		targetPlayer:SetAttribute("CurrentXP", 0)
		targetPlayer:SetAttribute("MaxXP", 500)
		targetPlayer:SetAttribute("OwnedSkin_Classic", true)

		-- ? BORRADO TOTAL DE DATASTORES (Incluyendo Leaderboards)
		pcall(function()
			PlayerDataStore:RemoveAsync(targetPlayer.UserId)
			-- Borrar del Leaderboard de Puntos
			local HighScoreStore = DataStoreService:GetOrderedDataStore("GlobalScore_V4")
			HighScoreStore:RemoveAsync(targetPlayer.UserId)
			-- Borrar del Leaderboard de Tiempo
			local TimePlayedStore = DataStoreService:GetOrderedDataStore("GlobalTime_V4")
			TimePlayedStore:RemoveAsync(targetPlayer.UserId)
		end)

		print("?? RESET COMPLETO (Data + Leaderboards) PARA: " .. targetPlayer.Name)
	end
end)

