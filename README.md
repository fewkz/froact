# froact
Froact is a wrapper around [Roact](https://github.com/Roblox/roact) and [Roact Hooks](https://github.com/Kampfkarren/roact-hooks)
to make UI development easier via utilies and improved types.

## Adding froact
You can download the latest release of froact as a rbxm file from https://github.com/fewkz/froact/releases.

Froact can be added to your project via [Wally](https://wally.run/) by adding this line under dependencies.
```toml
froact = "fewkz/froact@0.2.0"
```

## How to use
Froact needs to be configured in order to be used:
```lua
local baseFroact = require(path.to.froact)
local froact = baseFroact.configure({
    Roact = Roact,
    Hooks = Hooks.new(Roact),
    defaultProperties = {
        { class = "GuiObject", property = "BorderSizePixel", value = 0 }
    },
})
```
Configuration is where you give froact a reference to Roact and RoactHooks.
You can also set default properties to be applied to all elements froact creates.
For a good starting config, see [fluf-example-game/src/FroactConfig.lua](https://github.com/fewkz/fluf-example-game/blob/main/src/FroactConfig.lua).

This configured version of froact should be used, not the base froact module.

## Features
`froact.c` lets you create a functional component.
```lua
local Timer = froact.c({ pure = true, name = "Timer" }, function(props, hooks)
    local count, setCount = hooks.useState(0)
    hooks.useEffect(function()
        local thread = task.spawn(function()
            while true do
                task.wait(1)
                setCount(function(count)
                    return count + 1
                end)
            end
        end)
        return function()
            task.cancel(thread)
        end)
    end, {})
    return froact.TextLabel({
        Text = "It's been "..count.." seconds"
    })
end)
```
The first parameter configures the component.
It supports `pure` to make the component a `PureComponent`,
which only re-renders if it's properties or state change.
It also supports `name` which is the name of the Roact component.
Froact also uses the name of the component when generating a name with `froact.list`.

Froact is designed to be used by calling the component directly,
rather than using `Roact.createElement`.
Froact is designed to give you full luau type checking support this way.
```lua
type ReverseLabelProps = { text: string, layoutOrder: number? }
local ReverseLabel = froact.c({ name = "ReverseLabel" }, function(props: ReverseLabelProps, hooks)
    local reversed = string.reverse(props.text)
    return froact.TextLabel({ Text = reversed, LayoutOrder = props.layoutOrder })
end)
local element = ReverseLabel({
    layoutOrder = "five" -- Luau would warn against this
    -- Luau will warn that text was not specified
})
```

`froact.list` takes an array of elements and returns a Roact fragment with generated keys for each element.
If the `setOrder` config is enabled, it will set the `LayoutOrder` of elements.
If an element is not an instance component, it will instead assign `layoutOrder` to props.

If the `orderByName` config is enabled, keys will be prefixed by a number that can
be sorted by a `UIListLayout` with `SortOrder.Name`.
This makes the tree in the explorer easier to read in studio.

The key of elements can be set to the value of a prop using the `key` config.
```lua
local list1 = froact.list({ setOrder = true }, {
    froact.UIListLayout({ SortOrder = Enum.SortOrder.LayoutOrder }), -- Gets named UIListLayout
    froact.TextLabel({ Text = "This line is first" }), -- Gets named TextLabel 1
    froact.TextLabel({ Text = "This line is second" }), -- Gets named TextLabel 2
    Timer({}) -- Gets named Timer, since `name` was defined on it.
    ReverseLabel({ text = "This line is last" }) -- Gets named ReverseLabel, and has `layoutOrder` set.
})
local list2 = froact.list({ orderByName = true, key = "text" }, {
    froact.UIListLayout({ SortOrder = Enum.SortOrder.Name }), -- Gets named UIListLayout
    froact.TextLabel({ Text = "First line" }), -- Gets named 1 | First line
    froact.TextLabel({ Text = "Second line" }), -- Gets named 2 | Second line
})
```

You can connect to the events of an instance component via the `onEventName` prop.
```lua
local element = froact.TextButton({
    onActivated = function()
        print("Button was pressed")
    end 
})
```
You can connect to when a property of an instance component changes via the `bindPropertyName` prop.
Froact only has bind props for `Text`, `TextBounds`, and all `Absolute...` properties.
Binds for `TextBounds` and `Absolute...` properties will trigger as soon as the element is mounted.
```lua
local element = froact.TextBox({
    bindText = function(rbx)
        print("Text was changed to", rbx.Text)
    end 
})
```
To assign a ref to an element, you can use the `ref` prop
```lua
local ref = froact.Roact.createRef()
local element = froact.TextLabel({ ref = ref })
```

Froact has support for turning template-based UI into components.
This is useful when gradually porting an existing codebase to Roact,
or for having legacy UI still work without having to recode it.
```lua
local HealthBarTemplate = froact.template({ name = "HealthBar" }, function(name, parent, onUpdate)
    local rbx = ReplicatedStorage.UI.HealthBar:Clone()
    rbx.Name = name
    rbx.Parent = parent
    onUpdate(function(props: { percent: number })
        rbx.Percent.Size = UDim2.fromScale(props.percent, 0)
    end)
    return function()
        rbx:Destroy()
    end
})
-- Can be used like an ordinary component!
local element = froact.ScreenGui({}, HealthBarTemplate({ percent = 0.5 }))
froact.Roact.mount(element, Players.LocalPlayer.PlayerGui, "HealthBar")
```
Templates do not support hooks by default, so if you want to add functionality you should wrap the template in another froact component.

# froact testing
Generated by [Rojo](https://github.com/rojo-rbx/rojo) 7.2.1.

## Getting Started
To build the place from scratch, use:

```bash
rojo build -o "testing.rbxl" testing.project.json
```

Next, open `testing.rbxl` in Roblox Studio and start the Rojo server:

```bash
rojo serve testing.project.json
```

For more help, check out [the Rojo documentation](https://rojo.space/docs).
