-- _AUTO_RELOAD_DEBUG = true

tool = renoise.tool()
song = nil
push = nil
state = nil
modes = nil
midi = nil

local function letsGo ()
    if not song then song = renoise.song() end
    if not tool then tool = renoise.tool() end
    require "utils"
    require "push"
    require "state"
    require "modes"
    require "midi"
    if not push then push = Push() end
    if not state then state = State() end
    if not modes then modes = Modes() end
    if not midi then midi = Midi() end
    push:start()
end

local function goodnight ()
    push:stop()
    tool = nil
    song = nil
    push = nil
    state = nil
    modes = nil
    midi = nil
end

tool.app_new_document_observable:add_notifier(letsGo)
tool.app_release_document_observable:add_notifier(goodnight)
--push:stop()

