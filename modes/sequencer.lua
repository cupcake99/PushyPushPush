local sequencer = {
    name = "sequencer",
    control = "note",
    page = {
        [1] = {
            lights = function ()
                local lights = {
                    stop = Push.light.button.off,
                    note = Push.light.button.high,
                    x32t = Push.light.button.off,
                    x32 = Push.light.button.off,
                    x16t = Push.light.button.off,
                    x16 = Push.light.button.off,
                    x8t = Push.light.button.off,
                    x8 = Push.light.button.off,
                    x4t = Push.light.button.off,
                    x4 = Push.light.button.off,
                    softkey1A = Push.light.note_val.dim_yellow,
                    softkey2A = Push.light.note_val.dim_yellow,
                    softkey3A = Push.light.note_val.dim_yellow,
                    softkey4A = Push.light.note_val.dim_yellow,
                    softkey5A = Push.light.note_val.dim_yellow,
                    softkey6A = Push.light.note_val.dim_yellow,
                    softkey7A = Push.light.note_val.dim_yellow,
                    softkey8A = Push.light.note_val.dim_yellow,
                    softkey1B = Push.light.pad.light_grey,
                    softkey2B = Push.light.pad.light_grey,
                    softkey3B = Push.light.pad.light_grey,
                    softkey4B = Push.light.pad.light_grey,
                    softkey5B = Push.light.pad.light_grey,
                    softkey6B = Push.light.pad.light_grey,
                    softkey7B = Push.light.pad.light_grey,
                    softkey8B = Push.light.pad.light_grey,
                    mute = ((song.tracks[song.selected_track_index].mute_state ~= 1)
                        and Push.light.button.high + Push.light.blink.slow)
                        or Push.light.button.low,
                    csr_left = (song.selected_track_index == 1 and Push.light.button.off) or Push.light.button.low,
                    csr_right = (song.selected_track_index == (song.sequencer_track_count + song.send_track_count + 1)
                        and Push.light.button.off) or Push.light.button.low,
                    csr_up = (song.transport.edit_pos.line == 1 and Push.light.button.off) or Push.light.button.low,
                    csr_down = (song.transport.edit_pos.line == song.patterns[song.selected_pattern_index].number_of_lines
                        and Push.light.button.off) or Push.light.button.low,
                }
                return lights
            end,
            -- using direct reference to global push object below here. this is not ideal, but is done to make scope issues go
            -- away ASAP. Need to determine another way to free the declarations from being tied to a specific variable.
            -- Eventual intention is for the mode spec to be simple key-value pair style statements which are compiled into
            -- a callable function similar to the one below, but without necessity to write lots of conditionals etc.
            display = function ()
                local display = table.copy(Push.display)
                local z = 1
                for i = push._state.trackRange.from, push._state.trackRange.to do
                    if i == push._state.activeTrack then
                        display.line[1].zone[z] = ">" .. song.tracks[i].name
                    else
                        display.line[1].zone[z] = song.tracks[i].name
                    end
                    z = z + 1
                end
                display.line[2].zone[2] = (song.selected_instrument.name == "" and "un-named") or song.selected_instrument.name
                display.line[2].zone[3] = " Length:"
                display.line[3].zone[3] = "   " .. song.patterns[push._state.activePattern].number_of_lines

                return display
            end,
            action = function ()
                local action = {}
                action.tempo = assert(loadstring([[
                    local data = select(2, ...)
                    if push._state.shiftActive then
                        push._state:changeSequence(data)
                    else
                        push._state:changePattern(data)
                    end
                    push._state:setPatternDisplay {0, 0, 1}]]))
                action.swing = assert(loadstring([[
                    local data = select(2, ...)
                    if push._state:setEditPos(data) then
                        push._state:setPatternDisplay(data)
                    end]]))
                action.volume = push._state.setMasterVolume
                action.mute = assert(loadstring([[
                    local data = select(2, ...)
                    local index = select(3, ...)
                    local muted = song.tracks[push._state.activeTrack].mute_state ~= 1
                    if data[3] > 0 then
                        if muted then song.tracks[push._state.activeTrack]:unmute()
                        else song.tracks[push._state.activeTrack]:mute() end
                        push._state.current[index].value =
                        ((song.tracks[push._state.activeTrack].mute_state ~= 1)
                        and Push.light.button.high + Push.light.blink.slow) or Push.light.button.low
                    end]]))
                action.csr_up = action.swing
                action.csr_down = action.swing
                action.csr_left = assert(loadstring([[
                    local data = select(2, ...)
                    push._state:changeTrack(data)
                    push._state:setPatternDisplay {0, 0, 1}]]))
                action.csr_right = action.csr_left
                action.softkey1A = action.csr_left
                action.softkey2A = action.csr_left
                action.softkey3A = action.csr_left
                action.softkey4A = action.csr_left
                action.softkey5A = action.csr_left
                action.softkey6A = action.csr_left
                action.softkey7A = action.csr_left
                action.softkey8A = action.csr_left
                action.dial2 = push._state.changeInstrument
                action.oct_up = push._state.changeOctave
                action.oct_down = action.oct_up
                action.dial3 = push._state.changePatternLength

                return action
            end
        }
    }
}

return sequencer
