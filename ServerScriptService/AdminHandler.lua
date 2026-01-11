
 	
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

-- FUNCIÓN CORREGIDA PARA DAR TODOS LOS TÍTULOS
local function GiveAllTitles(player)
	-- Forzamos la carga del módulo actualizado
	local GameData = require(game.ReplicatedStorage:WaitForChild("GameData"))

	local function checkIsUnlocked(data)
		-- 0. CHEQUEO ADMIN (CORREGIDO: SIN ESPACIOS)
		local safeName = string.gsub(data.Name, " ", "")
		if player:GetAttribute("Title_" .. safeName) == true then
			return true
		end
	end
end

-- CONECTA ESTA FUNCIÓN A TU BOTÓN O EVENTO DEL ADMIN PANEL
-- Ejemplo:
-- AdminEvent.OnServerEvent:Connect(function(player, action)
--     if action == "GiveAllTitles" then
--         GiveAllTitles(player)
--     end
-- end)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local AdminEvent = ReplicatedStorage:WaitForChild("AdminAction")
local DATASTORE_NAME = "2048_PlayerData_V4_Stats" 
local PlayerDataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

-- REFERENCIAS A LEADERBOARDS (Para forzar actualización)
local StreakStore = DataStoreService:GetOrderedDataStore("GlobalStreak_V4")
local HighScoreStore = DataStoreService:GetOrderedDataStore("GlobalScore_V4")
local Score5x5Store = DataStoreService:GetOrderedDataStore("GlobalScore5x5_V4") -- ? ESTA ES LA QUE FALTABA


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
			local amount = tonumber(value) or 0
			leaderstats.Diamonds.Value = leaderstats.Diamonds.Value + amount

			-- ? NUEVO: Sumar al histórico (Admin)
			local current = targetPlayer:GetAttribute("TotalDiamonds") or 0
			targetPlayer:SetAttribute("TotalDiamonds", current + amount)
		end

	elseif action == "SetScore" then
		if leaderstats then
			local newScore = tonumber(value) or 0
			leaderstats.HighScore.Value = newScore

			-- ? FORZAR ACTUALIZACIÓN EN LEADERBOARD (SetAsync sobrescribe lo que sea)
			task.spawn(function()
				pcall(function()
					HighScoreStore:SetAsync(targetPlayer.UserId, newScore)
				end)
			end)
			print("?? Score forzado a " .. newScore .. " en Leaderboard para " .. targetPlayer.Name)
		end
		-- ... (fin del bloque SetScore normal)

		-- ? NUEVO COMANDO: SET SCORE 5x5
	elseif action == "SetScore5x5" then
		local newScore = tonumber(value) or 0

		-- 1. Guardar en el atributo del jugador
		targetPlayer:SetAttribute("HighScore5x5", newScore)

		-- 2. Forzar actualización inmediata en Leaderboard
		task.spawn(function()
			pcall(function()
				Score5x5Store:SetAsync(targetPlayer.UserId, newScore)
			end)
		end)
		print("?? 5x5 Score forzado a " .. newScore .. " para " .. targetPlayer.Name)

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
			targetPlayer:SetAttribute("MaxXP", newLvl * 1500) -- ? CORREGIDO: Multiplicador x1500 (Dificultad x3)

			print("?? Admin: Nivel cambiado a " .. newLvl .. " para " .. targetPlayer.Name)
		end

	elseif action == "ResetLevel" then
		if leaderstats then
			leaderstats.Level.Value = 1
			targetPlayer:SetAttribute("CurrentXP", 0)
			targetPlayer:SetAttribute("MaxXP", 1500) -- ? CORREGIDO: Base x1500
			print("?? Nivel reseteado a 1 para " .. targetPlayer.Name)
		end

		-- ? CONTROL DE RACHAS (Con actualización inmediata de Leaderboard)
	elseif action == "SetStreak" then
		local days = tonumber(value) or 1
		targetPlayer:SetAttribute("CurrentStreak", days)
		-- Ajustamos el "LastLoginDay" a hoy para que no se rompa sola mañana
		targetPlayer:SetAttribute("LastLoginDay", math.floor(os.time() / 86400))

		-- ? FORZAR ACTUALIZACIÓN EN LEADERBOARD AHORA MISMO
		task.spawn(function()
			pcall(function()
				StreakStore:UpdateAsync(targetPlayer.UserId, function()
					return days
				end)
			end)
		end)

		print("?? Racha establecida a " .. days .. " días para " .. targetPlayer.Name .. " (Leaderboard actualizado)")

	elseif action == "BreakStreak" then
		-- Para romper la racha, ponemos el último login en el año 2000
		targetPlayer:SetAttribute("LastLoginDay", 0)
		print("?? Racha ROTA para " .. targetPlayer.Name .. " (Simulando inactividad)")

	elseif action == "GiveAttribute" then
		-- ESTA ES LA FUNCIÓN PARA DAR CUALQUIER ATRIBUTO MANUALMENTE
		if value and value ~= "" then
			targetPlayer:SetAttribute(value, true)
			print("? Atributo otorgado: " .. value)
		end

	elseif action == "GiveTitle" then
		-- NUEVA FUNCIÓN INTELIGENTE: Busca el título por nombre
		local titleName = value -- Ej: "Tester", "Novice"
		local foundData = nil

		-- Buscar en la tabla de títulos
		local success, GameData = pcall(function() return require(ReplicatedStorage:WaitForChild("GameData")) end)
		if success and GameData.TITLES_DATA then
			for _, data in ipairs(GameData.TITLES_DATA) do
				if string.lower(data.Name) == string.lower(titleName) then
					foundData = data
					break
				end
			end
		end

		if foundData then
			-- Si el título tiene un atributo especial (ej: IsTester, IsAdmin), usamos ese
			if foundData.ReqAttribute then
				targetPlayer:SetAttribute(foundData.ReqAttribute, true)
				print("? Título Especial '"..foundData.Name.."' otorgado a " .. targetPlayer.Name .. " (Attr: " .. foundData.ReqAttribute .. ")")
			else
				-- Si es un título normal, usamos el formato estándar
				local safeName = string.gsub(foundData.Name, " ", "")
				targetPlayer:SetAttribute("Title_" .. safeName, true)
				print("? Título Normal '"..foundData.Name.."' desbloqueado para " .. targetPlayer.Name)
			end

			-- Sonido de éxito al target
			local s = Instance.new("Sound", workspace); s.SoundId="rbxassetid://1054811116"; s:Play(); game.Debris:AddItem(s, 2)
		else
			warn("?? Título no encontrado: " .. tostring(titleName))
		end

	elseif action == "UnlockAllTitles" or action == "GiveAllTitles" then
		print("?? Desbloqueando TODOS los títulos (Dinámico) para: " .. targetPlayer.Name)

		-- Forzamos carga fresca de GameData
		local success, GameData = pcall(function() return require(ReplicatedStorage:WaitForChild("GameData")) end)

		if success and GameData.TITLES_DATA then
			local count = 0
			for _, data in pairs(GameData.TITLES_DATA) do
				-- ARREGLO DE ESPACIOS: "Berry Picker" -> "BerryPicker"
				local safeName = string.gsub(data.Name, " ", "")
				local attrName = "Title_" .. safeName

				targetPlayer:SetAttribute(attrName, true)
				count = count + 1
			end
			print("? ADMIN: Se dieron " .. count .. " títulos a " .. targetPlayer.Name)

			-- Sonido confirmación
			local s = Instance.new("Sound", workspace)
			s.SoundId = "rbxassetid://1054811116"; s:Play(); game.Debris:AddItem(s, 2)
		else
			warn("?? ADMIN ERROR: No se leyó GameData.TITLES_DATA")
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
			-- ? NUEVA REFERENCIA
			local Score5x5Store = DataStoreService:GetOrderedDataStore("GlobalScore5x5_V4")
			HighScoreStore:RemoveAsync(targetPlayer.UserId)
			-- Borrar del Leaderboard de Tiempo
			local TimePlayedStore = DataStoreService:GetOrderedDataStore("GlobalTime_V4")
			TimePlayedStore:RemoveAsync(targetPlayer.UserId)
		end)

		print("?? RESET COMPLETO (Data + Leaderboards) PARA: " .. targetPlayer.Name)
	end
end)

