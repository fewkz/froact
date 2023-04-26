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
		local isPure = if config.pure == nil then not unpureByDefault else config.pure
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
		local nameFormat = "%0" .. math.floor(math.log10(#elements) + 1) .. "i | %s" -- For orderByName
		for _, element in elements do
			local isRobloxClass = typeof(element.component) == "string"
			local className = if isRobloxClass
				then element.component
				else element.component.__componentName

			local sortType = if not isRobloxClass
				then "Component"
				else if isRobloxClass and isA(element.component, "GuiObject")
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

type HookFunction<Props, Hooks> = (render: (Props, Hooks) -> any, options: any) -> any

local function newC<Hooks>(roact: any, hooks: HookFunction<any, Hooks>, unpureByDefault: boolean?)
	return function<Props>(
		config: ComponentConfig,
		body: (Props, Hooks, { Element }) -> any
	): (Props, Children) -> any
		local isPure = if config.pure == nil then not unpureByDefault else config.pure
		-- Wrap the body to have children passed in as a third argument
		local function wrappedBody(props: any, hooks)
			local children = props[roact.Children]
			props[roact.Children] = nil
			return body(props, hooks, if children then children else blankChildren)
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

type Ref = { current: any }
local function newCreateRef(roact: any): () -> Ref
	return roact.createRef
end

type Binding<T> = { getValue: (self: Binding<T>) -> T }
local function newCreateBinding(roact: any): <T>(default: T) -> (Binding<T>, (T) -> ())
	return roact.createBinding
end

type BindingPairs<T...> = { map: <O>(self: BindingPairs<T...>, f: (T...) -> O) -> Binding<O> }
local function newJoin(roact: any): (
	(<A>(b1: Binding<A>) -> BindingPairs<A>)
	& (<A, B>(b1: Binding<A>, b2: Binding<B>) -> BindingPairs<A, B>)
	& (<A, B, C>(b1: Binding<A>, b2: Binding<B>, b3: Binding<C>) -> BindingPairs<A, B, C>)
	& (<A, B, C, D>(
		b1: Binding<A>,
		b2: Binding<B>,
		b3: Binding<C>,
		b4: Binding<D>
	) -> BindingPairs<A, B, C, D>)
)
	return (
		function(...)
			local bindings = { ... }
			local joined = roact.joinBindings(bindings)
			return {
				map = function(self, f)
					return joined:map(function(a)
						return f(unpack(a))
					end)
				end,
			}
		end
	) :: any
end

local function newMap(roact: any): <T, O>(binding: Binding<T>, f: (T) -> O) -> Binding<O>
	return function(binding: any, f)
		return binding:map(f)
	end
end

-- We write our own Hooks type. Might make froact incompatible
-- with different versions of RoactHooks, although it's unlikely
-- there'd be a breaking change any time soon. We could consider
-- vendoring our own RoactHooks eventually.
-- One opinionated change we make is not making dependencies optional.
-- forgetting to include dependencies is a very easy way to
-- shoot yourself in the foot optimization-wise.
type Hooks = {
	useBinding: <T>(defaultValue: T) -> (Binding<T>, (newValue: T) -> ()),
	useCallback: <A..., R...>(
		callback: (A...) -> R...,
		dependencies: { unknown }
	) -> (A...) -> R...,
	useEffect: (callback: () -> (), dependencies: { unknown }) -> (),
	useMemo: <T...>(factory: () -> T..., dependencies: { unknown }) -> T...,
	useReducer: <S, A>(
		reducer: (state: S, action: A) -> S,
		initialState: S
	) -> (S, (action: A) -> ()),
	useState: <T>(default: T | (() -> T)) -> (T, (value: T) -> ()),
}

-- FROACTFUL_FUNCTION_TOP
function froact.configure(config: {
	Roact: any,
	Hooks: HookFunction<any, any>,
	defaultProperties: { DefaultPropertyConfig }?,
	unpureByDefault: boolean?,
})
	local hooks: HookFunction<any, Hooks> = config.Hooks
	local e = newE(
		config.Roact,
		config.Hooks,
		if config.defaultProperties then config.defaultProperties else {}
	)
	-- FROACTFUL_FUNCTION_BODY
	return {
		Roact = config.Roact,
		Hooks = hooks,
		e = e,
		c = newC(config.Roact, hooks, config.unpureByDefault),
		list = newList(config.Roact),
		template = newTemplate(config.Roact, config.unpureByDefault),
		createRef = newCreateRef(config.Roact),
		createBinding = newCreateBinding(config.Roact),
		join = newJoin(config.Roact),
		map = newMap(config.Roact),
		-- FROACTFUL_FUNCTION_EXPORTS
	}
end

return froact
