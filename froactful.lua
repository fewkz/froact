-- This file is generated by generate.py and not intended to be edited.
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

-- stylua: ignore start
type Event<Rbx, A...> = (rbx: Rbx, A...) -> ()
type BindProperty<Rbx> = (rbx: Rbx) -> ()
type InstanceProps<Rbx> = { Archivable: boolean?, Name: string?, Parent: Instance?, onAncestryChanged: Event<Rbx, Instance, Instance?>?, onAttributeChanged: Event<Rbx, string>?, onChanged: Event<Rbx, string>?, onChildAdded: Event<Rbx, Instance>?, onChildRemoved: Event<Rbx, Instance>?, onDescendantAdded: Event<Rbx, Instance>?, onDescendantRemoving: Event<Rbx, Instance>?, onDestroying: Event<Rbx>? }
type GuiObjectProps<Rbx> = GuiBase2dProps<Rbx> & { Active: boolean?, AnchorPoint: Vector2?, AutomaticSize: Enum.AutomaticSize?, BackgroundColor3: Color3?, BackgroundTransparency: number?, BorderColor3: Color3?, BorderMode: Enum.BorderMode?, BorderSizePixel: number?, ClipsDescendants: boolean?, LayoutOrder: number?, NextSelectionDown: GuiObject?, NextSelectionLeft: GuiObject?, NextSelectionRight: GuiObject?, NextSelectionUp: GuiObject?, Position: UDim2?, Rotation: number?, Selectable: boolean?, SelectionImageObject: GuiObject?, SelectionOrder: number?, Size: UDim2?, SizeConstraint: Enum.SizeConstraint?, Transparency: number?, Visible: boolean?, ZIndex: number?, onInputBegan: Event<Rbx, InputObject>?, onInputChanged: Event<Rbx, InputObject>?, onInputEnded: Event<Rbx, InputObject>?, onMouseEnter: Event<Rbx, number, number>?, onMouseLeave: Event<Rbx, number, number>?, onMouseMoved: Event<Rbx, number, number>?, onMouseWheelBackward: Event<Rbx, number, number>?, onMouseWheelForward: Event<Rbx, number, number>?, onSelectionGained: Event<Rbx>?, onSelectionLost: Event<Rbx>?, onTouchLongPress: Event<Rbx, { Vector2 }, Enum.UserInputState>?, onTouchPan: Event<Rbx, { Vector2 }, Vector2, Vector2, Enum.UserInputState>?, onTouchPinch: Event<Rbx, { Vector2 }, number, number, Enum.UserInputState>?, onTouchRotate: Event<Rbx, { Vector2 }, number, number, Enum.UserInputState>?, onTouchSwipe: Event<Rbx, Enum.SwipeDirection, number>?, onTouchTap: Event<Rbx, { Vector2 }>? }
type GuiBase2dProps<Rbx> = GuiBaseProps<Rbx> & { AutoLocalize: boolean?, RootLocalizationTable: LocalizationTable?, SelectionBehaviorDown: Enum.SelectionBehavior?, SelectionBehaviorLeft: Enum.SelectionBehavior?, SelectionBehaviorRight: Enum.SelectionBehavior?, SelectionBehaviorUp: Enum.SelectionBehavior?, SelectionGroup: boolean?, bindAbsolutePosition: BindProperty<Rbx>?, bindAbsoluteRotation: BindProperty<Rbx>?, bindAbsoluteSize: BindProperty<Rbx>?, onSelectionChanged: Event<Rbx, boolean, GuiObject, GuiObject>? }
type GuiBaseProps<Rbx> = InstanceProps<Rbx>
type GuiButtonProps<Rbx> = GuiObjectProps<Rbx> & { AutoButtonColor: boolean?, Modal: boolean?, Selected: boolean?, Style: Enum.ButtonStyle?, onActivated: Event<Rbx, InputObject, number>?, onMouseButton1Click: Event<Rbx>?, onMouseButton1Down: Event<Rbx, number, number>?, onMouseButton1Up: Event<Rbx, number, number>?, onMouseButton2Click: Event<Rbx>?, onMouseButton2Down: Event<Rbx, number, number>?, onMouseButton2Up: Event<Rbx, number, number>? }
type GuiLabelProps<Rbx> = GuiObjectProps<Rbx>
type LayerCollectorProps<Rbx> = GuiBase2dProps<Rbx> & { Enabled: boolean?, ResetOnSpawn: boolean?, ZIndexBehavior: Enum.ZIndexBehavior? }
type SurfaceGuiBaseProps<Rbx> = LayerCollectorProps<Rbx> & { Active: boolean?, Adornee: Instance?, Face: Enum.NormalId? }
type BasePartProps<Rbx> = PVInstanceProps<Rbx> & { Anchored: boolean?, AssemblyAngularVelocity: Vector3?, AssemblyLinearVelocity: Vector3?, BackSurface: Enum.SurfaceType?, BottomSurface: Enum.SurfaceType?, BrickColor: BrickColor?, CFrame: CFrame?, CanCollide: boolean?, CanQuery: boolean?, CanTouch: boolean?, CastShadow: boolean?, CollisionGroup: string?, CollisionGroupId: number?, Color: Color3?, CustomPhysicalProperties: PhysicalProperties?, FrontSurface: Enum.SurfaceType?, LeftSurface: Enum.SurfaceType?, LocalTransparencyModifier: number?, Locked: boolean?, Massless: boolean?, Material: Enum.Material?, MaterialVariant: string?, Orientation: Vector3?, PivotOffset: CFrame?, Position: Vector3?, Reflectance: number?, RightSurface: Enum.SurfaceType?, RootPriority: number?, Rotation: Vector3?, Size: Vector3?, TopSurface: Enum.SurfaceType?, Transparency: number?, onTouchEnded: Event<Rbx, BasePart>?, onTouched: Event<Rbx, BasePart>? }
type PVInstanceProps<Rbx> = InstanceProps<Rbx> & { Origin: CFrame? }
type FormFactorPartProps<Rbx> = BasePartProps<Rbx>
type PartProps<Rbx> = FormFactorPartProps<Rbx> & { Shape: Enum.PartType? }
type TriangleMeshPartProps<Rbx> = BasePartProps<Rbx>
type PartOperationProps<Rbx> = TriangleMeshPartProps<Rbx> & { UsePartColor: boolean? }
type UIConstraintProps<Rbx> = UIComponentProps<Rbx>
type UIComponentProps<Rbx> = UIBaseProps<Rbx>
type UIBaseProps<Rbx> = InstanceProps<Rbx>
type UIGridStyleLayoutProps<Rbx> = UILayoutProps<Rbx> & { FillDirection: Enum.FillDirection?, HorizontalAlignment: Enum.HorizontalAlignment?, SortOrder: Enum.SortOrder?, VerticalAlignment: Enum.VerticalAlignment?, bindAbsoluteContentSize: BindProperty<Rbx>? }
type UILayoutProps<Rbx> = UIComponentProps<Rbx>
type CameraProps = InstanceProps<Camera> & { CFrame: CFrame?, CameraSubject: Humanoid | BasePart | nil?, CameraType: Enum.CameraType?, DiagonalFieldOfView: number?, FieldOfView: number?, FieldOfViewMode: Enum.FieldOfViewMode?, Focus: CFrame?, HeadLocked: boolean?, HeadScale: number?, MaxAxisFieldOfView: number?, onFirstPersonTransition: Event<Camera, boolean>?, onInterpolationFinished: Event<Camera>? }
type CanvasGroupProps = GuiObjectProps<CanvasGroup> & { GroupColor3: Color3?, GroupTransparency: number? }
type FrameProps = GuiObjectProps<Frame> & { Style: Enum.FrameStyle? }
type ImageButtonProps = GuiButtonProps<ImageButton> & { HoverImage: string?, Image: string?, ImageColor3: Color3?, ImageRectOffset: Vector2?, ImageRectSize: Vector2?, ImageTransparency: number?, PressedImage: string?, ResampleMode: Enum.ResamplerMode?, ScaleType: Enum.ScaleType?, SliceCenter: Rect?, SliceScale: number?, TileSize: UDim2? }
type TextButtonProps = GuiButtonProps<TextButton> & { Font: Enum.Font?, FontFace: Font?, LineHeight: number?, MaxVisibleGraphemes: number?, RichText: boolean?, Text: string?, TextColor3: Color3?, TextScaled: boolean?, TextSize: number?, TextStrokeColor3: Color3?, TextStrokeTransparency: number?, TextTransparency: number?, TextTruncate: Enum.TextTruncate?, TextWrapped: boolean?, TextXAlignment: Enum.TextXAlignment?, TextYAlignment: Enum.TextYAlignment?, bindTextBounds: BindProperty<TextButton>? }
type ImageLabelProps = GuiLabelProps<ImageLabel> & { Image: string?, ImageColor3: Color3?, ImageRectOffset: Vector2?, ImageRectSize: Vector2?, ImageTransparency: number?, ResampleMode: Enum.ResamplerMode?, ScaleType: Enum.ScaleType?, SliceCenter: Rect?, SliceScale: number?, TileSize: UDim2? }
type TextLabelProps = GuiLabelProps<TextLabel> & { Font: Enum.Font?, FontFace: Font?, LineHeight: number?, MaxVisibleGraphemes: number?, RichText: boolean?, Text: string?, TextColor3: Color3?, TextScaled: boolean?, TextSize: number?, TextStrokeColor3: Color3?, TextStrokeTransparency: number?, TextTransparency: number?, TextTruncate: Enum.TextTruncate?, TextWrapped: boolean?, TextXAlignment: Enum.TextXAlignment?, TextYAlignment: Enum.TextYAlignment?, bindTextBounds: BindProperty<TextLabel>? }
type ScrollingFrameProps = GuiObjectProps<ScrollingFrame> & { AutomaticCanvasSize: Enum.AutomaticSize?, BottomImage: string?, CanvasPosition: Vector2?, CanvasSize: UDim2?, ElasticBehavior: Enum.ElasticBehavior?, HorizontalScrollBarInset: Enum.ScrollBarInset?, MidImage: string?, ScrollBarImageColor3: Color3?, ScrollBarImageTransparency: number?, ScrollBarThickness: number?, ScrollingDirection: Enum.ScrollingDirection?, ScrollingEnabled: boolean?, TopImage: string?, VerticalScrollBarInset: Enum.ScrollBarInset?, VerticalScrollBarPosition: Enum.VerticalScrollBarPosition?, bindAbsoluteCanvasSize: BindProperty<ScrollingFrame>?, bindAbsoluteWindowSize: BindProperty<ScrollingFrame>? }
type TextBoxProps = GuiObjectProps<TextBox> & { ClearTextOnFocus: boolean?, CursorPosition: number?, Font: Enum.Font?, FontFace: Font?, LineHeight: number?, MaxVisibleGraphemes: number?, MultiLine: boolean?, PlaceholderColor3: Color3?, PlaceholderText: string?, RichText: boolean?, SelectionStart: number?, ShowNativeInput: boolean?, Text: string?, TextColor3: Color3?, TextEditable: boolean?, TextScaled: boolean?, TextSize: number?, TextStrokeColor3: Color3?, TextStrokeTransparency: number?, TextTransparency: number?, TextTruncate: Enum.TextTruncate?, TextWrapped: boolean?, TextXAlignment: Enum.TextXAlignment?, TextYAlignment: Enum.TextYAlignment?, bindText: BindProperty<TextBox>?, bindTextBounds: BindProperty<TextBox>?, onFocusLost: Event<TextBox, boolean, InputObject>?, onFocused: Event<TextBox>?, onReturnPressedFromOnScreenKeyboard: Event<TextBox>? }
type VideoFrameProps = GuiObjectProps<VideoFrame> & { Looped: boolean?, Playing: boolean?, TimePosition: number?, Video: string?, Volume: number?, onDidLoop: Event<VideoFrame, string>?, onEnded: Event<VideoFrame, string>?, onLoaded: Event<VideoFrame, string>?, onPaused: Event<VideoFrame, string>?, onPlayed: Event<VideoFrame, string>? }
type ViewportFrameProps = GuiObjectProps<ViewportFrame> & { Ambient: Color3?, CurrentCamera: Camera?, ImageColor3: Color3?, ImageTransparency: number?, LightColor: Color3?, LightDirection: Vector3? }
type BillboardGuiProps = LayerCollectorProps<BillboardGui> & { Active: boolean?, Adornee: Instance?, AlwaysOnTop: boolean?, Brightness: number?, ClipsDescendants: boolean?, DistanceLowerLimit: number?, DistanceStep: number?, DistanceUpperLimit: number?, ExtentsOffset: Vector3?, ExtentsOffsetWorldSpace: Vector3?, LightInfluence: number?, MaxDistance: number?, PlayerToHideFrom: Instance?, Size: UDim2?, SizeOffset: Vector2?, StudsOffset: Vector3?, StudsOffsetWorldSpace: Vector3? }
type ScreenGuiProps = LayerCollectorProps<ScreenGui> & { ClipToDeviceSafeArea: boolean?, DisplayOrder: number?, IgnoreGuiInset: boolean?, SafeAreaCompatibility: Enum.SafeAreaCompatibility?, ScreenInsets: Enum.ScreenInsets? }
type AdGuiProps = SurfaceGuiBaseProps<AdGui> & { AdShape: Enum.AdShape? }
type SurfaceGuiProps = SurfaceGuiBaseProps<SurfaceGui> & { AlwaysOnTop: boolean?, Brightness: number?, CanvasSize: Vector2?, ClipsDescendants: boolean?, LightInfluence: number?, PixelsPerStud: number?, SizingMode: Enum.SurfaceGuiSizingMode?, ToolPunchThroughDistance: number?, ZOffset: number? }
type CornerWedgePartProps = BasePartProps<CornerWedgePart> & {  }
type SeatProps = PartProps<Seat> & { Disabled: boolean? }
type SpawnLocationProps = PartProps<SpawnLocation> & { AllowTeamChangeOnTouch: boolean?, Duration: number?, Enabled: boolean?, Neutral: boolean?, TeamColor: BrickColor? }
type WedgePartProps = FormFactorPartProps<WedgePart> & {  }
type MeshPartProps = TriangleMeshPartProps<MeshPart> & { TextureID: string? }
type IntersectOperationProps = PartOperationProps<IntersectOperation> & {  }
type NegateOperationProps = PartOperationProps<NegateOperation> & {  }
type UnionOperationProps = PartOperationProps<UnionOperation> & {  }
type TrussPartProps = BasePartProps<TrussPart> & { Style: Enum.Style? }
type VehicleSeatProps = BasePartProps<VehicleSeat> & { Disabled: boolean?, HeadsUpDisplay: boolean?, MaxSpeed: number?, Steer: number?, SteerFloat: number?, Throttle: number?, ThrottleFloat: number?, Torque: number?, TurnSpeed: number? }
type UIAspectRatioConstraintProps = UIConstraintProps<UIAspectRatioConstraint> & { AspectRatio: number?, AspectType: Enum.AspectType?, DominantAxis: Enum.DominantAxis? }
type UISizeConstraintProps = UIConstraintProps<UISizeConstraint> & { MaxSize: Vector2?, MinSize: Vector2? }
type UITextSizeConstraintProps = UIConstraintProps<UITextSizeConstraint> & { MaxTextSize: number?, MinTextSize: number? }
type UICornerProps = UIComponentProps<UICorner> & { CornerRadius: UDim? }
type UIGradientProps = UIComponentProps<UIGradient> & { Color: ColorSequence?, Enabled: boolean?, Offset: Vector2?, Rotation: number?, Transparency: NumberSequence? }
type UIGridLayoutProps = UIGridStyleLayoutProps<UIGridLayout> & { CellPadding: UDim2?, CellSize: UDim2?, FillDirectionMaxCells: number?, StartCorner: Enum.StartCorner?, bindAbsoluteCellCount: BindProperty<UIGridLayout>?, bindAbsoluteCellSize: BindProperty<UIGridLayout>? }
type UIListLayoutProps = UIGridStyleLayoutProps<UIListLayout> & { Padding: UDim? }
type UIPageLayoutProps = UIGridStyleLayoutProps<UIPageLayout> & { Animated: boolean?, Circular: boolean?, EasingDirection: Enum.EasingDirection?, EasingStyle: Enum.EasingStyle?, GamepadInputEnabled: boolean?, Padding: UDim?, ScrollWheelInputEnabled: boolean?, TouchInputEnabled: boolean?, TweenTime: number?, onPageEnter: Event<UIPageLayout, Instance>?, onPageLeave: Event<UIPageLayout, Instance>?, onStopped: Event<UIPageLayout, Instance>? }
type UITableLayoutProps = UIGridStyleLayoutProps<UITableLayout> & { FillEmptySpaceColumns: boolean?, FillEmptySpaceRows: boolean?, MajorAxis: Enum.TableMajorAxis?, Padding: UDim2? }
type UIPaddingProps = UIComponentProps<UIPadding> & { PaddingBottom: UDim?, PaddingLeft: UDim?, PaddingRight: UDim?, PaddingTop: UDim? }
type UIScaleProps = UIComponentProps<UIScale> & { Scale: number? }
type UIStrokeProps = UIComponentProps<UIStroke> & { ApplyStrokeMode: Enum.ApplyStrokeMode?, Color: Color3?, Enabled: boolean?, LineJoinMode: Enum.LineJoinMode?, Thickness: number?, Transparency: number? }
-- stylua: ignore end
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
	local function apply(props: any)
		local toRemove = {}
		local toAdd = {}
		for name, value in props do
			if typeof(name) == "string" then
				if name:sub(1, 2) == "on" then
					toAdd[(config.Roact.Event :: any)[name:sub(3)]] = value
					toRemove[name] = true
				elseif name:sub(1, 4) == "bind" then
					toAdd[(config.Roact.Change :: any)[name:sub(5)]] = value
					toRemove[name] = true
				end
			end
		end
		for name, value in toAdd do
			props[name] = value
		end
		for name, _ in toRemove do
			props[name] = nil
		end
		if props.ref then
			props[config.Roact.Ref] = props.ref
			props.ref = nil
		end
	end
	-- stylua: ignore start
	local function Camera(props: CameraProps, children)
		apply(props)
		return e("Camera", props, children)
	end
	local function CanvasGroup(props: CanvasGroupProps, children)
		apply(props)
		return e("CanvasGroup", props, children)
	end
	local function Frame(props: FrameProps, children)
		apply(props)
		return e("Frame", props, children)
	end
	local function ImageButton(props: ImageButtonProps, children)
		apply(props)
		return e("ImageButton", props, children)
	end
	local function TextButton(props: TextButtonProps, children)
		apply(props)
		return e("TextButton", props, children)
	end
	local function ImageLabel(props: ImageLabelProps, children)
		apply(props)
		return e("ImageLabel", props, children)
	end
	local function TextLabel(props: TextLabelProps, children)
		apply(props)
		return e("TextLabel", props, children)
	end
	local function ScrollingFrame(props: ScrollingFrameProps, children)
		apply(props)
		return e("ScrollingFrame", props, children)
	end
	local function TextBox(props: TextBoxProps, children)
		apply(props)
		return e("TextBox", props, children)
	end
	local function VideoFrame(props: VideoFrameProps, children)
		apply(props)
		return e("VideoFrame", props, children)
	end
	local function ViewportFrame(props: ViewportFrameProps, children)
		apply(props)
		return e("ViewportFrame", props, children)
	end
	local function BillboardGui(props: BillboardGuiProps, children)
		apply(props)
		return e("BillboardGui", props, children)
	end
	local function ScreenGui(props: ScreenGuiProps, children)
		apply(props)
		return e("ScreenGui", props, children)
	end
	local function AdGui(props: AdGuiProps, children)
		apply(props)
		return e("AdGui", props, children)
	end
	local function SurfaceGui(props: SurfaceGuiProps, children)
		apply(props)
		return e("SurfaceGui", props, children)
	end
	local function CornerWedgePart(props: CornerWedgePartProps, children)
		apply(props)
		return e("CornerWedgePart", props, children)
	end
	local function Part(props: PartProps<Part>, children)
		apply(props)
		return e("Part", props, children)
	end
	local function Seat(props: SeatProps, children)
		apply(props)
		return e("Seat", props, children)
	end
	local function SpawnLocation(props: SpawnLocationProps, children)
		apply(props)
		return e("SpawnLocation", props, children)
	end
	local function WedgePart(props: WedgePartProps, children)
		apply(props)
		return e("WedgePart", props, children)
	end
	local function MeshPart(props: MeshPartProps, children)
		apply(props)
		return e("MeshPart", props, children)
	end
	local function PartOperation(props: PartOperationProps<PartOperation>, children)
		apply(props)
		return e("PartOperation", props, children)
	end
	local function IntersectOperation(props: IntersectOperationProps, children)
		apply(props)
		return e("IntersectOperation", props, children)
	end
	local function NegateOperation(props: NegateOperationProps, children)
		apply(props)
		return e("NegateOperation", props, children)
	end
	local function UnionOperation(props: UnionOperationProps, children)
		apply(props)
		return e("UnionOperation", props, children)
	end
	local function TrussPart(props: TrussPartProps, children)
		apply(props)
		return e("TrussPart", props, children)
	end
	local function VehicleSeat(props: VehicleSeatProps, children)
		apply(props)
		return e("VehicleSeat", props, children)
	end
	local function UIAspectRatioConstraint(props: UIAspectRatioConstraintProps, children)
		apply(props)
		return e("UIAspectRatioConstraint", props, children)
	end
	local function UISizeConstraint(props: UISizeConstraintProps, children)
		apply(props)
		return e("UISizeConstraint", props, children)
	end
	local function UITextSizeConstraint(props: UITextSizeConstraintProps, children)
		apply(props)
		return e("UITextSizeConstraint", props, children)
	end
	local function UICorner(props: UICornerProps, children)
		apply(props)
		return e("UICorner", props, children)
	end
	local function UIGradient(props: UIGradientProps, children)
		apply(props)
		return e("UIGradient", props, children)
	end
	local function UIGridLayout(props: UIGridLayoutProps, children)
		apply(props)
		return e("UIGridLayout", props, children)
	end
	local function UIListLayout(props: UIListLayoutProps, children)
		apply(props)
		return e("UIListLayout", props, children)
	end
	local function UIPageLayout(props: UIPageLayoutProps, children)
		apply(props)
		return e("UIPageLayout", props, children)
	end
	local function UITableLayout(props: UITableLayoutProps, children)
		apply(props)
		return e("UITableLayout", props, children)
	end
	local function UIPadding(props: UIPaddingProps, children)
		apply(props)
		return e("UIPadding", props, children)
	end
	local function UIScale(props: UIScaleProps, children)
		apply(props)
		return e("UIScale", props, children)
	end
	local function UIStroke(props: UIStrokeProps, children)
		apply(props)
		return e("UIStroke", props, children)
	end
	-- stylua: ignore end
	return {
		Roact = config.Roact,
		Hooks = config.Hooks,
		e = e,
		c = newC(config.Roact, config.Hooks, config.unpureByDefault),
		list = newList(config.Roact),
		template = newTemplate(config.Roact, config.unpureByDefault),
		Camera = Camera,
		CanvasGroup = CanvasGroup,
		Frame = Frame,
		ImageButton = ImageButton,
		TextButton = TextButton,
		ImageLabel = ImageLabel,
		TextLabel = TextLabel,
		ScrollingFrame = ScrollingFrame,
		TextBox = TextBox,
		VideoFrame = VideoFrame,
		ViewportFrame = ViewportFrame,
		BillboardGui = BillboardGui,
		ScreenGui = ScreenGui,
		AdGui = AdGui,
		SurfaceGui = SurfaceGui,
		CornerWedgePart = CornerWedgePart,
		Part = Part,
		Seat = Seat,
		SpawnLocation = SpawnLocation,
		WedgePart = WedgePart,
		MeshPart = MeshPart,
		PartOperation = PartOperation,
		IntersectOperation = IntersectOperation,
		NegateOperation = NegateOperation,
		UnionOperation = UnionOperation,
		TrussPart = TrussPart,
		VehicleSeat = VehicleSeat,
		UIAspectRatioConstraint = UIAspectRatioConstraint,
		UISizeConstraint = UISizeConstraint,
		UITextSizeConstraint = UITextSizeConstraint,
		UICorner = UICorner,
		UIGradient = UIGradient,
		UIGridLayout = UIGridLayout,
		UIListLayout = UIListLayout,
		UIPageLayout = UIPageLayout,
		UITableLayout = UITableLayout,
		UIPadding = UIPadding,
		UIScale = UIScale,
		UIStroke = UIStroke,
	}
end

return froact

