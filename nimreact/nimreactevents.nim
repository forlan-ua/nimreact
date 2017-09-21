import strutils, dom, jsffi


type
    EventType* {.pure.} = enum
        # Clipboard Events
        onCopy = 0, onCut, onPaste,

        # Composition Events
        onCompositionEnd = 50, onCompositionStart, onCompositionUpdate,

        # Keyboard Events
        onKeyDown = 100, onKeyPress, onKeyUp,

        # Focus Events
        onFocus = 150, onBlur,

        # Form Events
        onChange = 200, onInput, onInvalid, onSubmit,

        # Mouse Events
        onClick = 250, onContextMenu, onDoubleClick, onDrag, onDragEnd, onDragEnter, onDragExit,
        onDragLeave, onDragOver, onDragStart, onDrop, onMouseDown, onMouseEnter, onMouseLeave,
        onMouseMove, onMouseOut, onMouseOver, onMouseUp,

        # Selection Events
        onSelect = 300,

        # Touch Events
        onTouchCancel = 350, onTouchEnd, onTouchMove, onTouchStart,

        # UI Events
        onScroll = 400,

        # Wheel Events
        onWheel = 450,

        # Media Events
        onAbort = 500, onCanPlay, onCanPlayThrough, onDurationChange, onEmptied, onEncrypted,
        onEnded, onError, onLoadedData, onLoadedMetadata, onLoadStart, onPause, onPlay,
        onPlaying, onProgress, onRateChange, onSeeked, onSeeking, onStalled, onSuspend, 
        onTimeUpdate, onVolumeChange, onWaiting, onLoad,

        # Animation Events
        onAnimationStart = 550, onAnimationEnd, onAnimationIteration,

        # Transition Events
        onTransitionEnd = 600


type EventData* = ref object of RootObj
    bubbles: bool
    cancelable: bool
    currentTarget: Element
    defaultPrevented: bool
    eventPhase: int
    isTrusted: bool
    nativeEvent: Event
    target: Element
    timeStamp: int
    `type`: cstring

template bubbles*(e: EventData): bool = e.bubbles
template cancelable*(e: EventData): bool = e.cancelable
template currentTarget*(echo: EventData): Element = e.currentTarget
template defaultPrevented*(e: EventData): bool = e.defaultPrevented
template eventPhase*(e: EventData): int = e.eventPhase
template isTrusted*(e: EventData): bool = e.isTrusted
template nativeEvent*(e: EventData): Event = e.nativeEvent
template target*(e: EventData): Element = e.target
template timeStamp*(e: EventData): int = e.timeStamp
template etype*(e: EventData): string = $e.`type`

type ExtendedEvent* = object
    id*: int
    kind*: EventType
    data*: EventData

proc preventDefault*(e: EventData) = {.emit: "`e`.preventDefault()".}
proc isDefaultPrevented*(e: EventData): bool = {.emit: "`e`.isDefaultPrevented()".}
proc stopPropagation*(e: EventData) = {.emit: "`e`.stopPropagation()".}
proc isPropagationStopped*(e: EventData): bool = {.emit: "`e`.isPropagationStopped()".}


type ClipboardEventData* = ref object of EventData
    clipboardData: JsObject

template clipboardData*(e: ClipboardEventData): JsObject = e.clipboardData

type CompositionEventData* = ref object of EventData
    data: cstring

template data*(e: CompositionEventData): string = $e.data

type KeyboardEventData* = ref object of EventData
    altKey: bool
    charCode: int
    ctrlKey: bool
    key: cstring
    keyCode: int
    locale: cstring
    location: float
    metaKey: bool
    repeat: bool
    shiftKey: bool
    which: int

template altKey*(e: KeyboardEventData): bool = e.altKey
template charCode*(e: KeyboardEventData): int = e.charCode
template ctrlKey*(e: KeyboardEventData): bool = e.ctrlKey
template key*(e: KeyboardEventData): string = $e.key
template keyCode*(e: KeyboardEventData): int = e.keyCode
template locale*(e: KeyboardEventData): string = $e.locale
template location*(e: KeyboardEventData): float = e.location
template metaKey*(e: KeyboardEventData): bool = e.metaKey
template repeat*(e: KeyboardEventData): bool = e.repeat
template shiftKey*(e: KeyboardEventData): bool = e.shiftKey
template which*(e: KeyboardEventData): int = e.which

proc getModifierState*(e: KeyboardEventData, key: int): bool = {.emit: "`e`.getModifierState()".}

type FocusEventData* = ref object of EventData
    relatedTarget: Element

template relatedTarget*(e: FocusEventData): JsObject = e.relatedTarget

type FormEventData* = ref object of EventData

type MouseEventData* = ref object of EventData
    altKey: bool
    buttons: int
    button: int
    clientX: int
    clientY: int
    ctrlKey: bool
    metaKey: bool
    pageX: int
    pageY: int
    relatedTarget: Element
    screenX: int
    screenY: int
    shiftKey: bool

template altKey*(e: MouseEventData): bool = e.altKey
template buttons*(e: MouseEventData): int = e.buttons
template button*(e: MouseEventData): int = e.button
template clientX*(e: MouseEventData): int = e.clientX
template clientY*(e: MouseEventData): int = e.clientY
template ctrlKey*(e: MouseEventData): bool = e.ctrlKey
template metaKey*(e: MouseEventData): bool = e.metaKey
template pageX*(e: MouseEventData): int = e.pageX
template pageY*(e: MouseEventData): int = e.pageY
template relatedTarget*(e: MouseEventData): Element = e.relatedTarget
template screenX*(e: MouseEventData): int = e.screenX
template screenY*(e: MouseEventData): int = e.screenY
template shiftKey*(e: MouseEventData): bool = e.shiftKey

proc getModifierState*(e: MouseEventData, key: int): bool = {.emit: "`e`.getModifierState()".}

type SelectionEventData* = ref object of EventData

type TouchEventData* = ref object of EventData
    altKey: bool
    changedTouches: TouchList
    ctrlKey: bool
    metaKey: bool
    shiftKey: bool
    targetTouches: TouchList
    touches: TouchList

template altKey*(e: TouchEventData): bool = e.altKey
template changedTouches*(e: TouchEventData): TouchList = e.changedTouches
template ctrlKey*(e: TouchEventData): bool = e.ctrlKey
template metaKey*(e: TouchEventData): bool = e.metaKey
template shiftKey*(e: TouchEventData): bool = e.shiftKey
template targetTouches*(e: TouchEventData): TouchList = e.targetTouches
template touches*(e: TouchEventData): TouchList = e.touches

proc getModifierState*(e: TouchEventData, key: int): bool = {.emit: "`e`.getModifierState()".}

type UIEventData* = ref object of EventData
    detail: int
    view: JsObject

template detail*(e: UIEventData): int = e.detail
template view*(e: UIEventData): JsObject = e.view

type WheelEventData* = ref object of EventData
    deltaMode: int
    deltaX: int
    deltaY: int
    deltaZ: int

template deltaMode*(e: WheelEventData): int = e.deltaMode
template deltaX*(e: WheelEventData): int = e.deltaX
template deltaY*(e: WheelEventData): int = e.deltaY
template deltaZ*(e: WheelEventData): int = e.deltaZ

type MediaEventData* = ref object of EventData

type AnimationEventData* = ref object of EventData
    animationName: cstring
    pseudoElement: cstring
    elapsedTime: float

template animationName*(e: AnimationEventData): string = $e.animationName
template pseudoElement*(e: AnimationEventData): string = $e.pseudoElement
template elapsedTime*(e: AnimationEventData): float = e.elapsedTime

type TransitionEventData* = ref object of EventData
    propertyName: cstring
    pseudoElement: cstring
    elapsedTime: float

template propertyName*(e: TransitionEventData): string = $e.propertyName
template pseudoElement*(e: TransitionEventData): string = $e.pseudoElement
template elapsedTime*(e: TransitionEventData): float = e.elapsedTime