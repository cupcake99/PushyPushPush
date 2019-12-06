
tool = nil
song = nil
push = nil

function letsGo ()
    tool = renoise.tool()
    song = renoise.song()

    require 'push'
    require 'sysex'
    require 'modes'

    push = Push()
    push:start()
end

function goodnight ()
    push:stop()

    tool = nil
    song = nil
    push = nil
end

renoise.tool().app_new_document_observable:add_notifier(letsGo)
renoise.tool().app_release_document_observable:add_notifier(goodnight)
--push:stop()


