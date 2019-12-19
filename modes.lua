class "Modes"

function Modes:__init(parent)
    self.push = parent
    self.select = {
        [getControlFromType("name", "note").cc] = Modes.sequencer
    }
-- self.track = {
--     name = "track",
--     cc = 0,
--     lights = {}
--     display = {
--
--     },
--     action = function (obj, data)
--         if (data[1] == 144 or data[1] == 128) and data[2] > 35 and data[2] < 100 then
--             receiveNote(obj, data)
--         elseif data[1] == 176 and data[2] == 85 then
--             Mode.play.action(obj, data[3])
--         elseif data[1] == 176 and data[2] == 86 then
--             Mode.edit.action(obj, data[3])
--         elseif data[1] == 176 and data[2] >= 102 and data[2] <= 109 then
--             local muted = song.tracks[obj.activeTrack + data[2] - 102].mute_state ~= 1
--             if data[3] > 0 then
--                 if muted then song.tracks[obj.activeTrack + data[2] - 102]:unmute() else song.tracks[obj.activeTrack + data[2] - 102]:mute() end
--                 obj.controlCurrent.cc[data[2]].value = ((song.tracks[obj.activeTrack + data[2] - 102].mute_state == 1) and Push.pad_light.pink) or 0
--             end
--         else
--             return
--         end
--         obj.dirty = true
--     end,
-- }

-- self.instrument = {
--     name = "instrument",
--     setup = function (obj)
--         for i = 0, 127 do
--             if obj.controlCurrent.cc[i] and obj.controlCurrent.cc[i].hasLED then
--                 obj.controlCurrent.cc[i].value = Mode.instrument.LEDs[i].value
--             end
--             if obj.controlCurrent.note[i] and obj.controlCurrent.note[i].hasLED then
--                 obj.controlCurrent.note[i].value = 0
--             end
--         end
--         for i = 1, 4 do
--             for j = 1, 8 do
--                 obj.displayState.line[i].zone[j] = ""
--             end
--         end
--     end,
--     action = function (obj, data)
--         if (data[1] == 144 or data[1] == 128) and data[2] > 35 and data[2] < 100 then
--             receiveNote(obj, data)
--         elseif data[1] == 176 and data[2] == 85 then
--             Mode.play.action(obj, data[3])
--         elseif data[1] == 176 and data[2] == 86 then
--             Mode.edit.action(obj, data[3])
--         else
--             return
--         end
--         obj.dirty = true
--     end
-- }

-- self.matrix = {
--     name = "matrix",
--     setup = function (obj)
--         for i = 0, 127 do
--             if obj.controlCurrent.cc[i] and obj.controlCurrent.cc[i].hasLED then
--                 obj.controlCurrent.cc[i].value = Mode.matrix.LEDs[i].value
--             end
--             if obj.controlCurrent.note[i] and obj.controlCurrent.note[i].hasLED then
--                 obj.controlCurrent.note[i].value = 0
--             end
--         end
--         for i = 1, 4 do
--             for j = 1, 8 do
--                 obj.displayState.line[i].zone[j] = ""
--             end
--         end
--     end,
--     action = function (obj, data)
--         if (data[1] == 144 or data[1] == 128) and data[2] > 35 and data[2] < 100 then
--             receiveNote(obj, data)
--         elseif data[1] == 176 and data[2] == 85 then
--             Mode.play.action(obj, data[3])
--         elseif data[1] == 176 and data[2] == 86 then
--             Mode.edit.action(obj, data[3])
--         else
--             return
--         end
--         obj.dirty = true
--     end
-- }

end

Modes.sequencer = {
    name = "sequencer",
    cc = 50,
    lights = function (self)
        local index
        for i = 1, 139 do
            if Push.control[i] and Push.control[i].hasLED then
                if Push.control[i].name == "stop" then self.push.state.current[i].value = Push.light.button.off
                elseif Push.control[i].name == "note" then self.push.state.current[i].value = Push.light.button.high
                elseif Push.control[i].name == "x32t" then self.push.state.current[i].value = Push.light.button.off
                elseif Push.control[i].name == "x32" then self.push.state.current[i].value = Push.light.button.off
                elseif Push.control[i].name == "x16t" then self.push.state.current[i].value = Push.light.button.off
                elseif Push.control[i].name == "x16" then self.push.state.current[i].value = Push.light.button.off
                elseif Push.control[i].name == "x8t" then self.push.state.current[i].value = Push.light.button.off
                elseif Push.control[i].name == "x8" then self.push.state.current[i].value = Push.light.button.off
                elseif Push.control[i].name == "x4t" then self.push.state.current[i].value = Push.light.button.off
                elseif Push.control[i].name == "x4" then self.push.state.current[i].value = Push.light.button.off
                elseif Push.control[i].name == "mute" then
                    self.push.state.current[i].value = ((song.tracks[self.push.state.activeTrack].mute_state ~= 1) and Push.light.button.high + Push.light.blink.slow) or Push.light.button.low
                elseif Push.control[i].name == "csr_left" then
                    self.push.state.current[i].value = (self.push.state.activeTrack == 1 and Push.light.button.off) or Push.light.button.low
                elseif Push.control[i].name == "csr_right" then
                    self.push.state.current[i].value = (self.push.state.activeTrack == (song.sequencer_track_count + song.send_track_count + 1) and Push.light.button.off) or Push.light.button.low
                end
            end
            index = i + 128
            if self.push.state.current[index] and self.push.state.current[index].hasNote and self.push.state.current[index].hasLED then
                self.push.state.current[index].value = 1
            end
        end
    end,
    display = function (self)
        self.push.state.display.line[1].zone[1] = song.tracks[self.push.state.activeTrack].name
        self.push.state.display.line[1].zone[2] = (song.selected_instrument.name == "" and "un-named") or song.selected_instrument.name
        self.push.state.display.line[1].zone[3] = " Length:"
        self.push.state.display.line[2].zone[3] = "   " .. song.patterns[self.push.state.activePattern].number_of_lines
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
                end
                -- self.push.state:receiveNote(data)
            end
        elseif data[1] == Midi.status.note_off then
            -- self.push.state:receiveNote(data)
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
            elseif control.name == "swing" and control.hasCC then
                if self.push.state:setLine(data) then
                    self.push.state:setPatternDisplay(data)
                end
            elseif control.name == "volume" then
                self.push.state:setMasterVolume(data)
            elseif control.name == "mute" then
                local muted = song.tracks[self.push.state.activeTrack].mute_state ~= 1
                if data[3] > 0 then
                    if muted then song.tracks[self.push.state.activeTrack]:unmute() else song.tracks[self.push.state.activeTrack]:mute() end
                    self.push.state.current[index].value = ((song.tracks[self.push.state.activeTrack].mute_state ~= 1) and Push.light.button.high + Push.light.blink.slow) or Push.light.button.low
                end
            elseif control.name == "csr_up" or control.name == "csr_down" then
                if self.push.state:setLine(data) then
                    self.push.state:setPatternDisplay(data)
                end
            elseif ((control.name == "csr_left" or control.name == "csr_right") or control.name == "dial1") then
                self.push.state:changeTrack(data)
            elseif control.name == "dial2" then
                self.push.state:changeInstrument(data)
            elseif control.name == "dial3" then
                self.push.state:changePatternLength(data)
            else return end
        end
        self.push.state.dirty = true
    end
}

