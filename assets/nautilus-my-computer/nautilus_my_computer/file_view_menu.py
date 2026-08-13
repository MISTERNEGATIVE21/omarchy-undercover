"""Native file-view context menu target: injects "Add/Remove from Bookmarks"
and "Pin/Unpin from My Computer" directly into a folder's native right-click
menu (the NautilusFilesView "selection-menu" popover).

Nautilus.MenuProvider.get_file_items() is deliberately NOT used to return
items here: every extension's get_file_items() results land in one shared,
separator-less GMenu section (selection-extensions-section), so our two lines
could end up jammed against another extension's with no visual break.
Instead this module injects directly into the native selection popover,
exactly like the bookmarks.py / preferred_folders.py native-menu injections,
which gives full control over placement and a real separator.

`ext` (the MyComputerExtension instance) is only used here to read
`ext._gsettings` and `ext._last_selected_folder_uri`, the latter populated by
MyComputerExtension.get_file_items() -- the official, reliable feed of
"what's currently selected" that Nautilus calls right before popping up the
menu, so the cache is guaranteed fresh at right-click time.
"""

import gi

gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")
gi.require_version("Gtk", "4.0")
from gi.repository import Gio, GLib, Gtk

from nautilus_my_computer import bookmarks, preferred_folders
from nautilus_my_computer.common import (
    _all_widgets,
    _log,
    _menu_section_index_with_action,
    _menu_section_with_action,
)
from nautilus_my_computer.context_menu import my_computer_additions_section


def attach_file_view_context_menu(ext, win) -> None:
    """Capture-phase gesture on the whole window: right-clicks happen in
    many places (sidebar rows, pathbar, our own panel cards), all handled
    by their own dedicated injections elsewhere, so we cheaply disambiguate
    on idle by checking the resulting popover's menu model rather than
    trying to scope the gesture to the per-tab NautilusFilesView (which is
    recreated per slot and would need its own discovery/watch machinery)."""
    gesture = Gtk.GestureClick()
    gesture.set_button(3)
    gesture.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
    gesture.connect("pressed", lambda *_a: GLib.idle_add(inject_file_view_menu_items, ext, win))
    win.add_controller(gesture)


def inject_file_view_menu_items(ext, win) -> bool:
    """Add/Remove from Bookmarks and Pin/Unpin from My Computer directly on
    a folder's native right-click menu (selection-menu), instead of
    leaving them buried behind the pathbar's "..." menu. Mirrors
    preferred_folders._inject_preferred_menu_item: undo the previous injection before
    re-evaluating, since the underlying GMenu model can be reused
    unchanged across several right-clicks (Nautilus only rebuilds it when
    the selection actually changes), not just when the popover widget is
    recreated."""
    uri = ext._last_selected_folder_uri
    if uri is None:
        return GLib.SOURCE_REMOVE

    model = None
    for w in _all_widgets(win):
        if isinstance(w, Gtk.PopoverMenu) and w.get_mapped():
            candidate = w.get_menu_model()
            if isinstance(candidate, Gio.Menu) and _menu_section_with_action(
                candidate, "view.rename"
            ):
                model = candidate
                break
    if model is None:
        return GLib.SOURCE_REMOVE

    prev_section = getattr(model, "_mc_fileview_section", None)
    if prev_section is not None:
        for i in range(model.get_n_items()):
            if model.get_item_link(i, Gio.MENU_LINK_SECTION) is prev_section:
                model.remove(i)
                break

    anchor = _menu_section_index_with_action(model, "view.properties")
    insert_at = anchor if anchor is not None else model.get_n_items()

    bookmarked = bookmarks.is_bookmarked(uri)
    preferred = preferred_folders.is_preferred(ext._gsettings, uri)
    built = my_computer_additions_section(
        bookmarked=bookmarked,
        preferred=preferred,
        toggle_bookmark_action=lambda: bookmarks.toggle_bookmark(uri),
        toggle_preferred_action=lambda: preferred_folders.toggle_preferred(ext._gsettings, uri),
    ).build("mcfileview")
    model.insert_section(insert_at, None, built.model)
    model._mc_fileview_section = built.model

    for w in _all_widgets(win):
        if isinstance(w, Gtk.PopoverMenu) and w.get_menu_model() is model:
            w.insert_action_group("mcfileview", built.action_group)
            break

    _log(f"inject_file_view_menu_items: injected for {uri}")
    return GLib.SOURCE_REMOVE
