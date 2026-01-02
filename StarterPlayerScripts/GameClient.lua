-- SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")

-- PLAYER
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-------------------------------------------------------------------------
-- 1. CONFIGURACIÓN GLOBAL Y VISUAL
-------------------------------------------------------------------------

local PADDING = 0.02
-- Variables dinámicas para el modo de juego
local BOARD_SIZE = 4 
local GAME_MODE = "Classic" 
local CELL_SIZE = (1 - (PADDING * (BOARD_SIZE + 1))) / BOARD_SIZE

-- CONFIGURACIÓN DE AUDIO Y ANIMACIÓN
local VolMove = 0.5
local VolMerge = 0.6
local TWEEN_SPEED = 0.1 
local POP_SPEED = 0.15

local FREE_UNDOS = 3
local UNDO_PRODUCT_ID = 0 
local MOCK_PURCHASE = true 
local VIP_GAMEPASS_ID = 1605082468 

-- MÓDULOS EXTERNOS (Cargados una sola vez)
local UIUtils = require(ReplicatedStorage:WaitForChild("UIUtils"))
-- GameData y MusicManager se cargan más abajo, no los dupliques aquí

local function formatNumber(n)
	
	return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- CARGAR DATOS DEL MÓDULO (Esto libera memoria del script principal)
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

local DEFAULT_TILES = GameData.DEFAULT_TILES
local DEFAULT_THEME_COLORS = GameData.DEFAULT_THEME_COLORS
local THEMES = GameData.THEMES
local MUSIC_PLAYLIST = GameData.MUSIC_PLAYLIST
local TITLES_DATA = GameData.TITLES_DATA -- Movemos Titles aquí también para ordenarlo

-- ✅ NUEVA VARIABLE GLOBAL PARA PASES (Aquí la ven TODOS)
local localSessionPasses = {} 

local currentSkin = "Classic"
local currentEquippedTitle = "Novice"
local currentlySelectedTitle = nil
local currentTitleCategory = "Main" -- ✅ ESTA VARIABLE FALTABA

local BOARD_COLOR = DEFAULT_THEME_COLORS.Board
local BG_COLOR = DEFAULT_THEME_COLORS.Bg
local EMPTY_CELL_COLOR = DEFAULT_THEME_COLORS.Empty
local TEXT_DARK = DEFAULT_THEME_COLORS.TextDark
local TEXT_LIGHT = DEFAULT_THEME_COLORS.TextLight

local SOUND_MOVE_ID = "rbxassetid://4590657391"
local SOUND_MERGE_ID = "rbxassetid://4590662766"
local SOUND_CLICK_ID = "rbxassetid://6895079853"

local MusicManager = require(ReplicatedStorage:WaitForChild("MusicManager"))

local VolMusic = player:GetAttribute("SavedVolMusic") or 0.5
local VolSFX = player:GetAttribute("SavedVolSFX") or 0.5
local isDarkMode = player:GetAttribute("SavedDarkMode") == true -- 🟢 ESTA ES LA VARIABLE QUE FALTABA

local UNDO_ICON_ID = "rbxassetid://110255570642946"
local SETTINGS_ICON_ID = "rbxassetid://134480740047113"
local COIN_ICON_ID = "rbxassetid://108796514719654" -- ✅ ID DE MONEDA CORREGIDO
local SHOP_ICON_ID = "rbxassetid://85619868467544"
-------------------------------------------------------------------------
-- 2. DECLARACIÓN ANTICIPADA DE UI
-------------------------------------------------------------------------
local ScreenGui, LoadingFrame, MenuFrame, MainFrame
local SettingsFrame, LeaderboardFrame, ShopFrame, TitlesFrame, StatsFrame
local ModeFrame = nil -- Le damos valor 'nil' para que el script no se queje
local MenuCoinLbl, MenuGemLbl, MenuFruitLbl -- Variables Globales para el Menú
local SettingsBtnMenu, SettingsBtnGame, SettingsBtnGlobal

-- Agregamos StatsButton, StatsCloseBtn y referencias para los Tabs del Leaderboard
local ShopButton, UndoButton, TitlesButton, PlayButton, LeaderboardButton, SkipButton, BackButton, StatsButton, StatsCloseBtn
local LTabHigh, LTabTime, LTabDonate, LTabStreak -- Variables para tabs
local currentLeaderboardTab = "HighScore"
local ShopCloseBtn, SCloseBtn, TitleCloseBtn, LCloseBtn
local ItemsContainer, ScrollList 
local moveSound, mergeSound, clickSound


-------------------------------------------------------------------------
-- 3. GUI CREATION (LIMPIO Y UNIFICADO)
-------------------------------------------------------------------------
if playerGui:FindFirstChild("Game2048UI") then playerGui.Game2048UI:Destroy() end

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Game2048UI"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling 
ScreenGui.Parent = playerGui

-- FONDO DE SKIN (ImageLabel)
local SkinBackground = Instance.new("ImageLabel")
SkinBackground.Name = "SkinBackground"
SkinBackground.Size = UDim2.new(1, 0, 1, 0)
SkinBackground.BackgroundTransparency = 1
SkinBackground.ScaleType = Enum.ScaleType.Crop
SkinBackground.Visible = false
SkinBackground.ZIndex = 0 
SkinBackground.Parent = ScreenGui

-- CREACIÓN DE SONIDOS
moveSound = Instance.new("Sound"); moveSound.SoundId = SOUND_MOVE_ID; moveSound.Volume = VolSFX; moveSound.Parent = ScreenGui
mergeSound = Instance.new("Sound"); mergeSound.SoundId = SOUND_MERGE_ID; mergeSound.Volume = VolSFX; mergeSound.Parent = ScreenGui
clickSound = Instance.new("Sound"); clickSound.SoundId = SOUND_CLICK_ID; clickSound.Volume = 1; clickSound.Parent = ScreenGui

-- ESCUCHAR CAMBIOS DE VOLUMEN (SFX)
player:GetAttributeChangedSignal("CurrentSFXVol"):Connect(function()
	local newVol = player:GetAttribute("CurrentSFXVol") or 0.5
	if moveSound then moveSound.Volume = newVol end
	if mergeSound then mergeSound.Volume = newVol end
end)

-- Configurar sonido en el módulo UIUtils
task.spawn(function() if clickSound then UIUtils.ClickSound = clickSound end end)
local function playClick() UIUtils.playClick() end

-- LOADING SCREEN
LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingScreen"
LoadingFrame.Size = UDim2.new(1, 0, 1, 0)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
LoadingFrame.ZIndex = 2000
LoadingFrame.Visible = true
LoadingFrame.Parent = ScreenGui

local LoadingText = Instance.new("TextLabel")
LoadingText.Text = "LOADING..."
LoadingText.Size = UDim2.new(1, 0, 0.1, 0)
LoadingText.Position = UDim2.new(0, 0, 0.4, 0)
LoadingText.TextColor3 = Color3.new(1,1,1)
LoadingText.BackgroundTransparency = 1
LoadingText.Font = Enum.Font.FredokaOne
LoadingText.TextScaled = true
LoadingText.ZIndex = 2001
LoadingText.Parent = LoadingFrame

local LoadingBarBG = Instance.new("Frame")
LoadingBarBG.Size = UDim2.new(0.6, 0, 0.03, 0)
LoadingBarBG.Position = UDim2.new(0.2, 0, 0.55, 0)
LoadingBarBG.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
LoadingBarBG.ZIndex = 2001
LoadingBarBG.Parent = LoadingFrame
Instance.new("UICorner", LoadingBarBG).CornerRadius = UDim.new(1, 0)

local LoadingBarFill = Instance.new("Frame")
LoadingBarFill.Size = UDim2.new(0, 0, 1, 0)
LoadingBarFill.BackgroundColor3 = Color3.fromHex("edc22e")
LoadingBarFill.ZIndex = 2002
LoadingBarFill.Parent = LoadingBarBG
Instance.new("UICorner", LoadingBarFill).CornerRadius = UDim.new(1, 0)

SkipButton = Instance.new("TextButton")
SkipButton.Text = "SKIP"
SkipButton.Size = UDim2.new(0.2, 0, 0.08, 0)
SkipButton.Position = UDim2.new(0.4, 0, 0.7, 0)
SkipButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
SkipButton.TextColor3 = Color3.new(1,1,1)
SkipButton.Font = Enum.Font.GothamBold
SkipButton.TextScaled = true
SkipButton.ZIndex = 2002
SkipButton.Parent = LoadingFrame
Instance.new("UICorner", SkipButton).CornerRadius = UDim.new(0, 8)

-- MAIN MENU
MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MenuScreen"
MenuFrame.Size = UDim2.new(1, 0, 1, 0)
MenuFrame.BackgroundColor3 = BG_COLOR
MenuFrame.Visible = false 
MenuFrame.ZIndex = 1000
MenuFrame.Parent = ScreenGui

local MenuTitle = Instance.new("TextLabel")
MenuTitle.Text = "2048"
MenuTitle.Size = UDim2.new(1, 0, 0.25, 0)
MenuTitle.Position = UDim2.new(0, 0, 0.15, 0)
MenuTitle.BackgroundTransparency = 1
MenuTitle.TextColor3 = TEXT_DARK
MenuTitle.Font = Enum.Font.FredokaOne
MenuTitle.TextScaled = true
MenuTitle.ZIndex = 1001 
MenuTitle.Parent = MenuFrame

PlayButton = Instance.new("TextButton")
PlayButton.Text = "PLAY"
PlayButton.Size = UDim2.new(0.3, 0, 0.1, 0)
PlayButton.Position = UDim2.new(0.35, 0, 0.45, 0)
PlayButton.BackgroundColor3 = Color3.fromHex("8f7a66")
PlayButton.TextColor3 = Color3.new(1,1,1)
PlayButton.Font = Enum.Font.GothamBold
PlayButton.TextScaled = true
PlayButton.ZIndex = 1001
PlayButton.Parent = MenuFrame
Instance.new("UICorner", PlayButton).CornerRadius = UDim.new(0, 6)

LeaderboardButton = Instance.new("TextButton")
LeaderboardButton.Text = "LEADERBOARD"
LeaderboardButton.Size = UDim2.new(0.3, 0, 0.1, 0)
LeaderboardButton.Position = UDim2.new(0.35, 0, 0.6, 0)
LeaderboardButton.BackgroundColor3 = Color3.fromHex("8f7a66")
LeaderboardButton.TextColor3 = Color3.new(1,1,1)
LeaderboardButton.Font = Enum.Font.GothamBold
LeaderboardButton.TextScaled = true
LeaderboardButton.ZIndex = 1001
LeaderboardButton.Parent = MenuFrame
Instance.new("UICorner", LeaderboardButton).CornerRadius = UDim.new(0, 6)

-- --- GLOBAL STATS BAR ---
do
	if ScreenGui:FindFirstChild("GlobalStats") then ScreenGui.GlobalStats:Destroy() end
	local GlobalStatsFrame = Instance.new("Frame", ScreenGui)
	GlobalStatsFrame.Name = "GlobalStats"
	GlobalStatsFrame.Size = UDim2.new(0.5, 0, 0.08, 0)
	GlobalStatsFrame.Position = UDim2.new(0.98, 0, 0.02, 0)
	GlobalStatsFrame.AnchorPoint = Vector2.new(1, 0)
	GlobalStatsFrame.BackgroundTransparency = 1
	GlobalStatsFrame.ZIndex = 2000

	local gsLayout = Instance.new("UIListLayout", GlobalStatsFrame)
	gsLayout.FillDirection = Enum.FillDirection.Horizontal
	gsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	gsLayout.Padding = UDim.new(0, 10)

	local function createGlobalStat(iconId, color)
		local bg = Instance.new("Frame", GlobalStatsFrame)
		bg.Size = UDim2.new(0.3, 0, 1, 0); bg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", bg).Color = color; Instance.new("UIStroke", bg).Thickness = 3
		local icon = Instance.new("ImageLabel", bg)
		icon.Image = iconId; icon.Size = UDim2.new(0.6,0,0.6,0); icon.SizeConstraint=Enum.SizeConstraint.RelativeYY
		icon.Position = UDim2.new(0.05,0,0.2,0); icon.BackgroundTransparency = 1
		local lbl = Instance.new("TextLabel", bg)
		lbl.Text = "0"; lbl.Size = UDim2.new(0.65,0,0.8,0); lbl.Position = UDim2.new(0.3,0,0.1,0)
		lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.new(1,1,1); lbl.Font=Enum.Font.FredokaOne; lbl.TextScaled=true; lbl.TextXAlignment=Enum.TextXAlignment.Right
		return lbl
	end
	MenuCoinLbl = createGlobalStat("rbxassetid://108796514719654", Color3.fromRGB(255, 200, 0))
	MenuGemLbl = createGlobalStat("rbxassetid://111308733495717", Color3.fromRGB(0, 200, 255))
	MenuFruitLbl = createGlobalStat("rbxassetid://128100423386205", Color3.fromRGB(255, 80, 100))
end

-- 1. SHOP BUTTON
ShopButton = Instance.new("ImageButton")
ShopButton.Size = UDim2.new(0.08, 0, 0.08, 0)
ShopButton.AnchorPoint = Vector2.new(0, 1)
ShopButton.Position = UDim2.new(0.05, 0, 0.95, 0)
ShopButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
ShopButton.BackgroundTransparency = 1
ShopButton.Image = SHOP_ICON_ID
ShopButton.ImageColor3 = Color3.new(1,1,1)
ShopButton.ZIndex = 1005
ShopButton.Parent = MenuFrame

-- 2. TITLES BUTTON
TitlesButton = Instance.new("ImageButton")
TitlesButton.Name = "TitlesButton"
TitlesButton.Size = UDim2.new(0.08, 0, 0.08, 0)
TitlesButton.AnchorPoint = Vector2.new(0, 1)
TitlesButton.Position = UDim2.new(0.05, 0, 0.70, 0) 
TitlesButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
TitlesButton.BackgroundTransparency = 1
TitlesButton.Image = "rbxassetid://76052568643498"
TitlesButton.ZIndex = 1005
TitlesButton.Parent = MenuFrame

-- 3. STATS BUTTON
StatsButton = Instance.new("ImageButton")
StatsButton.Name = "StatsButton"
StatsButton.Size = UDim2.new(0.08, 0, 0.08, 0)
StatsButton.AnchorPoint = Vector2.new(0, 1)
StatsButton.Position = UDim2.new(0.15, 0, 0.95, 0)
StatsButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
StatsButton.BackgroundTransparency = 1
StatsButton.Image = "rbxassetid://95799613339728"
StatsButton.ZIndex = 1005
StatsButton.Parent = MenuFrame

-- ✅ 4. BOTÓN CALENDARIO (POSICIÓN CORREGIDA + RACHA)
local DailyButton = Instance.new("ImageButton", MenuFrame)
-- Posición: 0.15 (X) al lado del trofeo, 0.70 (Y) misma altura que trofeo/arriba de info
DailyButton.Position = UDim2.new(0.15, 0, 0.70, 0) 
DailyButton.Name = "DailyButton"
DailyButton.Size = UDim2.new(0.08, 0, 0.08, 0)
DailyButton.AnchorPoint = Vector2.new(0, 1)
DailyButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
DailyButton.BackgroundTransparency = 1
DailyButton.Image = "rbxassetid://86257281348163" -- Azul por defecto
DailyButton.ZIndex = 1005
DailyButton.Parent = MenuFrame

-- GLOBO DE FUEGO DE RACHA (CORREGIDO CON IDs NUEVOS)
if DailyButton:FindFirstChild("StreakBadge") then DailyButton.StreakBadge:Destroy() end

-- Ahora es un ImageLabel (Fuego) en vez de un Frame
local StreakBadge = Instance.new("ImageLabel", DailyButton)
StreakBadge.Name = "StreakBadge"
StreakBadge.Size = UDim2.new(0.6, 0, 0.6, 0) -- Un poco más grande para que luzca el fuego
StreakBadge.Position = UDim2.new(0.6, 0, -0.2, 0) 
StreakBadge.BackgroundTransparency = 1
StreakBadge.Image = "rbxassetid://134763959761180" -- Fuego Rojo por defecto

local StreakNumMenu = Instance.new("TextLabel", StreakBadge)
StreakNumMenu.Name = "Label"
StreakNumMenu.Size = UDim2.new(0.6, 0, 0.6, 0)
StreakNumMenu.Position = UDim2.new(0.2, 0, 0.4, 0) -- Centrado en la base del fuego
StreakNumMenu.BackgroundTransparency = 1
StreakNumMenu.TextColor3 = Color3.new(1,1,1)
StreakNumMenu.Font = Enum.Font.FredokaOne
StreakNumMenu.TextScaled = true
StreakNumMenu.Text = "1"
StreakNumMenu.ZIndex = 2
-- Sombra al texto para que se lea sobre el fuego
local txtStroke = Instance.new("UIStroke", StreakNumMenu)
txtStroke.Thickness = 2
txtStroke.Color = Color3.new(0,0,0)

-- VENTANA (Ya la tienes, aseguramos referencia)
local DailyFrame = ScreenGui:FindFirstChild("DailyRewardsFrame") or Instance.new("Frame", ScreenGui)
DailyFrame.Name = "DailyRewardsFrame"

-- VENTANA DE DAILY REWARDS
local DailyFrame = Instance.new("Frame", ScreenGui)
DailyFrame.Name = "DailyRewardsFrame"
DailyFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
DailyFrame.Position = UDim2.new(0.5, 0, 0.5, 0); DailyFrame.AnchorPoint = Vector2.new(0.5, 0.5)
DailyFrame.BackgroundColor3 = Color3.fromRGB(40, 45, 60); DailyFrame.Visible = false; DailyFrame.ZIndex = 1400
Instance.new("UICorner", DailyFrame).CornerRadius = UDim.new(0, 15)
Instance.new("UIStroke", DailyFrame).Color = Color3.fromRGB(255, 200, 50); Instance.new("UIStroke", DailyFrame).Thickness = 4

local DailyTitle = Instance.new("TextLabel", DailyFrame); DailyTitle.Text = "DAILY REWARDS"; DailyTitle.Size = UDim2.new(1, 0, 0.1, 0); DailyTitle.BackgroundTransparency = 1; DailyTitle.TextColor3 = Color3.new(1,1,1); DailyTitle.Font = Enum.Font.FredokaOne; DailyTitle.TextScaled = true
local DailyClose = Instance.new("TextButton", DailyFrame); DailyClose.Text = "X"; DailyClose.Size = UDim2.new(0.08, 0, 0.08, 0); DailyClose.Position = UDim2.new(0.98, 0, 0.02, 0); DailyClose.AnchorPoint = Vector2.new(1, 0); DailyClose.BackgroundColor3 = Color3.fromRGB(255, 80, 80); DailyClose.TextColor3 = Color3.new(1,1,1); DailyClose.Font = Enum.Font.FredokaOne; DailyClose.TextScaled = true; Instance.new("UICorner", DailyClose).CornerRadius = UDim.new(0, 8)

local DailyScroll = Instance.new("ScrollingFrame", DailyFrame)
DailyScroll.Size = UDim2.new(0.95, 0, 0.85, 0); DailyScroll.Position = UDim2.new(0.5, 0, 0.55, 0); DailyScroll.AnchorPoint = Vector2.new(0.5, 0.5); DailyScroll.BackgroundTransparency = 1; DailyScroll.ScrollBarThickness = 6
local DailyLayout = Instance.new("UIGridLayout", DailyScroll); DailyLayout.CellSize = UDim2.new(0.18, 0, 0, 100); DailyLayout.CellPadding = UDim2.new(0.02, 0, 0.02, 0); DailyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- 🎵 INICIAR MÚSICA (RESTAURADO) 🎵
if MusicManager then
	-- Nos aseguramos de pasar el volumen guardado
	local savedVol = player:GetAttribute("SavedVolMusic") or 0.5
	MusicManager.init(ScreenGui, MenuFrame, savedVol)
end

-- BOTÓN SETTINGS (MENU)
SettingsBtnGlobal = Instance.new("ImageButton")
SettingsBtnGlobal.Name = "SettingsBtn"
SettingsBtnGlobal.Size = UDim2.new(0.08, 0, 0.08, 0)
SettingsBtnGlobal.AnchorPoint = Vector2.new(1, 1) 
SettingsBtnGlobal.Position = UDim2.new(0.95, 0, 0.95, 0) 
SettingsBtnGlobal.SizeConstraint = Enum.SizeConstraint.RelativeXX
SettingsBtnGlobal.BackgroundColor3 = Color3.new(0,0,0)
SettingsBtnGlobal.BackgroundTransparency = 1
SettingsBtnGlobal.Image = SETTINGS_ICON_ID
SettingsBtnGlobal.ImageColor3 = TEXT_DARK
SettingsBtnGlobal.ZIndex = 2000 
SettingsBtnGlobal.Visible = false 
SettingsBtnGlobal.Parent = ScreenGui 

-- MÓDULOS DE UI (SHOP, SETTINGS, LEADERBOARD, TITLES)
local ShopRefs = {} 
local toggleMenuButtons = nil 
local toggleMenu = nil 
local skinChangeCallback = nil

local ShopManager = require(ReplicatedStorage:WaitForChild("ShopManager"))
local ShopFrame, ShopRefs = ShopManager.init(ScreenGui, VIP_GAMEPASS_ID)

if ShopRefs.CloseBtn then
	ShopRefs.CloseBtn.MouseButton1Click:Connect(function() 
		UIUtils.closeMenuWithAnim(ShopFrame)
		toggleMenuButtons(true) 
	end)
end

-- TITLES FRAME (CON PESTAÑAS DE CATEGORÍA)
do 
	if ScreenGui:FindFirstChild("TitlesFrame") then ScreenGui.TitlesFrame:Destroy() end

	TitlesFrame = Instance.new("Frame", ScreenGui)
	TitlesFrame.Name = "TitlesFrame"
	TitlesFrame.Size = UDim2.new(0.7, 0, 0.7, 0); TitlesFrame.Position = UDim2.new(0.15, 0, 0.15, 0)
	TitlesFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35); TitlesFrame.Visible = false; TitlesFrame.ZIndex = 1300
	Instance.new("UICorner", TitlesFrame).CornerRadius = UDim.new(0, 12)

	-- HEADER
	local TitlesHeader = Instance.new("Frame", TitlesFrame)
	TitlesHeader.Size = UDim2.new(1, 0, 0.15, 0); TitlesHeader.BackgroundColor3 = Color3.fromRGB(255, 255, 255); TitlesHeader.BackgroundTransparency = 0.95; TitlesHeader.ZIndex = 1301
	Instance.new("UICorner", TitlesHeader).CornerRadius = UDim.new(0, 15)

	local WinTitle = Instance.new("TextLabel", TitlesHeader)
	WinTitle.Text = "TITLES"; WinTitle.Size = UDim2.new(1, 0, 1, 0); WinTitle.BackgroundTransparency = 1; WinTitle.TextColor3 = Color3.new(1,1,1); WinTitle.Font = Enum.Font.FredokaOne; WinTitle.TextScaled = true; WinTitle.ZIndex = 1302

	TitleCloseBtn = Instance.new("TextButton", TitlesHeader)
	TitleCloseBtn.Text = "X"; TitleCloseBtn.Size = UDim2.new(0.08, 0, 0.8, 0); TitleCloseBtn.Position = UDim2.new(0.99, 0, 0.1, 0); TitleCloseBtn.AnchorPoint = Vector2.new(1, 0); TitleCloseBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80); TitleCloseBtn.TextColor3 = Color3.new(1,1,1); TitleCloseBtn.Font = Enum.Font.FredokaOne; TitleCloseBtn.TextScaled = true; TitleCloseBtn.ZIndex = 1302
	Instance.new("UICorner", TitleCloseBtn).CornerRadius = UDim.new(0, 8)

	-- PESTAÑAS (TABS) - ¡AQUÍ ESTÁN LAS CATEGORÍAS!
	local TabsContainer = Instance.new("Frame", TitlesFrame)
	TabsContainer.Size = UDim2.new(0.9, 0, 0.1, 0); TabsContainer.Position = UDim2.new(0.05, 0, 0.16, 0); TabsContainer.BackgroundTransparency = 1; TabsContainer.ZIndex = 1301
	local tl = Instance.new("UIListLayout", TabsContainer); tl.FillDirection = Enum.FillDirection.Horizontal; tl.Padding = UDim.new(0.05, 0); tl.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local function createTab(name, cat)
		local b = Instance.new("TextButton", TabsContainer)
		b.Text = name; b.Size = UDim2.new(0.3, 0, 1, 0); b.BackgroundColor3 = Color3.fromRGB(50, 50, 55); b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamBold; b.TextScaled = true; b.ZIndex = 1302
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		b.MouseButton1Click:Connect(function()
			currentTitleCategory = cat
			populateTitlesList() -- Recarga la lista con la nueva categoría
		end)
	end
	createTab("MAIN", "Main"); createTab("FRUITS", "Fruits"); createTab("OTHERS", "Others")

	-- LISTAS
	LeftPanel = Instance.new("ScrollingFrame", TitlesFrame)
	LeftPanel.Size = UDim2.new(0.4, 0, 0.65, 0); LeftPanel.Position = UDim2.new(0.05, 0, 0.3, 0); LeftPanel.BackgroundColor3 = Color3.fromRGB(45, 45, 50); LeftPanel.ScrollBarThickness = 4; LeftPanel.ZIndex = 1301
	Instance.new("UICorner", LeftPanel).CornerRadius = UDim.new(0, 8)
	local ll = Instance.new("UIListLayout", LeftPanel); ll.Padding = UDim.new(0, 5); ll.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local RightPanel = Instance.new("Frame", TitlesFrame)
	RightPanel.Size = UDim2.new(0.45, 0, 0.65, 0); RightPanel.Position = UDim2.new(0.5, 0, 0.3, 0); RightPanel.BackgroundColor3 = Color3.fromRGB(45, 45, 50); RightPanel.ZIndex = 1301
	Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0, 8)

	PreviewTitle = Instance.new("TextLabel", RightPanel); PreviewTitle.Text = "Select"; PreviewTitle.Size = UDim2.new(0.9, 0, 0.2, 0); PreviewTitle.Position = UDim2.new(0.05, 0, 0.1, 0); PreviewTitle.BackgroundColor3 = Color3.fromRGB(30, 30, 30); PreviewTitle.TextColor3 = Color3.new(1,1,1); PreviewTitle.Font = Enum.Font.FredokaOne; PreviewTitle.TextScaled = true; PreviewTitle.ZIndex = 1302; Instance.new("UICorner", PreviewTitle).CornerRadius = UDim.new(0, 6)
	DescLabel = Instance.new("TextLabel", RightPanel); DescLabel.Text = "..."; DescLabel.Size = UDim2.new(0.9, 0, 0.4, 0); DescLabel.Position = UDim2.new(0.05, 0, 0.35, 0); DescLabel.BackgroundTransparency = 1; DescLabel.TextColor3 = Color3.fromRGB(200, 200, 200); DescLabel.Font = Enum.Font.GothamMedium; DescLabel.TextScaled = true; DescLabel.TextWrapped = true; DescLabel.ZIndex = 1302; DescLabel.Parent = RightPanel
	EquipButton = Instance.new("TextButton", RightPanel); EquipButton.Text = "EQUIP"; EquipButton.Size = UDim2.new(0.8, 0, 0.15, 0); EquipButton.Position = UDim2.new(0.1, 0, 0.8, 0); EquipButton.BackgroundColor3 = Color3.fromHex("f65e3b"); EquipButton.TextColor3 = Color3.new(1,1,1); EquipButton.Font = Enum.Font.GothamBold; EquipButton.TextScaled = true; EquipButton.ZIndex = 1302; Instance.new("UICorner", EquipButton).CornerRadius = UDim.new(0, 8)
end


local SettingsManager = require(ReplicatedStorage:WaitForChild("SettingsManager"))
local SettingsFrame, StatsFrame, StRefs = SettingsManager.init(ScreenGui, MenuFrame)

if StRefs.SCloseBtn then
	StRefs.SCloseBtn.MouseButton1Click:Connect(function() if not MainFrame.Visible then toggleMenuButtons(true) end end)
end
if StRefs.StatsCloseBtn then
	StRefs.StatsCloseBtn.MouseButton1Click:Connect(function() if not MainFrame.Visible then toggleMenuButtons(true) end end)
end

local LeaderboardManager = require(ReplicatedStorage:WaitForChild("LeaderboardManager"))
local LeaderboardFrame, LbRefs = LeaderboardManager.init(ScreenGui)

if LbRefs.CloseBtn then
	LbRefs.CloseBtn.MouseButton1Click:Connect(function() UIUtils.closeMenuWithAnim(LeaderboardFrame); toggleMenuButtons(true) end) 
end

-- GAME CONTAINER (UNA SOLA VEZ)
MainFrame = Instance.new("Frame")
MainFrame.Name = "GameContainer"
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundColor3 = BG_COLOR
MainFrame.Visible = false
MainFrame.ZIndex = 500
MainFrame.Parent = ScreenGui

local BoardFrame = Instance.new("Frame")
BoardFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
BoardFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
BoardFrame.Position = UDim2.new(0.5, 0, 0.55, 0)
BoardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
BoardFrame.BackgroundColor3 = BOARD_COLOR
BoardFrame.Parent = MainFrame
Instance.new("UICorner", BoardFrame).CornerRadius = UDim.new(0, 6)

local TilesLayer = Instance.new("Frame")
TilesLayer.Size = UDim2.new(1, 0, 1, 0)
TilesLayer.BackgroundTransparency = 1
TilesLayer.ZIndex = 10
TilesLayer.Parent = BoardFrame

-- SCORE BOXES
local ScoreContainer = Instance.new("Frame")
ScoreContainer.Size = UDim2.new(0.22, 0, 0.1, 0)
ScoreContainer.Position = UDim2.new(0.02, 0, 0.15, 0) 
ScoreContainer.BackgroundColor3 = BOARD_COLOR
ScoreContainer.Parent = MainFrame
Instance.new("UICorner", ScoreContainer).CornerRadius = UDim.new(0, 6)

local ScoreTitle = Instance.new("TextLabel")
ScoreTitle.Text = "SCORE"
ScoreTitle.Size = UDim2.new(1, 0, 0.4, 0)
ScoreTitle.BackgroundTransparency = 1
ScoreTitle.TextColor3 = Color3.new(0.9,0.9,0.9)
ScoreTitle.Font = Enum.Font.GothamBold
ScoreTitle.TextScaled = true
ScoreTitle.Parent = ScoreContainer

local ScoreLabel = Instance.new("TextLabel")
ScoreLabel.Text = "0"
ScoreLabel.Size = UDim2.new(1, 0, 0.6, 0)
ScoreLabel.Position = UDim2.new(0, 0, 0.4, 0)
ScoreLabel.BackgroundTransparency = 1
ScoreLabel.TextColor3 = Color3.new(1,1,1)
ScoreLabel.Font = Enum.Font.GothamBold
ScoreLabel.TextScaled = true
ScoreLabel.Parent = ScoreContainer

local BestScoreContainer = Instance.new("Frame")
BestScoreContainer.Size = UDim2.new(0.22, 0, 0.1, 0)
BestScoreContainer.Position = UDim2.new(0.02, 0, 0.27, 0) 
BestScoreContainer.BackgroundColor3 = BOARD_COLOR
BestScoreContainer.Parent = MainFrame
Instance.new("UICorner", BestScoreContainer).CornerRadius = UDim.new(0, 6)

local BestScoreTitle = Instance.new("TextLabel")
BestScoreTitle.Text = "BEST"
BestScoreTitle.Size = UDim2.new(1, 0, 0.4, 0)
BestScoreTitle.BackgroundTransparency = 1
BestScoreTitle.TextColor3 = Color3.new(0.9,0.9,0.9)
BestScoreTitle.Font = Enum.Font.GothamBold
BestScoreTitle.TextScaled = true
BestScoreTitle.Parent = BestScoreContainer

local BestScoreLabel = Instance.new("TextLabel")
BestScoreLabel.Text = "0"
BestScoreLabel.Size = UDim2.new(1, 0, 0.6, 0)
BestScoreLabel.Position = UDim2.new(0, 0, 0.4, 0)
BestScoreLabel.BackgroundTransparency = 1
BestScoreLabel.TextColor3 = Color3.new(1,1,1)
BestScoreLabel.Font = Enum.Font.GothamBold
BestScoreLabel.TextScaled = true
BestScoreLabel.Parent = BestScoreContainer

-- COINS DISPLAY
local CoinContainer = Instance.new("Frame")
CoinContainer.Size = UDim2.new(0.18, 0, 0.12, 0) 
CoinContainer.Position = UDim2.new(0.02, 0, 0.39, 0) 
CoinContainer.BackgroundColor3 = Color3.fromRGB(255, 220, 80) 
CoinContainer.ZIndex = 505
CoinContainer.Parent = MainFrame
Instance.new("UICorner", CoinContainer).CornerRadius = UDim.new(0, 8)
local CoinStroke = Instance.new("UIStroke"); CoinStroke.Color = Color3.fromRGB(220, 180, 50); CoinStroke.Thickness = 3; CoinStroke.Parent = CoinContainer

local CoinIcon = Instance.new("ImageLabel")
CoinIcon.Size = UDim2.new(0.5, 0, 0.5, 0) 
CoinIcon.AnchorPoint = Vector2.new(0, 0.5)
CoinIcon.Position = UDim2.new(0.05, 0, 0.5, 0)
CoinIcon.SizeConstraint = Enum.SizeConstraint.RelativeYY 
CoinIcon.BackgroundTransparency = 1
CoinIcon.Image = "rbxassetid://108796514719654" 
CoinIcon.ZIndex = 506
CoinIcon.Parent = CoinContainer

local CoinLabel = Instance.new("TextLabel")
CoinLabel.Text = "0"
CoinLabel.Size = UDim2.new(0.6, 0, 0.8, 0)
CoinLabel.AnchorPoint = Vector2.new(0, 0.5)
CoinLabel.Position = UDim2.new(0.35, 0, 0.5, 0)
CoinLabel.BackgroundTransparency = 1
CoinLabel.TextColor3 = Color3.new(0.2, 0.2, 0.2)
CoinLabel.Font = Enum.Font.FredokaOne
CoinLabel.TextScaled = true
CoinLabel.TextXAlignment = Enum.TextXAlignment.Left
CoinLabel.ZIndex = 506
CoinLabel.Parent = CoinContainer

-- GEMS (DIAMONDS)
local FruitContainer = Instance.new("Frame")
FruitContainer.Size = UDim2.new(0.18, 0, 0.12, 0)
FruitContainer.Position = UDim2.new(0.02, 0, 0.52, 0)
FruitContainer.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
FruitContainer.ZIndex = 505
FruitContainer.Parent = MainFrame
Instance.new("UICorner", FruitContainer).CornerRadius = UDim.new(0, 8)
local FruitStroke = Instance.new("UIStroke"); FruitStroke.Color = Color3.fromRGB(0, 100, 200); FruitStroke.Thickness = 3; FruitStroke.Parent = FruitContainer

local FruitIcon = Instance.new("ImageLabel")
FruitIcon.Size = UDim2.new(0.6, 0, 0.6, 0)
FruitIcon.AnchorPoint = Vector2.new(0, 0.5)
FruitIcon.Position = UDim2.new(0.05, 0, 0.5, 0)
FruitIcon.SizeConstraint = Enum.SizeConstraint.RelativeYY
FruitIcon.BackgroundTransparency = 1
FruitIcon.Image = "rbxassetid://111308733495717" 
FruitIcon.ZIndex = 506
FruitIcon.Parent = FruitContainer

local FruitLabel = Instance.new("TextLabel")
FruitLabel.Text = "0"
FruitLabel.Size = UDim2.new(0.6, 0, 0.8, 0)
FruitLabel.AnchorPoint = Vector2.new(0, 0.5)
FruitLabel.Position = UDim2.new(0.35, 0, 0.5, 0)
FruitLabel.BackgroundTransparency = 1
FruitLabel.TextColor3 = Color3.new(0.2, 0.2, 0.2)
FruitLabel.Font = Enum.Font.FredokaOne
FruitLabel.TextScaled = true
FruitLabel.TextXAlignment = Enum.TextXAlignment.Left
FruitLabel.ZIndex = 506
FruitLabel.Parent = FruitContainer

-- REAL FRUIT GEMS DISPLAY (Para el Modo Frutas)
local FruitGemContainer = Instance.new("Frame")
FruitGemContainer.Size = UDim2.new(0.18, 0, 0.12, 0)
FruitGemContainer.Position = UDim2.new(0.02, 0, 0.65, 0) -- Un poco más abajo
FruitGemContainer.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
FruitGemContainer.ZIndex = 505
FruitGemContainer.Visible = false -- Oculto por defecto
FruitGemContainer.Parent = MainFrame
Instance.new("UICorner", FruitGemContainer).CornerRadius = UDim.new(0, 8)
local FStroke = Instance.new("UIStroke", FruitGemContainer); FStroke.Color = Color3.fromRGB(200, 50, 50); FStroke.Thickness = 3

local FruitGemIcon = Instance.new("ImageLabel", FruitGemContainer)
FruitGemIcon.Size = UDim2.new(0.6, 0, 0.6, 0)
FruitGemIcon.AnchorPoint = Vector2.new(0, 0.5)
FruitGemIcon.Position = UDim2.new(0.05, 0, 0.5, 0)
FruitGemIcon.SizeConstraint = Enum.SizeConstraint.RelativeYY
FruitGemIcon.BackgroundTransparency = 1
FruitGemIcon.Image = "rbxassetid://128100423386205" -- Fresa
FruitGemIcon.ZIndex = 506

local FruitGemLabel = Instance.new("TextLabel", FruitGemContainer)
FruitGemLabel.Text = "0"
FruitGemLabel.Size = UDim2.new(0.6, 0, 0.8, 0)
FruitGemLabel.AnchorPoint = Vector2.new(0, 0.5)
FruitGemLabel.Position = UDim2.new(0.35, 0, 0.5, 0)
FruitGemLabel.BackgroundTransparency = 1
FruitGemLabel.TextColor3 = Color3.new(0.2, 0.2, 0.2)
FruitGemLabel.Font = Enum.Font.FredokaOne
FruitGemLabel.TextScaled = true
FruitGemLabel.TextXAlignment = Enum.TextXAlignment.Left
FruitGemLabel.ZIndex = 506

-- LEVEL BAR (RIGHT)
local LevelContainer = Instance.new("Frame")
LevelContainer.Size = UDim2.new(0.2, 0, 0.08, 0)
LevelContainer.AnchorPoint = Vector2.new(1, 0.5)
LevelContainer.Position = UDim2.new(0.98, 0, 0.5, 0)
LevelContainer.BackgroundTransparency = 1
LevelContainer.ZIndex = 505
LevelContainer.Parent = MainFrame

local LevelIcon = Instance.new("ImageLabel")
LevelIcon.Size = UDim2.new(1.3, 0, 1.3, 0)
LevelIcon.SizeConstraint = Enum.SizeConstraint.RelativeYY
LevelIcon.AnchorPoint = Vector2.new(0.5, 0.5)
LevelIcon.Position = UDim2.new(0.1, 0, 0.5, 0)
LevelIcon.BackgroundTransparency = 1
LevelIcon.Image = "rbxassetid://128231447120718"
LevelIcon.ZIndex = 508
LevelIcon.Parent = LevelContainer

local LevelNumLabel = Instance.new("TextLabel")
LevelNumLabel.Name = "LevelNum"
LevelNumLabel.Text = "1"
LevelNumLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
LevelNumLabel.AnchorPoint = Vector2.new(0.5, 0.5)
LevelNumLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
LevelNumLabel.BackgroundTransparency = 1
LevelNumLabel.TextColor3 = Color3.new(1,1,1)
LevelNumLabel.Font = Enum.Font.FredokaOne
LevelNumLabel.TextScaled = true
LevelNumLabel.ZIndex = 509
LevelNumLabel.Parent = LevelIcon

local LevelBarBG = Instance.new("Frame")
LevelBarBG.Size = UDim2.new(0.75, 0, 0.5, 0)
LevelBarBG.Position = UDim2.new(0.25, 0, 0.25, 0)
LevelBarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
LevelBarBG.ZIndex = 506
LevelBarBG.Parent = LevelContainer
Instance.new("UICorner", LevelBarBG).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", LevelBarBG).Color = Color3.new(1,1,1); Instance.new("UIStroke", LevelBarBG).Thickness = 2

local LevelBarFill = Instance.new("Frame")
LevelBarFill.Size = UDim2.new(0, 0, 1, 0)
LevelBarFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
LevelBarFill.ZIndex = 507
LevelBarFill.Parent = LevelBarBG
Instance.new("UICorner", LevelBarFill).CornerRadius = UDim.new(1, 0)

local LevelProgressText = Instance.new("TextLabel")
LevelProgressText.Text = "0%"
LevelProgressText.Size = UDim2.new(1, 0, 0.8, 0)
LevelProgressText.Position = UDim2.new(0, 0, 0.1, 0)
LevelProgressText.BackgroundTransparency = 1
LevelProgressText.TextColor3 = Color3.new(1,1,1)
LevelProgressText.Font = Enum.Font.GothamBold
LevelProgressText.TextScaled = true
LevelProgressText.ZIndex = 508
LevelProgressText.Parent = LevelBarBG

-- MENU BUTTON
BackButton = Instance.new("TextButton")
BackButton.Text = "MENU"
BackButton.Size = UDim2.new(0.2, 0, 0.06, 0)
BackButton.Position = UDim2.new(0.05, 0, 0.92, 0) 
BackButton.AnchorPoint = Vector2.new(0, 1)
BackButton.BackgroundColor3 = Color3.fromHex("8f7a66")
BackButton.TextColor3 = Color3.new(1,1,1)
BackButton.Font = Enum.Font.GothamBold
BackButton.TextScaled = true
BackButton.ZIndex = 505
BackButton.Parent = MainFrame
Instance.new("UICorner", BackButton).CornerRadius = UDim.new(0, 6)

-- UNDO BUTTON
UndoButton = Instance.new("ImageButton")
UndoButton.Size = UDim2.new(0.08, 0, 0.08, 0)
UndoButton.AnchorPoint = Vector2.new(1, 1)
UndoButton.Position = UDim2.new(0.95, 0, 0.92, 0)
UndoButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
UndoButton.BackgroundTransparency = 1
UndoButton.Image = UNDO_ICON_ID
UndoButton.ScaleType = Enum.ScaleType.Fit
UndoButton.ImageColor3 = Color3.new(1,1,1)
UndoButton.ZIndex = 505
UndoButton.Parent = MainFrame

local AspectRatio = Instance.new("UIAspectRatioConstraint")
AspectRatio.AspectRatio = 1 
AspectRatio.Parent = UndoButton

local UndoCountLabel = Instance.new("TextLabel")
UndoCountLabel.Name = "Count"
UndoCountLabel.Text = "3"
UndoCountLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
UndoCountLabel.Position = UDim2.new(0.55, 0, 0.55, 0) 
UndoCountLabel.BackgroundTransparency = 1 
UndoCountLabel.TextColor3 = Color3.new(1,1,1)
UndoCountLabel.Font = Enum.Font.GothamBlack
UndoCountLabel.TextStrokeTransparency = 0.5
UndoCountLabel.TextScaled = true
UndoCountLabel.ZIndex = 506
UndoCountLabel.Parent = UndoButton

-- SETTINGS BTN (IN-GAME)
SettingsBtnGame = Instance.new("ImageButton")
SettingsBtnGame.Name = "SettingsBtnGame"
SettingsBtnGame.Size = UDim2.new(0.08, 0, 0.08, 0)
SettingsBtnGame.AnchorPoint = Vector2.new(1, 0)
SettingsBtnGame.Position = UDim2.new(0.95, 0, 0.05, 0) 
SettingsBtnGame.SizeConstraint = Enum.SizeConstraint.RelativeXX
SettingsBtnGame.BackgroundTransparency = 1 
SettingsBtnGame.Image = SETTINGS_ICON_ID
SettingsBtnGame.ImageColor3 = TEXT_DARK 
SettingsBtnGame.ZIndex = 505
SettingsBtnGame.Parent = MainFrame

-- GAME OVER SCREEN
local GameOverFrame = Instance.new("Frame")
GameOverFrame.Name = "GameOverFrame"
GameOverFrame.Size = UDim2.new(1, 0, 1, 0)
GameOverFrame.BackgroundColor3 = Color3.new(0, 0, 0)
GameOverFrame.BackgroundTransparency = 0.5 
GameOverFrame.ZIndex = 800
GameOverFrame.Visible = false
GameOverFrame.Parent = MainFrame

local GameOverText = Instance.new("TextLabel")
GameOverText.Text = "GAME OVER!"
GameOverText.Size = UDim2.new(1, 0, 0.2, 0)
GameOverText.Position = UDim2.new(0, 0, 0.3, 0)
GameOverText.BackgroundTransparency = 1
GameOverText.TextColor3 = Color3.new(1,1,1)
GameOverText.Font = Enum.Font.FredokaOne
GameOverText.TextScaled = true
GameOverText.ZIndex = 801
GameOverText.Parent = GameOverFrame

local TryAgainButton = Instance.new("TextButton")
TryAgainButton.Text = "TRY AGAIN"
TryAgainButton.Size = UDim2.new(0.4, 0, 0.08, 0)
TryAgainButton.Position = UDim2.new(0.3, 0, 0.55, 0)
TryAgainButton.BackgroundColor3 = Color3.fromHex("f65e3b")
TryAgainButton.TextColor3 = Color3.new(1,1,1)
TryAgainButton.Font = Enum.Font.GothamBold
TryAgainButton.TextScaled = true
TryAgainButton.ZIndex = 802
TryAgainButton.Parent = GameOverFrame
Instance.new("UICorner", TryAgainButton).CornerRadius = UDim.new(0, 6)

local GameOverMenuButton = Instance.new("TextButton")
GameOverMenuButton.Text = "MAIN MENU"
GameOverMenuButton.Size = UDim2.new(0.4, 0, 0.08, 0)
GameOverMenuButton.Position = UDim2.new(0.3, 0, 0.65, 0)
GameOverMenuButton.BackgroundColor3 = Color3.fromHex("8f7a66")
GameOverMenuButton.TextColor3 = Color3.new(1,1,1)
GameOverMenuButton.Font = Enum.Font.GothamBold
GameOverMenuButton.TextScaled = true
GameOverMenuButton.ZIndex = 802
GameOverMenuButton.Parent = GameOverFrame
Instance.new("UICorner", GameOverMenuButton).CornerRadius = UDim.new(0, 6)

-- EXIT CONFIRMATION
local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Size = UDim2.new(0.6, 0, 0.3, 0)
ConfirmFrame.Position = UDim2.new(0.2, 0, 0.35, 0)
ConfirmFrame.BackgroundColor3 = BOARD_COLOR
ConfirmFrame.ZIndex = 900
ConfirmFrame.Visible = false
ConfirmFrame.Parent = MainFrame
Instance.new("UICorner", ConfirmFrame).CornerRadius = UDim.new(0, 8)

local ConfirmText = Instance.new("TextLabel")
ConfirmText.Text = "Are you sure? You will lose your progress"
ConfirmText.Size = UDim2.new(0.9, 0, 0.4, 0)
ConfirmText.Position = UDim2.new(0.05, 0, 0.1, 0)
ConfirmText.BackgroundTransparency = 1
ConfirmText.TextColor3 = Color3.new(1,1,1)
ConfirmText.Font = Enum.Font.GothamBold
ConfirmText.TextScaled = true
ConfirmText.ZIndex = 901
ConfirmText.Parent = ConfirmFrame

local YesButton = Instance.new("TextButton")
YesButton.Text = "YES"
YesButton.Size = UDim2.new(0.4, 0, 0.3, 0)
YesButton.Position = UDim2.new(0.05, 0, 0.6, 0)
YesButton.BackgroundColor3 = Color3.fromHex("f65e3b")
YesButton.TextColor3 = Color3.new(1,1,1)
YesButton.Font = Enum.Font.GothamBold
YesButton.TextScaled = true
YesButton.ZIndex = 902
YesButton.Parent = ConfirmFrame
Instance.new("UICorner", YesButton).CornerRadius = UDim.new(0, 6)

local NoButton = Instance.new("TextButton")
NoButton.Text = "NO"
NoButton.Size = UDim2.new(0.4, 0, 0.3, 0)
NoButton.Position = UDim2.new(0.55, 0, 0.6, 0)
NoButton.BackgroundColor3 = Color3.fromHex("8f7a66")
NoButton.TextColor3 = Color3.new(1,1,1)
NoButton.Font = Enum.Font.GothamBold
NoButton.TextScaled = true
NoButton.ZIndex = 902
NoButton.Parent = ConfirmFrame
Instance.new("UICorner", NoButton).CornerRadius = UDim.new(0, 6)
RunService.RenderStepped:Connect(function(dt)
	if currentSkin == "Rainbow" and MainFrame.Visible then
		local time = tick() * 0.5 -- Velocidad de la animación

		-- 1. Animar el borde del tablero suavemente
		local boardF = MainFrame:FindFirstChild("Frame")
		if boardF then
			boardF.BackgroundColor3 = Color3.fromHSV((time * 0.2) % 1, 0.8, 0.5) -- Color oscuro rotativo
		end

		-- 2. ANIMAR FICHAS (Efecto Ola Diagonal)
		-- Recorremos la matriz visual para pintar cada ficha según su posición
		for r = 1, BOARD_SIZE do
			if tileVisuals[r] then
				for c = 1, BOARD_SIZE do
					local tile = tileVisuals[r][c]
					if tile then
						-- La magia: El color depende del tiempo Y de la posición (r+c)
						-- Esto crea una diagonal de colores que se mueve
						local waveHue = (time + (r + c) * 0.15) % 1
						local rgbColor = Color3.fromHSV(waveHue, 0.85, 1) -- Color brillante

						tile.BackgroundColor3 = rgbColor

						-- Si tiene borde (UIStroke), lo ponemos blanco o más brillante
						local s = tile:FindFirstChild("UIStroke")
						if s then 
							s.Color = Color3.new(1,1,1) -- Borde blanco para resaltar el RGB
							s.Transparency = 0.5
						end

						-- Texto siempre blanco
						local txt = tile:FindFirstChild("TextLabel")
						if txt then txt.TextColor3 = Color3.new(1,1,1) end
					end
				end
			end
		end
	end
end)

-------------------------------------------------------------------------
-- 4. GAME LOGIC & VFX (2048 ENGINE)
-------------------------------------------------------------------------
board = {}          -- CORREGIDO: Sin "local"
tileVisuals = {}    -- CORREGIDO: Sin "local"
local score = 0
local highScore = 0 
local isAnimating = false
local undoCount = FREE_UNDOS
local gameStateStack = {} 

local function getCenterPosition(r, c)
	local x = PADDING + (c-1)*(CELL_SIZE+PADDING) + (CELL_SIZE/2)
	local y = PADDING + (r-1)*(CELL_SIZE+PADDING) + (CELL_SIZE/2)
	return UDim2.new(x, 0, y, 0)
end

local function clearVisuals()
	TilesLayer:ClearAllChildren()
	tileVisuals = {}
	-- CORRECCIÓN: Usar BOARD_SIZE en lugar de 4
	for r=1, BOARD_SIZE do 
		tileVisuals[r]={} 
	end
end

-- VFX: EXPLOSIÓN DE CONFETI (SOPORTA IMÁGENES)
local function spawnConfetti(centerPos, colorOrId, isImage)
	for i = 1, 8 do 
		local p
		if isImage then
			p = Instance.new("ImageLabel")
			p.Image = colorOrId
			p.BackgroundTransparency = 1
		else
			p = Instance.new("Frame")
			p.BackgroundColor3 = colorOrId
			p.BorderSizePixel = 0
		end

		p.Size = UDim2.new(0.08, 0, 0.08, 0)
		p.Position = centerPos
		p.Parent = TilesLayer
		p.ZIndex = 50

		local angle = math.rad(math.random(0, 360))
		local dist = 0.12 + (math.random()*0.05)
		local targetPos = centerPos + UDim2.new(math.cos(angle)*dist, 0, math.sin(angle)*dist, 0)

		local properties = {
			Position = targetPos,
			Rotation = math.random(0, 360)
		}
		if isImage then properties.ImageTransparency = 1 else properties.BackgroundTransparency = 1 end

		local tween = TweenService:Create(p, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
		tween:Play()
		Debris:AddItem(p, 0.4)
	end
end

-- ✨ NUEVA FUNCIÓN: TEXTO FLOTANTE DE XP (V11.0 - Arriba de la Barra)
local function spawnFloatingXP(ignoredPos, amount, isDouble)
	local showXP = player:GetAttribute("SavedShowXP")
	if showXP == false then return end 

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.20, 0, 0.08, 0)

	-- 1. POSICIÓN: ARRIBA DE LA BARRA
	-- La barra está en Y=0.5. Nosotros nos ponemos en Y=0.42 (Arriba).
	-- En X nos ponemos en 0.88 para estar centrados sobre la barra.
	local randomX = math.random(-20, 20) / 1000 
	local randomY = math.random(-10, 10) / 1000 

	label.Position = UDim2.new(0.88 + randomX, 0, 0.42 + randomY, 0)
	label.AnchorPoint = Vector2.new(0.5, 1) -- Anclado abajo-centro (crece hacia arriba)

	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.ZIndex = 200 
	label.Parent = MainFrame 

	-- 2. COLOR
	local baseColor, strokeColor
	if amount <= 4 then
		baseColor = Color3.fromRGB(120, 255, 120); strokeColor = Color3.fromRGB(0, 100, 0) 
	elseif amount <= 8 then
		baseColor = Color3.fromRGB(0, 255, 255); strokeColor = Color3.fromRGB(0, 100, 150) 
	elseif amount <= 16 then
		baseColor = Color3.fromRGB(255, 180, 50); strokeColor = Color3.fromRGB(150, 50, 0) 
	elseif amount <= 32 then
		baseColor = Color3.fromRGB(255, 100, 220); strokeColor = Color3.fromRGB(150, 0, 100) 
	else
		baseColor = Color3.fromRGB(255, 50, 50); strokeColor = Color3.fromRGB(100, 0, 0) 
	end

	-- 3. ESTILO
	label.TextColor3 = baseColor
	if isDouble then
		label.TextStrokeColor3 = Color3.fromRGB(255, 215, 0)
		label.TextStrokeTransparency = 0
		label.Text = "✨ +" .. amount .. " XP" 
	else
		label.TextStrokeColor3 = strokeColor
		label.TextStrokeTransparency = 0.3
		label.Text = "+" .. amount .. " XP" 
	end

	-- 4. ANIMACIÓN RÁPIDA
	-- Sube un poco más hacia arriba
	local targetPos = label.Position - UDim2.new(0, 0, 0.08, 0) 

	local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tweenMove = TweenService:Create(label, tweenInfo, {Position = targetPos})

	task.delay(0.4, function()
		if label and label.Parent then
			local tweenFade = TweenService:Create(label, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, TextStrokeTransparency = 1})
			tweenFade:Play()
		end
	end)

	tweenMove:Play()
	game.Debris:AddItem(label, 0.9) 
end


-- 1. FUNCIÓN VISUAL NEÓN (Esta es la que te faltaba)
local function UpdateTileVisuals(frame, value)
	local neonColor
	if value == 2 or value == 4 or value == 128 or value == 256 then
		neonColor = Color3.fromRGB(0, 255, 255) -- Cian
	else
		neonColor = Color3.fromRGB(255, 50, 220) -- Magenta
	end

	frame.ClipsDescendants = false 
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
	frame.BorderSizePixel = 0
	frame.ZIndex = 10 

	local corner = frame:FindFirstChild("UICorner") or Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0.15, 0)

	-- Brillo suave
	local softGlow = frame:FindFirstChild("NeonSoftGlow") or Instance.new("ImageLabel", frame)
	softGlow.Name = "NeonSoftGlow"
	softGlow.BackgroundTransparency = 1
	softGlow.Image = "rbxassetid://1316045217" 
	softGlow.ImageColor3 = neonColor
	softGlow.ImageTransparency = 0.4 
	softGlow.Size = UDim2.new(1.0, 0, 1.0, 0) 
	softGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
	softGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	softGlow.ZIndex = 0 

	-- Borde Neón
	local stroke = frame:FindFirstChild("UIStroke") or Instance.new("UIStroke", frame)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = neonColor
	stroke.Thickness = 4 
	stroke.Transparency = 0
	stroke.Enabled = true

	-- Circuito
	local circuit = frame:FindFirstChild("CircuitImage") or Instance.new("ImageLabel", frame)
	circuit.Name = "CircuitImage"
	circuit.BackgroundTransparency = 1
	circuit.Size = UDim2.new(1, 0, 1, 0)
	circuit.Image = "rbxassetid://85388047115646" 
	circuit.ImageColor3 = neonColor
	circuit.ImageTransparency = 0.5 
	circuit.ScaleType = Enum.ScaleType.Crop
	circuit.ZIndex = 1
	local circuitCorner = circuit:FindFirstChild("UICorner") or Instance.new("UICorner", circuit)
	circuitCorner.CornerRadius = UDim.new(0.15, 0)

	-- Texto
	local label = frame:FindFirstChild("TextLabel") or Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = tostring(value)
	label.TextColor3 = neonColor 
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.ZIndex = 2
	label.TextStrokeColor3 = neonColor
	label.TextStrokeTransparency = 0.8 

	local pad = label:FindFirstChild("UIPadding") or Instance.new("UIPadding", label)
	pad.PaddingTop = UDim.new(0.15, 0)
	pad.PaddingBottom = UDim.new(0.15, 0)
end

-- 2. FUNCIÓN VISUAL ROBOT
local function UpdateTileVisuals_Robot(frame, value, theme)
	frame.ClipsDescendants = true
	-- Usamos color de la tabla o gris si falla
	local baseColor = theme.Tiles[value] or Color3.fromRGB(150,150,150)
	frame.BackgroundColor3 = baseColor
	frame.BorderSizePixel = 0

	-- Borde Grueso Gris (Estilo Robot)
	local stroke = frame:FindFirstChild("UIStroke") or Instance.new("UIStroke", frame)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.fromRGB(60, 65, 70) 
	stroke.Thickness = 5 
	stroke.Transparency = 0
	stroke.Enabled = true

	local corner = frame:FindFirstChild("UICorner") or Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0, theme.CornerRadius or 6)

	-- Texto Industrial
	local label = frame:FindFirstChild("TextLabel") or Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = tostring(value)
	label.Font = Enum.Font.FredokaOne 
	label.TextScaled = true

	-- Contraste de texto
	if value == 2 or value == 256 then
		label.TextColor3 = Color3.new(0.2, 0.2, 0.2)
	else
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
		label.TextStrokeTransparency = 0.6
	end
	label.ZIndex = 2

	local pad = label:FindFirstChild("UIPadding") or Instance.new("UIPadding", label)
	pad.PaddingTop = UDim.new(0.15, 0)
	pad.PaddingBottom = UDim.new(0.15, 0)
end

-- 3. FUNCIÓN VISUAL VOLCANIC
-- 3. FUNCIÓN VISUAL VOLCANIC (Versión Final: Números de Fuego con Color Variable + Profundidad 3D)
local function UpdateTileVisuals_Volcanic(frame, value)
	-- [LIMPIEZA Y BASE]
	frame:ClearAllChildren()
	frame.ClipsDescendants = false 
	frame.BackgroundColor3 = Color3.fromRGB(25, 20, 20) -- Roca oscura
	frame.BorderSizePixel = 0
	frame.ZIndex = 10

	local corner = Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0.15, 0)

	-- [CAPA 1: TEXTURA DE ROCA]
	local rockTex = Instance.new("ImageLabel", frame)
	rockTex.Name = "RockTexture"
	rockTex.Size = UDim2.new(1, 0, 1, 0)
	rockTex.BackgroundTransparency = 1
	-- Asegúrate de que este ID sea correcto para tu textura de roca
	rockTex.Image = "rbxassetid://120246405984277" 
	rockTex.ImageColor3 = Color3.fromRGB(180, 180, 180)
	rockTex.ScaleType = Enum.ScaleType.Tile
	rockTex.TileSize = UDim2.new(0.5, 0, 0.5, 0)
	rockTex.ZIndex = 11
	Instance.new("UICorner", rockTex).CornerRadius = UDim.new(0.15, 0)

	-- [CAPA 2: BORDE EXTERIOR 3D]
	local outerStroke = Instance.new("UIStroke", frame)
	outerStroke.Thickness = 3
	outerStroke.Color = Color3.fromRGB(10, 5, 5)
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	-- [CAPA 3: EL CRÁTER (Contenedor)]
	local craterFrame = Instance.new("Frame", frame)
	craterFrame.Name = "Crater"
	craterFrame.Size = UDim2.new(0.85, 0, 0.85, 0)
	craterFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	craterFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	craterFrame.BackgroundColor3 = Color3.fromRGB(40, 10, 0)
	craterFrame.ZIndex = 12
	Instance.new("UICorner", craterFrame).CornerRadius = UDim.new(0.25, 0)

	-- Sombra interna del cráter
	local innerShadow = Instance.new("UIStroke", craterFrame)
	innerShadow.Thickness = 4
	innerShadow.Color = Color3.fromRGB(20, 5, 0)
	innerShadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	-- [CAPA 4: LA LAVA (Fondo del número)]
	local lavaFill = Instance.new("ImageLabel", craterFrame)
	lavaFill.Size = UDim2.new(1, -6, 1, -6)
	lavaFill.Position = UDim2.new(0.5, 0, 0.5, 0)
	lavaFill.AnchorPoint = Vector2.new(0.5, 0.5)
	lavaFill.BackgroundTransparency = 1
	lavaFill.ScaleType = Enum.ScaleType.Crop
	lavaFill.ZIndex = 13
	Instance.new("UICorner", lavaFill).CornerRadius = UDim.new(0.22, 0)

	-- Selección de textura y color base de lava según valor
	local lavaColor
	if value <= 8 then
		lavaFill.Image = "rbxassetid://92214905274314"
		lavaColor = Color3.fromRGB(255, 120, 50)
	elseif value <= 64 then
		lavaFill.Image = "rbxassetid://117595917570651"
		lavaColor = Color3.fromRGB(255, 180, 0)
	else
		lavaFill.Image = "rbxassetid://125266390559404"
		lavaColor = Color3.fromRGB(255, 255, 150)
	end
	lavaFill.ImageColor3 = lavaColor

	-- [CAPA 5: GRADIENTE DE CALOR (Lava fondo)]
	local lavaGradient = Instance.new("UIGradient", lavaFill)
	lavaGradient.Rotation = 90
	lavaGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(220, 220, 220)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(200, 200, 200))
	}

	-- [CAPA 6: GLOW INTERNO (Borde de calor alrededor de la lava)]
	local heatStroke = Instance.new("UIStroke", lavaFill)
	heatStroke.Thickness = 2
	heatStroke.Color = Color3.fromRGB(255, 100, 0)
	heatStroke.Transparency = 0.5
	heatStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	-- [CAPA 7: TEXTO FLOTANTE DE FUEGO VARIABLE] -> ¡CAMBIOS AQUÍ!
	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = tostring(value)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.ZIndex = 15

	-- Importante: Color base blanco para que los gradientes funcionen bien
	label.TextColor3 = Color3.new(1, 1, 1) 

	local textGradient = Instance.new("UIGradient", label)
	textGradient.Rotation = 90 -- Gradiente vertical

	-- LÓGICA DE COLOR DEL TEXTO SEGÚN VALOR
	local colorSeq
	if value <= 4 then
		-- WHITE HOT (Números bajos: Muy caliente, blanco/amarillo brillante)
		colorSeq = ColorSequence.new{
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 180)), -- Amarillo pálido
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), -- Blanco núcleo
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 220, 100))  -- Amarillo dorado
		}
	elseif value <= 32 then
		-- MAGMA ORANGE (Números medios: Naranja intenso clásico)
		colorSeq = ColorSequence.new{
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 160, 0)),   -- Naranja
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 100)), -- Amarillo brillante
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 60, 0))     -- Rojo naranja
		}
	else
		-- DEEP RED HEAT (Números altos: Rojo profundo e intenso)
		colorSeq = ColorSequence.new{
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(220, 60, 0)),    -- Rojo oscuro
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 0)),   -- Naranja intenso
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(180, 30, 0))     -- Granate
		}
	end

	-- Aplicamos la secuencia de color seleccionada
	textGradient.Color = colorSeq

	-- 3. Borde del texto (quemado)
	local textStroke = Instance.new("UIStroke", label)
	textStroke.Thickness = 3
	textStroke.Color = Color3.fromRGB(60, 15, 0) -- Rojo muy oscuro, casi negro
	textStroke.Transparency = 0

	-- Padding
	local pad = Instance.new("UIPadding", label)
	pad.PaddingTop = UDim.new(0.2, 0)
	pad.PaddingBottom = UDim.new(0.2, 0)
	pad.PaddingLeft = UDim.new(0.1, 0)
	pad.PaddingRight = UDim.new(0.1, 0)
end

-- 4. FUNCIÓN CREATETILE PRINCIPAL (CONECTA TODO)
local function createTile(r, c, val, isSpawnAnim)
	local t = Instance.new("Frame")
	t.Name = "Tile_"..r.."_"..c
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = getCenterPosition(r, c)
	t.ZIndex = 20
	t.Parent = TilesLayer

	local theme = THEMES[currentSkin] or THEMES["Classic"]

	if theme.IsNeonStyle then
		UpdateTileVisuals(t, val) -- ✅ AHORA SÍ EXISTE

	elseif theme.IsRobotStyle then
		UpdateTileVisuals_Robot(t, val, theme) -- ✅ AHORA SÍ EXISTE

	elseif theme.IsVolcanicStyle then
		UpdateTileVisuals_Volcanic(t, val) -- ✅ AHORA SÍ EXISTE

	elseif theme.IsImageBased then
		Instance.new("UICorner", t).CornerRadius = UDim.new(0, theme.CornerRadius or 4)
		t.BackgroundColor3 = Color3.new(1,1,1); t.BackgroundTransparency = 1 

		-- La Imagen
		local img = Instance.new("ImageLabel", t); 
		img.Size = UDim2.new(1,0,1,0); 
		img.BackgroundTransparency = 1; 
		img.ScaleType = Enum.ScaleType.Fit
		img.Image = theme.Images[val] or theme.Images["SUPER"]
		img.ZIndex = 21

		-- ✅ CAMBIO: TEXTO SIEMPRE VISIBLE (Encima de la fruta)
		local num = Instance.new("TextLabel", t)
		num.Text = tostring(val)
		num.Size = UDim2.new(0.6, 0, 0.4, 0)
		num.Position = UDim2.new(0.5, 0, 0.5, 0) -- Centrado
		num.AnchorPoint = Vector2.new(0.5, 0.5)
		num.BackgroundTransparency = 1
		num.TextColor3 = Color3.new(1, 1, 1) -- Blanco
		num.Font = Enum.Font.FredokaOne
		num.TextScaled = true
		num.ZIndex = 22

		-- Borde negro para que se lea bien sobre cualquier fruta
		local stroke = Instance.new("UIStroke", num)
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Thickness = 2
		stroke.Transparency = 0

	else
		-- ESTILO CLÁSICO
		Instance.new("UICorner", t).CornerRadius = UDim.new(0, theme.CornerRadius or 4)
		local paletteColor = theme.Tiles[val] or theme.Tiles["SUPER"] or Color3.new(0,0,0)
		t.BackgroundColor3 = paletteColor

		if theme.HasBorder then
			local s = Instance.new("UIStroke", t); s.Color = Color3.fromRGB(50, 50, 50); s.Thickness = 4; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		end

		local lbl = Instance.new("TextLabel", t)
		lbl.Size = UDim2.new(0.8,0,0.8,0); lbl.Position = UDim2.new(0.1,0,0.1,0); lbl.BackgroundTransparency = 1
		lbl.Text = tostring(val); lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true

		if theme.HasTextStroke then
			lbl.TextColor3 = Color3.new(1,1,1); lbl.TextStrokeTransparency = 0; lbl.TextStrokeColor3 = Color3.new(0,0,0)
		else
			lbl.TextColor3 = (theme.TextDark and val <= 4) and theme.TextDark or theme.TextLight
		end
	end

	if isSpawnAnim then
		t.Size = UDim2.new(0,0,0,0); TweenService:Create(t, TweenInfo.new(POP_SPEED, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(CELL_SIZE,0,CELL_SIZE,0)}):Play()
	else
		t.Size = UDim2.new(CELL_SIZE,0,CELL_SIZE,0)
	end
	return t
end

local function redrawBoard(mergedMap)
	clearVisuals()

	-- Protección 1: Verificar datos lógicos
	if not board or #board < BOARD_SIZE then return end 

	for r = 1, BOARD_SIZE do
		if not board[r] then continue end
		for c = 1, BOARD_SIZE do
			local val = board[r][c]
			if val ~= 0 then 
				local isMerged = mergedMap and mergedMap[r] and mergedMap[r][c]

				-- Protección 2: Asegurar que la matriz visual existe antes de escribir
				if not tileVisuals[r] then tileVisuals[r] = {} end

				tileVisuals[r][c] = createTile(r, c, val, isMerged) 
			end
		end
	end
	ScoreLabel.Text = tostring(score)
end

-- CAMBIAR COLORES (FONDO)
-- CAMBIAR COLORES (FONDO Y SKIN)
local function applySkinColors()
	local theme = THEMES[currentSkin] or THEMES["Classic"]

	BOARD_COLOR = theme.Board or Color3.fromRGB(200,200,200)
	BG_COLOR = theme.Bg or Color3.fromRGB(250,250,250)
	EMPTY_CELL_COLOR = theme.Empty
	TEXT_DARK = theme.TextDark
	TEXT_LIGHT = theme.TextLight

	-- 1. BUSCAR O CREAR LA IMAGEN DE FONDO
	local bgImg = ScreenGui:FindFirstChild("SkinBackground")

	-- Si la skin tiene imagen definida
	if theme.BgImage and theme.BgImage ~= "" then
		if not bgImg then
			bgImg = Instance.new("ImageLabel", ScreenGui)
			bgImg.Name = "SkinBackground"
			bgImg.Size = UDim2.new(1, 0, 1, 0)
			bgImg.Position = UDim2.new(0, 0, 0, 0)
			bgImg.BackgroundTransparency = 1
			bgImg.ScaleType = Enum.ScaleType.Crop
			bgImg.ZIndex = -5 -- Al fondo de todo
			bgImg.Parent = ScreenGui
		end

		bgImg.Image = theme.BgImage

		-- MOSTRAR SOLO SI ESTAMOS JUGANDO
		if MainFrame.Visible then
			bgImg.Visible = true
			-- ⚠️ FORZAMOS TRANSPARENCIA PARA QUE SE VEA LA IMAGEN
			MainFrame.BackgroundTransparency = 1 
			MainFrame.BackgroundColor3 = Color3.new(1,1,1) 
		else
			bgImg.Visible = false
		end
	else

		-- SI NO HAY IMAGEN (Classic, Blue, etc)
		if bgImg then bgImg.Visible = false end

		-- Restauramos el color sólido
		MainFrame.BackgroundTransparency = 0 
		MainFrame.BackgroundColor3 = BG_COLOR 
	end

	-- Aplicar colores a los otros frames
	-- 🆕 CORRECCIÓN: El menú SIEMPRE mantiene el color original (Default), no cambia con la skin.
	if MenuFrame then MenuFrame.BackgroundColor3 = DEFAULT_THEME_COLORS.Bg end

	-- El tablero sí cambia
	if BoardFrame then BoardFrame.BackgroundColor3 = BOARD_COLOR end

	redrawBoard()
end

local function spawnRandom()
	local empty = {}
	for r=1,4 do for c=1,4 do if board[r][c] == 0 then table.insert(empty, {r,c}) end end end
	if #empty > 0 then
		local p = empty[math.random(#empty)]
		local val = (math.random() > 0.9) and 4 or 2
		board[p[1]][p[2]] = val
		tileVisuals[p[1]][p[2]] = createTile(p[1], p[2], val, true)
	end
end

for r = 1, 4 do
	for c = 1, 4 do
		local bg = Instance.new("Frame")
		bg.BackgroundColor3 = THEMES["Classic"].Empty
		bg.Size = UDim2.new(CELL_SIZE, 0, CELL_SIZE, 0)
		bg.Position = UDim2.new(PADDING + (c-1)*(CELL_SIZE+PADDING), 0, PADDING + (r-1)*(CELL_SIZE+PADDING), 0)
		bg.Parent = BoardFrame
		Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)
	end
end

-- UNDO LOGIC
local function updateUndoButton()
	if undoCount > 0 then
		UndoCountLabel.Text = tostring(undoCount)
		UndoButton.BackgroundColor3 = Color3.fromHex("8f7a66") 
	else
		UndoCountLabel.Text = "+" 
		UndoButton.BackgroundColor3 = Color3.fromHex("f67c5f")
	end
end

local function saveState()
	local boardCopy = {}
	for r=1,4 do
		boardCopy[r] = {}
		for c=1,4 do boardCopy[r][c] = board[r][c] end
	end

	table.insert(gameStateStack, {
		board = boardCopy,
		score = score
	})
	if #gameStateStack > 50 then table.remove(gameStateStack, 1) end
end

local function applyUndo()
	if #gameStateStack == 0 then return end

	local lastState = table.remove(gameStateStack)
	board = lastState.board
	score = lastState.score

	redrawBoard()
	GameOverFrame.Visible = false

	-- Actualizamos visualmente
	undoCount = undoCount - 1
	updateUndoButton()

	-- ✅ ESTA ES LA LÍNEA QUE FALTA (AVISAR AL SERVIDOR)
	local event = ReplicatedStorage:FindFirstChild("UseUndo")
	if event then event:FireServer() end
end

local function buyUndo()
	-- ✅ TU ID REAL DE 3 UNDOS
	local UNDO_PRODUCT_ID = 3472578365 
	
	if UNDO_PRODUCT_ID > 0 then
		MarketplaceService:PromptProductPurchase(player, UNDO_PRODUCT_ID)
	end
end

-- Callback wrapper (Sin 'local' para conectar con la variable del inicio)
skinChangeCallback = function(skinName)
	currentSkin = skinName
	applySkinColors()
end

-- === CONEXIONES DE LA TIENDA (LIMPIO Y CORREGIDO) ===

-- 1. Definir la función para cambiar skins (Sin local para que sea global)
skinChangeCallback = function(skinName)
	currentSkin = skinName
	applySkinColors()
end

local function checkGameOver()
	for r=1,BOARD_SIZE do for c=1,BOARD_SIZE do if board[r][c] == 0 then return end end end
	for r=1,BOARD_SIZE do
		for c=1,BOARD_SIZE do
			if c < BOARD_SIZE and board[r][c] == board[r][c+1] then return end
			if r < BOARD_SIZE and board[r][c] == board[r+1][c] then return end
		end
	end
	GameOverFrame.Visible = true

	local event = ReplicatedStorage:FindFirstChild("SaveScore")
	if event then 
		-- ✅ CAMBIO: Enviamos el BOARD_SIZE al servidor para saber si es 5x5
		event:FireServer(score, BOARD_SIZE) 
	end
end

local function initGame()
	-- Crear tablero dinámico
	board = {}
	for i=1, BOARD_SIZE do
		board[i] = {}
		for j=1, BOARD_SIZE do board[i][j] = 0 end
	end

	-- Limpiar fondo del tablero antiguo y recrearlo
	BoardFrame:ClearAllChildren()
	local TilesLayerNew = Instance.new("Frame")
	TilesLayerNew.Name = "TilesLayer"
	TilesLayerNew.Size = UDim2.new(1, 0, 1, 0); TilesLayerNew.BackgroundTransparency = 1; TilesLayerNew.ZIndex = 10; TilesLayerNew.Parent = BoardFrame
	TilesLayer = TilesLayerNew -- Actualizar referencia

	-- Crear celdas de fondo según BOARD_SIZE
	for r = 1, BOARD_SIZE do
		for c = 1, BOARD_SIZE do
			local bg = Instance.new("Frame")
			bg.BackgroundColor3 = THEMES["Classic"].Empty -- O current skin
			bg.Size = UDim2.new(CELL_SIZE, 0, CELL_SIZE, 0)
			bg.Position = UDim2.new(PADDING + (c-1)*(CELL_SIZE+PADDING), 0, PADDING + (r-1)*(CELL_SIZE+PADDING), 0)
			bg.Parent = BoardFrame
			Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)
		end
	end

	score = 0 
	ScoreLabel.Text = "0"
	undoCount = FREE_UNDOS
	gameStateStack = {}
	updateUndoButton()
	GameOverFrame.Visible = false
	tileVisuals = {}
	for r=1,BOARD_SIZE do tileVisuals[r]={} end

	spawnRandom()
	spawnRandom()

	-- GESTIÓN DE VISIBILIDAD (Solo mostrar la moneda del modo actual)
	if CoinContainer then CoinContainer.Visible = false end
	if FruitContainer then FruitContainer.Visible = false end -- (Este es el de Diamantes)
	if FruitGemContainer then FruitGemContainer.Visible = false end -- (Este es el de Frutas)

	if GAME_MODE == "Classic" or GAME_MODE == "5x5" then
		if CoinContainer then CoinContainer.Visible = true end

	elseif GAME_MODE == "Special" then
		-- Modo Diamante
		if FruitContainer then FruitContainer.Visible = true end 
		if FruitContainer then FruitContainer.Position = UDim2.new(0.02, 0, 0.39, 0) end -- Mover a posición principal

	elseif GAME_MODE == "Fruit" then
		-- Modo Fruta
		if FruitGemContainer then FruitGemContainer.Visible = true end
		if FruitGemContainer then FruitGemContainer.Position = UDim2.new(0.02, 0, 0.39, 0) end -- Mover a posición principal
	end

	-- ? ESTA LÍNEA ES LA CLAVE: Aplica la skin y la transparencia al empezar
	applySkinColors()
end

local function move(dx, dy)
	-- 1. Si hay menús abiertos o animaciones, no mover
	if isAnimating or GameOverFrame.Visible or ConfirmFrame.Visible or SettingsFrame.Visible or ShopFrame.Visible or TitlesFrame.Visible or (ModeFrame and ModeFrame.Visible) then return end

	-- 2. PROTECCIÓN ANTI-CRASH (BLINDAJE TOTAL)
	if not board then return end
	if #board ~= BOARD_SIZE then return end 

	for i = 1, BOARD_SIZE do
		if board[i] == nil then return end
		if #board[i] ~= BOARD_SIZE then return end
	end

	-- 3. COPIA SEGURA DEL TABLERO
	local preMoveBoard = {}
	for r = 1, BOARD_SIZE do
		preMoveBoard[r] = {}
		for c = 1, BOARD_SIZE do
			preMoveBoard[r][c] = board[r][c] or 0
		end
	end
	local preMoveScore = score

	local moved = false
	local anyMerge = false

	local mergedFlags = {}
	for i=1,BOARD_SIZE do mergedFlags[i]={} for j=1,BOARD_SIZE do mergedFlags[i][j]=false end end

	local movesList = {} 
	local mergedMap = {}
	for i=1,BOARD_SIZE do mergedMap[i]={} for j=1,BOARD_SIZE do mergedMap[i][j]=false end end

	local newBoard = {}
	for r=1,BOARD_SIZE do 
		newBoard[r]={} 
		for c=1,BOARD_SIZE do 
			newBoard[r][c] = board[r][c] or 0
		end 
	end

	local rStart, rEnd, rStep = 1, BOARD_SIZE, 1
	local cStart, cEnd, cStep = 1, BOARD_SIZE, 1
	if dx == 1 then cStart, cEnd, cStep = BOARD_SIZE, 1, -1 end
	if dy == 1 then rStart, rEnd, rStep = BOARD_SIZE, 1, -1 end

	-- VARIABLES DE ECONOMÍA
	local xpGained = 0
	local diamondsGained = 0
	local coinsGained = 0
	local fruitGained = 0 -- ?? AGREGADO: Acumulador para frutas

	for r = rStart, rEnd, rStep do
		for c = cStart, cEnd, cStep do
			if newBoard[r][c] ~= 0 then
				local val = newBoard[r][c]
				local bestR, bestC = r, c
				local wasMerged = false
				local nr, nc = r + dy, c + dx

				while nr >= 1 and nr <= BOARD_SIZE and nc >= 1 and nc <= BOARD_SIZE do
					if newBoard[nr][nc] == 0 then
						bestR, bestC = nr, nc
					elseif newBoard[nr][nc] == val and not mergedFlags[nr][nc] then
						bestR, bestC = nr, nc
						newBoard[nr][nc] = val * 2
						newBoard[r][c] = 0
						mergedFlags[nr][nc] = true
						mergedMap[nr][nc] = true 
						table.insert(movesList, {fr=r, fc=c, tr=nr, tc=nc, merge=true})
						moved = true
						anyMerge = true
						score = score + (val * 2)
						wasMerged = true

						-- === SISTEMA DE RECOMPENSAS ===

						-- 1. CÁLCULO DE XP CON VISUALIZACIÓN
						local baseXP = (val * 2) -- La XP base es el valor de la nueva ficha

						-- Detectar GamePass x2 XP (ID: 1609347878)
						local hasXpPass = false
						-- Revisamos memoria local (rápida) o Marketplace (lenta)
						if localSessionPasses[1609347878] then 
							hasXpPass = true 
						else
							-- Verificación asíncrona rápida (pcall inline) para no frenar el juego
							task.spawn(function()
								local s, h = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1609347878) end)
								if s and h then localSessionPasses[1609347878] = true end
							end)
							-- Si ya lo tenías cacheado de antes, úsalo
							if localSessionPasses[1609347878] then hasXpPass = true end
						end

						-- Si tiene pase, duplicamos visualmente lo que le mostramos
						local finalShowXP = hasXpPass and (baseXP * 2) or baseXP

						-- Acumulamos para enviar al servidor (el servidor vuelve a verificar el pase, no te preocupes)
						xpGained = xpGained + baseXP 

						-- ✨ LANZAR TEXTO FLOTANTE
						spawnFloatingXP(getCenterPosition(nr, nc), finalShowXP, hasXpPass)
						-- 2. ECONOMÍA POR MODO
						if GAME_MODE == "Special" then
							-- MODO DIAMANTES
							local tileCreated = val * 2 
							if tileCreated >= 32 then
								local reward = 0
								if tileCreated == 32 then reward = 1
								elseif tileCreated == 64 then reward = 2
								elseif tileCreated == 128 then reward = 3
								elseif tileCreated == 256 then reward = 5
								elseif tileCreated >= 512 then reward = 10
								end
								if reward > 0 then diamondsGained = diamondsGained + reward end
							end

						elseif GAME_MODE == "Fruit" then
							-- ?? MODO FRUTAS
							local tileCreated = val * 2
							local reward = 1 -- 1 Gema por fusión base

							-- Bonus por fusiones grandes
							if tileCreated >= 64 then reward = 3 end
							if tileCreated >= 256 then reward = 8 end

							fruitGained = fruitGained + reward

						else
							-- Modos Classic y 5x5: Dan Monedas (1 por fusión)
							coinsGained = coinsGained + 1
						end

						-- VFX
						local theme = THEMES[currentSkin] or THEMES["Classic"]
						if theme.IsImageBased then
							local nextVal = val * 2
							local imgId = theme.Images[nextVal] or theme.Images["SUPER"]
							spawnConfetti(getCenterPosition(nr, nc), imgId, true)
						else
							local tColor = theme.Tiles[val*2] or Color3.new(1,1,1)
							spawnConfetti(getCenterPosition(nr, nc), tColor, false)
						end

						break
					else break end
					nr, nc = nr + dy, nc + dx
				end
				if not wasMerged and (bestR ~= r or bestC ~= c) then
					newBoard[bestR][bestC] = val
					newBoard[r][c] = 0
					table.insert(movesList, {fr=r, fc=c, tr=bestR, tc=bestC, merge=false})
					moved = true
				end
			end
		end
	end

	if moved then
		table.insert(gameStateStack, {board = preMoveBoard, score = preMoveScore})
		isAnimating = true
		board = newBoard

		if score > highScore then
			highScore = score
			BestScoreLabel.Text = tostring(highScore)
		end

		if anyMerge then 
			if mergeSound then mergeSound:Play() end 

			-- ENVIAR DATOS AL SERVIDOR

			-- 1. XP
			if xpGained > 0 then
				local xpEvt = ReplicatedStorage:FindFirstChild("AddXP")
				if xpEvt then xpEvt:FireServer(xpGained) end
			end

			-- 2. DIAMANTES (Modo Special)
			if diamondsGained > 0 then
				-- Usamos WaitForChild con timeout por seguridad
				local dEvt = ReplicatedStorage:FindFirstChild("AddDiamond")
				if dEvt then 
					dEvt:FireServer(diamondsGained) 
					print("💎 CLIENTE: Enviando " .. diamondsGained .. " diamantes al servidor.")
				else
					warn("🔴 ERROR CRÍTICO: No se encuentra el evento 'AddDiamond' en ReplicatedStorage")
				end
			end

			-- 3. MONEDAS (Modo Classic / 5x5)
			if coinsGained > 0 then
				local cEvt = ReplicatedStorage:FindFirstChild("AddCurrency")
				if cEvt then cEvt:FireServer(coinsGained) end
			end

			-- 4. FRUTAS (Modo Fruit) ??
			if fruitGained > 0 then
				local fEvt = ReplicatedStorage:FindFirstChild("AddFruitPoint")
				if fEvt then fEvt:FireServer(fruitGained) end
			end

		else 
			if moveSound then moveSound:Play() end 
		end

		local tweenTime = TWEEN_SPEED
		for _, m in ipairs(movesList) do
			if tileVisuals[m.fr] and tileVisuals[m.fr][m.fc] then
				local tile = tileVisuals[m.fr][m.fc]
				if tile then
					TweenService:Create(tile, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = getCenterPosition(m.tr, m.tc)
					}):Play()
					tileVisuals[m.fr][m.fc] = nil 

					if not tileVisuals[m.tr] then tileVisuals[m.tr] = {} end
					tileVisuals[m.tr][m.tc] = tile
				end
			end
		end

		task.wait(tweenTime)
		redrawBoard(mergedMap) 
		spawnRandom()
		checkGameOver() 
		isAnimating = false
	end
end


	-- 1. OCULTAR TODO CON SEGURIDAD (Usamos 'if' por si algo no existe)
	if ShopRefs.CurrencyContainer then ShopRefs.CurrencyContainer.Visible = false end
	if ShopRefs.SkinsPageContainer then ShopRefs.SkinsPageContainer.Visible = false end
	if ShopRefs.PassesContainer then ShopRefs.PassesContainer.Visible = false end
	-- Intentamos ocultar el viejo por si acaso quedó referencia
	if ShopRefs.LevelPackContainer then ShopRefs.LevelPackContainer.Visible = false end

	-- 2. RESETEAR COLORES DE BOTONES
	if ShopRefs.TabCurrencyBtn then ShopRefs.TabCurrencyBtn.BackgroundColor3 = Color3.fromRGB(200, 160, 0) end
	if ShopRefs.TabSkinsBtn then ShopRefs.TabSkinsBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 200) end
	if ShopRefs.TabPassesBtn then ShopRefs.TabPassesBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 200) end


-- Variable nueva para recordar compras en GameClient (Pégalo justo encima de la función)
 

local function checkIsUnlocked(data)
	-- 0. CHEQUEO ADMIN / GUARDADO (SIN ESPACIOS)
	-- Quitamos los espacios para que coincida con el servidor (Ej: "Berry Picker" -> "BerryPicker")
	local safeName = string.gsub(data.Name, " ", "")
	if player:GetAttribute("Title_" .. safeName) == true then
		return true
	end

	-- 1. Títulos Especiales (Staff, Rachas)
	if data.ReqAttribute then
		return player:GetAttribute(data.ReqAttribute) == true
	end

	-- 2. Chequeo VIP
	if data.IsVIP then
		if localSessionPasses[VIP_GAMEPASS_ID] == true then return true end
		local success, hasPass = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_GAMEPASS_ID) end)
		return success and hasPass
	end

	-- 3. Chequeo Skin Específica
	if data.ReqSkin then
		-- Quitamos espacios también para las skins
		local safeSkin = string.gsub(data.ReqSkin, " ", "")
		return player:GetAttribute("OwnedSkin_" .. safeSkin) == true
	end

	-- 4. Chequeo Gemas Totales (Fruits)
	if data.ReqTotalGems then
		local total = player:GetAttribute("TotalFruitGems") or 0
		return total >= data.ReqTotalGems
	end

	-- 5. Chequeo Robux Spent (Others)
	if data.ReqRobux then
		local total = player:GetAttribute("TotalRobuxSpent") or 0
		return total >= data.ReqRobux
	end

	-- 6. Chequeo Score Normal (Main)
	if data.Req then
		-- ARREGLO NOVICE: Si requiere 0 puntos, siempre es true
		if data.Req == 0 then return true end

		local leaderstats = player:FindFirstChild("leaderstats")
		local bestScore = (leaderstats and leaderstats:FindFirstChild("HighScore")) and leaderstats.HighScore.Value or 0
		return bestScore >= data.Req
	end

	return false
end

local function updateRightPanel(data)
	currentlySelectedTitle = data.Name
	local isUnlocked = checkIsUnlocked(data)
	PreviewTitle.Text = data.Name
	PreviewTitle.TextColor3 = data.Color 

	if isUnlocked then
		DescLabel.Text = data.Desc
	else
		if data.IsVIP then 
			DescLabel.Text = "Purchase VIP Gamepass to unlock."
		elseif data.ReqSkin then
			DescLabel.Text = "Purchase/Unlock '"..data.ReqSkin.."' skin first."
		elseif data.ReqTotalGems then
			local current = player:GetAttribute("TotalFruitGems") or 0
			DescLabel.Text = "Collect " .. data.ReqTotalGems .. " total Fruit Gems. (You have: " .. current .. ")"
		elseif data.ReqAttribute then
			DescLabel.Text = data.Desc .. " (Locked)"
		elseif data.ReqRobux then
			-- ✅ CORRECCIÓN: Mostrar texto de Robux
			local currentSpent = player:GetAttribute("TotalRobuxSpent") or 0
			DescLabel.Text = "Spend " .. formatNumber(data.ReqRobux) .. " Robux. (You: " .. formatNumber(currentSpent) .. ")"
		else 
			local reqScore = data.Req or 0
			DescLabel.Text = "Reach score " .. formatNumber(reqScore) .. " to unlock." 
		end
	end

	if not isUnlocked then
		EquipButton.Text = data.IsVIP and "BUY VIP" or "LOCKED 🔒"
		EquipButton.BackgroundColor3 = data.IsVIP and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(80, 80, 80)
		EquipButton.Active = data.IsVIP 
	elseif currentEquippedTitle == data.Name then
		EquipButton.Text = "EQUIPPED"
		EquipButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50) 
		EquipButton.Active = false
	else
		EquipButton.Text = "EQUIP"
		EquipButton.BackgroundColor3 = Color3.fromHex("f65e3b")
		EquipButton.Active = true
	end
end

populateTitlesList = function()
	if not LeftPanel then return end
	for _, child in pairs(LeftPanel:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end

	for _, data in ipairs(TITLES_DATA) do
		if data.Category == currentTitleCategory then
			local isUnlocked = checkIsUnlocked(data)

			local btn = Instance.new("TextButton")
			btn.Name = data.Name
			btn.Size = UDim2.new(0.9, 0, 0, 45)
			btn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
			btn.Font = Enum.Font.FredokaOne
			btn.TextSize = 20
			btn.ZIndex = 1302
			btn.Parent = LeftPanel
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

			-- === APLICAR COLOR SIEMPRE (Desbloqueado o Bloqueado) ===
			btn.TextColor3 = Color3.new(1, 1, 1) -- Blanco base para que el gradiente funcione

			if isUnlocked then
				btn.Text = data.Name
			else
				btn.Text = "🔒 " .. data.Name -- Solo cambia el texto, no el color
			end

			-- Crear Gradiente (Se ve en ambos casos)
			if data.Gradient then
				local gradient = Instance.new("UIGradient")
				gradient.Color = data.Gradient
				gradient.Rotation = 0
				gradient.Parent = btn
			end

			btn.MouseButton1Click:Connect(function() 
				playClick()
				updateRightPanel(data) 

				-- Aplicar al preview también
				if PreviewTitle then
					PreviewTitle.Text = data.Name
					PreviewTitle.TextColor3 = Color3.new(1, 1, 1)
					local old = PreviewTitle:FindFirstChildOfClass("UIGradient"); if old then old:Destroy() end

					if data.Gradient then -- Sin condición 'isUnlocked'
						local g = Instance.new("UIGradient")
						g.Color = data.Gradient
						g.Parent = PreviewTitle
					end
				end
			end)
		end
	end
end


-- LÓGICA DAILY REWARDS (COLORES: AZUL -> VERDE)
local function openDailyRewards()
	UIUtils.playClick(); DailyScroll:ClearAllChildren()
	local uiGrid = Instance.new("UIGridLayout", DailyScroll); uiGrid.CellSize = UDim2.new(0.18, 0, 0, 100); uiGrid.CellPadding = UDim2.new(0.02, 0, 0.02, 0); uiGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local isVip = localSessionPasses[VIP_GAMEPASS_ID] == true
	if isVip then DailyButton.Image = "rbxassetid://80848827945021" else DailyButton.Image = "rbxassetid://86257281348163" end

	-- OBTENCIÓN DE RACHA SEGURA
	local rawStreak = player:GetAttribute("CurrentStreak") or 1
	if rawStreak < 1 then rawStreak = 1 end -- Protección por si es 0

	-- FÓRMULA DEL CICLO 30 DÍAS
	-- Ejemplo: Racha 1 -> Día 1. Racha 30 -> Día 30. Racha 31 -> Día 1.
	local displayDay = ((rawStreak - 1) % 30) + 1 

	local alreadyClaimed = player:GetAttribute("DailyClaimed") == true

	for day = 1, 30 do
		local frame = Instance.new("TextButton", DailyScroll)
		frame.Text = ""; frame.AutoButtonColor = false 

		-- === LÓGICA DE ESTADO (CORREGIDA) ===
		local isPastDay = day < displayDay -- Días anteriores en este ciclo (ej: si hoy es 5, 1-4 son pasados)
		local isToday = day == displayDay
		local isFuture = day > displayDay

		-- 1. COLOR DE FONDO
		if isPastDay then
			frame.BackgroundColor3 = Color3.fromRGB(40, 200, 100) -- Verde (Reclamado Histórico)
		elseif isToday then
			if alreadyClaimed then
				frame.BackgroundColor3 = Color3.fromRGB(40, 200, 100) -- Verde (Reclamado Hoy)
			else
				frame.BackgroundColor3 = Color3.fromRGB(0, 170, 255) -- Azul (¡RECLÁMAME!)
			end
		else
			frame.BackgroundColor3 = Color3.fromRGB(60, 60, 65) -- Gris (Futuro)
		end

		-- Borde brillante solo si toca hoy y falta cobrar
		if day == displayDay and not alreadyClaimed then
			local s=Instance.new("UIStroke", frame); s.Color=Color3.new(1,1,1); s.Thickness=3; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
		end

		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
		local dayLbl = Instance.new("TextLabel", frame); dayLbl.Text = "Day " .. day; dayLbl.Size = UDim2.new(1,0,0.3,0); dayLbl.BackgroundTransparency=1; dayLbl.TextColor3=Color3.new(1,1,1); dayLbl.Font=Enum.Font.GothamBold; dayLbl.TextScaled=true

		-- PREMIOS BUFFEADOS
		local rewardAmt = day * 1500 
		local rewardType = "Coins"
		local iconId = "rbxassetid://108796514719654" 

		if day % 7 == 0 then rewardType="Gems"; rewardAmt=day*50; iconId="rbxassetid://111308733495717" end
		if day == 30 then rewardType="Skin"; rewardAmt=1; iconId="rbxassetid://85619868467544" end

		-- ETIQUETA VIP MEJORADA (Esquina superior derecha + Inclinación)
		if isVip and rewardType ~= "Skin" then 
			rewardAmt = rewardAmt * 2
			local vipTag = Instance.new("TextLabel", frame)
			vipTag.Text = "VIP x2"
			vipTag.Size = UDim2.new(0.6, 0, 0.25, 0)
			vipTag.Position = UDim2.new(1, -2, 0, -2) -- Esquina superior derecha
			vipTag.AnchorPoint = Vector2.new(1, 0)
			vipTag.Rotation = 15 -- Inclinación estilizada
			vipTag.BackgroundTransparency = 1
			vipTag.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dorado puro
			vipTag.Font = Enum.Font.FredokaOne
			vipTag.TextScaled = true
			vipTag.ZIndex = 5
			-- Borde negro para que se lea mejor
			local st = Instance.new("UIStroke", vipTag); st.Color = Color3.new(0,0,0); st.Thickness = 2
		end

		local icon = Instance.new("ImageLabel", frame); icon.Image = iconId; icon.Size = UDim2.new(0.4,0,0.4,0); icon.Position=UDim2.new(0.3,0,0.3,0); icon.BackgroundTransparency=1; icon.ScaleType=Enum.ScaleType.Fit; icon.ZIndex=2

		-- LÓGICA DE TEXTO Y ESTADO VISUAL CORREGIDA
		local txtContent = formatNumber(rewardAmt)
		if day == 30 then txtContent = "MYSTERY" end

		-- Texto "CLAIMED!" para días pasados O el actual si ya cobraste
		if isPastDay or (isToday and alreadyClaimed) then 
			txtContent = "CLAIMED!" 
		end

		local amtLbl = Instance.new("TextLabel", frame); amtLbl.Text = txtContent; amtLbl.Size=UDim2.new(1,0,0.25,0); amtLbl.Position=UDim2.new(0,0,0.75,0); amtLbl.BackgroundTransparency=1; amtLbl.TextColor3=Color3.new(1,1,1); amtLbl.Font=Enum.Font.FredokaOne; amtLbl.TextScaled=true; amtLbl.ZIndex=2

		-- EVENTO CLICK (Solo para el día actual si no está reclamado)
		if day == displayDay and not alreadyClaimed then
			frame.AutoButtonColor = true 

			frame.MouseButton1Click:Connect(function()
				if frame:GetAttribute("IsProcessing") then return end
				frame:SetAttribute("IsProcessing", true)

				local s = Instance.new("Sound", workspace); s.SoundId="rbxassetid://2865227271"; s:Play(); game.Debris:AddItem(s, 2)

				-- Cambio visual inmediato
				frame.BackgroundColor3 = Color3.fromRGB(40, 200, 100) 
				amtLbl.Text = "CLAIMED!"
				local s = frame:FindFirstChild("UIStroke"); if s then s:Destroy() end
				frame.AutoButtonColor = false

				-- Enviar al Server
				local event = ReplicatedStorage:FindFirstChild("ClaimDaily")
				if event then event:FireServer() end
			end)
		end
	end
	toggleMenuButtons(false); UIUtils.openMenuWithAnim(DailyFrame)
end

-- LOGICA TOGGLE MENU (Corregida)
local function toggleMenu(frame)
	if frame.Visible then 
		UIUtils.closeMenuWithAnim(frame)
		-- Solo mostramos botones si no estamos jugando
		if not MainFrame.Visible then toggleMenuButtons(true) end
	else
		-- Cerrar TODO lo demás antes de abrir
		if ShopFrame.Visible then UIUtils.closeMenuWithAnim(ShopFrame) end
		if TitlesFrame.Visible then UIUtils.closeMenuWithAnim(TitlesFrame) end
		if SettingsFrame.Visible then UIUtils.closeMenuWithAnim(SettingsFrame) end
		if LeaderboardFrame.Visible then UIUtils.closeMenuWithAnim(LeaderboardFrame) end
		if StatsFrame.Visible then UIUtils.closeMenuWithAnim(StatsFrame) end
		if DailyFrame and DailyFrame.Visible then UIUtils.closeMenuWithAnim(DailyFrame) end -- Cerrar Daily

		toggleMenuButtons(false)
		UIUtils.openMenuWithAnim(frame)

		if frame == TitlesFrame then populateTitlesList() end
		if frame == ShopFrame and ShopRefs.switchShopTab then ShopRefs.switchShopTab("Currency") end
		-- IMPORTANTE: Abrir Daily si toca
		if frame == DailyFrame then openDailyRewards() end
	end
end

-- CONEXIÓN CORRECTA DEL BOTÓN (Usando Toggle)
if DailyButton then 
	DailyButton.MouseButton1Click:Connect(function()
		toggleMenu(DailyFrame) 
	end)
end

-------------------------------------------------------------------------
-- 7. BUTTON ANIMATION LOGIC (OPTIMIZADO PARA MEMORIA)
-------------------------------------------------------------------------

-- LÓGICA DE UI CENTRALIZADA
toggleMenuButtons = function(visible)
	if PlayButton then PlayButton.Visible = visible end
	if LeaderboardButton then LeaderboardButton.Visible = visible end
	if MenuTitle then MenuTitle.Visible = visible end

	-- NUEVO: Ocultar la barra de estadísticas global (Monedas/Diamantes/Frutas)
	local gStats = ScreenGui:FindFirstChild("GlobalStats")
	if gStats then gStats.Visible = visible end
end

-- LÓGICA DE MENÚS (CORREGIDA PARA CALENDARIO)
toggleMenu = function(frameToToggle)
	if frameToToggle.Visible then
		-- SI YA ESTÁ ABIERTO -> CERRAR
		UIUtils.closeMenuWithAnim(frameToToggle)
		-- Solo restaurar botones si no estamos jugando
		if not MainFrame.Visible then toggleMenuButtons(true) end
	else
		-- SI ESTÁ CERRADO -> ABRIR (Y CERRAR LOS DEMÁS)

		-- Cerrar Shop, Titles, Settings, Leaderboard, Stats
		if ShopFrame.Visible then UIUtils.closeMenuWithAnim(ShopFrame) end
		if TitlesFrame.Visible then UIUtils.closeMenuWithAnim(TitlesFrame) end
		if SettingsFrame.Visible then UIUtils.closeMenuWithAnim(SettingsFrame) end
		if LeaderboardFrame.Visible then UIUtils.closeMenuWithAnim(LeaderboardFrame) end
		if StatsFrame.Visible then UIUtils.closeMenuWithAnim(StatsFrame) end

		-- ✅ IMPORTANTE: Cerrar Daily si está abierto y estamos abriendo otra cosa
		if DailyFrame and DailyFrame.Visible and frameToToggle ~= DailyFrame then 
			UIUtils.closeMenuWithAnim(DailyFrame) 
		end

		toggleMenuButtons(false)
		UIUtils.openMenuWithAnim(frameToToggle)

		-- Lógica específica al abrir
		if frameToToggle == TitlesFrame then populateTitlesList() end
		if frameToToggle == ShopFrame and ShopRefs.switchShopTab then ShopRefs.switchShopTab("Currency") end
		-- ✅ ABRIR DAILY REWARDS SI TOCA
		if frameToToggle == DailyFrame then openDailyRewards() end
	end
end


-- APLICAR EFECTOS A LOS BOTONES (Usando UIUtils)
UIUtils.addHoverEffect(ShopButton)
UIUtils.addHoverEffect(TitlesButton)
UIUtils.addHoverEffect(PlayButton)
UIUtils.addHoverEffect(LeaderboardButton)
UIUtils.addHoverEffect(SettingsBtnGlobal)
UIUtils.addHoverEffect(SettingsBtnGame)
UIUtils.addHoverEffect(UndoButton)
if StatsButton then UIUtils.addHoverEffect(StatsButton) end

-------------------------------------------------------------------------
-- 8. MAIN CONNECTIONS & MOBILE CONTROLS
-------------------------------------------------------------------------

TryAgainButton.MouseButton1Click:Connect(function()
	playClick()
	initGame()
end)

-- ESTA ES LA FUNCIÓN QUE TE FALTABA (showMenu)
local function showMenu()
	-- 1. Reproducir sonido si existe
	if typeof(playClick) == "function" then playClick() end

	-- 2. Ocultar todos los contenedores de juego y menús secundarios
	if MainFrame then MainFrame.Visible = false end
	if GameOverFrame then GameOverFrame.Visible = false end
	if ConfirmFrame then ConfirmFrame.Visible = false end
	if SettingsFrame then SettingsFrame.Visible = false end
	if LeaderboardFrame then LeaderboardFrame.Visible = false end
	if ShopFrame then ShopFrame.Visible = false end
	if TitlesFrame then TitlesFrame.Visible = false end

	-- 3. Mostrar el Menú Principal
	if MenuFrame then MenuFrame.Visible = true end

	-- 4. Asegurar que los botones del menú (Settings, etc.) estén visibles
	if SettingsBtnGlobal then SettingsBtnGlobal.Visible = true end
	if SettingsBtnGame then SettingsBtnGame.Visible = false end -- Ocultar el del juego

	-- Ocultar fondo de skin si existe
	local bgSkin = ScreenGui:FindFirstChild("SkinBackground")
	if bgSkin then bgSkin.Visible = false end

	-- Restaurar botones del menú (Play, Leaderboard, etc.)
	toggleMenuButtons(true)

	-- 5. === LÓGICA DE DESAPARICIÓN DE PANTALLA DE CARGA ===
	-- (Esta es la parte que faltaba)
	if LoadingFrame and LoadingFrame.Visible then
		local fadeTime = 1.0 
		local fadeInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

		-- Desvanecer el fondo negro
		TweenService:Create(LoadingFrame, fadeInfo, {BackgroundTransparency = 1}):Play()

		-- Desvanecer textos, barras y botones dentro del LoadingFrame
		for _, element in pairs(LoadingFrame:GetDescendants()) do
			if element:IsA("TextLabel") or element:IsA("TextButton") then
				TweenService:Create(element, fadeInfo, {TextTransparency = 1}):Play()
			end
			if element:IsA("Frame") or element:IsA("TextButton") or element:IsA("ImageButton") then
				TweenService:Create(element, fadeInfo, {BackgroundTransparency = 1}):Play()
			end
			if element:IsA("ImageLabel") or element:IsA("ImageButton") then
				TweenService:Create(element, fadeInfo, {ImageTransparency = 1}):Play()
			end
		end

		-- Esperar a que termine la animación y apagar el Frame
		task.delay(fadeTime, function()
			LoadingFrame.Visible = false
		end)
	end
end

GameOverMenuButton.MouseButton1Click:Connect(showMenu)
-- CONEXIÓN DE UNDO BUTTON
UndoButton.MouseButton1Click:Connect(function()
	playClick()
	if undoCount > 0 then applyUndo() else buyUndo() end
end)

-- ==============================================================
-- ✅ SINCRONIZACIÓN VISUAL DE UNDOS (SILENCIOSO)
-- ==============================================================
local function syncUndoVisuals()
	local serverUndos = player:GetAttribute("Undos") or 0
	undoCount = serverUndos 

	if UndoCountLabel then
		if undoCount > 0 then
			UndoCountLabel.Text = tostring(undoCount)
			UndoButton.BackgroundColor3 = Color3.fromHex("8f7a66") 
		else
			UndoCountLabel.Text = "+"
			UndoButton.BackgroundColor3 = Color3.fromHex("f67c5f")
		end
	end
end

player:GetAttributeChangedSignal("Undos"):Connect(syncUndoVisuals)
task.delay(1, syncUndoVisuals)

-- CONECTAMOS LA SEÑAL:
-- Cada vez que el PurchaseHandler cambie el atributo "Undos", esta función se activa sola.
player:GetAttributeChangedSignal("Undos"):Connect(syncUndoVisuals)

-- LLAMADA INICIAL:
-- Para que al entrar al juego cargue los Undos que tenías guardados
task.delay(1, syncUndoVisuals)

local loadingActive = true
local TOTAL_LOAD_TIME = 15

-- LÓGICA DEL SELECTOR DE MODOS (RESTAURADA)
local function openModeSelector()
	UIUtils.playClick()

	-- Verificar si ya existe, si no, crearlo
	local frame = ScreenGui:FindFirstChild("ModeSelect")
	if not frame then
		frame = Instance.new("Frame", ScreenGui)
		frame.Name = "ModeSelect"
		frame.Size = UDim2.new(0.8, 0, 0.6, 0)
		frame.Position = UDim2.new(0.5, 0, 0.5, 0); frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45); frame.Visible = false; frame.ZIndex = 2000
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 15)
		local st = Instance.new("UIStroke", frame); st.Color = Color3.new(1,1,1); st.Thickness = 2

		local title = Instance.new("TextLabel", frame); title.Text = "SELECT MODE"; title.Size = UDim2.new(1, 0, 0.15, 0); title.BackgroundTransparency = 1; title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.FredokaOne; title.TextScaled = true

		local container = Instance.new("Frame", frame); container.Name = "Container"; container.Size = UDim2.new(0.9, 0, 0.7, 0); container.Position = UDim2.new(0.05, 0, 0.2, 0); container.BackgroundTransparency = 1
		local lay = Instance.new("UIListLayout", container); lay.Padding = UDim.new(0, 10); lay.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local closeBtn = Instance.new("TextButton", frame); closeBtn.Text = "CANCEL"; closeBtn.Size = UDim2.new(0.4, 0, 0.1, 0); closeBtn.Position = UDim2.new(0.3, 0, 0.88, 0); closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80); closeBtn.TextColor3 = Color3.new(1,1,1); closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true; Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

		closeBtn.MouseButton1Click:Connect(function() 
			UIUtils.closeMenuWithAnim(frame)
			toggleMenuButtons(true) 
		end)
	end

	-- Llenar botones
	local container = frame:FindFirstChild("Container")
	if container then
		for _, c in pairs(container:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end

		local function addBtn(name, desc, reqLvl, size, modeId)
			local btn = Instance.new("TextButton", container); btn.Size = UDim2.new(1, 0, 0.25, 0); btn.BackgroundColor3 = Color3.fromRGB(60, 60, 65); btn.Text = ""; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
			local t = Instance.new("TextLabel", btn); t.Text = name; t.Size = UDim2.new(0.4, 0, 0.5, 0); t.Position = UDim2.new(0.05, 0, 0.1, 0); t.BackgroundTransparency = 1; t.TextColor3 = Color3.new(1,1,1); t.Font = Enum.Font.GothamBold; t.TextScaled = true; t.TextXAlignment = Enum.TextXAlignment.Left
			local d = Instance.new("TextLabel", btn); d.Text = desc; d.Size = UDim2.new(0.4, 0, 0.3, 0); d.Position = UDim2.new(0.05, 0, 0.6, 0); d.BackgroundTransparency = 1; d.TextColor3 = Color3.fromRGB(180,180,180); d.Font = Enum.Font.Gotham; d.TextScaled = true; d.TextXAlignment = Enum.TextXAlignment.Left

			local myLvl = 1; local ls = player:FindFirstChild("leaderstats"); if ls then myLvl = ls.Level.Value end
			local locked = myLvl < reqLvl
			local st = Instance.new("TextLabel", btn); st.Size = UDim2.new(0.3, 0, 0.6, 0); st.Position = UDim2.new(0.65, 0, 0.2, 0); st.BackgroundTransparency = 1; st.Font = Enum.Font.FredokaOne; st.TextScaled = true

			if locked then
				btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); st.Text = "Lvl "..reqLvl.." 🔒"; st.TextColor3 = Color3.fromRGB(255, 80, 80)
			else
				st.Text = "PLAY"; st.TextColor3 = Color3.fromRGB(100, 255, 100)
				btn.MouseButton1Click:Connect(function()
					UIUtils.playClick()
					GAME_MODE = modeId
					BOARD_SIZE = size
					CELL_SIZE = (1 - (PADDING * (BOARD_SIZE + 1))) / BOARD_SIZE

					-- Ocultar todo e iniciar
					frame.Visible = false
					MenuFrame.Visible = false
					if SettingsBtnGlobal then SettingsBtnGlobal.Visible = false end
					MainFrame.Visible = true

					if ReplicatedStorage:FindFirstChild("StartGame") then ReplicatedStorage.StartGame:FireServer() end
					initGame()
				end)
			end
		end
		-- BOTONES NORMALES (Classic, Big Board, Diamond Rush)
		addBtn("Classic", "The original 4x4 experience.", 0, 4, "Classic")
		addBtn("Big Board", "More space, 5x5 grid.", 10, 5, "5x5")
		-- ✅ AQUÍ PUSE EL DIAMANTE 💎
		addBtn("Diamond Rush 💎", "Merge 16+16 to earn Gems!", 15, 4, "Special")

		-- NUEVO BOTÓN: FRUIT MODE (Personalizado)
		local btnFruit = Instance.new("TextButton", container); btnFruit.Size = UDim2.new(1, 0, 0.25, 0); btnFruit.BackgroundColor3 = Color3.fromRGB(60, 60, 65); btnFruit.Text = ""; Instance.new("UICorner", btnFruit).CornerRadius = UDim.new(0, 8)

		-- ✅ AQUÍ PUSE LA FRESA 🍓 EN EL TÍTULO
		local t = Instance.new("TextLabel", btnFruit); t.Text = "Fruit Harvest 🍓"; t.Size = UDim2.new(0.4, 0, 0.5, 0); t.Position = UDim2.new(0.05, 0, 0.1, 0); t.BackgroundTransparency = 1; t.TextColor3 = Color3.new(1,1,1); t.Font = Enum.Font.GothamBold; t.TextScaled = true; t.TextXAlignment = Enum.TextXAlignment.Left

		local d = Instance.new("TextLabel", btnFruit); d.Text = "Farm Fruit Gems! (Req: Lvl 30 + Fruit Skin)"; d.Size = UDim2.new(0.45, 0, 0.3, 0); d.Position = UDim2.new(0.05, 0, 0.6, 0); d.BackgroundTransparency = 1; d.TextColor3 = Color3.fromRGB(180,180,180); d.Font = Enum.Font.Gotham; d.TextScaled = true; d.TextXAlignment = Enum.TextXAlignment.Left

		-- Verificación de requisitos
		local myLvl = 1; local ls = player:FindFirstChild("leaderstats"); if ls then myLvl = ls.Level.Value end
		local currentThemeData = THEMES[currentSkin]
		local hasFruitSkin = currentThemeData and currentThemeData.IsFruitSkin == true

		local status = Instance.new("TextLabel", btnFruit); status.Size = UDim2.new(0.3, 0, 0.6, 0); status.Position = UDim2.new(0.65, 0, 0.2, 0); status.BackgroundTransparency = 1; status.Font = Enum.Font.FredokaOne; status.TextScaled = true

		if myLvl < 30 then
			btnFruit.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			status.Text = "Lvl 30 🔒"; status.TextColor3 = Color3.fromRGB(255, 80, 80) -- Candado para nivel
		elseif not hasFruitSkin then
			btnFruit.BackgroundColor3 = Color3.fromRGB(40, 30, 30)
			-- ✅ AQUÍ PUSE LA FRESA 🍓 PARA EL REQUISITO DE SKIN
			status.Text = "Need Fruit Skin 🍓"; status.TextColor3 = Color3.fromRGB(255, 140, 0)
			d.Text = "Equip a Fruit Skin (Shop) to enter!" 
		else
			status.Text = "PLAY"; status.TextColor3 = Color3.fromRGB(100, 255, 100)
			btnFruit.MouseButton1Click:Connect(function()
				UIUtils.playClick()
				GAME_MODE = "Fruit"
				BOARD_SIZE = 4
				CELL_SIZE = (1 - (PADDING * (BOARD_SIZE + 1))) / BOARD_SIZE

				frame.Visible = false; MenuFrame.Visible = false; MainFrame.Visible = true
				if SettingsBtnGlobal then SettingsBtnGlobal.Visible = false end
				if ReplicatedStorage:FindFirstChild("StartGame") then ReplicatedStorage.StartGame:FireServer() end
				initGame()
			end)
		end
	end

	toggleMenuButtons(false)
	UIUtils.openMenuWithAnim(frame)
end

-- CONEXIÓN DEL BOTÓN PLAY (Aquí es donde revivimos el botón)
if PlayButton then PlayButton.MouseButton1Click:Connect(openModeSelector) end

-- SKIP BUTTON
if SkipButton then
	SkipButton.MouseButton1Click:Connect(function()
		playClick()
		loadingActive = false
		showMenu()
	end)
end

-- Exit Confirmation
BackButton.MouseButton1Click:Connect(function() playClick(); ConfirmFrame.Visible = true end)
YesButton.MouseButton1Click:Connect(function() playClick(); ConfirmFrame.Visible = false; showMenu() end)
NoButton.MouseButton1Click:Connect(function() playClick(); ConfirmFrame.Visible = false end)

-- BUTTON BINDS
TitlesButton.MouseButton1Click:Connect(function() toggleMenu(TitlesFrame) end)
TitleCloseBtn.MouseButton1Click:Connect(function() UIUtils.closeMenuWithAnim(TitlesFrame); toggleMenuButtons(true) end)



-- ... (código anterior) ...

-- CONEXIONES DE LA TIENDA
if ShopButton then  -- 🔴 ESTE IF SE ABRIÓ AQUÍ

	-- CONEXIONES DE LA TIENDA (Corregidas)
	ShopButton.MouseButton1Click:Connect(function() 
		toggleMenu(ShopFrame) 
		-- Al abrir, cargamos la pestaña de monedas y pasamos el callback
		if ShopFrame.Visible then 
			ShopManager.switchTab("Currency", currentSkin, skinChangeCallback) 
		end
	end)

	-- PESTAÑAS DE LA TIENDA
	if ShopRefs.TabCurrencyBtn then 
		ShopRefs.TabCurrencyBtn.MouseButton1Click:Connect(function() 
			ShopManager.switchTab("Currency", currentSkin, skinChangeCallback) 
		end) 
	end

	if ShopRefs.TabPassesBtn then
		ShopRefs.TabPassesBtn.MouseButton1Click:Connect(function()
			ShopManager.switchTab("Passes", currentSkin, skinChangeCallback)
		end)
	end

	-- ✅ CONEXIÓN DE LA PESTAÑA SKINS (ESTO FALTABA)
	if ShopRefs.TabSkinsBtn then
		ShopRefs.TabSkinsBtn.MouseButton1Click:Connect(function()
			ShopManager.switchTab("Skins", currentSkin, skinChangeCallback)
		end)
	end

end 


-- NUEVA LÓGICA DE SETTINGS (UNIFICADA)

local function toggleSettings()
	UIUtils.playClick()

	if SettingsFrame.Visible then
		-- CASO 1: CERRAR SETTINGS
		UIUtils.closeMenuWithAnim(SettingsFrame)

		-- Solo volvemos a mostrar los botones del menú (Play/Leaderboard)
		-- SI NO estamos dentro de una partida.
		if not MainFrame.Visible then 
			toggleMenuButtons(true) 
		end
	else
		-- CASO 2: ABRIR SETTINGS

		-- A. Cerrar cualquier otro menú que estorbe
		if ShopFrame and ShopFrame.Visible then UIUtils.closeMenuWithAnim(ShopFrame) end
		if LeaderboardFrame and LeaderboardFrame.Visible then UIUtils.closeMenuWithAnim(LeaderboardFrame) end
		if TitlesFrame and TitlesFrame.Visible then UIUtils.closeMenuWithAnim(TitlesFrame) end
		if StatsFrame and StatsFrame.Visible then UIUtils.closeMenuWithAnim(StatsFrame) end
		if ModeFrame and ModeFrame.Visible then UIUtils.closeMenuWithAnim(ModeFrame) end

		-- B. Ocultar botones del menú principal para que no se vean detrás
		toggleMenuButtons(false)

		-- C. Abrir Settings
		UIUtils.openMenuWithAnim(SettingsFrame)
	end
end

-- Desconectar conexiones viejas por seguridad (si existen) y conectar las nuevas
if SettingsBtnGlobal then 
	pcall(function() SettingsBtnGlobal.MouseButton1Click:DisconnectAll() end) -- Limpieza extra
	SettingsBtnGlobal.MouseButton1Click:Connect(toggleSettings) 
end

if SettingsBtnGame then 
	pcall(function() SettingsBtnGame.MouseButton1Click:DisconnectAll() end) -- Limpieza extra
	SettingsBtnGame.MouseButton1Click:Connect(toggleSettings) 
end

-- Conexión extra para el botón Stats (que también abre un menú similar)
if StatsButton then
	StatsButton.MouseButton1Click:Connect(function()
		-- Usamos lógica similar: cerrar otros menús primero
		if ShopFrame.Visible then UIUtils.closeMenuWithAnim(ShopFrame) end
		if LeaderboardFrame.Visible then UIUtils.closeMenuWithAnim(LeaderboardFrame) end

		toggleMenuButtons(false)
		toggleMenu(StatsFrame)
		SettingsManager.updateStats() 
	end)
end
-- El botón cerrar de stats también está en el módulo
if StatsButton then UIUtils.addHoverEffect(StatsButton) end

-- ... (LTab Connections se mantienen igual porque no usaban closeMenuWithAnim) ...

-- 4. Botón Leaderboard Principal
LeaderboardButton.MouseButton1Click:Connect(function()
	toggleMenu(LeaderboardFrame)
	LeaderboardManager.switchTab("HighScore") 
end)

-- Nota: Los botones internos de las pestañas (High, Time, etc) y el botón Cerrar
-- ya se conectaron automáticamente dentro del módulo LeaderboardManager.init().
-- No necesitas conectarlos aquí de nuevo.

EquipButton.MouseButton1Click:Connect(function()
	playClick()
	if not currentlySelectedTitle then return end
	local data = nil
	for _, d in ipairs(TITLES_DATA) do if d.Name == currentlySelectedTitle then data = d break end end
	if not data then return end
	local isUnlocked = checkIsUnlocked(data)

	if not isUnlocked and data.IsVIP then
		if VIP_GAMEPASS_ID > 0 then MarketplaceService:PromptGamePassPurchase(player, VIP_GAMEPASS_ID) end
		return
	end

	if isUnlocked then
		currentEquippedTitle = currentlySelectedTitle
		updateRightPanel(data)
		local oldText = EquipButton.Text
		EquipButton.Text = "..."
		local event = ReplicatedStorage:WaitForChild("EquipTitle", 5)
		if event then
			event:FireServer(currentEquippedTitle)
			EquipButton.Text = "OK!"
			task.wait(0.5)
			if currentlySelectedTitle == data.Name then updateRightPanel(data) end
		end
	end
end)


-- ==========================================================
-- ✅ DETECTOR DE COMPRA DE GAMEPASS (ARREGLADO REAL + TITULOS)
-- ==========================================================
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(playerWhoPurchased, passId, wasPurchased)

	if playerWhoPurchased == player and wasPurchased == true then
		print("✅ GamePass Comprado ID: " .. tostring(passId))

		-- Sonido de éxito
		local s = Instance.new("Sound", workspace); s.SoundId="rbxassetid://2865227271"; s:Play(); game.Debris:AddItem(s, 2)

		-- 1. GUARDAR EN MEMORIA DE SHOP (Módulo)
		ShopManager.registerLocalPurchase(passId)

		-- 2. GUARDAR EN MEMORIA DE GAMECLIENT (Para Títulos)
		localSessionPasses[passId] = true 

		-- 3. REFRESCAR TIENDA SI ESTÁ ABIERTA
		if ShopFrame.Visible then
			if ShopRefs.PassesContainer and ShopRefs.PassesContainer.Visible then
				ShopManager.switchTab("Passes", currentSkin, skinChangeCallback)
			end
			if ShopRefs.SkinsPageContainer and ShopRefs.SkinsPageContainer.Visible then
				ShopManager.switchTab("Skins", currentSkin, skinChangeCallback)
			end
		end

		-- 4. REFRESCAR MENÚ DE TÍTULOS SI ESTÁ ABIERTO (Para desbloquear VIP al instante)
		if TitlesFrame and TitlesFrame.Visible then
			populateTitlesList() -- Recargar lista izquierda
			-- Si tenías seleccionado el VIP, refrescar el panel derecho
			if currentlySelectedTitle == "VIP" then
				local vipData = nil
				for _, d in ipairs(TITLES_DATA) do if d.Name == "VIP" then vipData = d break end end
				if vipData then updateRightPanel(vipData) end
			end
		end

	else
		print("❌ Compra cancelada o fallida para ID:", passId)
	end
end)

-- CONTROLES (AISLADOS EN FUNCIÓN PARA EVITAR ERROR DE MEMORIA)
local function setupControls()
	local function disableControls(actionName, inputState, inputObject)
		if inputState == Enum.UserInputState.Begin and MainFrame.Visible and not ConfirmFrame.Visible and not LeaderboardFrame.Visible and not SettingsFrame.Visible and not ShopFrame.Visible and not TitlesFrame.Visible then
			local key = inputObject.KeyCode; if key == Enum.KeyCode.Up or key == Enum.KeyCode.W then move(0, -1) elseif key == Enum.KeyCode.Down or key == Enum.KeyCode.S then move(0, 1) elseif key == Enum.KeyCode.Left or key == Enum.KeyCode.A then move(-1, 0) elseif key == Enum.KeyCode.Right or key == Enum.KeyCode.D then move(1, 0) end; return Enum.ContextActionResult.Sink
		end; return Enum.ContextActionResult.Pass
	end
	ContextActionService:BindActionAtPriority("Move", disableControls, false, 3000, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.A, Enum.KeyCode.D)

	local tsp = nil
	UserInputService.InputBegan:Connect(function(i, p) if not p and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) then tsp = i.Position end end)
	UserInputService.InputEnded:Connect(function(i, p)
		if not p and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) and tsp then
			local d = i.Position - tsp; if d.Magnitude > 30 then if math.abs(d.X) > math.abs(d.Y) then if d.X > 0 then move(1, 0) else move(-1, 0) end else if d.Y > 0 then move(0, 1) else move(0, -1) end end end; tsp = nil
		end
	end)
end -- CIERRE DE SETUPCONTROLS

setupControls()

-- FREEZE CHAR
RunService.Stepped:Connect(function()
	if player and player.Character then local h = player.Character:FindFirstChild("Humanoid"); if h then h.WalkSpeed = 0; h.JumpPower = 0 end end
end)

-- CONEXIÓN DE LA X (DAILY REWARDS)
if DailyClose then 
	DailyClose.MouseButton1Click:Connect(function()
		-- 1. Reproducir sonido click
		UIUtils.playClick()
		-- 2. Cerrar la ventana con animación
		UIUtils.closeMenuWithAnim(DailyFrame)
		-- 3. IMPORTANTE: Volver a mostrar los botones del menú (Play, Leaderboard, etc)
		toggleMenuButtons(true) 
	end) 
end
-- LOAD LOOP & UI UPDATE (CORREGIDO Y FUSIONADO)
task.spawn(function()
	local startTime = tick()
	while true do
		-- 1. PANTALLA DE CARGA
		if loadingActive then
			local elapsed = tick() - startTime; local progress = math.clamp(elapsed / TOTAL_LOAD_TIME, 0, 1)
			if LoadingBarFill then LoadingBarFill.Size = UDim2.new(progress, 0, 1, 0) end
			if LoadingText then LoadingText.Text = "LOADING... " .. math.floor(progress * 100) .. "%" end
			if elapsed >= TOTAL_LOAD_TIME then loadingActive = false; showMenu() end
		end

		-- 2. ACTUALIZACIÓN DE UI
		if player then
			local ls = player:FindFirstChild("leaderstats")
			if ls then
				local c = ls:FindFirstChild("Coins") and ls.Coins.Value or 0
				local d = ls:FindFirstChild("Diamonds") and ls.Diamonds.Value or 0
				local f = ls:FindFirstChild("FruitGems") and ls.FruitGems.Value or 0
				local sc, sd, sf = formatNumber(c), formatNumber(d), formatNumber(f)

				-- Actualizar etiquetas
				if CoinLabel then CoinLabel.Text = sc end       -- Monedas
				if FruitLabel then FruitLabel.Text = sd end     -- Diamantes (Variable vieja)
				if FruitGemLabel then FruitGemLabel.Text = sf end -- Frutas (Nueva)
				if MenuCoinLbl then MenuCoinLbl.Text = sc end; if MenuGemLbl then MenuGemLbl.Text = sd end; if MenuFruitLbl then MenuFruitLbl.Text = sf end
				if ShopRefs.CoinLbl then ShopRefs.CoinLbl.Text = sc end; if ShopRefs.GemLbl then ShopRefs.GemLbl.Text = sd end; if ShopRefs.FruitLbl then ShopRefs.FruitLbl.Text = sf end

				-- ? ACTUALIZAR NÚMERO DE RACHA E ICONO DE FUEGO
				if StreakNumMenu and StreakBadge then
					local st = player:GetAttribute("CurrentStreak") or 1
					StreakNumMenu.Text = tostring(st)

					-- IDs DE FUEGO (Según días)
					if st >= 150 then
						StreakBadge.Image = "rbxassetid://132241895741787" -- Morado
					elseif st >= 50 then
						StreakBadge.Image = "rbxassetid://85252887341379" -- Verde
					else
						StreakBadge.Image = "rbxassetid://134763959761180" -- Rojo (Normal)
					end
				end

				-- ? ACTUALIZAR CALENDARIO DORADO (VIP)
				-- Revisamos si tenemos el VIP en cache o en atributo
				local hasVip = localSessionPasses[VIP_GAMEPASS_ID] == true

				-- Si no está en cache, intentamos una vez leerlo (sin spamear API)
				if not hasVip and not player:GetAttribute("CheckedVipOnce") then
					player:SetAttribute("CheckedVipOnce", true)
					task.spawn(function()
						local s, r = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_GAMEPASS_ID) end)
						if s and r then 
							localSessionPasses[VIP_GAMEPASS_ID] = true 
						end
					end)
				end

				-- Aplicar imagen si encontramos el VIP
				if localSessionPasses[VIP_GAMEPASS_ID] then
					DailyButton.Image = "rbxassetid://80848827945021" -- Dorado
				else
					DailyButton.Image = "rbxassetid://86257281348163" -- Azul Normal
				end

				-- NIVEL Y XP
				if ls:FindFirstChild("Level") then
					local lvl = ls.Level.Value
					if LevelNumLabel then LevelNumLabel.Text = tostring(lvl) end

					local cur = player:GetAttribute("CurrentXP") or 0
					local max = player:GetAttribute("MaxXP") or 500
					local pct = math.clamp(cur / max, 0, 1)

					-- Barra Azul
					if LevelBarFill then 
						TweenService:Create(LevelBarFill, TweenInfo.new(0.2), {Size = UDim2.new(pct, 0, 1, 0)}):Play() 
					end

					-- ✅ TEXTO COMBINADO: "59% | 0 / 1434 XP"
					if LevelProgressText then 
						local percentText = math.floor(pct * 100) .. "%"
						local xpText = formatNumber(cur) .. " / " .. formatNumber(max) .. " XP"
						LevelProgressText.Text = percentText .. " | " .. xpText
					end
				end
			end
		end
		task.wait(0.2)
	end -- CIERRE DEL WHILE
end) -- CIERRE DEL TASK.SPAWN
