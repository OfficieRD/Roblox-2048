local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIUtils = require(ReplicatedStorage:WaitForChild("UIUtils"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

local MusicManager = {}

local musicSound = nil
local currentSongIndex = 1
local songLabel = nil
local playBtn = nil

function MusicManager.init(screenGui, parentFrame, startVolume)
	-- 1. Crear Objeto de Sonido
	musicSound = Instance.new("Sound")
	musicSound.Name = "MusicSound"
	musicSound.SoundId = GameData.MUSIC_PLAYLIST[currentSongIndex].Id
	musicSound.Volume = startVolume
	musicSound.Looped = true
	musicSound.Parent = screenGui
	musicSound:Play()

	-- 2. Crear Interfaz
	local MusicFrame = Instance.new("Frame")
	MusicFrame.Name = "MusicPlayer"
	MusicFrame.Size = UDim2.new(0.4, 0, 0.15, 0)
	MusicFrame.AnchorPoint = Vector2.new(0.5, 1)
	MusicFrame.Position = UDim2.new(0.5, 0, 0.98, 0)
	MusicFrame.BackgroundTransparency = 1
	MusicFrame.ZIndex = 1006
	MusicFrame.Parent = parentFrame

	songLabel = Instance.new("TextLabel")
	songLabel.Text = "🎵 " .. GameData.MUSIC_PLAYLIST[currentSongIndex].Name
	songLabel.Size = UDim2.new(1, 0, 0.4, 0)
	songLabel.Position = UDim2.new(0, 0, -0.1, 0)
	songLabel.BackgroundTransparency = 1
	songLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
	songLabel.Font = Enum.Font.GothamBold
	songLabel.TextScaled = true
	songLabel.ZIndex = 1007
	songLabel.Parent = MusicFrame

	local ControlsContainer = Instance.new("Frame")
	ControlsContainer.Size = UDim2.new(1, 0, 0.6, 0)
	ControlsContainer.Position = UDim2.new(0, 0, 0.4, 0)
	ControlsContainer.BackgroundTransparency = 1
	ControlsContainer.Parent = MusicFrame

	local layout = Instance.new("UIListLayout")
	layout.Parent = ControlsContainer
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 15)

	-- Función auxiliar interna para botones
	local function createBtn(text, symbol, callback)
		local btn = Instance.new("TextButton")
		btn.Text = symbol
		btn.Size = UDim2.new(0, 40, 0, 40)
		btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		btn.BackgroundTransparency = 0.5
		btn.TextColor3 = Color3.new(1,1,1)
		btn.Font = Enum.Font.FredokaOne
		btn.TextSize = 24
		btn.Parent = ControlsContainer
		Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

		UIUtils.addHoverEffect(btn) -- Usamos el módulo de UI

		btn.MouseButton1Click:Connect(function()
			UIUtils.playClick()
			callback(btn)
		end)
		return btn
	end

	-- Botones
	createBtn("Prev", "⏮", function() MusicManager.changeSong(-1) end)

	playBtn = createBtn("Play", "⏸", function(self)
		if musicSound.IsPlaying then
			musicSound:Pause()
			self.Text = "▶"
		else
			musicSound:Resume()
			self.Text = "⏸"
		end
	end)

	createBtn("Next", "⏭", function() MusicManager.changeSong(1) end)
end

function MusicManager.changeSong(direction)
	currentSongIndex = currentSongIndex + direction
	if currentSongIndex > #GameData.MUSIC_PLAYLIST then currentSongIndex = 1 end
	if currentSongIndex < 1 then currentSongIndex = #GameData.MUSIC_PLAYLIST end

	MusicManager.loadCurrentSong()
end

function MusicManager.loadCurrentSong()
	if not musicSound then return end
	musicSound:Stop()
	musicSound.SoundId = GameData.MUSIC_PLAYLIST[currentSongIndex].Id
	if songLabel then songLabel.Text = "🎵 " .. GameData.MUSIC_PLAYLIST[currentSongIndex].Name end
	musicSound:Play()
	if playBtn then playBtn.Text = "⏸" end
end

function MusicManager.setVolume(vol)
	if musicSound then musicSound.Volume = vol end
end

return MusicManager
