--!strict
-- ThemeTokens: Authoritative visual design tokens for Project Bloomtrail (React-Lua)
-- Sourced directly from docs/ART_BIBLE.md

local ThemeTokens = {
    Colors = {
        -- Surfaces & Containers
        ParchmentIvory   = Color3.fromRGB(255, 248, 238), -- #FFF8EE
        RiverStone       = Color3.fromRGB(232, 224, 213), -- #E8E0D5
        CedarUmber       = Color3.fromRGB(92, 56, 30),    -- #5C381E
        DeepEspresso     = Color3.fromRGB(46, 27, 14),    -- #2E1B0E
        BotanicalScrim   = Color3.fromRGB(20, 35, 20),    -- #142314
        
        -- Botanical Accents
        LeafSage         = Color3.fromRGB(78, 141, 83),   -- #4E8D53
        BotanicalForest  = Color3.fromRGB(38, 77, 43),   -- #264D2B
        SproutLime       = Color3.fromRGB(138, 201, 38),  -- #8AC926
        
        -- Match-3 Piece Colors
        BerryCrimson     = Color3.fromRGB(230, 57, 70),   -- #E63946 (Apple / Berry)
        DewdropBlue      = Color3.fromRGB(42, 157, 143),  -- #2A9D8F (Water Dewdrop)
        BlossomYellow    = Color3.fromRGB(244, 162, 97),  -- #F4A261 (Sun Blossom)
        PlumPurple       = Color3.fromRGB(114, 9, 183),   -- #7209B7 (Royal Plum)
        EmeraldLeaf      = Color3.fromRGB(78, 141, 83),   -- #4E8D53 (Leaf Gem)
        
        -- Metrics & Rewards
        StarGold         = Color3.fromRGB(255, 183, 3),   -- #FFB703
        CoinAmber        = Color3.fromRGB(251, 133, 0),   -- #FB8500
    },

    Radii = {
        Pill   = UDim.new(0.5, 0),
        Modal  = UDim.new(0, 18),
        Card   = UDim.new(0, 12),
        Tile   = UDim.new(0, 10),
        Badge  = UDim.new(0, 8),
    },

    Typography = {
        DisplayHero = {
            Font = Enum.Font.FredokaOne,
            Size = 32,
        },
        SectionHeader = {
            Font = Enum.Font.GothamBold,
            Size = 22,
        },
        MetricValue = {
            Font = Enum.Font.GothamBlack,
            Size = 26,
        },
        ButtonLabel = {
            Font = Enum.Font.GothamBold,
            Size = 18,
        },
        BodyText = {
            Font = Enum.Font.GothamMedium,
            Size = 14,
        },
        Caption = {
            Font = Enum.Font.Gotham,
            Size = 11,
        },
    },

    Spacing = {
        XXS = 4,
        XS  = 8,
        SM  = 12,
        MD  = 16,
        LG  = 24,
        XL  = 32,
        XXL = 48,
    },
}

return ThemeTokens
