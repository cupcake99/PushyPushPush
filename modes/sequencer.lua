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
                local display = push._state.display
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
            end,
            action = function (data)
                local control, index
                if data[1] == Midi.status.note_on then
                    control = getControlFromType("note", data[2])
                    if control.hasNote and control.note < 36 then
                        return
                    elseif control.hasNote and control.note > 35 and control.note < 100 then
                        if push._state:insertNote(data) then
                            push._state:setPatternDisplay {0, 0, 1}
                        else
                            push._state:receiveNote(data)
                        end
                    end
                elseif data[1] == Midi.status.note_off then
                    control = getControlFromType("note", data[2])
                    if control.hasNote and control.note < 36 then
                        return
                    elseif control.hasNote and control.note > 35 and control.note < 100 then
                        if song.transport.edit_mode then
                            return
                        else
                            push._state:receiveNote(data)
                        end
                    end
                elseif data[1] == Midi.status.cc then
                    control, index = getControlFromType("cc", data[2])
                    if control.hasCC and control.cc > 35 and control.cc < 44 then
                        -- push._state:setSharp(data)
                    elseif control.name == "tempo" and control.hasCC then
                        if push._state.shiftActive then
                            push._state:changeSequence(data)
                        else
                            push._state:changePattern(data)
                        end
                        push._state:setPatternDisplay {0, 0, 1}
                    elseif control.name == "swing" and control.hasCC then
                        if push._state:setEditPos(data) then
                            push._state:setPatternDisplay(data)
                        end
                    elseif control.name == "volume" then
                        push._state:setMasterVolume(data)
                    elseif control.name == "mute" then
                        local muted = song.tracks[push._state.activeTrack].mute_state ~= 1
                        if data[3] > 0 then
                            if muted then song.tracks[push._state.activeTrack]:unmute()
                            else song.tracks[push._state.activeTrack]:mute() end
                            push._state.current[index].value =
                            ((song.tracks[push._state.activeTrack].mute_state ~= 1)
                            and Push.light.button.high + Push.light.blink.slow) or Push.light.button.low
                        end
                    elseif control.name == "csr_up" or control.name == "csr_down" then
                        if push._state:setEditPos(data) then
                            push._state:setPatternDisplay(data)
                        end
                    elseif control.name == "csr_left" or
                        control.name == "csr_right" or--[[or control.name == "dial1"]]
                        control.name == "softkey1A" or
                        control.name == "softkey2A" or
                        control.name == "softkey3A" or
                        control.name == "softkey4A" or
                        control.name == "softkey5A" or
                        control.name == "softkey6A" or
                        control.name == "softkey7A" or
                        control.name == "softkey8A" then
                            push._state:changeTrack(data)
                            push._state:setPatternDisplay {0, 0, 1}
                    elseif control.name == "dial2" then
                        push._state:changeInstrument(data)
                    elseif control.name == "oct_up" or control.name == "oct_down" then
                        push._state:changeOctave(data)
                    elseif control.name == "dial3" then
                        push._state:changePatternLength(data)
                    else return end
                end
                push._state.dirty = true
            end
        }
    }
}

return sequencer
