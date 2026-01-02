local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UIUtils = require(ReplicatedStorage:WaitForChild("UIUtils"))

local LeaderboardManager = {}
local LbRefs = {} -- Referencias a objetos UI
local LeaderboardFrame = nil

-- Variables de Tabs
local currentLeaderboardTab = "HighScore"
local Tabs = {}

function LeaderboardManager.init(ScreenGui)
	-- 1. CREAR UI (Si no existe, aunque idealmente ya la creaste en GameClient, 
	-- pero vamos a asumir que la manejamos desde aquí o tomamos referencia)

	-- Para no reescribir toda la creación UI aquí y complicarte, 
	-- vamos a hacer que este init reciba el Frame ya creado o lo busque.
	-- Pero para mantener la limpieza que hicimos con Shop, lo ideal es crearlo aquí.

	-- (Para ser prácticos y rápidos: Crearemos la estructura lógica aquí)
	LeaderboardFrame = Instance.new("Frame")
	LeaderboardFrame.Name = "LeaderboardFrame"
	LeaderboardFrame.Size = UDim2.new(0.9, 0, 0.8, 0)
	LeaderboardFrame.Position = UDim2.new(0.5, 0, 0.5, 0) 
	LeaderboardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	LeaderboardFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	LeaderboardFrame.ZIndex = 1100
	LeaderboardFrame.Visible = false
	LeaderboardFrame.Parent = ScreenGui
	Instance.new("UICorner", LeaderboardFrame).CornerRadius = UDim.new(0, 15)
	Instance.new("UIStroke", LeaderboardFrame).Color = Color3.fromHex("edc22e"); Instance.new("UIStroke", LeaderboardFrame).Thickness = 2

	-- TABS CONTAINER
	local TabsContainer = Instance.new("Frame", LeaderboardFrame)
	TabsContainer.Size = UDim2.new(0.9, 0, 0.08, 0)
	TabsContainer.Position = UDim2.new(0.05, 0, 0.03, 0)
	TabsContainer.BackgroundTransparency = 1
	local TabsLayout = Instance.new("UIListLayout", TabsContainer); TabsLayout.FillDirection = Enum.FillDirection.Horizontal; TabsLayout.Padding = UDim.new(0, 10); TabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local function createTab(name)
		local b = Instance.new("TextButton", TabsContainer)
		b.Text = name
		b.Size = UDim2.new(0.155, 0, 1, 0)
		b.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
		b.TextColor3 = Color3.new(1,1,1)
		b.Font = Enum.Font.GothamBold
		b.TextScaled = true
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

		UIUtils.addHoverEffect(b)
		return b
	end

	Tabs.HighScore = createTab("High Score")
	Tabs.HighScore.BackgroundColor3 = Color3.fromHex("edc22e"); Tabs.HighScore.TextColor3 = Color3.new(0,0,0)

	-- ? NUEVAS PESTAÑAS
	Tabs.Score5x5 = createTab("5x5 Score")
	Tabs.Level = createTab("Level")

	Tabs.TimePlayed = createTab("Time Played")
	Tabs.RobuxSpent = createTab("Robux Spent")
	Tabs.Streaks = createTab("Streaks")

	-- SCROLL LIST
	LbRefs.ScrollList = Instance.new("ScrollingFrame")
	LbRefs.ScrollList.Size = UDim2.new(0.9, 0, 0.72, 0)
	LbRefs.ScrollList.Position = UDim2.new(0.05, 0, 0.15, 0)
	LbRefs.ScrollList.BackgroundTransparency = 1
	LbRefs.ScrollList.ScrollBarThickness = 6
	LbRefs.ScrollList.ScrollBarImageColor3 = Color3.fromHex("edc22e")
	LbRefs.ScrollList.ZIndex = 1101
	LbRefs.ScrollList.Parent = LeaderboardFrame
	local UIListLayout = Instance.new("UIListLayout"); UIListLayout.Padding = UDim.new(0, 6); UIListLayout.Parent = LbRefs.ScrollList
	
	-- ? CONTADOR DE ACTUALIZACIÓN
	local TimerLabel = Instance.new("TextLabel", LeaderboardFrame)
	TimerLabel.Name = "RefreshTimer"
	TimerLabel.Text = "Refresh: 60s"
	TimerLabel.Size = UDim2.new(0.3, 0, 0.05, 0)
	TimerLabel.Position = UDim2.new(0.5, 0, 0.92, 0) -- Abajo al centro
	TimerLabel.AnchorPoint = Vector2.new(0.5, 0)
	TimerLabel.BackgroundTransparency = 1
	TimerLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	TimerLabel.Font = Enum.Font.GothamMedium
	TimerLabel.TextScaled = true
	TimerLabel.ZIndex = 1105

	-- LÓGICA DEL CONTADOR (Bucle Continuo Global)
	task.spawn(function()
		local countdown = 60
		while true do
			task.wait(1)

			-- 1. Restar SIEMPRE (Esté abierto o cerrado)
			countdown = countdown - 1

			-- 2. Solo actualizar el texto si el jugador lo está viendo
			if LeaderboardFrame.Visible then
				TimerLabel.Text = "Refresh: " .. countdown .. "s"
			end

			-- 3. Cuando llega a 0, reiniciar ciclo
			if countdown <= 0 then
				countdown = 60

				-- Solo pedir datos nuevos al servidor si la ventana está abierta
				-- (Para no gastar internet si nadie está mirando)
				if LeaderboardFrame.Visible and currentLeaderboardTab then
					LeaderboardManager.switchTab(currentLeaderboardTab)
				end
			end
		end
	end)

	-- CLOSE BUTTON (El código que ya tenías sigue aquí abajo...)
	local LCloseBtn = Instance.new("TextButton")
	-- CLOSE BUTTON
	local LCloseBtn = Instance.new("TextButton")
	LCloseBtn.Text = "X"
	LCloseBtn.Size = UDim2.new(0.1, 0, 0.08, 0)
	LCloseBtn.AnchorPoint = Vector2.new(1, 0)
	LCloseBtn.Position = UDim2.new(0.98, 0, -0.02, 0)
	LCloseBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	LCloseBtn.TextColor3 = Color3.new(1,1,1)
	LCloseBtn.Font = Enum.Font.FredokaOne
	LCloseBtn.TextScaled = true
	LCloseBtn.ZIndex = 1105
	LCloseBtn.Parent = LeaderboardFrame
	Instance.new("UICorner", LCloseBtn).CornerRadius = UDim.new(1, 0)

	LbRefs.CloseBtn = LCloseBtn

	-- CONEXIONES
	Tabs.HighScore.MouseButton1Click:Connect(function() LeaderboardManager.switchTab("HighScore") end)

	-- ? CONEXIONES NUEVAS
	Tabs.Score5x5.MouseButton1Click:Connect(function() LeaderboardManager.switchTab("Score5x5") end)
	Tabs.Level.MouseButton1Click:Connect(function() LeaderboardManager.switchTab("Level") end)

	Tabs.TimePlayed.MouseButton1Click:Connect(function() LeaderboardManager.switchTab("TimePlayed") end)
	Tabs.RobuxSpent.MouseButton1Click:Connect(function() LeaderboardManager.switchTab("RobuxSpent") end)
	Tabs.Streaks.MouseButton1Click:Connect(function() LeaderboardManager.switchTab("Streaks") end)
	Tabs.Streaks.MouseButton1Click:Connect(function() LeaderboardManager.switchTab("Streaks") end)

	return LeaderboardFrame, LbRefs
end

local function formatNumber(n)
	return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function formatTime(seconds)
	local hrs = math.floor(seconds / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	if hrs > 0 then return string.format("%dh %dm", hrs, mins) end
	return string.format("%dm", mins)
end

function LeaderboardManager.updateUI(data, mode)
	if not LbRefs.ScrollList then return end
	for _, child in pairs(LbRefs.ScrollList:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
	end

	-- Solo Donate sigue en construcción
	if mode == "Donate" then
		local msg = Instance.new("TextLabel", LbRefs.ScrollList)
		msg.Size = UDim2.new(1,0,0.5,0); msg.Text = "Coming Soon..."; msg.TextColor3 = Color3.new(0.7,0.7,0.7); msg.Font = Enum.Font.FredokaOne; msg.TextSize = 24; msg.BackgroundTransparency = 1
		return
	end

	for i, entry in ipairs(data) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 50)
		row.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
		row.BorderSizePixel = 0
		row.Parent = LbRefs.ScrollList
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

		if i == 1 then row.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		elseif i == 2 then row.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
		elseif i == 3 then row.BackgroundColor3 = Color3.fromRGB(205, 127, 50)
		end

		local rank = Instance.new("TextLabel", row)
		rank.Text = i .. "."
		rank.Size = UDim2.new(0.1, 0, 1, 0); rank.Position = UDim2.new(0.02, 0, 0, 0); rank.BackgroundTransparency = 1
		rank.TextColor3 = (i<=3) and Color3.new(0,0,0) or Color3.new(1,1,1); rank.Font = Enum.Font.FredokaOne; rank.TextSize = 22

		local avatar = Instance.new("ImageLabel", row)
		avatar.Size = UDim2.new(0.8, 0, 0.8, 0); avatar.SizeConstraint = Enum.SizeConstraint.RelativeYY; avatar.Position = UDim2.new(0.15, 0, 0.1, 0); avatar.BackgroundColor3 = Color3.new(0,0,0); avatar.BackgroundTransparency = 0.5; avatar.Parent = row; Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
		task.spawn(function()
			local content, isReady = Players:GetUserThumbnailAsync(entry.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			avatar.Image = content
		end)

		local name = Instance.new("TextLabel", row)
		name.Text = entry.name
		name.Size = UDim2.new(0.4, 0, 1, 0); name.Position = UDim2.new(0.3, 0, 0, 0); name.BackgroundTransparency = 1
		name.TextColor3 = (i<=3) and Color3.new(0,0,0) or Color3.new(1,1,1); name.TextXAlignment = Enum.TextXAlignment.Left; name.Font = Enum.Font.GothamBold; name.TextSize = 16

		local s = Instance.new("TextLabel", row)
		local valDisplay = formatNumber(entry.value)

		-- Lógica especial de visualización
		if mode == "TimePlayed" then 
			-- 1. Usamos la función 'formatTime' que ya tienes creada arriba
			valDisplay = formatTime(tonumber(entry.value) or 0)
			s.Text = valDisplay

			-- 2. Color Verde (Solo si no es Top 3, para que se lea bien)
			if i > 3 then s.TextColor3 = Color3.fromRGB(100, 255, 150) end

			-- 3. IMPORTANTE: Definir tamaño y posición (igual que HighScore)
			s.Size = UDim2.new(0.3, 0, 1, 0) 
			s.Position = UDim2.new(0.68, 0, 0, 0) 
			s.TextXAlignment = Enum.TextXAlignment.Right

		elseif mode == "RobuxSpent" then
			-- ... (tu código de robux) ...

			-- ? NUEVO: FORMATO NIVEL
		elseif mode == "Level" then
			valDisplay = "Lvl " .. entry.value
			s.Text = valDisplay
			s.TextColor3 = Color3.fromRGB(0, 200, 255) -- Azul Cielito

			-- ? NUEVO: FORMATO 5x5
		elseif mode == "Score5x5" then
			valDisplay = formatNumber(entry.value)
			s.Text = valDisplay
			s.TextColor3 = Color3.fromRGB(255, 100, 255) -- Rosado/Morado para diferenciar

		elseif mode == "Streaks" then
			-- ...
			local days = tonumber(entry.value) or 0
			if days <= 0 then days = 1 end

			-- 1. Texto de Días (Alineado un poco a la izquierda para dejar sitio al fuego)
			s.Text = days .. " Days"
			s.Size = UDim2.new(0.2, 0, 1, 0)
			s.Position = UDim2.new(0.65, 0, 0, 0) 
			s.TextXAlignment = Enum.TextXAlignment.Right

			-- 2. Icono de Fuego (Al lado del texto)
			local fire = Instance.new("ImageLabel", row)
			fire.Size = UDim2.new(0.7, 0, 0.7, 0)
			fire.SizeConstraint = Enum.SizeConstraint.RelativeYY
			fire.Position = UDim2.new(0.88, 0, 0.15, 0) -- A la derecha del todo
			fire.BackgroundTransparency = 1
			fire.ZIndex = 5

			-- Lógica de Color (IDs Solicitados)
			if days >= 150 then
				fire.Image = "rbxassetid://132241895741787" -- Morado
			elseif days >= 50 then
				fire.Image = "rbxassetid://85252887341379" -- Verde
			else
				fire.Image = "rbxassetid://134763959761180" -- Rojo
			end
		else
			-- Caso normal (HighScore)
			s.Text = valDisplay
			s.Size = UDim2.new(0.25, 0, 1, 0); s.Position = UDim2.new(0.72, 0, 0, 0)
			s.TextXAlignment = Enum.TextXAlignment.Right
		end

		s.BackgroundTransparency = 1
		s.TextColor3 = (i<=3) and Color3.new(0,0,0) or Color3.fromHex("edc22e")
		s.Font = Enum.Font.FredokaOne
		s.TextSize = 18

		s.Text = valDisplay
		s.Size = UDim2.new(0.25, 0, 1, 0); s.Position = UDim2.new(0.72, 0, 0, 0); s.BackgroundTransparency = 1
		s.TextColor3 = (i<=3) and Color3.new(0,0,0) or Color3.fromHex("edc22e"); s.Font = Enum.Font.FredokaOne; s.TextSize = 18; s.TextXAlignment = Enum.TextXAlignment.Right
	end
end

function LeaderboardManager.switchTab(tabName)
	UIUtils.playClick()
	currentLeaderboardTab = tabName

	-- Reset Colores
	for _, btn in pairs(Tabs) do
		btn.BackgroundColor3 = Color3.fromRGB(60,60,65)
		btn.TextColor3 = Color3.new(1,1,1)
	end

	-- Mapeo de nombres si cambiaste la clave en la tabla Tabs
	local btnKey = tabName
	if tabName == "RobuxSpent" then btnKey = "RobuxSpent" end -- Aseguramos coincidencia

	local activeBtn = Tabs[btnKey] or Tabs.HighScore
	if activeBtn then
		activeBtn.BackgroundColor3 = Color3.fromHex("edc22e")
		activeBtn.TextColor3 = Color3.new(0,0,0)
	end

	-- ? SOLICITUD AL SERVIDOR (AHORA FUNCIONA PARA TODO)
	local getScoresFunc = ReplicatedStorage:FindFirstChild("GetTopScores")
	if getScoresFunc then
		task.spawn(function()
			-- Limpiar lista visualmente mientras carga
			LeaderboardManager.updateUI({}, tabName)

			local data = getScoresFunc:InvokeServer(tabName)
			if data then LeaderboardManager.updateUI(data, tabName) end
		end)
	end
end

return LeaderboardManager