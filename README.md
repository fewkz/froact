# froact
Froact is a wrapper around [Roact](https://github.com/Roblox/roact) and [Roact Hooks](https://github.com/Kampfkarren/roact-hooks)
to make UI development easier via utilies and improved types.

## Adding froact
You can download the latest release of froact as a rbxm file from https://github.com/fewkz/froact/releases.

Froact can be added to your project via [Wally](https://wally.run/) by adding this line under dependencies.
```toml
froact = "fewkz/froact@0.1.1"
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

`froact.list` takes an array of elements and will generate names and set LayoutOrder.
It returns a Roact fragment.
For components, it will assign `layoutOrder` to props.
```lua
local fragment = froact.list({ setOrder = true }, {
    froact.UIListLayout({ SortOrder = Enum.SortOrder.LayoutOrder }), -- Gets named UIListLayout1
    froact.TextLabel({ Text = "This line is first" }), -- Gets named TextLabel1
    froact.TextLabel({ Text = "This line is second" }), -- Gets named TextLabel2
    Timer({}) -- Gets named Timer1, since `name` was defined on it.
    ReverseLabel({ text = "This line is last" }) -- Gets named ReverseLabel1, and has `layoutOrder` set.
})
```

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