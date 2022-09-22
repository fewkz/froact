--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local froact = require(ReplicatedStorage.Common.myFroact)

local Counter = froact.c({}, function(props: { text: string }, hooks)
	local count, setCount = hooks.useState(0)
	local hovering, setHovering = hooks.useBinding(false)
	local onClick = hooks.useCallback(function()
		setCount(function(count: number)
			return count + 1
		end)
	end, {})
	return froact.list({ setOrder = true, initial = 1 }, {
		froact.UIScale({ Scale = 2 }),
		froact.UIListLayout({
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		froact.TextLabel({
			AutomaticSize = Enum.AutomaticSize.XY,
			Text = "You clicked " .. count .. " times",
		}),
		froact.TextButton({
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = hovering:map(function(hovering)
				return if hovering
					then Color3.fromRGB(189, 74, 74)
					else Color3.fromRGB(255, 100, 100)
			end),
			Text = "Click to increase",
			onActivated = onClick,
			onMouseEnter = function()
				setHovering(true)
			end,
			onMouseLeave = function()
				setHovering(false)
			end,
		}, {
			UIPadding = froact.UIPadding({
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
			UICorner = froact.UICorner({ CornerRadius = UDim.new(0.5, 0) }),
		}),
	})
end)

local e = froact.ScreenGui(
	{},
	froact.Frame({
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromOffset(200, 100),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}, {
		UIScale = froact.UIScale({ Scale = 2 }),
		UICorner = froact.UICorner({ CornerRadius = UDim.new(0.25, 0) }),
		Counter = Counter({ text = "hello" }),
	})
)

Roact.mount(e, Players.LocalPlayer.PlayerGui, "Counter")

print("Hello world, from client!")
