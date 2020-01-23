-- _AUTO_RELOAD_DEBUG = true

tool = renoise.tool()
song = nil
push = nil

function letsGo ()
    song = renoise.song()

    require "utils"
    require "push"
    require "state"
    require "modes"
    require "midi"

    push = Push()
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

