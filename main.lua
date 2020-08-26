
tool = renoise.tool()
song = nil
push = nil

local function letsGo ()
    if not song then song = renoise.song() end
    if not tool then tool = renoise.tool() end
    require "utils"
    require "push"
    require "state"
    require "mode"
    require "midi"
    if not push then push = Push() end
    push:start()
end

local function goodnight ()
    push:stop()
    tool = nil
    song = nil
    push = nil
end

tool.app_new_document_observable:add_notifier(letsGo)
tool.app_release_document_observable:add_notifier(goodnight)

function disable ()
    if push then goodnight() else letsGo() end
end
tool:add_keybinding { name = "Global:tool:disable_PPP",  invoke = disable }

