local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local UIUtils = require(ReplicatedStorage:WaitForChild("UIUtils"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local MusicManager = require(ReplicatedStorage:WaitForChild("MusicManager"))

local SettingsManager = {}
local Refs = {}
local SettingsFrame = nil
local StatsFrame = nil
local player = Players.LocalPlayer

-- EVENTOS (Los buscamos aquí para no ensuciar el cliente)
local SaveSettingsEvent = ReplicatedStorage:WaitForChild("SaveSettings", 5)
local GetStatsFunc = ReplicatedStorage:WaitForChild("GetPlayerStats", 5)

function SettingsManager.init(ScreenGui, menuFrame)
	-- === 1. CREAR SETTINGS FRAME ===
	SettingsFrame = Instance.new("Frame")
	SettingsFrame.Name = "SettingsFrame"
	SettingsFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
	SettingsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	SettingsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	SettingsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	SettingsFrame.BorderSizePixel = 0
	SettingsFrame.ZIndex = 1500
	SettingsFrame.Visible = false
	SettingsFrame.Parent = ScreenGui
	Instance.new("UICorner", SettingsFrame).CornerRadius = UDim.new(0, 15)
	Instance.new("UIStroke", SettingsFrame).Color = Color3.fromRGB(100, 200, 255); Instance.new("UIStroke", SettingsFrame).Thickness = 2

	local SettingsHeader = Instance.new("Frame", SettingsFrame)
	SettingsHeader.Size = UDim2.new(1, 0, 0.15, 0); SettingsHeader.BackgroundTransparency = 1
	local STitle = Instance.new("TextLabel", SettingsHeader); STitle.Text = "SETTINGS ??"; STitle.Size = UDim2.new(1, 0, 1, 0); STitle.BackgroundTransparency = 1; STitle.TextColor3 = Color3.new(1,1,1); STitle.Font = Enum.Font.FredokaOne; STitle.TextSize = 24; STitle.ZIndex = 1501

	local SContainer = Instance.new("Frame", SettingsFrame)
	SContainer.Size = UDim2.new(0.9, 0, 0.7, 0); SContainer.Position = UDim2.new(0.05, 0, 0.15, 0); SContainer.BackgroundTransparency = 1; SContainer.ZIndex = 1501

	-- CLOSE BUTTON SETTINGS
	Refs.SCloseBtn = Instance.new("TextButton")
	Refs.SCloseBtn.Text = "CLOSE"
	Refs.SCloseBtn.Size = UDim2.new(0.4, 0, 0.12, 0)
	Refs.SCloseBtn.Position = UDim2.new(0.3, 0, 0.88, 0)
	Refs.SCloseBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	Refs.SCloseBtn.TextColor3 = Color3.new(1,1,1)
	Refs.SCloseBtn.Font = Enum.Font.GothamBold
	Refs.SCloseBtn.TextScaled = true
	Refs.SCloseBtn.ZIndex = 1502
	Refs.SCloseBtn.Parent = SettingsFrame
	Instance.new("UICorner", Refs.SCloseBtn).CornerRadius = UDim.new(0, 8)
	UIUtils.addHoverEffect(Refs.SCloseBtn)

	-- CONEXIÓN CERRAR INTERNA
	Refs.SCloseBtn.MouseButton1Click:Connect(function()
		UIUtils.closeMenuWithAnim(SettingsFrame)
		-- Aquí no podemos restaurar los botones del menú principal fácilmente porque no tenemos referencia
		-- pero el GameClient se encargará si detecta que se cerró.
	end)

	-- === 2. FUNCIONES DE UI INTERNAS ===
	local function createModernSlider(name, yPos, attrName, callback)
		local container = Instance.new("Frame", SContainer)
		container.Size = UDim2.new(1, 0, 0.25, 0); container.Position = UDim2.new(0, 0, yPos, 0); container.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
		local label = Instance.new("TextLabel", container); label.Text = name; label.Size = UDim2.new(0.4, 0, 1, 0); label.Position = UDim2.new(0.02, 0, 0, 0); label.BackgroundTransparency = 1; label.TextColor3 = Color3.new(1,1,1); label.Font = Enum.Font.GothamBold; label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left
		local sliderBg = Instance.new("Frame", container); sliderBg.Size = UDim2.new(0.55, 0, 0.2, 0); sliderBg.Position = UDim2.new(0.4, 0, 0.4, 0); sliderBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30); Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
		local sliderFill = Instance.new("Frame", sliderBg); sliderFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255); Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
		local currentVal = player:GetAttribute(attrName) or 0.5; sliderFill.Size = UDim2.new(currentVal, 0, 1, 0) 
		local trigger = Instance.new("TextButton", sliderBg); trigger.Text = ""; trigger.Size = UDim2.new(1, 0, 3, 0); trigger.Position = UDim2.new(0, 0, -1, 0); trigger.BackgroundTransparency = 1

		local function updateVisual(val)
			sliderFill.Size = UDim2.new(math.clamp(val, 0, 1), 0, 1, 0)
			callback(val)
		end
		local isDragging = false
		trigger.MouseButton1Down:Connect(function() isDragging = true end)
		UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = false end end)
		RunService.RenderStepped:Connect(function() 
			if isDragging then 
				local inputX = UserInputService:GetMouseLocation().X
				local pos = math.clamp((inputX - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
				updateVisual(pos)
				if SaveSettingsEvent then SaveSettingsEvent:FireServer(attrName, pos) end
			end 
		end)

		-- ? VIGILANTE: Si el servidor carga los datos después, actualizamos la barra visualmente
		player:GetAttributeChangedSignal(attrName):Connect(function()
			if not isDragging then -- No molestar si el jugador lo está moviendo
				local serverVal = player:GetAttribute(attrName) or 0.5
				updateVisual(serverVal)
			end
		end)
	end

	local function createToggle(name, yPos, attrName, callback)
		local container = Instance.new("Frame", SContainer)
		container.Size = UDim2.new(1, 0, 0.25, 0); container.Position = UDim2.new(0, 0, yPos, 0); container.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

		local label = Instance.new("TextLabel", container); label.Text = name; label.Size = UDim2.new(0.6, 0, 1, 0); label.Position = UDim2.new(0.02, 0, 0, 0); label.BackgroundTransparency = 1; label.TextColor3 = Color3.new(1,1,1); label.Font = Enum.Font.GothamBold; label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left

		local switchBg = Instance.new("Frame", container); switchBg.Size = UDim2.new(0.15, 0, 0.6, 0); switchBg.Position = UDim2.new(0.8, 0, 0.2, 0); Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
		local knob = Instance.new("Frame", switchBg); knob.Size = UDim2.new(0, 0, 0.85, 0); knob.SizeConstraint = Enum.SizeConstraint.RelativeYY; knob.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
		local btn = Instance.new("TextButton", container); btn.Text = ""; btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1

		-- ? LÓGICA DE ESTADO INICIAL (Corregida)
		local attrVal = player:GetAttribute(attrName)
		local isOn = false
		-- Si es el botón de XP y es nil (nunca guardado), lo activamos por defecto
		if attrName == "SavedShowXP" and attrVal == nil then
			isOn = true
		else
			isOn = (attrVal == true)
		end

		local function setVisual(state, animate)
			-- ? AQUÍ ESTÁ LA LÍNEA QUE FALTABA:
			local targetColor = state and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(80, 80, 80)

			local targetPos = state and UDim2.new(0.95, 0, 0.5, 0) or UDim2.new(0.05, 0, 0.5, 0)
			local targetAnchor = state and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)

			if animate then
				TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
				TweenService:Create(knob, TweenInfo.new(0.2), {Position = targetPos, AnchorPoint = targetAnchor}):Play()
			else
				switchBg.BackgroundColor3 = targetColor; knob.Position = targetPos; knob.AnchorPoint = targetAnchor
			end
			callback(state)
		end

		setVisual(isOn, false)

		btn.MouseButton1Click:Connect(function()
			UIUtils.playClick()
			isOn = not isOn
			setVisual(isOn, true)
			if SaveSettingsEvent then SaveSettingsEvent:FireServer(attrName, isOn) end
		end)

		-- ? VIGILANTE: Si el servidor carga los datos después, actualizamos el botón visualmente
		player:GetAttributeChangedSignal(attrName):Connect(function()
			local serverState = (player:GetAttribute(attrName) == true)
			if serverState ~= isOn then
				isOn = serverState
				setVisual(isOn, true)
			end
		end)
	end

	-- CONTROLES (Reajustados para que quepan 4 opciones: 0, 0.25, 0.5, 0.75)

	-- 1. Música
	createModernSlider("MUSIC VOLUME", 0, "SavedVolMusic", function(val) MusicManager.setVolume(val) end)

	-- 2. Efectos
	createModernSlider("SFX VOLUME", 0.25, "SavedVolSFX", function(val) 
		player:SetAttribute("CurrentSFXVol", val)
	end)

	-- 3. Modo Oscuro
	createToggle("DARK MODE ??", 0.5, "SavedDarkMode", function(active)
		if menuFrame then
			local targetBg = active and Color3.fromRGB(20, 20, 25) or GameData.DEFAULT_THEME_COLORS.Bg
			TweenService:Create(menuFrame, TweenInfo.new(0.5), {BackgroundColor3 = targetBg}):Play()
		end
	end)

	-- 4. ? NUEVO: Mostrar XP
	createToggle("SHOW XP TEXT ?", 0.75, "SavedShowXP", function(active)
		-- No necesitamos lógica aquí, el GameClient lee el atributo "SavedShowXP" directamente
	end)

	-- === 3. CREAR STATS FRAME ===
	StatsFrame = Instance.new("Frame")
	StatsFrame.Name = "StatsFrame"
	StatsFrame.Size = UDim2.new(0.5, 0, 0.6, 0)
	StatsFrame.Position = UDim2.new(0.25, 0, 0.2, 0)
	StatsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	StatsFrame.BorderSizePixel = 0
	StatsFrame.ZIndex = 1600
	StatsFrame.Visible = false
	StatsFrame.Parent = ScreenGui
	Instance.new("UICorner", StatsFrame).CornerRadius = UDim.new(0, 12)
	Instance.new("UIStroke", StatsFrame).Color = Color3.fromRGB(100, 200, 255); Instance.new("UIStroke", StatsFrame).Thickness = 2

	local StatsTitle = Instance.new("TextLabel", StatsFrame); StatsTitle.Text = "PLAYER STATS"; StatsTitle.Size = UDim2.new(1, 0, 0.15, 0); StatsTitle.BackgroundTransparency = 1; StatsTitle.TextColor3 = Color3.new(1,1,1); StatsTitle.Font = Enum.Font.FredokaOne; StatsTitle.TextScaled = true; StatsTitle.ZIndex = 1601
	Refs.StatsList = Instance.new("ScrollingFrame", StatsFrame); Refs.StatsList.Size = UDim2.new(0.85, 0, 0.65, 0); Refs.StatsList.Position = UDim2.new(0.075, 0, 0.18, 0); Refs.StatsList.BackgroundTransparency = 1; Refs.StatsList.ScrollBarThickness = 4; Refs.StatsList.ZIndex = 1601
	local StatsLayout = Instance.new("UIListLayout", Refs.StatsList); StatsLayout.SortOrder = Enum.SortOrder.LayoutOrder; StatsLayout.Padding = UDim.new(0, 8)

	local function createStatRow(name, valText)
		local row = Instance.new("Frame", Refs.StatsList); row.Size = UDim2.new(1, 0, 0, 30); row.BackgroundColor3 = Color3.fromRGB(50, 50, 55); Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
		local n = Instance.new("TextLabel", row); n.Text = name; n.Size = UDim2.new(0.5, 0, 1, 0); n.Position = UDim2.new(0.05, 0, 0, 0); n.BackgroundTransparency = 1; n.TextColor3 = Color3.new(0.8,0.8,0.8); n.Font = Enum.Font.GothamMedium; n.TextXAlignment = Enum.TextXAlignment.Left; n.TextSize = 14
		local v = Instance.new("TextLabel", row); v.Name = "ValueLabel"; v.Text = valText; v.Size = UDim2.new(0.4, 0, 1, 0); v.Position = UDim2.new(0.55, 0, 0, 0); v.BackgroundTransparency = 1; v.TextColor3 = Color3.new(1,1,1); v.Font = Enum.Font.GothamBold; v.TextXAlignment = Enum.TextXAlignment.Right; v.TextSize = 14
	end
	createStatRow("Games Played:", "Loading...")
	createStatRow("High Score:", "Loading...")
	createStatRow("Total Coins:", "Loading...")
	createStatRow("Total Fruit Gems:", "Loading...")
	-- ? NUEVA FILA VISUAL AQUÍ
	createStatRow("Robux Spent:", "Loading...") 
	createStatRow("Titles Unlocked:", "Loading...")
	createStatRow("Time Played:", "Loading...")

	Refs.StatsCloseBtn = Instance.new("TextButton", StatsFrame)
	Refs.StatsCloseBtn.Text = "CLOSE"
	Refs.StatsCloseBtn.Size = UDim2.new(0.3, 0, 0.1, 0); Refs.StatsCloseBtn.Position = UDim2.new(0.35, 0, 0.88, 0); Refs.StatsCloseBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 255); Refs.StatsCloseBtn.TextColor3 = Color3.new(1,1,1); Refs.StatsCloseBtn.Font = Enum.Font.GothamBold; Refs.StatsCloseBtn.TextScaled = true; Refs.StatsCloseBtn.ZIndex = 1602; Instance.new("UICorner", Refs.StatsCloseBtn).CornerRadius = UDim.new(0, 6)
	UIUtils.addHoverEffect(Refs.StatsCloseBtn)

	Refs.StatsCloseBtn.MouseButton1Click:Connect(function() UIUtils.closeMenuWithAnim(StatsFrame) end)

	return SettingsFrame, StatsFrame, Refs
end

function SettingsManager.updateStats()
	if not GetStatsFunc then return end
	task.spawn(function()
		local stats = GetStatsFunc:InvokeServer()
		if not stats then return end
		local list = Refs.StatsList
		if not list then return end

		local function formatNumber(n) return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "") end
		local function formatTime(s) local h=math.floor(s/3600); local m=math.floor((s%3600)/60); if h>0 then return string.format("%dh %dm",h,m) end return string.format("%dm",m) end

		local myBest = 0; local leaderstats = player:FindFirstChild("leaderstats"); if leaderstats then myBest = leaderstats.HighScore.Value end
		local titlesCount = 0 -- Simplificado

		for _, frame in pairs(list:GetChildren()) do
			if frame:IsA("Frame") then
				local nameLbl = frame:FindFirstChild("TextLabel"); local valLbl = frame:FindFirstChild("ValueLabel")
				if nameLbl and valLbl then
					if nameLbl.Text == "Games Played:" then valLbl.Text = formatNumber(stats.GamesPlayed) end
					if nameLbl.Text == "High Score:" then valLbl.Text = formatNumber(myBest) end
					if nameLbl.Text == "Total Coins:" then valLbl.Text = formatNumber(stats.TotalCoins) end
					if nameLbl.Text == "Total Fruit Gems:" then valLbl.Text = formatNumber(stats.TotalFruitGems) end

					-- ? ACTUALIZAR EL VALOR DE ROBUX
					if nameLbl.Text == "Robux Spent:" then valLbl.Text = "R$ " .. formatNumber(stats.TotalRobuxSpent or 0) end

					-- ? ACTUALIZAR EL VALOR DE TÍTULOS (Ahora real)
					if nameLbl.Text == "Titles Unlocked:" then valLbl.Text = (stats.TitlesCount or 0) .. " Titles" end

					if nameLbl.Text == "Time Played:" then valLbl.Text = formatTime(stats.TimePlayed) end
					
				end
			end
		end
	end)
end

return SettingsManager