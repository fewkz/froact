--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local Hooks = require(ReplicatedStorage.Packages.RoactHooks)

local baseFroact = require(ReplicatedStorage.froact.ful)

-- stylua: ignore
local defaultProperties: { baseFroact.DefaultPropertyConfig } = {
	{ class = "GuiObject", property = "BackgroundColor3", value = Color3.new(1, 1, 1) },
	{ class = "GuiObject", property = "BorderColor3", value = Color3.new(0, 0, 0) },
	{ class = "GuiObject", property = "BorderSizePixel", value = 0 },

	{ class = "TextLabel", property = "Font", value = Enum.Font.SourceSans },
	{ class = "TextLabel", property = "Text", value = "" },
	{ class = "TextLabel", property = "TextColor3", value = Color3.new(0, 0, 0) },
	{ class = "TextLabel", property = "TextSize", value = 14 },

	{ class = "TextBox", property = "Font", value = Enum.Font.SourceSans },
	{ class = "TextBox", property = "Text", value = "" },
	{ class = "TextBox", property = "TextColor3", value = Color3.new(0, 0, 0) },
	{ class = "TextBox", property = "TextSize", value = 14 },
	{ class = "TextButton", property = "Font", value = Enum.Font.SourceSans },
	{ class = "TextButton", property = "Text", value = "" },
	{ class = "TextButton", property = "TextColor3", value = Color3.new(0, 0, 0) },
	{ class = "TextButton", property = "TextSize", value = 14 },

	{ class = "TextButton", property = "AutoButtonColor", value = false },
	{ class = "ImageButton", property = "AutoButtonColor", value = false },

	{ class = "UIGridStyleLayout", property = "SortOrder", value = Enum.SortOrder.LayoutOrder },

	{ class = "LayerCollector", property = "ZIndexBehavior", value = Enum.ZIndexBehavior.Sibling },
	{ class = "LayerCollector", property = "ResetOnSpawn", value = false },
	{ class = "SurfaceGui", property = "SizingMode", value = Enum.SurfaceGuiSizingMode.PixelsPerStud },
	{ class = "SurfaceGui", property = "PixelsPerStud", value = 50 },
}

local froact = baseFroact.configure({
	Roact = Roact,
	Hooks = Hooks.new(Roact),
	defaultProperties = defaultProperties,
})

type froact = typeof(froact)

return froact
