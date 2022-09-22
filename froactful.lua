--!strict
local froact = {}

export type DefaultPropertyConfig = {
	class: string,
	property: string,
	value: any,
}
type ComponentConfig = { pure: boolean? }

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
				else "Component"
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

local pureHookOption, unpureHookOption = { componentType = "PureComponent" }, {}

type HookFunction<Props, Hooks> = (
	render: (Props, Hooks) -> any,
	options: any
) -> any

local function newC<Hooks>(
	roact,
	hooks: HookFunction<any, Hooks>,
	defaultComponentConfig: ComponentConfig?
)
	return function<Props>(
		config: ComponentConfig,
		body: (Props, Hooks) -> any
	): (Props, Children) -> any
		if defaultComponentConfig then
			if config.pure == nil then
				config.pure = defaultComponentConfig.pure
			end
		end
		local Component = hooks(
			body,
			if config.pure == false then unpureHookOption else pureHookOption
		)
		return function(props, children)
			return roact.createElement(Component, props, children)
		end
	end
end

	type Event<Rbx, A...> = (rbx: Rbx, A...) -> ()
type InstanceProps<Rbx> = { Archivable: boolean?, Name: string?, Parent: Instance?, onAncestryChanged: Event<Rbx, Instance, Instance>?, onAttributeChanged: Event<Rbx, string>?, onChanged: Event<Rbx, string>?, onChildAdded: Event<Rbx, Instance>?, onChildRemoved: Event<Rbx, Instance>?, onDescendantAdded: Event<Rbx, Instance>?, onDescendantRemoving: Event<Rbx, Instance>?, onDestroying: Event<Rbx>? }
type GuiObjectProps<Rbx> = GuiBase2dProps<Rbx> & { Active: boolean?, AnchorPoint: Vector2?, AutomaticSize: Enum.AutomaticSize?, BackgroundColor3: Color3?, BackgroundTransparency: number?, BorderColor3: Color3?, BorderMode: Enum.BorderMode?, BorderSizePixel: number?, ClipsDescendants: boolean?, LayoutOrder: number?, NextSelectionDown: GuiObject?, NextSelectionLeft: GuiObject?, NextSelectionRight: GuiObject?, NextSelectionUp: GuiObject?, Position: UDim2?, Rotation: number?, Selectable: boolean?, SelectionImageObject: GuiObject?, SelectionOrder: number?, Size: UDim2?, SizeConstraint: Enum.SizeConstraint?, Transparency: number?, Visible: boolean?, ZIndex: number?, onInputBegan: Event<Rbx, InputObject>?, onInputChanged: Event<Rbx, InputObject>?, onInputEnded: Event<Rbx, InputObject>?, onMouseEnter: Event<Rbx, number, number>?, onMouseLeave: Event<Rbx, number, number>?, onMouseMoved: Event<Rbx, number, number>?, onMouseWheelBackward: Event<Rbx, number, number>?, onMouseWheelForward: Event<Rbx, number, number>?, onSelectionGained: Event<Rbx>?, onSelectionLost: Event<Rbx>?, onTouchLongPress: Event<Rbx, { any }, Enum.UserInputState>?, onTouchPan: Event<Rbx, { any }, Vector2, Vector2, Enum.UserInputState>?, onTouchPinch: Event<Rbx, { any }, number, number, Enum.UserInputState>?, onTouchRotate: Event<Rbx, { any }, number, number, Enum.UserInputState>?, onTouchSwipe: Event<Rbx, Enum.SwipeDirection, number>?, onTouchTap: Event<Rbx, { any }>? }
type GuiBase2dProps<Rbx> = GuiBaseProps<Rbx> & { AutoLocalize: boolean?, RootLocalizationTable: LocalizationTable?, SelectionBehaviorDown: Enum.SelectionBehavior?, SelectionBehaviorLeft: Enum.SelectionBehavior?, SelectionBehaviorRight: Enum.SelectionBehavior?, SelectionBehaviorUp: Enum.SelectionBehavior?, SelectionGroup: boolean?, onSelectionChanged: Event<Rbx, boolean, GuiObject, GuiObject>? }
type GuiBaseProps<Rbx> = InstanceProps<Rbx>
type GuiButtonProps<Rbx> = GuiObjectProps<Rbx> & { AutoButtonColor: boolean?, Modal: boolean?, Selected: boolean?, Style: Enum.ButtonStyle?, onActivated: Event<Rbx, InputObject, number>?, onMouseButton1Click: Event<Rbx>?, onMouseButton1Down: Event<Rbx, number, number>?, onMouseButton1Up: Event<Rbx, number, number>?, onMouseButton2Click: Event<Rbx>?, onMouseButton2Down: Event<Rbx, number, number>?, onMouseButton2Up: Event<Rbx, number, number>? }
type GuiLabelProps<Rbx> = GuiObjectProps<Rbx>
type LayerCollectorProps<Rbx> = GuiBase2dProps<Rbx> & { Enabled: boolean?, ResetOnSpawn: boolean?, ZIndexBehavior: Enum.ZIndexBehavior? }
type SurfaceGuiBaseProps<Rbx> = LayerCollectorProps<Rbx> & { Active: boolean?, Adornee: Instance?, Face: Enum.NormalId? }
type BasePartProps<Rbx> = PVInstanceProps<Rbx> & { Anchored: boolean?, AssemblyAngularVelocity: Vector3?, AssemblyLinearVelocity: Vector3?, BackSurface: Enum.SurfaceType?, BottomSurface: Enum.SurfaceType?, BrickColor: BrickColor?, CFrame: CFrame?, CanCollide: boolean?, CanQuery: boolean?, CanTouch: boolean?, CastShadow: boolean?, CollisionGroup: string?, CollisionGroupId: number?, Color: Color3?, CustomPhysicalProperties: PhysicalProperties?, FrontSurface: Enum.SurfaceType?, LeftSurface: Enum.SurfaceType?, LocalTransparencyModifier: number?, Locked: boolean?, Massless: boolean?, Material: Enum.Material?, MaterialVariant: string?, Orientation: Vector3?, PivotOffset: CFrame?, Position: Vector3?, Reflectance: number?, RightSurface: Enum.SurfaceType?, RootPriority: number?, Rotation: Vector3?, Size: Vector3?, TopSurface: Enum.SurfaceType?, Transparency: number?, onTouchEnded: Event<Rbx, BasePart>?, onTouched: Event<Rbx, BasePart>? }
type PVInstanceProps<Rbx> = InstanceProps<Rbx>
type FormFactorPartProps<Rbx> = BasePartProps<Rbx>
type PartProps<Rbx> = FormFactorPartProps<Rbx> & { Shape: Enum.PartType? }
type TriangleMeshPartProps<Rbx> = BasePartProps<Rbx>
type PartOperationProps<Rbx> = TriangleMeshPartProps<Rbx> & { UsePartColor: boolean? }
type UIConstraintProps<Rbx> = UIComponentProps<Rbx>
type UIComponentProps<Rbx> = UIBaseProps<Rbx>
type UIBaseProps<Rbx> = InstanceProps<Rbx>
type UIGridStyleLayoutProps<Rbx> = UILayoutProps<Rbx> & { FillDirection: Enum.FillDirection?, HorizontalAlignment: Enum.HorizontalAlignment?, SortOrder: Enum.SortOrder?, VerticalAlignment: Enum.VerticalAlignment? }
type UILayoutProps<Rbx> = UIComponentProps<Rbx>
type CameraProps = InstanceProps<Camera> & { CFrame: CFrame?, CameraSubject: Instance?, CameraType: Enum.CameraType?, DiagonalFieldOfView: number?, FieldOfView: number?, FieldOfViewMode: Enum.FieldOfViewMode?, Focus: CFrame?, HeadLocked: boolean?, HeadScale: number?, MaxAxisFieldOfView: number?, onFirstPersonTransition: Event<Camera, boolean>?, onInterpolationFinished: Event<Camera>? }
type FrameProps = GuiObjectProps<Frame> & { Style: Enum.FrameStyle? }
type ImageButtonProps = GuiButtonProps<ImageButton> & { HoverImage: string?, Image: string?, ImageColor3: Color3?, ImageRectOffset: Vector2?, ImageRectSize: Vector2?, ImageTransparency: number?, PressedImage: string?, ResampleMode: Enum.ResamplerMode?, ScaleType: Enum.ScaleType?, SliceCenter: Rect?, SliceScale: number?, TileSize: UDim2? }
type TextButtonProps = GuiButtonProps<TextButton> & { Font: Enum.Font?, FontFace: Font?, LineHeight: number?, MaxVisibleGraphemes: number?, RichText: boolean?, Text: string?, TextColor3: Color3?, TextScaled: boolean?, TextSize: number?, TextStrokeColor3: Color3?, TextStrokeTransparency: number?, TextTransparency: number?, TextTruncate: Enum.TextTruncate?, TextWrapped: boolean?, TextXAlignment: Enum.TextXAlignment?, TextYAlignment: Enum.TextYAlignment? }
type ImageLabelProps = GuiLabelProps<ImageLabel> & { Image: string?, ImageColor3: Color3?, ImageRectOffset: Vector2?, ImageRectSize: Vector2?, ImageTransparency: number?, ResampleMode: Enum.ResamplerMode?, ScaleType: Enum.ScaleType?, SliceCenter: Rect?, SliceScale: number?, TileSize: UDim2? }
type TextLabelProps = GuiLabelProps<TextLabel> & { Font: Enum.Font?, FontFace: Font?, LineHeight: number?, MaxVisibleGraphemes: number?, RichText: boolean?, Text: string?, TextColor3: Color3?, TextScaled: boolean?, TextSize: number?, TextStrokeColor3: Color3?, TextStrokeTransparency: number?, TextTransparency: number?, TextTruncate: Enum.TextTruncate?, TextWrapped: boolean?, TextXAlignment: Enum.TextXAlignment?, TextYAlignment: Enum.TextYAlignment? }
type ScrollingFrameProps = GuiObjectProps<ScrollingFrame> & { AutomaticCanvasSize: Enum.AutomaticSize?, BottomImage: string?, CanvasPosition: Vector2?, CanvasSize: UDim2?, ElasticBehavior: Enum.ElasticBehavior?, HorizontalScrollBarInset: Enum.ScrollBarInset?, MidImage: string?, ScrollBarImageColor3: Color3?, ScrollBarImageTransparency: number?, ScrollBarThickness: number?, ScrollingDirection: Enum.ScrollingDirection?, ScrollingEnabled: boolean?, TopImage: string?, VerticalScrollBarInset: Enum.ScrollBarInset?, VerticalScrollBarPosition: Enum.VerticalScrollBarPosition? }
type TextBoxProps = GuiObjectProps<TextBox> & { ClearTextOnFocus: boolean?, CursorPosition: number?, Font: Enum.Font?, FontFace: Font?, LineHeight: number?, MaxVisibleGraphemes: number?, MultiLine: boolean?, PlaceholderColor3: Color3?, PlaceholderText: string?, RichText: boolean?, SelectionStart: number?, ShowNativeInput: boolean?, Text: string?, TextColor3: Color3?, TextEditable: boolean?, TextScaled: boolean?, TextSize: number?, TextStrokeColor3: Color3?, TextStrokeTransparency: number?, TextTransparency: number?, TextTruncate: Enum.TextTruncate?, TextWrapped: boolean?, TextXAlignment: Enum.TextXAlignment?, TextYAlignment: Enum.TextYAlignment?, onFocusLost: Event<TextBox, boolean, InputObject>?, onFocused: Event<TextBox>?, onReturnPressedFromOnScreenKeyboard: Event<TextBox>? }
type VideoFrameProps = GuiObjectProps<VideoFrame> & { Looped: boolean?, Playing: boolean?, TimePosition: number?, Video: string?, Volume: number?, onDidLoop: Event<VideoFrame, string>?, onEnded: Event<VideoFrame, string>?, onLoaded: Event<VideoFrame, string>?, onPaused: Event<VideoFrame, string>?, onPlayed: Event<VideoFrame, string>? }
type ViewportFrameProps = GuiObjectProps<ViewportFrame> & { Ambient: Color3?, CurrentCamera: Camera?, ImageColor3: Color3?, ImageTransparency: number?, LightColor: Color3?, LightDirection: Vector3? }
type BillboardGuiProps = LayerCollectorProps<BillboardGui> & { Active: boolean?, Adornee: Instance?, AlwaysOnTop: boolean?, Brightness: number?, ClipsDescendants: boolean?, DistanceLowerLimit: number?, DistanceStep: number?, DistanceUpperLimit: number?, ExtentsOffset: Vector3?, ExtentsOffsetWorldSpace: Vector3?, LightInfluence: number?, MaxDistance: number?, PlayerToHideFrom: Instance?, Size: UDim2?, SizeOffset: Vector2?, StudsOffset: Vector3?, StudsOffsetWorldSpace: Vector3? }
type ScreenGuiProps = LayerCollectorProps<ScreenGui> & { DisplayOrder: number?, IgnoreGuiInset: boolean? }
type SurfaceGuiProps = SurfaceGuiBaseProps<SurfaceGui> & { AlwaysOnTop: boolean?, Brightness: number?, CanvasSize: Vector2?, ClipsDescendants: boolean?, LightInfluence: number?, PixelsPerStud: number?, SizingMode: Enum.SurfaceGuiSizingMode?, ToolPunchThroughDistance: number?, ZOffset: number? }
type CornerWedgePartProps = BasePartProps<CornerWedgePart> & {  }
type SeatProps = PartProps<Seat> & { Disabled: boolean? }
type SpawnLocationProps = PartProps<SpawnLocation> & { AllowTeamChangeOnTouch: boolean?, Duration: number?, Enabled: boolean?, Neutral: boolean?, TeamColor: BrickColor? }
type WedgePartProps = FormFactorPartProps<WedgePart> & {  }
type MeshPartProps = TriangleMeshPartProps<MeshPart> & { TextureID: string? }
type NegateOperationProps = PartOperationProps<NegateOperation> & {  }
type UnionOperationProps = PartOperationProps<UnionOperation> & {  }
type TrussPartProps = BasePartProps<TrussPart> & { Style: Enum.Style? }
type VehicleSeatProps = BasePartProps<VehicleSeat> & { Disabled: boolean?, HeadsUpDisplay: boolean?, MaxSpeed: number?, Steer: number?, SteerFloat: number?, Throttle: number?, ThrottleFloat: number?, Torque: number?, TurnSpeed: number? }
type UIAspectRatioConstraintProps = UIConstraintProps<UIAspectRatioConstraint> & { AspectRatio: number?, AspectType: Enum.AspectType?, DominantAxis: Enum.DominantAxis? }
type UISizeConstraintProps = UIConstraintProps<UISizeConstraint> & { MaxSize: Vector2?, MinSize: Vector2? }
type UITextSizeConstraintProps = UIConstraintProps<UITextSizeConstraint> & { MaxTextSize: number?, MinTextSize: number? }
type UICornerProps = UIComponentProps<UICorner> & { CornerRadius: UDim? }
type UIGradientProps = UIComponentProps<UIGradient> & { Color: ColorSequence?, Enabled: boolean?, Offset: Vector2?, Rotation: number?, Transparency: NumberSequence? }
type UIGridLayoutProps = UIGridStyleLayoutProps<UIGridLayout> & { CellPadding: UDim2?, CellSize: UDim2?, FillDirectionMaxCells: number?, StartCorner: Enum.StartCorner? }
type UIListLayoutProps = UIGridStyleLayoutProps<UIListLayout> & { Padding: UDim? }
type UIPageLayoutProps = UIGridStyleLayoutProps<UIPageLayout> & { Animated: boolean?, Circular: boolean?, EasingDirection: Enum.EasingDirection?, EasingStyle: Enum.EasingStyle?, GamepadInputEnabled: boolean?, Padding: UDim?, ScrollWheelInputEnabled: boolean?, TouchInputEnabled: boolean?, TweenTime: number?, onPageEnter: Event<UIPageLayout, Instance>?, onPageLeave: Event<UIPageLayout, Instance>?, onStopped: Event<UIPageLayout, Instance>? }
type UITableLayoutProps = UIGridStyleLayoutProps<UITableLayout> & { FillEmptySpaceColumns: boolean?, FillEmptySpaceRows: boolean?, MajorAxis: Enum.TableMajorAxis?, Padding: UDim2? }
type UIPaddingProps = UIComponentProps<UIPadding> & { PaddingBottom: UDim?, PaddingLeft: UDim?, PaddingRight: UDim?, PaddingTop: UDim? }
type UIScaleProps = UIComponentProps<UIScale> & { Scale: number? }
type UIStrokeProps = UIComponentProps<UIStroke> & { ApplyStrokeMode: Enum.ApplyStrokeMode?, Color: Color3?, Enabled: boolean?, LineJoinMode: Enum.LineJoinMode?, Thickness: number?, Transparency: number? }
-- stylua: ignore
function froact.configure<Hooks>(config: {
	Roact: any,
	Hooks: HookFunction<any, Hooks>,
	defaultProperties: { DefaultPropertyConfig }?,
	defaultComponentConfig: ComponentConfig?,
})
	local e = newE(
		config.Roact,
		config.Hooks,
		if config.defaultProperties then config.defaultProperties else {}
	)
	local function applyEvent(props: any, tags: { any })
		for _, tag in tags do
			props[(config.Roact.Event :: any)[tag]] = props["on"..tag]
			props["on"..tag] = nil
		end
	end
	local function Camera(props: CameraProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "InterpolationFinished", "DescendantRemoving", "DescendantAdded", "Destroying", "FirstPersonTransition", "ChildAdded" })
		return e("Camera", props, children)
	end
	local function Frame(props: FrameProps, children)
		applyEvent(props, { "TouchPinch", "AttributeChanged", "InputChanged", "DescendantRemoving", "ChildAdded", "Changed", "AncestryChanged", "InputEnded", "MouseWheelForward", "SelectionChanged", "ChildRemoved", "TouchPan", "TouchSwipe", "MouseLeave", "TouchLongPress", "TouchRotate", "SelectionGained", "MouseMoved", "MouseWheelBackward", "InputBegan", "SelectionLost", "DescendantAdded", "Destroying", "TouchTap", "MouseEnter" })
		return e("Frame", props, children)
	end
	local function ImageButton(props: ImageButtonProps, children)
		applyEvent(props, { "TouchPinch", "AttributeChanged", "InputChanged", "MouseButton1Up", "DescendantRemoving", "ChildAdded", "MouseButton1Down", "Changed", "AncestryChanged", "MouseButton1Click", "InputEnded", "MouseWheelForward", "SelectionChanged", "MouseButton2Up", "ChildRemoved", "TouchPan", "TouchSwipe", "MouseButton2Click", "Activated", "TouchLongPress", "TouchRotate", "SelectionGained", "MouseMoved", "MouseButton2Down", "MouseWheelBackward", "InputBegan", "SelectionLost", "DescendantAdded", "Destroying", "MouseLeave", "TouchTap", "MouseEnter" })
		return e("ImageButton", props, children)
	end
	local function TextButton(props: TextButtonProps, children)
		applyEvent(props, { "TouchPinch", "AttributeChanged", "InputChanged", "MouseButton1Up", "DescendantRemoving", "ChildAdded", "MouseButton1Down", "Changed", "AncestryChanged", "MouseButton1Click", "InputEnded", "MouseWheelForward", "SelectionChanged", "MouseButton2Up", "ChildRemoved", "TouchPan", "TouchSwipe", "MouseButton2Click", "Activated", "TouchLongPress", "TouchRotate", "SelectionGained", "MouseMoved", "MouseButton2Down", "MouseWheelBackward", "InputBegan", "SelectionLost", "DescendantAdded", "Destroying", "MouseLeave", "TouchTap", "MouseEnter" })
		return e("TextButton", props, children)
	end
	local function ImageLabel(props: ImageLabelProps, children)
		applyEvent(props, { "TouchPinch", "AttributeChanged", "InputChanged", "DescendantRemoving", "ChildAdded", "Changed", "AncestryChanged", "InputEnded", "MouseWheelForward", "SelectionChanged", "ChildRemoved", "TouchPan", "TouchSwipe", "MouseLeave", "TouchLongPress", "TouchRotate", "SelectionGained", "MouseMoved", "MouseWheelBackward", "InputBegan", "SelectionLost", "DescendantAdded", "Destroying", "TouchTap", "MouseEnter" })
		return e("ImageLabel", props, children)
	end
	local function TextLabel(props: TextLabelProps, children)
		applyEvent(props, { "TouchPinch", "AttributeChanged", "InputChanged", "DescendantRemoving", "ChildAdded", "Changed", "AncestryChanged", "InputEnded", "MouseWheelForward", "SelectionChanged", "ChildRemoved", "TouchPan", "TouchSwipe", "MouseLeave", "TouchLongPress", "TouchRotate", "SelectionGained", "MouseMoved", "MouseWheelBackward", "InputBegan", "SelectionLost", "DescendantAdded", "Destroying", "TouchTap", "MouseEnter" })
		return e("TextLabel", props, children)
	end
	local function ScrollingFrame(props: ScrollingFrameProps, children)
		applyEvent(props, { "TouchPinch", "AttributeChanged", "InputChanged", "DescendantRemoving", "ChildAdded", "Changed", "AncestryChanged", "InputEnded", "MouseWheelForward", "SelectionChanged", "ChildRemoved", "TouchPan", "TouchSwipe", "MouseLeave", "TouchLongPress", "TouchRotate", "SelectionGained", "MouseMoved", "MouseWheelBackward", "InputBegan", "SelectionLost", "DescendantAdded", "Destroying", "TouchTap", "MouseEnter" })
		return e("ScrollingFrame", props, children)
	end
	local function TextBox(props: TextBoxProps, children)
		applyEvent(props, { "TouchPinch", "AttributeChanged", "InputChanged", "DescendantRemoving", "ChildAdded", "Changed", "AncestryChanged", "InputEnded", "MouseWheelForward", "SelectionChanged", "ReturnPressedFromOnScreenKeyboard", "FocusLost", "ChildRemoved", "TouchPan", "TouchSwipe", "MouseLeave", "TouchLongPress", "TouchRotate", "SelectionGained", "MouseMoved", "MouseWheelBackward", "Focused", "InputBegan", "SelectionLost", "DescendantAdded", "Destroying", "TouchTap", "MouseEnter" })
		return e("TextBox", props, children)
	end
	local function VideoFrame(props: VideoFrameProps, children)
		applyEvent(props, { "TouchPinch", "AttributeChanged", "InputChanged", "Paused", "DescendantRemoving", "ChildAdded", "Changed", "AncestryChanged", "Ended", "Played", "InputEnded", "MouseWheelForward", "SelectionChanged", "ChildRemoved", "DidLoop", "TouchPan", "TouchSwipe", "TouchLongPress", "TouchRotate", "SelectionGained", "Loaded", "MouseMoved", "MouseWheelBackward", "InputBegan", "SelectionLost", "DescendantAdded", "Destroying", "MouseLeave", "TouchTap", "MouseEnter" })
		return e("VideoFrame", props, children)
	end
	local function ViewportFrame(props: ViewportFrameProps, children)
		applyEvent(props, { "TouchPinch", "AttributeChanged", "InputChanged", "DescendantRemoving", "ChildAdded", "Changed", "AncestryChanged", "InputEnded", "MouseWheelForward", "SelectionChanged", "ChildRemoved", "TouchPan", "TouchSwipe", "MouseLeave", "TouchLongPress", "TouchRotate", "SelectionGained", "MouseMoved", "MouseWheelBackward", "InputBegan", "SelectionLost", "DescendantAdded", "Destroying", "TouchTap", "MouseEnter" })
		return e("ViewportFrame", props, children)
	end
	local function BillboardGui(props: BillboardGuiProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "SelectionChanged", "Destroying", "ChildAdded" })
		return e("BillboardGui", props, children)
	end
	local function ScreenGui(props: ScreenGuiProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "SelectionChanged", "Destroying", "ChildAdded" })
		return e("ScreenGui", props, children)
	end
	local function SurfaceGui(props: SurfaceGuiProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "SelectionChanged", "Destroying", "ChildAdded" })
		return e("SurfaceGui", props, children)
	end
	local function CornerWedgePart(props: CornerWedgePartProps, children)
		applyEvent(props, { "Touched", "ChildRemoved", "AttributeChanged", "AncestryChanged", "Changed", "TouchEnded", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("CornerWedgePart", props, children)
	end
	local function Part(props: PartProps<Part>, children)
		applyEvent(props, { "Touched", "ChildRemoved", "AttributeChanged", "AncestryChanged", "Changed", "TouchEnded", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("Part", props, children)
	end
	local function Seat(props: SeatProps, children)
		applyEvent(props, { "Touched", "ChildRemoved", "AttributeChanged", "AncestryChanged", "Changed", "TouchEnded", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("Seat", props, children)
	end
	local function SpawnLocation(props: SpawnLocationProps, children)
		applyEvent(props, { "Touched", "ChildRemoved", "AttributeChanged", "AncestryChanged", "Changed", "TouchEnded", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("SpawnLocation", props, children)
	end
	local function WedgePart(props: WedgePartProps, children)
		applyEvent(props, { "Touched", "ChildRemoved", "AttributeChanged", "AncestryChanged", "Changed", "TouchEnded", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("WedgePart", props, children)
	end
	local function MeshPart(props: MeshPartProps, children)
		applyEvent(props, { "Touched", "ChildRemoved", "AttributeChanged", "AncestryChanged", "Changed", "TouchEnded", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("MeshPart", props, children)
	end
	local function PartOperation(props: PartOperationProps<PartOperation>, children)
		applyEvent(props, { "Touched", "ChildRemoved", "AttributeChanged", "AncestryChanged", "Changed", "TouchEnded", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("PartOperation", props, children)
	end
	local function NegateOperation(props: NegateOperationProps, children)
		applyEvent(props, { "Touched", "ChildRemoved", "AttributeChanged", "AncestryChanged", "Changed", "TouchEnded", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("NegateOperation", props, children)
	end
	local function UnionOperation(props: UnionOperationProps, children)
		applyEvent(props, { "Touched", "ChildRemoved", "AttributeChanged", "AncestryChanged", "Changed", "TouchEnded", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("UnionOperation", props, children)
	end
	local function TrussPart(props: TrussPartProps, children)
		applyEvent(props, { "Touched", "ChildRemoved", "AttributeChanged", "AncestryChanged", "Changed", "TouchEnded", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("TrussPart", props, children)
	end
	local function VehicleSeat(props: VehicleSeatProps, children)
		applyEvent(props, { "Touched", "ChildRemoved", "AttributeChanged", "AncestryChanged", "Changed", "TouchEnded", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("VehicleSeat", props, children)
	end
	local function UIAspectRatioConstraint(props: UIAspectRatioConstraintProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("UIAspectRatioConstraint", props, children)
	end
	local function UISizeConstraint(props: UISizeConstraintProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("UISizeConstraint", props, children)
	end
	local function UITextSizeConstraint(props: UITextSizeConstraintProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("UITextSizeConstraint", props, children)
	end
	local function UICorner(props: UICornerProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("UICorner", props, children)
	end
	local function UIGradient(props: UIGradientProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("UIGradient", props, children)
	end
	local function UIGridLayout(props: UIGridLayoutProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("UIGridLayout", props, children)
	end
	local function UIListLayout(props: UIListLayoutProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("UIListLayout", props, children)
	end
	local function UIPageLayout(props: UIPageLayoutProps, children)
		applyEvent(props, { "ChildRemoved", "AttributeChanged", "AncestryChanged", "Changed", "PageEnter", "DescendantRemoving", "DescendantAdded", "ChildAdded", "PageLeave", "Destroying", "Stopped" })
		return e("UIPageLayout", props, children)
	end
	local function UITableLayout(props: UITableLayoutProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("UITableLayout", props, children)
	end
	local function UIPadding(props: UIPaddingProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("UIPadding", props, children)
	end
	local function UIScale(props: UIScaleProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("UIScale", props, children)
	end
	local function UIStroke(props: UIStrokeProps, children)
		applyEvent(props, { "ChildRemoved", "Changed", "AttributeChanged", "AncestryChanged", "DescendantRemoving", "DescendantAdded", "Destroying", "ChildAdded" })
		return e("UIStroke", props, children)
	end
	return {
		Roact = config.Roact,
		Hooks = config.Hooks,
		e = e,
		c = newC(config.Roact, config.Hooks, config.defaultComponentConfig),
		list = newList(config.Roact),
		Camera = Camera,
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
		SurfaceGui = SurfaceGui,
		CornerWedgePart = CornerWedgePart,
		Part = Part,
		Seat = Seat,
		SpawnLocation = SpawnLocation,
		WedgePart = WedgePart,
		MeshPart = MeshPart,
		PartOperation = PartOperation,
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

