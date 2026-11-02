"""urwid screens. Each function runs its own MainLoop and returns the choice,
or BACK; the wizard in flow.py strings them together.

Plain on purpose: one vertical list per screen (narrow tiled terminals), 16
colours with reverse-video focus (the Linux console, any alacritty theme),
ASCII only, no mouse (so selecting text to copy an error still works).
"""

from __future__ import annotations

import threading
import time
from typing import Any, Callable

import urwid

BACK = object()

PALETTE = [
    ("title", "white,bold", "dark blue"),
    ("focus", "standout", ""),
    ("error", "light red,bold", ""),
    ("warn", "yellow,bold", ""),
    ("dim", "dark gray", ""),
    ("bold", "bold", ""),
]

MIN_COLS, MIN_ROWS = 80, 24


class _Result:
    value: Any = None


def _exit(holder: _Result, value: Any) -> None:
    holder.value = value
    raise urwid.ExitMainLoop()


def _frame(title: str, body: list[urwid.Widget], footer: str) -> urwid.Widget:
    header = urwid.AttrMap(urwid.Text(f" install-host: {title}"), "title")
    listbox = urwid.ListBox(urwid.SimpleFocusListWalker(body))
    return urwid.Frame(
        urwid.Padding(listbox, left=1, right=1),
        header=header,
        footer=urwid.AttrMap(urwid.Text(footer), "dim"),
    )


def _text(markup: Any) -> urwid.Text:
    return urwid.Text(markup)


class _Button(urwid.Button):
    # urwid's "< label >" doubles up with labels like "< Back" and "Continue >"
    button_left = urwid.Text(" ")
    button_right = urwid.Text(" ")


def _button(label: str, on_click: Callable[[], None]) -> urwid.Widget:
    b = _Button(label)
    urwid.connect_signal(b, "click", lambda _b: on_click())
    return urwid.AttrMap(b, None, focus_map="focus")


def _disabled(label: str, why: str) -> urwid.Widget:
    return urwid.AttrMap(urwid.Text(f"  - {label}  ({why})"), "dim")


def _run(
    widget: urwid.Widget,
    holder: _Result,
    keys: dict[str, Callable[[], None]] | None = None,
    *,
    esc: bool = True,
) -> Any:
    def unhandled(key: str) -> None:
        if key == "esc" and esc:
            _exit(holder, BACK)
        if keys and key in keys:
            keys[key]()

    urwid.MainLoop(widget, PALETTE, handle_mouse=False, unhandled_input=unhandled).run()
    return holder.value


def _intro(intro: Any) -> list[urwid.Widget]:
    if not intro:
        return []
    return [_text(intro), urwid.Divider()]


FOOTER = " Up/Down: move   Enter: select   Esc: back"


def menu(
    title: str,
    intro: Any,
    items: list[tuple[str, Any] | tuple[str, Any, str]],
    *,
    back: bool = True,
) -> Any:
    """Pick one. An item with a third element is shown greyed out with that reason."""
    holder = _Result()
    body = _intro(intro)
    for item in items:
        if len(item) == 3:
            body.append(_disabled(item[0], item[2]))  # type: ignore[misc]
        else:
            label, value = item  # type: ignore[misc]
            body.append(_button(label, lambda v=value: _exit(holder, v)))
    if back:
        body += [urwid.Divider(), _button("< Back", lambda: _exit(holder, BACK))]
    # Without a Back item, Esc does nothing: callers only expect the items' values
    footer = FOOTER if back else " Up/Down: move   Enter: select"
    return _run(_frame(title, body, footer), holder, esc=back)


def checklist(title: str, intro: Any, items: list[tuple[str, Any, bool]]) -> Any:
    """Tick any. Returns the ticked values, or BACK."""
    holder = _Result()
    boxes = [(urwid.CheckBox(label, state=checked), value) for label, value, checked in items]
    body = _intro(intro) + [urwid.AttrMap(b, None, focus_map="focus") for b, _ in boxes]
    done = lambda: _exit(holder, [v for b, v in boxes if b.get_state()])  # noqa: E731
    body += [urwid.Divider(), _button("Continue >", done), _button("< Back", lambda: _exit(holder, BACK))]
    return _run(_frame(title, body, " Space: tick   Enter: select   Esc: back"), holder)


def text_input(title: str, intro: Any, prompt: str, default: str, validate: Callable[[str], str | None]) -> Any:
    """A line of text, re-asked until validate returns None."""
    holder = _Result()
    edit = urwid.Edit(prompt, default)
    error = _text("")

    def submit() -> None:
        value = edit.get_edit_text().strip()
        if err := validate(value):
            error.set_text(("error", err))
        else:
            _exit(holder, value)

    body = _intro(intro) + [
        urwid.AttrMap(edit, None, focus_map="focus"),
        error,
        urwid.Divider(),
        _button("Continue >", submit),
        _button("< Back", lambda: _exit(holder, BACK)),
    ]
    return _run(_frame(title, body, " Enter: continue   Esc: back"), holder, keys={"enter": submit})


def filter_menu(
    title: str,
    intro: Any,
    pinned: list[tuple[str, Any]],
    items: list[tuple[str, Any] | tuple[str, Any, str]],
    *,
    extra: list[tuple[str, Any]] = (),  # type: ignore[assignment]
) -> Any:
    """Pick one from a long list: type to filter (all words must match),
    Down to move into the results. `pinned` stays above the filter."""
    holder = _Result()
    edit = urwid.Edit("Filter: ")
    walker = urwid.SimpleFocusListWalker([])

    def entry(item: tuple) -> urwid.Widget:
        if len(item) == 3:
            return _disabled(item[0], item[2])
        return _button(item[0], lambda v=item[1]: _exit(holder, v))

    head: list[urwid.Widget] = _intro(intro)
    if pinned:
        head += [_text(("bold", "Suggested for this machine:"))] + [entry(p) for p in pinned]
    head += [entry(e) for e in extra] + [urwid.Divider(), urwid.AttrMap(edit, None, focus_map="focus")]

    def refresh(_w: Any = None, text: str | None = None) -> None:
        words = (edit.get_edit_text() if text is None else text).lower().split()
        shown = [entry(i) for i in items if all(w in i[0].lower() for w in words)]
        walker[len(head) :] = shown[:300] + [_button("< Back", lambda: _exit(holder, BACK))]

    walker.extend(head)
    refresh()
    urwid.connect_signal(edit, "change", refresh)
    walker.set_focus(len(head) - 1 if not pinned else len(_intro(intro)) + 1)
    header = urwid.AttrMap(urwid.Text(f" install-host: {title}"), "title")
    frame = urwid.Frame(
        urwid.Padding(urwid.ListBox(walker), left=1, right=1),
        header=header,
        footer=urwid.AttrMap(urwid.Text(" Type to filter   Up/Down: move   Enter: select   Esc: back"), "dim"),
    )
    return _run(frame, holder)


def message(title: str, text: Any, buttons: list[tuple[str, Any]] | None = None) -> Any:
    """Show text (long output scrolls) and wait for a button."""
    holder = _Result()
    buttons = buttons or [("OK", True)]
    lines = text.splitlines() if isinstance(text, str) else None
    body: list[urwid.Widget] = [_text(line) for line in lines] if lines is not None else [_text(text)]
    body.append(urwid.Divider())
    first = len(body)
    body += [_button(label, lambda v=value: _exit(holder, v)) for label, value in buttons]
    frame = _frame(title, body, FOOTER)
    frame.body.original_widget.body.set_focus(first)  # type: ignore[attr-defined]
    return _run(frame, holder)


def spinner(title: str, text: str, work: Callable[[], Any]) -> Any:
    """Run work() in a thread (nix eval can take a minute) and show progress.
    Returns its result, or re-raises its exception."""
    holder = _Result()
    outcome: dict[str, Any] = {}

    def target() -> None:
        try:
            outcome["value"] = work()
        except BaseException as e:  # re-raised below, in the main thread
            outcome["error"] = e

    thread = threading.Thread(target=target, daemon=True)
    status = _text("")
    started = time.monotonic()
    frames = "|/-\\"

    def tick(loop: urwid.MainLoop, _data: Any = None) -> None:
        if not thread.is_alive():
            _exit(holder, None)
        n = int((time.monotonic() - started) * 4)
        status.set_text(f"{frames[n % 4]} {text}  ({int(time.monotonic() - started)}s)")
        loop.set_alarm_in(0.25, tick)

    widget = urwid.Filler(urwid.Padding(status, left=2, right=2), valign="middle")
    frame = urwid.Frame(widget, header=urwid.AttrMap(urwid.Text(f" install-host: {title}"), "title"))
    thread.start()
    loop = urwid.MainLoop(frame, PALETTE, handle_mouse=False)
    loop.set_alarm_in(0, tick)
    loop.run()
    if "error" in outcome:
        raise outcome["error"]
    return outcome.get("value")
