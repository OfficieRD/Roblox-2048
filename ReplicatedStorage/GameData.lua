local GameData = {}

-- 1. COLORES BASE (Default)
GameData.DEFAULT_THEME_COLORS = {
	Board = Color3.fromHex("bbada0"),
	Bg = Color3.fromHex("faf8ef"),
	Empty = Color3.fromHex("cdc1b4"),
	TextDark = Color3.fromHex("776e65"),
	TextLight = Color3.fromHex("f9f6f2")
}

GameData.DEFAULT_TILES = {
	[2] = Color3.fromHex("eee4da"), [4] = Color3.fromHex("ede0c8"),
	[8] = Color3.fromHex("f2b179"), [16] = Color3.fromHex("f59563"),
	[32] = Color3.fromHex("f67c5f"), [64] = Color3.fromHex("f65e3b"),
	[128] = Color3.fromHex("edcf72"), [256] = Color3.fromHex("edcc61"),
	[512] = Color3.fromHex("edc850"), [1024] = Color3.fromHex("edc53f"),
	[2048] = Color3.fromHex("edc22e"), ["SUPER"] = Color3.fromHex("3c3a32")
}

-- 2. PALETAS PERSONALIZADAS

-- A) CLASSIC 2048 (Lego/Pastel)
GameData.CLASSIC_PALETTE = {
	[2] = Color3.fromRGB(250, 240, 255),   -- Blanco/Rosado
	[4] = Color3.fromRGB(168, 230, 207),   -- Verde Menta
	[8] = Color3.fromRGB(253, 233, 118),   -- Amarillo
	[16] = Color3.fromRGB(245, 178, 124),  -- Naranja
	[32] = Color3.fromRGB(247, 124, 124),  -- Rojo
	[64] = Color3.fromRGB(235, 77, 77),    -- Rojo Intenso
	[128] = Color3.fromRGB(237, 207, 114), 
	[256] = Color3.fromRGB(237, 204, 97), 
	[512] = Color3.fromRGB(237, 200, 80), 
	[1024] = Color3.fromRGB(237, 197, 63),
	[2048] = Color3.fromRGB(237, 194, 46),
	["SUPER"] = Color3.fromRGB(60, 58, 50)
}

-- B) BLUE PALETTE (La vieja Neon - Solo azules)
GameData.BLUE_PALETTE = {
	[2] = Color3.fromRGB(0, 255, 255),     -- Cyan
	[4] = Color3.fromRGB(0, 200, 255),     -- Azul Cielo
	[8] = Color3.fromRGB(0, 150, 255),     -- Azul
	[16] = Color3.fromRGB(50, 100, 255),   -- Azul Real
	[32] = Color3.fromRGB(80, 50, 255),    -- Azul/Violeta
	[64] = Color3.fromRGB(150, 0, 255),    -- Violeta
	[128] = Color3.fromRGB(255, 0, 200),   -- Magenta
	[256] = Color3.fromRGB(255, 0, 100),
	[512] = Color3.fromRGB(255, 50, 50),
	[1024] = Color3.fromRGB(255, 150, 0),
	[2048] = Color3.fromRGB(255, 255, 0),
	["SUPER"] = Color3.fromRGB(0, 0, 0)
}

-- C) NEON CYBERPUNK (La nueva especial)
GameData.NEON_PALETTE = {
	[2] = Color3.fromRGB(0, 255, 255),     -- Cyan Neon
	[4] = Color3.fromRGB(255, 0, 255),     -- Magenta Neon
	[8] = Color3.fromRGB(255, 255, 0),     -- Amarillo Neon
	[16] = Color3.fromRGB(0, 255, 0),      -- Verde Neon
	[32] = Color3.fromRGB(255, 50, 50),    -- Rojo Neon
	[64] = Color3.fromRGB(100, 100, 255),  -- Azul Neon
	[128] = Color3.fromRGB(255, 150, 0),   -- Naranja Neon
	[256] = Color3.fromRGB(0, 255, 200),
	[512] = Color3.fromRGB(200, 0, 255),
	[1024] = Color3.fromRGB(50, 255, 50),
	[2048] = Color3.fromRGB(255, 255, 255),
	["SUPER"] = Color3.fromRGB(255, 255, 255)
}

-- 3. LISTA DE TEMAS (SKINS)
GameData.THEMES = {
	["Classic"] = {
		Board = GameData.DEFAULT_THEME_COLORS.Board,
		Bg = GameData.DEFAULT_THEME_COLORS.Bg,
		Empty = GameData.DEFAULT_THEME_COLORS.Empty,
		TextDark = GameData.DEFAULT_THEME_COLORS.TextDark,
		TextLight = GameData.DEFAULT_THEME_COLORS.TextLight,
		Tiles = GameData.DEFAULT_TILES
	},

	-- SKIN BLUE (La antigua Neon, ahora simple)
	["Blue"] = { 
		Board = Color3.fromRGB(10, 20, 40),
		Bg = Color3.fromRGB(5, 10, 20),
		Empty = Color3.fromRGB(20, 40, 70),
		TextDark = Color3.fromRGB(255, 255, 255),
		TextLight = Color3.fromRGB(255, 255, 255),
		Tiles = GameData.BLUE_PALETTE
	},

	-- SKIN NEON (Estilo Cyberpunk: Borde Color, Relleno Negro)
	["Neon"] = { 
		Board = Color3.fromRGB(10, 10, 20),
		Bg = Color3.fromRGB(5, 5, 15),
		Empty = Color3.fromRGB(20, 20, 30),
		TextDark = Color3.fromRGB(255, 255, 255),
		TextLight = Color3.fromRGB(255, 255, 255),
		Tiles = GameData.NEON_PALETTE,


		-- TU ID ORIGINAL:
		BgImage = "rbxassetid://111069386777584", 
		IsNeonStyle = true,
		CornerRadius = 8
	},

	["Dark"] = {
		Board = Color3.fromRGB(50, 50, 50),
		Bg = Color3.fromRGB(30, 30, 30),
		Empty = Color3.fromRGB(70, 70, 70),
		TextDark = Color3.fromRGB(255, 255, 255),
		TextLight = Color3.fromRGB(255, 255, 255),
		Tiles = {
			[2] = Color3.fromRGB(100, 100, 100), [4] = Color3.fromRGB(120, 120, 120),
			[8] = Color3.fromRGB(140, 140, 140), [16] = Color3.fromRGB(160, 160, 160),
			[32] = Color3.fromRGB(180, 180, 180), [64] = Color3.fromRGB(200, 200, 200),
			[128] = Color3.fromRGB(220, 220, 220), [256] = Color3.fromRGB(80, 80, 80),
			[512] = Color3.fromRGB(60, 60, 60), [1024] = Color3.fromRGB(40, 40, 40),
			[2048] = Color3.fromRGB(20, 20, 20), ["SUPER"] = Color3.fromRGB(0, 0, 0)
		}
	},
	["Gold"] = {
		Board = Color3.fromRGB(60, 50, 20),
		Bg = Color3.fromRGB(40, 30, 10),
		Empty = Color3.fromRGB(80, 70, 40),
		TextDark = Color3.fromRGB(255, 255, 255),
		TextLight = Color3.fromRGB(255, 255, 255),
		Tiles = {
			[2] = Color3.fromRGB(255, 250, 200), [4] = Color3.fromRGB(255, 240, 150),
			[8] = Color3.fromRGB(255, 230, 100), [16] = Color3.fromRGB(255, 215, 0),
			[32] = Color3.fromRGB(255, 200, 0), [64] = Color3.fromRGB(255, 180, 0),
			[128] = Color3.fromRGB(255, 160, 0), [256] = Color3.fromRGB(255, 140, 0),
			[512] = Color3.fromRGB(255, 100, 0), [1024] = Color3.fromRGB(255, 50, 0),
			[2048] = Color3.fromRGB(255, 255, 255), ["SUPER"] = Color3.fromRGB(0, 0, 0)
		}
	},
	--[[ 
	   SKIN VIP REDISEÑADA - Estilo "Royal Knight Neon"
	   Basado en la armadura azul, dorada y el neón morado de la imagen.
	]]
	-- ?? SKIN VIP (Edición Lujo: Oro, Azul y Negro)
	["VIP"] = {
		-- Entorno elegante y oscuro
		Board = Color3.fromRGB(10, 10, 15),     -- Negro con tono azulado muy oscuro
		Bg = Color3.fromRGB(0, 0, 0),           -- Fondo Negro Puro
		Empty = Color3.fromRGB(25, 25, 35),     -- Casillas vacías gris oscuro

		TextDark = Color3.fromRGB(255, 215, 0), -- Texto Dorado
		TextLight = Color3.fromRGB(255, 255, 255), -- Texto Blanco

		IsRoyalStyle = true, 
		CornerRadius = 4, -- Bordes más rectos para que se vea más "fuerte"

		-- PALETA: De Azul Profundo a Oro Brillante
		Tiles = { 
			[2] = Color3.fromRGB(0, 30, 80),      -- Azul Marino Oscuro
			[4] = Color3.fromRGB(0, 50, 120),
			[8] = Color3.fromRGB(0, 80, 180),     -- Azul Real
			[16] = Color3.fromRGB(0, 120, 255),   -- Azul Eléctrico
			[32] = Color3.fromRGB(30, 144, 255),
			[64] = Color3.fromRGB(135, 206, 250), -- Azul Cielo
			[128] = Color3.fromRGB(25, 25, 112),  -- Azul Medianoche (Transición)
			[256] = Color3.fromRGB(218, 165, 32), -- Oro Viejo
			[512] = Color3.fromRGB(255, 215, 0),  -- ORO PURO
			[1024] = Color3.fromRGB(255, 223, 0), -- Amarillo Dorado
			[2048] = Color3.fromRGB(255, 255, 0), -- Amarillo Neón (Máximo Lujo)
			["SUPER"] = Color3.fromRGB(0, 0, 0)   -- Negro
		}
	},
	-- ?? SKIN RAINBOW (MEJORADA: Efecto Ola RGB)
	["Rainbow"] = {
		Board = Color3.fromRGB(20, 20, 25),   -- Marco casi negro
		Bg = Color3.fromRGB(10, 10, 15),      -- Fondo oscuro
		Empty = Color3.fromRGB(35, 35, 40),   -- Casillas vacías oscuras
		TextDark = Color3.fromRGB(255, 255, 255),
		TextLight = Color3.fromRGB(255, 255, 255),
		Tiles = GameData.DEFAULT_TILES, -- Se ignorará, lo controla el script
		IsRainbow = true,
		HasBorder = true,  -- Activamos borde para pintarlo RGB
		CornerRadius = 8
	},

	-- === NUEVAS SKINS DE COLORES (Baratas a Caras) ===

	["Red"] = { -- Rojo
		Board = Color3.fromRGB(100, 40, 40), Bg = Color3.fromRGB(60, 20, 20), Empty = Color3.fromRGB(120, 60, 60),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(255, 200, 200), [4]=Color3.fromRGB(255, 150, 150), [8]=Color3.fromRGB(255, 100, 100), ["SUPER"]=Color3.fromRGB(150, 0, 0)}
	},
	["Green"] = { -- Verde
		Board = Color3.fromRGB(40, 100, 40), Bg = Color3.fromRGB(20, 60, 20), Empty = Color3.fromRGB(60, 120, 60),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(200, 255, 200), [4]=Color3.fromRGB(150, 255, 150), [8]=Color3.fromRGB(100, 255, 100), ["SUPER"]=Color3.fromRGB(0, 150, 0)}
	},
	["Purple"] = { -- Morado
		Board = Color3.fromRGB(80, 40, 100), Bg = Color3.fromRGB(40, 20, 60), Empty = Color3.fromRGB(100, 60, 120),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(230, 200, 255), [4]=Color3.fromRGB(200, 150, 255), [8]=Color3.fromRGB(180, 100, 255), ["SUPER"]=Color3.fromRGB(100, 0, 150)}
	},
	["Orange"] = { -- Naranja
		Board = Color3.fromRGB(120, 70, 20), Bg = Color3.fromRGB(80, 40, 10), Empty = Color3.fromRGB(150, 90, 40),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(255, 220, 180), [4]=Color3.fromRGB(255, 180, 100), [8]=Color3.fromRGB(255, 140, 50), ["SUPER"]=Color3.fromRGB(180, 80, 0)}
	},
	["Pink"] = { -- Rosa
		Board = Color3.fromRGB(120, 40, 80), Bg = Color3.fromRGB(80, 20, 50), Empty = Color3.fromRGB(150, 60, 100),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(255, 200, 230), [4]=Color3.fromRGB(255, 150, 200), [8]=Color3.fromRGB(255, 100, 180), ["SUPER"]=Color3.fromRGB(180, 0, 100)}
	},
	["Cyan"] = { -- Cian/Turquesa
		Board = Color3.fromRGB(20, 100, 100), Bg = Color3.fromRGB(10, 60, 60), Empty = Color3.fromRGB(40, 140, 140),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(200, 255, 255), [4]=Color3.fromRGB(150, 255, 255), [8]=Color3.fromRGB(50, 200, 200), ["SUPER"]=Color3.fromRGB(0, 150, 150)}
	},
	["Mint"] = { -- Menta (Suave)
		Board = Color3.fromRGB(60, 120, 90), Bg = Color3.fromRGB(30, 80, 50), Empty = Color3.fromRGB(90, 150, 120),
		TextDark = Color3.fromRGB(50, 80, 60), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(220, 255, 230), [4]=Color3.fromRGB(180, 255, 200), [8]=Color3.fromRGB(140, 255, 170), ["SUPER"]=Color3.fromRGB(40, 150, 100)}
	},
	["Lavender"] = { -- Lavanda (Suave)
		Board = Color3.fromRGB(90, 80, 120), Bg = Color3.fromRGB(60, 50, 90), Empty = Color3.fromRGB(120, 110, 150),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(240, 230, 255), [4]=Color3.fromRGB(220, 200, 255), [8]=Color3.fromRGB(200, 170, 255), ["SUPER"]=Color3.fromRGB(100, 80, 180)}
	},
	["Hot Pink"] = { -- Rosa Intenso
		Board = Color3.fromRGB(150, 20, 100), Bg = Color3.fromRGB(100, 10, 60), Empty = Color3.fromRGB(180, 50, 130),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(255, 200, 240), [4]=Color3.fromRGB(255, 100, 200), [8]=Color3.fromRGB(255, 50, 180), ["SUPER"]=Color3.fromRGB(200, 0, 150)}
	},
	-- === SKINS PRO (Con Relieve/Borde) ===

	["Blue Pro"] = {
		Board = Color3.fromRGB(0, 50, 100), Bg = Color3.fromRGB(0, 20, 40), Empty = Color3.fromRGB(0, 80, 150),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(100, 220, 255), [4]=Color3.fromRGB(50, 200, 255), [8]=Color3.fromRGB(0, 180, 255), ["SUPER"]=Color3.fromRGB(0, 100, 200)},
		HasBorder = true, CornerRadius = 8 -- ? Borde activado para relieve
	},
	["Red Pro"] = {
		Board = Color3.fromRGB(100, 20, 20), Bg = Color3.fromRGB(50, 10, 10), Empty = Color3.fromRGB(150, 50, 50),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(255, 180, 180), [4]=Color3.fromRGB(255, 120, 120), [8]=Color3.fromRGB(255, 80, 80), ["SUPER"]=Color3.fromRGB(200, 0, 0)},
		HasBorder = true, CornerRadius = 8
	},
	["Green Pro"] = {
		Board = Color3.fromRGB(20, 80, 20), Bg = Color3.fromRGB(10, 40, 10), Empty = Color3.fromRGB(50, 120, 50),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(180, 255, 180), [4]=Color3.fromRGB(120, 255, 120), [8]=Color3.fromRGB(80, 255, 80), ["SUPER"]=Color3.fromRGB(0, 180, 0)},
		HasBorder = true, CornerRadius = 8
	},
	["Purple Pro"] = {
		Board = Color3.fromRGB(80, 20, 100), Bg = Color3.fromRGB(40, 10, 50), Empty = Color3.fromRGB(120, 60, 150),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(220, 180, 255), [4]=Color3.fromRGB(200, 140, 255), [8]=Color3.fromRGB(180, 100, 255), ["SUPER"]=Color3.fromRGB(120, 0, 200)},
		HasBorder = true, CornerRadius = 8
	},
	["Orange Pro"] = {
		Board = Color3.fromRGB(120, 60, 0), Bg = Color3.fromRGB(60, 30, 0), Empty = Color3.fromRGB(160, 100, 20),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(255, 200, 150), [4]=Color3.fromRGB(255, 180, 100), [8]=Color3.fromRGB(255, 150, 50), ["SUPER"]=Color3.fromRGB(200, 100, 0)},
		HasBorder = true, CornerRadius = 8
	},
	["Pink Pro"] = {
		Board = Color3.fromRGB(120, 20, 80), Bg = Color3.fromRGB(60, 10, 40), Empty = Color3.fromRGB(160, 60, 120),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(255, 200, 220), [4]=Color3.fromRGB(255, 150, 200), [8]=Color3.fromRGB(255, 100, 180), ["SUPER"]=Color3.fromRGB(200, 0, 120)},
		HasBorder = true, CornerRadius = 8
	},
	["Cyan Pro"] = {
		Board = Color3.fromRGB(0, 80, 100), Bg = Color3.fromRGB(0, 40, 50), Empty = Color3.fromRGB(0, 120, 150),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		Tiles = {[2]=Color3.fromRGB(200, 255, 255), [4]=Color3.fromRGB(150, 255, 255), [8]=Color3.fromRGB(50, 220, 220), ["SUPER"]=Color3.fromRGB(0, 180, 180)},
		HasBorder = true, CornerRadius = 8
	},
	-- === FRUIT COLLECTION ===

	-- 1. ORIGINAL (Restaurada)
	["Fruit Mix"] = {
		Board = Color3.fromRGB(101, 67, 33), Bg = Color3.fromRGB(222, 184, 135), Empty = Color3.fromRGB(139, 69, 19),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		IsImageBased = true,
		IsFruitSkin = true, -- ? IMPORTANTE: Marca como skin de fruta
		Images = {
			-- IDs Originales del archivo subido
			[2] = "rbxassetid://82155629413293", 
			[4] = "rbxassetid://116490216224760",
			[8] = "rbxassetid://112971287879477", 
			[16] = "rbxassetid://105463210552976",
			[32] = "rbxassetid://128100423386205", 
			["SUPER"] = "rbxassetid://105418130110436"
		}
	},

	-- 2. MIX 2 (Variado)
	["Fruit Mix 2"] = {
		Board = Color3.fromRGB(90, 60, 30), Bg = Color3.fromRGB(240, 230, 180), Empty = Color3.fromRGB(120, 80, 40),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		IsImageBased = true, IsFruitSkin = true,
		Images = {
			[2] = "rbxassetid://76951596663341",   -- Limon
			[4] = "rbxassetid://139818222601413",  -- Sandia
			[8] = "rbxassetid://78776843765357",   -- Melon v1
			[16] = "rbxassetid://132000975413440", -- Pera
			[32] = "rbxassetid://73675450769816",  -- Custard Apple
			[64] = "rbxassetid://117586290048073", -- Kiwi
			[128] = "rbxassetid://93248093536327", -- Piña
			[256] = "rbxassetid://100659106786283",-- Arandanos
			[512] = "rbxassetid://91382253679136", -- Cerezas v1
			[1024] = "rbxassetid://108744734844187",-- Aguacate
			[2048] = "rbxassetid://93291750469341", -- Uva Verde
			["SUPER"] = "rbxassetid://93248093536327" 
		}
	},

	-- 3. MIX 3 (Exóticas)
	["Fruit Mix 3"] = {
		Board = Color3.fromRGB(100, 50, 50), Bg = Color3.fromRGB(255, 220, 220), Empty = Color3.fromRGB(150, 70, 70),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		IsImageBased = true, IsFruitSkin = true,
		Images = {
			[2] = "rbxassetid://116453258699233",  -- Uva Morada
			[4] = "rbxassetid://88713982101816",   -- Green Mango
			[8] = "rbxassetid://96024693618887",   -- Melon v2
			[16] = "rbxassetid://112968271193557", -- Chayote
			[32] = "rbxassetid://128181068243828", -- Green Berry
			[64] = "rbxassetid://136853516693553", -- Dragon Fruit
			[128] = "rbxassetid://110048911581992",-- Red Fruit
			[256] = "rbxassetid://113133998929200",-- Uva Roja
			[512] = "rbxassetid://112934857714958",-- Cerezas v2
			[1024] = "rbxassetid://88045392381930",-- Red Fruit v2
			[2048] = "rbxassetid://136853516693553",-- Dragon Fruit
			["SUPER"] = "rbxassetid://136853516693553"
		}
	},

	-- 4. GREEN ONLY (Sin Sandía, solo verdes puros)
	["Fruits Green"] = { 
		Board = Color3.fromRGB(40, 80, 40), Bg = Color3.fromRGB(200, 255, 200), Empty = Color3.fromRGB(60, 100, 60),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		IsImageBased = true, IsFruitSkin = true,
		Images = {
			[2] = "rbxassetid://76951596663341",   -- Limon
			[4] = "rbxassetid://132000975413440",  -- Pera
			[8] = "rbxassetid://117586290048073",  -- Kiwi
			[16] = "rbxassetid://108744734844187", -- Aguacate
			[32] = "rbxassetid://93291750469341",  -- Uva Verde
			[64] = "rbxassetid://88713982101816",  -- Green Mango
			[128] = "rbxassetid://112968271193557",-- Chayote
			[256] = "rbxassetid://128181068243828",-- Green Berry
			[512] = "rbxassetid://78776843765357", -- Melon v1
			[1024] = "rbxassetid://96024693618887",-- Melon v2
			[2048] = "rbxassetid://73675450769816",-- Custard Apple
			["SUPER"] = "rbxassetid://76951596663341" -- Limon
		}
	},

	-- 5. RED ONLY (Incluye Sandía y Morados)
	["Fruits Red"] = { 
		Board = Color3.fromRGB(100, 20, 40), Bg = Color3.fromRGB(255, 200, 200), Empty = Color3.fromRGB(150, 60, 80),
		TextDark = Color3.new(1,1,1), TextLight = Color3.new(1,1,1),
		IsImageBased = true, IsFruitSkin = true,
		Images = {
			[2] = "rbxassetid://139818222601413",  -- Sandia (Movida aquí)
			[4] = "rbxassetid://91382253679136",   -- Cerezas v1
			[8] = "rbxassetid://112934857714958",  -- Cerezas v2
			[16] = "rbxassetid://110048911581992", -- Red Fruit
			[32] = "rbxassetid://88045392381930",  -- Red Fruit v2
			[64] = "rbxassetid://113133998929200", -- Uva Roja
			[128] = "rbxassetid://136853516693553",-- Dragon Fruit
			[256] = "rbxassetid://116453258699233",-- Uva Morada
			[512] = "rbxassetid://100659106786283",-- Arandanos
			[1024] = "rbxassetid://110048911581992",-- Red Fruit (Repetido alto valor)
			[2048] = "rbxassetid://136853516693553",-- Dragon Fruit (Repetido alto valor)
			["SUPER"] = "rbxassetid://139818222601413"
		}
	},

	["Classic 2048"] = {
		Board = Color3.fromRGB(187, 173, 160),
		Bg = Color3.fromRGB(250, 248, 239),
		Empty = Color3.fromRGB(205, 193, 180),
		TextDark = Color3.fromRGB(255, 255, 255),
		TextLight = Color3.fromRGB(255, 255, 255),
		Tiles = GameData.CLASSIC_PALETTE,
		-- TU ID ORIGINAL:
		BgImage = "rbxassetid://125708979547514", 
		HasBorder = true,
		HasTextStroke = true,
		CornerRadius = 12
	},

	-- ?? NUEVA SKIN ROBOT (Estilo Industrial/Carcasa)
	["Robot"] = {
		Board = Color3.fromRGB(80, 85, 90),    -- Marco Gris Metal
		Bg = Color3.fromRGB(135, 206, 235),    -- (El fondo será tu imagen, este color es de reserva)
		Empty = Color3.fromRGB(120, 125, 130), -- Casilla vacía metálica
		TextDark = Color3.fromRGB(255, 255, 255),
		TextLight = Color3.fromRGB(255, 255, 255),
		Tiles = {
			-- Paleta sacada de tu imagen de referencia
			[2] = Color3.fromRGB(230, 230, 235),   -- Gris Claro (Placa)
			[4] = Color3.fromRGB(100, 190, 180),   -- Cian Metálico
			[8] = Color3.fromRGB(160, 160, 165),   -- Gris Medio
			[16] = Color3.fromRGB(140, 145, 150),  -- Gris Oscuro
			[32] = Color3.fromRGB(210, 215, 220),  -- Gris Plata
			[64] = Color3.fromRGB(60, 100, 160),   -- Azul Industrial
			[128] = Color3.fromRGB(100, 200, 200), -- Cian Brillante
			[256] = Color3.fromRGB(80, 80, 90),
			["SUPER"] = Color3.fromRGB(50, 50, 60)
		},
		-- TU ID EXACTO DEL BACKGROUND:
		BgImage = "rbxassetid://97832119311463", 
		IsRobotStyle = true,
		CornerRadius = 8 -- Bordes redondeados pero industriales
	},
	-- ?? SKIN VOLCANIC (Corregida: Colores Oscuros)
	["Volcanic"] = {
		Board = Color3.fromRGB(30, 15, 10),   -- Borde del tablero (Roca oscura)
		Bg = Color3.fromRGB(15, 10, 5),       -- Fondo de pantalla oscuro
		Empty = Color3.fromRGB(45, 35, 35),   -- ? ESTO QUITA EL BEIGE: Casillas vacías color roca
		TextDark = Color3.fromRGB(255, 200, 50), 
		TextLight = Color3.fromRGB(255, 100, 0), 
		Tiles = GameData.DEFAULT_TILES, 

		-- TU ID DE FONDO:
		BgImage = "rbxassetid://138298720179782",

		IsVolcanicStyle = true,
		CornerRadius = 8
	},
}


-- 4. PLAYLIST DE MÚSICA
GameData.MUSIC_PLAYLIST = {
	{Id = "rbxassetid://5979775161", Name = "Lofi Hip Hop"},
	{Id = "rbxassetid://1848354536", Name = "Chill Vibes"},
	{Id = "rbxassetid://9046862941", Name = "Relaxing Beat"},
	{Id = "rbxassetid://9046865270", Name = "Study Session"},
	{Id = "rbxassetid://1837070127", Name = "Deep Focus"}
}

-- TABLA DE TÍTULOS (ACTUALIZADA Y ORDENADA)
GameData.TITLES_DATA = {
	-- === [MAIN] (Ordenado por Dificultad) ===
	{Name="Novice",      Category="Main", Desc="Play for the first time.", Req=0, Color=Color3.fromRGB(200,200,200), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(220,220,220)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150,150,150))}},
	{Name="Pro",         Category="Main", Desc="Reach 10,000 Score.",    Req=10000, Color=Color3.fromRGB(50,100,255), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(50,100,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,50,200))}},
	{Name="Expert",      Category="Main", Desc="Reach 50,000 Score.",    Req=50000, Color=Color3.fromRGB(180, 50, 255), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(180,50,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(100,0,180))}}, -- NUEVO
	{Name="Master",      Category="Main", Desc="Reach 100,000 Score.",   Req=100000, Color=Color3.fromRGB(255,50,50), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255,50,50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150,0,0))}},
	{Name="Grandmaster", Category="Main", Desc="Reach 500,000 Score.",   Req=500000, Color=Color3.fromRGB(255,150,0), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255,150,0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,80,0))}}, -- NUEVO
	{Name="Legend",      Category="Main", Desc="Reach 1,000,000 Score.", Req=1000000, Color=Color3.fromRGB(0,255,255), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(0,255,255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,200,255))}}, -- NUEVO

	-- RACHAS (Dentro de Main)
	{Name="Dedicated",   Category="Main", Desc="7 Day Login Streak.",  ReqAttribute="Streak7", Color=Color3.fromRGB(100,255,100), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(100,255,100)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,180,0))}},
	{Name="Addicted",    Category="Main", Desc="30 Day Login Streak.", ReqAttribute="Streak30", Color=Color3.fromRGB(255,150,0), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255,150,0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,80,0))}},
	{Name="Eternal",     Category="Main", Desc="100 Day Streak.",      ReqAttribute="Streak100", Color=Color3.fromRGB(255,0,255), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,255))}},

	-- === [RICHES] (Divisa/Dinero/Frutas) ===

	-- FRUTAS (Fruit Gems)
	{Name="Berry Picker",  Category="Riches", Desc="Collect 1,000 Fruit Gems.", ReqTotalGems=1000, Color=Color3.fromRGB(255,100,150), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255,150,180)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,50,100))}}, -- Buffeado a 1000
	{Name="Collector",     Category="Riches", Desc="Collect 5,000 Fruit Gems.", ReqTotalGems=5000, Color=Color3.fromRGB(255,180,50), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255,200,80)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200,100,0))}}, -- Nuevo
	{Name="Fruit Ninja",   Category="Riches", Desc="Collect 10,000 Fruit Gems.",ReqTotalGems=10000, Color=Color3.fromRGB(100,255,50), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(150,255,50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(50,200,0))}},
	{Name="Harvest King",  Category="Riches", Desc="Collect 100k Fruit Gems.",  ReqTotalGems=100000, Color=Color3.fromRGB(255,215,0), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255,215,0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(50,200,50))}},

	-- MONEDAS (Coins)
	{Name="Saver",         Category="Riches", Desc="Have 10,000 Coins.",       ReqCoins=10000, Color=Color3.fromRGB(200,200,100), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(220,220,150)), ColorSequenceKeypoint.new(1, Color3.fromRGB(180,180,50))}},
	{Name="Banker",        Category="Riches", Desc="Have 100,000 Coins.",      ReqCoins=100000, Color=Color3.fromRGB(50,255,100), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(100,255,150)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,150,50))}},
	{Name="Tycoon",        Category="Riches", Desc="Have 1,000,000 Coins.",    ReqCoins=1000000, Color=Color3.fromRGB(50,200,255), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(50,200,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,150))}},

	-- DIAMANTES (Gems)
	{Name="Shiny",         Category="Riches", Desc="Have 500 Gems.",           ReqGems=500, Color=Color3.fromRGB(100,240,255), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(200,250,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,200,255))}},
	{Name="Gem Hunter",    Category="Riches", Desc="Have 2,000 Gems.",         ReqGems=2000, Color=Color3.fromRGB(0,150,255), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(0,180,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,200))}},
	{Name="Rich",          Category="Riches", Desc="Have 10,000 Gems.",        ReqGems=10000, Color=Color3.fromRGB(255,0,255), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255,100,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150,0,150))}},
	-- === [OTHERS] (Ordenado por tipo) ===

	-- ESPECIALES (Tester, VIP)
	{Name="Tester",    Category="Others", Desc="Beta Tester.",         ReqAttribute="IsTester", Color=Color3.fromRGB(0,200,255), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(0,255,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,150,200))}}, -- NUEVO
	{Name="VIP",       Category="Others", Desc="Exclusive VIP Title.", IsVIP=true, Color=Color3.fromRGB(255, 200, 80), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromHex("FFC850")), ColorSequenceKeypoint.new(1, Color3.fromHex("FFF0B4"))}},

	-- ROBUX SPENT
	{Name="Supporter", Category="Others", Desc="Spent 100+ Robux.",    ReqRobux=100, Color=Color3.fromRGB(0,255,150), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(80,255,150)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,180,100))}},
	{Name="Whale",     Category="Others", Desc="Spent 5,000+ Robux.",  ReqRobux=5000, Color=Color3.fromRGB(0,255,255), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(0,255,255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,0,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,255))}},
	{Name="Leviathan", Category="Others", Desc="Spent 50,000+ Robux.", ReqRobux=50000, Color=Color3.fromRGB(100,0,255), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(150,0,255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,0,0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150,0,255))}},

	-- STAFF (Al final)
	{Name="Mod",       Category="Others", Desc="Community Moderator.", ReqAttribute="IsMod", Color=Color3.fromRGB(50,200,100), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(0,255,100)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,100,50))}},
	{Name="Admin",     Category="Others", Desc="Game Administrator.",  ReqAttribute="IsAdmin", Color=Color3.fromRGB(255,50,50), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255,80,80)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150,0,0))}},
	{Name="Owner",     Category="Others", Desc="Game Creator.",        ReqAttribute="IsOwner", Color=Color3.fromRGB(255,0,0), Gradient=ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(100,0,0))}}
}

return GameData