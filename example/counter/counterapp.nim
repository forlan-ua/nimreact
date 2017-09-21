import dom
import ../../nimreact/nimreact


type Counter = ref object of ReactComponent

method getInitialState(c: Counter): JsObject =
    {"count": 0.toJs}.toState

method render(c: Counter): ReactElement =
    c.create(result, "div", {"className": "main"}.newProps):
        c.create("button", {EventType.onClick: 1}.newEvents):
            c.createText("dec")
        c.createText(c.getStateVal("count", int))
        c.create("button", {EventType.onClick: 2}.newEvents):
            c.createText("inc")

method handleEvent(c: Counter, event: ExtendedEvent) =
    case event.id:
        of 1:
            c.setState({"count": (c.getStateVal("count", int) - 1).toJs})
        of 2:
            c.setState({"count": (c.getStateVal("count", int) + 1).toJs})
        else:
            discard


registerComponent(Counter)


reactDOMRender(Counter, document.getElementById("maincontainer"))