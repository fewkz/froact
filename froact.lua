--!strict
local froact = {}

export type DefaultPropertyConfig = {
	class: string,
	property: string,
	value: any,
}
type ComponentConfig = {
	pure: boolean?,
	name: string?,
}

local isAMemo = {}
local function isA(class: string, ancestor: string)
	local key = class .. "-" .. ancestor
	if isAMemo[key] then
		return isAMemo[key]
	end
	local instance: Instance = Instance.new(class :: any)
	isAMemo[key] = instance:IsA(ancestor)
	return isAMemo[key]
end

type Element = any
-- type Children = Element | { Element } | nil
type Children = any? -- For simpler definitions, since it's the equivalent as above

local function newE(roact, hooks, defaults: { DefaultPropertyConfig })
	return function(class: string, props: { [string]: any }, children: Children)
		for _, default in defaults do
			if isA(class, default.class) and not props[default.property] then
				props[default.property] = default.value
			end
		end
		return roact.createElement(class, props, children)
	end
end

local function newList(roact)
	return function(
		config: { setOrder: true, initial: number? } | { setOrder: false?, initial: nil },
		elements: { [number]: Element }
	)
		local index = if config.initial then config.initial else 0
		local count: { [string]: number } = {}
		local dict = {}
		for _, element in elements do
			local isRobloxClass = typeof(element.component) == "string"
			local className = if isRobloxClass
				then element.component
				else element.component.__componentName
			if count[className] == nil then
				count[className] = 1
			else
				count[className] += 1
			end
			local instanceName = className .. count[className]
			dict[instanceName] = element
			if
				config.setOrder
				and isRobloxClass
				and isA(element.component, "GuiObject")
			then
				index += 1
				element.props.LayoutOrder = index
			elseif config.setOrder and not isRobloxClass then
				index += 1
				element.props.layoutOrder = index
			end
		end
		return roact.createFragment(dict)
	end
end

type HookFunction<Props, Hooks> = (
	render: (Props, Hooks) -> any,
	options: any
) -> any

local function newC<Hooks>(
	roact,
	hooks: HookFunction<any, Hooks>,
	unpureByDefault: boolean?
)
	return function<Props>(
		config: ComponentConfig,
		body: (Props, Hooks) -> any
	): (Props, Children) -> any
		if not unpureByDefault then
			if config.pure == nil then
				config.pure = true
			end
		end
		local Component = hooks(body, {
			componentType = if config.pure
				then "PureComponent"
				else "Component",
			name = if config.name then config.name else "Component",
		})
		return function(props, children)
			return roact.createElement(Component, props, children)
		end
	end
end

-- FROACTFUL_FUNCTION_TOP
function froact.configure<Hooks>(config: {
	Roact: any,
	Hooks: HookFunction<any, Hooks>,
	defaultProperties: { DefaultPropertyConfig }?,
	unpureByDefault: boolean?,
})
	local e = newE(
		config.Roact,
		config.Hooks,
		if config.defaultProperties then config.defaultProperties else {}
	)
	-- FROACTFUL_FUNCTION_BODY
	return {
		Roact = config.Roact,
		Hooks = config.Hooks,
		e = e,
		c = newC(config.Roact, config.Hooks, config.unpureByDefault),
		list = newList(config.Roact),
		-- FROACTFUL_FUNCTION_EXPORTS
	}
end

return froact
