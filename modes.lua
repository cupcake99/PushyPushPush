local sequencer = {
    name = "sequencer",
    cc = getControlFromType("name", "note").cc,
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
                        and Push.light.button.off) or Push.light.button.low
                }
                return lights
            end,
            display = function ()
                local display = state.display
                local z = 1
                for i = state.trackRange.from, state.trackRange.to do
                    if i == state.activeTrack then
                        display.line[1].zone[z] = ">" .. song.tracks[i].name
                    else
                        display.line[1].zone[z] = song.tracks[i].name
                    end
                    z = z + 1
                end
                display.line[2].zone[2] = (song.selected_instrument.name == "" and "un-named") or song.selected_instrument.name
                display.line[2].zone[3] = " Length:"
                display.line[3].zone[3] = "   " .. song.patterns[state.activePattern].number_of_lines
            end,
            action = function (data)
                local control, index
                if data[1] == Midi.status.note_on then
                    control, index = getControlFromType("note", data[2])
                    if control.hasNote and control.note < 36 then
                        return
                    elseif control.hasNote and control.note > 35 and control.note < 100 then
                        if state:insertNote(data) then
                            state:setPatternDisplay({0, 0, 1})
                        else
                            state:receiveNote(data)
                        end
                    end
                elseif data[1] == Midi.status.note_off then
                    control, index = getControlFromType("note", data[2])
                    if control.hasNote and control.note < 36 then
                        return
                    elseif control.hasNote and control.note > 35 and control.note < 100 then
                        if song.transport.edit_mode then
                            return
                        else
                            state:receiveNote(data)
                        end
                    end
                elseif data[1] == Midi.status.cc then
                    control, index = getControlFromType("cc", data[2])
                    if control.hasCC and control.cc > 35 and control.cc < 44 then
                        state:setSharp(data)
                    elseif control.name == "tempo" and control.hasCC then
                        if state.shiftActive then
                            state:changeSequence(data)
                        else
                            state:changePattern(data)
                        end
                        state:setPatternDisplay({0, 0, 1})
                    elseif control.name == "swing" and control.hasCC then
                        if state:setEditPos(data) then
                            state:setPatternDisplay(data)
                        end
                    elseif control.name == "volume" then
                        state:setMasterVolume(data)
                    elseif control.name == "mute" then
                        local muted = song.tracks[state.activeTrack].mute_state ~= 1
                        if data[3] > 0 then
                            if muted then song.tracks[state.activeTrack]:unmute()
                            else song.tracks[state.activeTrack]:mute() end
                            state.current[index].value =
                            ((song.tracks[state.activeTrack].mute_state ~= 1)
                            and Push.light.button.high + Push.light.blink.slow) or Push.light.button.low
                        end
                    elseif control.name == "csr_up" or control.name == "csr_down" then
                        if state:setEditPos(data) then
                            state:setPatternDisplay(data)
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
                            state:changeTrack(data)
                            state:setPatternDisplay({0, 0, 1})
                    elseif control.name == "dial2" then
                        state:changeInstrument(data)
                    elseif control.name == "dial3" then
                        state:changePatternLength(data)
                    else return end
                end
                state.dirty = true
            end
        }
    }
}

class "Modes"
-- mappings to connect actions from the Push device to the state of the Renoise song

function Modes:__init ()
    self.modes = {}
    self:registerMode(sequencer)
end

function Modes:registerMode (modespec)
    self.modes[modespec.cc] = {name = modespec.name}
    for page, spec in ipairs(modespec.page) do
        local temp = setmetatable({}, {__index = Push.control})
        for name, value in pairs(spec.lights()) do
            local control = getControlFromType("name", name)
            if control then
                temp[control.cc] = control
                temp[control.cc].value = value
            end
        end
        self.modes[modespec.cc] = {
            page = {
                [page] = {
                    temp,
                    display = modespec.page[page].display,
                    action = modespec.page[page].action
                }
            }
        }
    end
end

function Modes:select (cc)
    return self.modes[cc]
end



-- Midi.track = {
--     name = "track",
--     cc = 0,
--     lights = function (self)

--     end,
--     display = function (self)

--     end,
--     action = function (self, data)
--         if (data[1] == 144 or data[1] == 128) and data[2] > 35 and data[2] < 100 then
--             receiveNote(self, data)
--         elseif data[1] == 176 and data[2] == 85 then
--             Mode.play.action(self, data[3])
--         elseif data[1] == 176 and data[2] == 86 then
--             Mode.edit.action(self, data[3])
--         elseif data[1] == 176 and data[2] >= 102 and data[2] <= 109 then
--             local muted = song.tracks[self.activeTrack + data[2] - 102].mute_state ~= 1
--             if data[3] > 0 then
--                 if muted then song.tracks[self.activeTrack + data[2] - 102]:unmute() else song.tracks[self.activeTrack + data[2] - 102]:mute() end
--                 self.controlCurrent.cc[data[2]].value = ((song.tracks[self.activeTrack + data[2] - 102].mute_state == 1) and Push.pad_light.pink) or 0
--             end
--         else
--             return
--         end
--         state.dirty = true
--     end
-- }

-- Midi.instrument = {
--     name = "instrument",
--     cc = 0,
--     lights = function (self)

--     end,
--     display = function (self)

--     end,
--     action = function (self, data)
--         if (data[1] == 144 or data[1] == 128) and data[2] > 35 and data[2] < 100 then
--             receiveNote(self, data)
--         elseif data[1] == 176 and data[2] == 85 then
--             Mode.play.action(self, data[3])
--         elseif data[1] == 176 and data[2] == 86 then
--             Mode.edit.action(self, data[3])
--         elseif data[1] == 176 and data[2] >= 102 and data[2] <= 109 then
--             local muted = song.tracks[self.activeTrack + data[2] - 102].mute_state ~= 1
--             if data[3] > 0 then
--                 if muted then song.tracks[self.activeTrack + data[2] - 102]:unmute() else song.tracks[self.activeTrack + data[2] - 102]:mute() end
--                 self.controlCurrent.cc[data[2]].value = ((song.tracks[self.activeTrack + data[2] - 102].mute_state == 1) and Push.pad_light.pink) or 0
--             end
--         else
--             return
--         end
--         state.dirty = true
--     end
-- }

-- Midi.matrix = {
--     name = "matrix",
--     cc = 0,
--     lights = function (self)

--     end,
--     display = function (self)

--     end,
--     action = function (self, data)
--         if (data[1] == 144 or data[1] == 128) and data[2] > 35 and data[2] < 100 then
--             receiveNote(self, data)
--         elseif data[1] == 176 and data[2] == 85 then
--             Mode.play.action(self, data[3])
--         elseif data[1] == 176 and data[2] == 86 then
--             Mode.edit.action(self, data[3])
--         elseif data[1] == 176 and data[2] >= 102 and data[2] <= 109 then
--             local muted = song.tracks[self.activeTrack + data[2] - 102].mute_state ~= 1
--             if data[3] > 0 then
--                 if muted then song.tracks[self.activeTrack + data[2] - 102]:unmute() else song.tracks[self.activeTrack + data[2] - 102]:mute() end
--                 self.controlCurrent.cc[data[2]].value = ((song.tracks[self.activeTrack + data[2] - 102].mute_state == 1) and Push.pad_light.pink) or 0
--             end
--         else
--             return
--         end
--         state.dirty = true
--     end
-- }

