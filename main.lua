-- _AUTO_RELOAD_DEBUG = true

tool = renoise.tool()
song = nil
push = nil

function letsGo ()
    if not song then song = renoise.song() end
    if not tool then tool = renoise.tool() end

    require "utils"
    require "push"
    require "state"
    require "modes"
    require "midi"

    if not push then push = Push() end
    push:start()
end

function goodnight ()
    push:stop()

    tool = nil
    song = nil
    push = nil
end

tool.app_new_document_observable:add_notifier(letsGo)
tool.app_release_document_observable:add_notifier(goodnight)
--push:stop()

