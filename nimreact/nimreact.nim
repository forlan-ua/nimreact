import jsffi, tables, dom, typetraits, strutils, sequtils
import nimreactevents
export nimreactevents, jsffi, typetraits


type ReactComponent* = ref object of RootObj
    state*: JsObject
    props*: JsObject
type ReactElement* = ref object of RootObj
type ReactTextElement* = ref object of ReactElement
    text: cstring

type Props* = ref object of RootObj
    pairs*: TableRef[string, JsObject]
type Styles* = ref object of RootObj
    pairs*: TableRef[string, string]
type Events* = ref object of RootObj
    pairs*: TableRef[EventType, int]

proc newProps*(pairs: openarray[(string, JsObject)]): Props = Props(pairs: pairs.newTable)
proc newProps*(pairs: openarray[(string, string)]): Props = pairs.map(proc(x: (string, string)): (string, JsObject) = (x[0], x[1].toJs)).newProps
proc newEvents*(pairs: openarray[(EventType, int)]): Events = Events(pairs: pairs.newTable)
proc newEvents*(items: openarray[EventType]): Events =
    var pairs = newSeq[(EventType, int)](items.len)
    for i, item in items:
        pairs[i] = (item, i)
    pairs.newEvents
proc newStyles*(pairs: openarray[(string, string)]): Styles = Styles(pairs: pairs.newTable)


proc getStateVal*(c: ReactComponent, key: string, T: typedesc): T = c.state[key.cstring].to(T)
proc getPropVal*(c: ReactComponent, key: string, T: typedesc): T = c.props[key.cstring].to(T)
proc toState*(state: openarray[(string, JsObject)]): JsObject =
    result = newJsObject()
    for value in state:
        result[value[0].cstring] = value[1]
proc toProps*(props: openarray[(string, JsObject)]): JsObject =
    result = newJsObject()
    for value in props:
        result[value[0].cstring] = value[1]


proc createElement(T: ReactComponent | cstring, attrs: JsObject, children: JsObject): ReactElement {.importc: "React.createElement".}
proc reactDOMRender(re: ReactElement, de: Element) {.importc: "ReactDOM.render".}

proc setState*(c: ReactComponent, data: JsObject) = {.emit: "`c`.setState(`data`)".}
proc setState*(c: ReactComponent, data: openarray[(string, JsObject)]) = c.setState(data.toState)
proc setState*(c: ReactComponent, cb: proc(prevState: JsObject): JsObject) = {.emit: "`c`.setState(`cb`)".}
proc setState*(c: ReactComponent, cb: proc(prevState: JsObject, props: JsObject): JsObject) = {.emit: "`c`.setState(`cb`, `props`)".}


method componentWillMount*(c: ReactComponent) {.base.} = discard
method componentDidMount*(c: ReactComponent) {.base.} = discard
method componentWillReceiveProps*(c: ReactComponent, nextProps: JsObject) {.base.} = discard
method shouldComponentUpdate*(c: ReactComponent, nextProps: JsObject, nextState: JsObject): bool {.base.} = true
method componentWillUpdate*(c: ReactComponent, nextProps: JsObject, nextState: JsObject) {.base.} = discard
method componentDidUpdate*(c: ReactComponent, prevProps: JsObject, prevState: JsObject) {.base.} = discard
method componentWillUnmount*(c: ReactComponent) {.base.} = discard
method render*(c: ReactComponent): ReactElement {.base.} = discard
method getDefaultProps*(c: ReactComponent): JsObject {.base.} = discard
method getInitialState*(c: ReactComponent): JsObject {.base.} = discard
method handleEvent(c: ReactComponent, event: ExtendedEvent) {.base.} = discard


proc internalComponentWillMount(c: ReactComponent) = c.componentWillMount()
proc internalComponentDidMount(c: ReactComponent) = c.componentDidMount()
proc internalComponentWillReceiveProps(c: ReactComponent, nextProps: JsObject) = c.componentWillReceiveProps(nextProps)
proc internalShouldComponentUpdate(c: ReactComponent, nextProps: JsObject, nextState: JsObject): bool = c.shouldComponentUpdate(nextProps, nextState)
proc internalComponentWillUpdate(c: ReactComponent, nextProps: JsObject, nextState: JsObject) = c.componentWillUpdate(nextProps, nextState)
proc internalComponentDidUpdate(c: ReactComponent, prevProps: JsObject, prevState: JsObject) = c.componentDidUpdate(prevProps, prevState)
proc internalComponentWillUnmount(c: ReactComponent) = c.componentWillUnmount()
proc internalRender(c: ReactComponent): ReactElement = c.render()
proc internalGetDefaultProps(c: ReactComponent): JsObject = c.getDefaultProps()
proc internalGetInitialState(c: ReactComponent): JsObject = c.getInitialState()


var componentsRegistry = newTable[string, ReactComponent]()

proc registerComponent(c: ReactComponent, n: string) =
    if componentsRegistry.hasKey(n):
        raise newException(ValueError, "Component with name " & n & " has been already registered") 

    var r: ReactComponent
    {.emit: """
        `r` = React.createClass({
            render: function() {
                return `internalRender`(this);
            },
            getDefaultProps: function() {
                return `internalGetDefaultProps`(this);
            },
            getInitialState: function() {
                for (var i in `c`) {
                    if (`c`.hasOwnProperty(i)) {
                        this[i] = `c`[i];
                    }
                }
                return `internalGetInitialState`(this);
            },
            componentWillMount: function() {
                `internalComponentWillMount`(this);
            },
            componentDidMount: function() {
                `internalComponentDidMount`(this);
            },
            componentWillReceiveProps: function(nextProps) {
                `internalComponentWillReceiveProps`(this, nextProps);
            },
            shouldComponentUpdate: function(nextProps, nextState) {
                return `internalShouldComponentUpdate`(this, nextProps, nextState);
            },
            componentWillUpdate: function(nextProps, nextState) {
                `internalComponentWillUpdate`(this, nextProps, nextState);
            },
            componentDidUpdate: function(prevProps, prevState) {
                `internalComponentDidUpdate`(this);
            }
        })
    """.}
    componentsRegistry[n] = r

template registerComponent*(T: typedesc) =
    registerComponent(T(), T.name)

template getComponent(T: typedesc): ReactComponent =
    componentsRegistry[T.name]


var elements: seq[seq[ReactElement]] = @[]
var uniq = 1


proc getChildren(): JsObject =
    var children = elements.pop()
    result = [].toJs()

    for i, child in children:
        if child of ReactTextElement:
            result[i] = child.ReactTextElement.text.toJs()
        else:
            result[i] = child.toJs()
    
    
proc getAttrs(c: ReactComponent, attrs: Props, events: Events, styles: Styles): JsObject =
    var iskey = false

    result = newJsObject()
    if not attrs.isNil and not attrs.pairs.isNil:
        for key, value in attrs.pairs:
            if key == "key":
                iskey = true
            result[key.cstring] = value.toJs()
    
    if not iskey:
        result["key".cstring] = ($uniq).toJs()
        uniq.inc
    
    if not styles.isNil and not styles.pairs.isNil:
        result["style".cstring] = newJsObject()
        for key, value in styles.pairs:
            result["style".cstring][key.cstring] = value.toJs()
    
    if not events.isNil and not events.pairs.isNil:
        for kind, id in events.pairs:
            result[($kind).cstring] = (proc(d: EventData) = c.handleEvent(ExtendedEvent(kind: kind, id: id, data: d))).toJs()


template create*(c: ReactComponent, r: var ReactElement, T: typedesc | cstring | string, attrs: Props, events: Events, styles: Styles, genChildren: untyped): typed =
    elements.add(newSeq[ReactElement]())

    genChildren

    when T is cstring:
        r = createElement(T, getAttrs(c, attrs, events, styles), getChildren())
    elif T is string:
        r = createElement(T.cstring, getAttrs(c, attrs, events, styles), getChildren())
    else:
        r = createElement(getComponent(T), getAttrs(c, attrs, events, styles), getChildren())

    if elements.len > 0:
        elements[elements.len - 1].add(r)

template create*(c: ReactComponent, T: typedesc | cstring | string, attrs: Props, events: Events, styles: Styles, genChildren: untyped): typed =
    var r: ReactElement
    create(c, r, T, attrs, events, styles, genChildren)


# Without Events
template create*(c: ReactComponent, r: var ReactElement, T: typedesc | cstring | string, attrs: Props, styles: Styles, genChildren: untyped): typed = create(c, r, T, attrs, nil, styles, genChildren)
template create*(c: ReactComponent, T: typedesc | cstring | string, attrs: Props, styles: Styles, genChildren: untyped): typed = create(c, T, attrs, nil, styles, genChildren)

# Without Props
template create*(c: ReactComponent, r: var ReactElement, T: typedesc | cstring | string, events: Events, styles: Styles, genChildren: untyped): typed = create(c, r, T, nil, events, styles, genChildren)
template create*(c: ReactComponent, T: typedesc | cstring | string, events: Events, styles: Styles, genChildren: untyped): typed = create(c, T, nil, events, styles, genChildren)

# Without Styles
template create*(c: ReactComponent, r: var ReactElement, T: typedesc | cstring | string, attrs: Props, events: Events, genChildren: untyped): typed = create(c, r, T, attrs, events, nil, genChildren)
template create*(c: ReactComponent, T: typedesc | cstring | string, attrs: Props, events: Events, genChildren: untyped): typed = create(c, T, attrs, events, nil, genChildren)
    
# Without Props, Events
template create*(c: ReactComponent, r: var ReactElement, T: typedesc | cstring | string, styles: Styles, genChildren: untyped): typed = create(c, r, T, nil, nil, styles, genChildren)
template create*(c: ReactComponent, T: typedesc | cstring | string, styles: Styles, genChildren: untyped): typed = create(c, T, nil, nil, styles, genChildren)

# Without Events, Styles
template create*(c: ReactComponent, r: var ReactElement, T: typedesc | cstring | string, attrs: Props, genChildren: untyped): typed = create(c, r, T, attrs, nil, nil, genChildren)
template create*(c: ReactComponent, T: typedesc | cstring | string, attrs: Props, genChildren: untyped): typed = create(c, T, attrs, nil, nil, genChildren)

# Without Props, Styles
template create*(c: ReactComponent, r: var ReactElement, T: typedesc | cstring | string, events: Events, genChildren: untyped): typed = create(c, r, T, nil, events, nil, genChildren)
template create*(c: ReactComponent, T: typedesc | cstring | string, events: Events, genChildren: untyped): typed = create(c, T, nil, events, nil, genChildren)

# Without Events, Props, Styles
template create*(c: ReactComponent, r: var ReactElement, T: typedesc | cstring | string, genChildren: untyped): typed = create(c, r, T, nil, nil, nil, genChildren)
template create*(c: ReactComponent, T: typedesc | cstring | string, genChildren: untyped): typed = create(c, T, nil, nil, nil, genChildren)
    

template createText*(c: ReactComponent, T: cstring) =
    let r = ReactTextElement(text: T)
    if elements.len > 0:
        elements[elements.len - 1].add(r)

template createText*[T](c: ReactComponent, s: T): typed =
    createText(c, ($s).cstring)


template reactDOMRender*(T: typedesc, re: Element) = reactDOMRender(createElement(getComponent(T), nil, nil), re)
template reactDOMRender*(T: cstring, re: Element) = reactDOMRender(createElement(T, nil, nil), re)
template reactDOMRender*(T: string, re: Element) = reactDOMRender(T.cstring, re)