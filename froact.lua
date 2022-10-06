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

local function newE(roact: any, hooks, defaults: { DefaultPropertyConfig })
	return function(class: string, props: { [string]: any }, children: Children)
		for _, default in defaults do
			if isA(class, default.class) and not props[default.property] then
				props[default.property] = default.value
			end
		end
		return roact.createElement(class, props, children)
	end
end

local function newTemplate(roact: any, unpureByDefault: boolean?)
	type CleanupMethod = () -> ()
	type UpdateMethod<Props> = (props: Props) -> CleanupMethod
	type Constructor<Props> = (
		name: string,
		parent: Instance,
		onUpdate: (UpdateMethod<Props>) -> ()
	) -> CleanupMethod
	return function<Props>(config: ComponentConfig, f: Constructor<Props>)
		local isPure = if config.pure == nil
			then not unpureByDefault
			else config.pure
		local Component = if isPure
			then roact.PureComponent:extend(config.name or "Component")
			else roact.Component:extend(config.name or "Component")
		function Component:init()
			local _className, hostKey, hostParent, _children
			for name, field in self do
				if tostring(name) == "Symbol(InternalData)" then
					_className = field.componentClass
					hostKey = field.virtualNode.hostKey
					hostParent = field.virtualNode.hostParent
					_children = field.virtualNode.children
				end
			end
			self.updateCallbacks = {}
			self.updateCleanups = {}
			self.cleanup = f(hostKey, hostParent, function(callback)
				table.insert(self.updateCleanups, callback(self.props))
				table.insert(self.updateCallbacks, f)
			end)
		end
		function Component:render()
			return roact.createFragment()
		end
		function Component:didUpdate()
			for _, cleanup in self.updateCleanups do
				cleanup()
			end
			self.updateCleanups = {}
			for _, callback in self.updateCallbacks do
				table.insert(self.updateCleanups, callback(self.props))
			end
		end
		function Component:willUnmount()
			for _, cleanup in self.updateCleanups do
				cleanup()
			end
			self.cleanup()
		end
		return function(props: Props, children)
			return roact.createElement(Component, props, children)
		end
	end
end

-- stylua: ignore
type ListConfig = (
	{ orderByName: boolean?, setOrder: true, initial: number?, key: string? }
	| { orderByName: boolean?, setOrder: false?, initial: nil, key: string? }
)
local function newList(roact: any)
	return function(config: ListConfig, elements: { [number]: Element })
		local index = if config.initial then config.initial else 0
		local count: { [string]: number } = {}
		local dict = {}
		local nameFormat = "%0"
			.. math.floor(math.log10(#elements) + 1)
			.. "i | %s" -- For orderByName
		for _, element in elements do
			local isRobloxClass = typeof(element.component) == "string"
			local className = if isRobloxClass
				then element.component
				else element.component.__componentName

			local sortType = if not isRobloxClass
				then "Component"
				else if isRobloxClass
						and isA(element.component, "GuiObject")
					then "Instance"
					else "None"

			local key = if config.key and element.props[config.key]
				then element.props[config.key]
				else className
			if config.orderByName and sortType ~= "None" then
				index += 1
				key = string.format(nameFormat, index, key)
			end
			if count[key] == 1 then
				dict[key .. " " .. count[key]] = dict[key]
				dict[key] = nil
			end
			if count[key] then
				count[key] += 1
				dict[key .. " " .. count[key]] = element
			else
				count[key] = 1
				dict[key] = element
			end

			if config.setOrder and sortType == "Instance" then
				index += 1
				element.props.LayoutOrder = index
			elseif config.setOrder and sortType == "Component" then
				index += 1
				element.props.layoutOrder = index
			end
		end
		return roact.createFragment(dict)
	end
end

local blankChildren = table.freeze({})

type HookFunction<Props, Hooks> = (
	render: (Props, Hooks, { Element }) -> any,
	options: any
) -> any

local function newC<Hooks>(
	roact: any,
	hooks: HookFunction<any, Hooks>,
	unpureByDefault: boolean?
)
	return function<Props>(
		config: ComponentConfig,
		body: (Props, Hooks, { Element }) -> any
	): (Props, Children) -> any
		local isPure = if config.pure == nil
			then not unpureByDefault
			else config.pure
		-- Wrap the body to have children passed in as a third argument
		local function wrappedBody(props: any, hooks)
			local children = props[roact.Children]
			props[roact.Children] = nil
			body(props, hooks, if children then children else blankChildren)
		end
		local Component = hooks(wrappedBody, {
			componentType = if isPure then "PureComponent" else "Component",
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
		template = newTemplate(config.Roact, config.unpureByDefault),
		-- FROACTFUL_FUNCTION_EXPORTS
	}
end

return froact
