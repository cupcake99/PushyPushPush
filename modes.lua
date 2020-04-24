class "Modes"
-- mappings to connect actions from the Push device to the state of the Renoise song

function Modes:__init (parent)
    self.push = parent
    self.select = {
        -- use this construction to map mode objects to buttons on the Push by button name (second argument)
        -- just a fancy way to set the index to the CC of the Push button without having to use a literal numerical
        -- CC value (opaque). The mode is passed as an object reference and should be 'read only' (static const)
        [getControlFromType("name", "note").cc] = Modes.sequencer
        -- [getControlFromType("name", "track").cc] = Modes.track
        -- [getControlFromType("name", "device").cc] = Modes.instrument
        -- [getControlFromType("name", "session").cc] = Modes.matrix
    }
end

Modes.sequencer = {
    name = "sequencer",
    cc = 50,
    lights = function (self)
        local index
        local control, current = Push.control, self.push.state.current
        local trk = self.push.state.activeTrack
        for i = 1, 120 do
            if control[i] and control[i].hasLED then
                if control[i].name == "stop" then current[i].value = Push.light.button.off
                elseif control[i].name == "note" then current[i].value = Push.light.button.high
                elseif control[i].name == "x32t" then current[i].value = Push.light.button.off
                elseif control[i].name == "x32" then current[i].value = Push.light.button.off
                elseif control[i].name == "x16t" then current[i].value = Push.light.button.off
                elseif control[i].name == "x16" then current[i].value = Push.light.button.off
                elseif control[i].name == "x8t" then current[i].value = Push.light.button.off
                elseif control[i].name == "x8" then current[i].value = Push.light.button.off
                elseif control[i].name == "x4t" then current[i].value = Push.light.button.off
                elseif control[i].name == "x4" then current[i].value = Push.light.button.off
                elseif control[i].name == "mute" then
                    current[i].value = ((song.tracks[trk].mute_state ~= 1)
                    and Push.light.button.high + Push.light.blink.slow) or Push.light.button.low
                elseif control[i].name == "csr_left" then
                    current[i].value = (trk == 1 and Push.light.button.off) or Push.light.button.low
                elseif control[i].name == "csr_right" then
                    current[i].value = (trk == (song.sequencer_track_count + song.send_track_count + 1)
                    and Push.light.button.off) or Push.light.button.low
                end
            end
            index = i + 128
            if current[index] and current[index].hasNote and current[index].hasLED then current[index].value = 1 end
        end
    end,
    display = function (self)
        local display = self.push.state.display
        display.line[1].zone[1] = song.tracks[self.push.state.activeTrack].name
        display.line[1].zone[2] = (song.selected_instrument.name == "" and "un-named") or song.selected_instrument.name
        display.line[1].zone[3] = " Length:"
        display.line[2].zone[3] = "   " .. song.patterns[self.push.state.activePattern].number_of_lines
    end,
    action = function (self, data)
        local control, index
        if data[1] == Midi.status.note_on then
            control, index = getControlFromType("note", data[2])
            if control.hasNote and control.note < 36 then
                return
            elseif control.hasNote and control.note > 35 and control.note < 100 then
                if self.push.state:insertNote(data) then
                    self.push.state:setPatternDisplay({0, 0, 1})
                else
                    self.push.state:receiveNote(data)
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
                    self.push.state:receiveNote(data)
                end
            end
        elseif data[1] == Midi.status.cc then
            control, index = getControlFromType("cc", data[2])
            if control.hasCC and control.cc > 35 and control.cc < 44 then
                self.push.state:setSharp(data)
            elseif control.name == "tempo" and control.hasCC then
                if self.push.state.shiftActive then
                    self.push.state:changeSequence(data)
                else
                    self.push.state:changePattern(data)
                end
                self.push.state:setPatternDisplay({0, 0, 1})
            elseif control.name == "swing" and control.hasCC then
                if self.push.state:setLine(data) then
                    self.push.state:setPatternDisplay(data)
                end
            elseif control.name == "volume" then
                self.push.state:setMasterVolume(data)
            elseif control.name == "mute" then
                local muted = song.tracks[self.push.state.activeTrack].mute_state ~= 1
                if data[3] > 0 then
                    if muted then song.tracks[self.push.state.activeTrack]:unmute()
                    else song.tracks[self.push.state.activeTrack]:mute() end
                    self.push.state.current[index].value =
                    ((song.tracks[self.push.state.activeTrack].mute_state ~= 1)
                    and Push.light.button.high + Push.light.blink.slow) or Push.light.button.low
                end
            elseif control.name == "csr_up" or control.name == "csr_down" then
                if self.push.state:setLine(data) then
                    self.push.state:setPatternDisplay(data)
                end
            elseif ((control.name == "csr_left" or control.name == "csr_right") or control.name == "dial1") then
                self.push.state:changeTrack(data)
                self.push.state:setPatternDisplay({0, 0, 1})
            elseif control.name == "dial2" then
                self.push.state:changeInstrument(data)
            elseif control.name == "dial3" then
                self.push.state:changePatternLength(data)
            else return end
        end
        self.push.state.dirty = true
    end
}

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
--         self.push.state.dirty = true
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
--         self.push.state.dirty = true
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
--         self.push.state.dirty = true
--     end
-- }

