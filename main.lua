local _DEBUG = true
_OSC = false

tool = renoise.tool()
song = nil
push = nil
config = require "config"

local function letsGo ()
    if not song then song = renoise.song() end
    if not tool then tool = renoise.tool() end
    require "utils"
    require "push"
    require "state"
    require "mode"
    require "midi"
    if not push then push = Push() end
    config.getPush(push)
    if config.prefs.autostart.value then
        local scanner = "sysex"
        if os.platform() == "WINDOWS" then
            scanner = "name"
        end
        push:start(scanner)
    end
end

local function goodnight ()
    if push then push:stop() end
    tool = nil
    song = nil
    push = nil
end

tool.app_new_document_observable:add_notifier(letsGo)
tool.app_release_document_observable:add_notifier(goodnight)

if _DEBUG then
    function disable ()
        if push then goodnight() else letsGo() end
    end
    tool:add_keybinding { name = "Global:tool:disable_PPP",  invoke = disable }
end

