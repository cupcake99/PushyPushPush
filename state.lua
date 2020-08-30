local _push, _mode, _midi
local note_table = {
    ["C"] = 0,
    ["D"] = 1,
    ["E"] = 2,
    ["F"] = 3,
    ["G"] = 4,
    ["A"] = 5,
    ["B"] = 6,
    ["O"] = 7,
    [0] = "C",
    [1] = "D",
    [2] = "E",
    [3] = "F",
    [4] = "G",
    [5] = "A",
    [6] = "B",
    [7] = "OFF",
}

class "State"
-- representation of the state of the Renoise song and methods to change parameters within it

function State:__init ()
    self.activeMode = {name = ""}
    self.activePage = 0
    self.activeSeqIndex = nil
    self.activePattern = nil
    self.activeTrack = nil
    self.trackRange = nil
    self.editPos = nil
    self.playbackPos = nil
    self.activeInstrument = nil
    self.instrumentCount = 0
    self.octave = 0
    self.display = {
        line = {
            {zone = {"", "", "", "", "", "", "", ""}},
            {zone = {"", "", "", "", "", "", "", ""}},
            {zone = {"", "", "", "", "", "", "", ""}},
            {zone = {"", "", "", "", "", "", "", ""}}
        }
    }
    self.displaySysexByLine = {}
    self.current = table.copy(Push.control)
    -- self.last = table.copy(self.current)
    self.shiftActive = false
    self.dirty = false
    self.noteOns = {}
    self.noteDelta = nil
end

function State.setRefs (parent)
    _push = parent
    _mode = parent._mode
    _midi = parent._midi
end

function State:getState ()
    self.activeSeqIndex = song.selected_sequence_index
    self.activePattern = song.selected_pattern_index
    self.activeTrack = song.selected_track_index
    self.octave = song.transport.octave
    self:getTrackRange()
    self.editPos = song.selected_line_index
    self.activeInstrument = song.selected_instrument_index
    self:getInstrumentCount()
end

function State:getTrackRange ()
    if self.activeTrack <= 8 then
        self.trackRange = { from = 1, to = song.sequencer_track_count }
    else
        if self.activeTrack + 7 <= song.sequencer_track_count then
            self.trackRange = { from = self.activeTrack, to = self.activeTrack + 7 }
        else
            self.trackRange = { from = song.sequencer_track_count - 7, to = song.sequencer_track_count }
        end
    end
end

function State:getInstrumentCount ()
    local instrumentCt
    for i, _ in ipairs(song.instruments) do
        instrumentCt = i
    end
    if self.instrumentCount ~= instrumentCt then self.instrumentCount = instrumentCt end
end

function State:getMode (cc)
    local page, mode = 1, _mode:select(cc)
    if mode then
        if mode.name == self.activeMode.name then
            if self.activePage == #mode.page then page = 1 else
                page = self.activePage + 1 <= #mode.page and self.activePage + 1 or nil
            end
            if not page then return end --see if page can change, if not mode and page is already loaded so exit
        end
        for i = 1, 120 do
            self.current[i] = nil
            if mode.page[page].lights[i] then
                self.current[i] = mode.page[page].lights[i]
            end
        end
        mode.page[page].display()
        self.activeMode = {name = mode.name, action = mode.page[page].action}
        self.activePage = page
        return true
    end
    return false
end

function State:changeMode (data)
    if _mode.modes[data[2]] and data[3] > 1 then
        if not self:getMode(data[2]) then return false end
        rprint(self.current)
        self:setPatternDisplay {0,0,1}
        self.dirty = true
        return true
    end
    return false
end

function State:shift (data)
    if data[3] == 0 then
        self.shiftActive = false
        self.current[data[2]].value = Push.light.button.low
    else
        self.shiftActive = true
        self.current[data[2]].value = Push.light.button.high
    end
    self.dirty = true
end

function State:play (data)
    if not Push.control[data[2]].name == "play" then return end
    if data[3] == 0 then return end
    local playing = song.transport.playing and self.current[data[2]].value == Push.light.button.high
    if playing then
        song.transport:stop()
        self.current[data[2]].value = Push.light.button.low
    else
        local mode
        if self.shiftActive then
            mode = renoise.Transport.PLAYMODE_CONTINUE_PATTERN
        else
            mode = renoise.Transport.PLAYMODE_RESTART_PATTERN
        end
        song.transport:start(mode)
        self.current[data[2]].value = Push.light.button.high
    end
    self.dirty = true
end


function State:edit (data)
    if not Push.control[data[2]].name == "record" then return end
    if data[3] == 0 then return end
    local editing = song.transport.edit_mode and self.current[data[2]].value == Push.light.button.high
    if editing then
        song.transport.edit_mode = false
        self.current[data[2]].value = Push.light.button.low
    else
        song.transport.edit_mode = true
        self.current[data[2]].value = Push.light.button.high
    end
    self.dirty = true
end


function State:setEditPos (data)
    if data[3] == 0 then return end
    local pos = song.transport.edit_pos
    if pos == nil then return false end
    local shift_mult = (self.shiftActive and 10) or 1
    if data[2] == 15 then
        local encoderVal = _midi.encoderParse(data, 7)
        if encoderVal == 0 then return nil end
        pos.line = pos.line + encoderVal * shift_mult
    elseif (data[2] == 46 or data[2] == 47) and data[3] > 0 then
        pos.line = pos.line + (((data[2] - 46 == 1) and 1) or -1) * shift_mult
    end
    -- print("Set Line: \n", "Sequence: ", pos.sequence, "\n", "Line: ", pos.line)
    if song.transport.wrapped_pattern_edit then
        if pos.line < 1 then
            pos.line = (
                pos.sequence == 1 and 1
                ) or song.patterns[song.sequencer:pattern(pos.sequence - 1)].number_of_lines
            pos.sequence = (
                pos.sequence - 1 > 0 and pos.sequence - 1
                ) or 1
        elseif pos.line > song.patterns[self.activePattern].number_of_lines then
            pos.line = (
                pos.sequence == song.transport.song_length.sequence
                and song.patterns[self.activePattern].number_of_lines
                ) or 1
            pos.sequence = (
                pos.sequence + 1 < song.transport.song_length.sequence + 1 and pos.sequence + 1
                ) or song.transport.song_length.sequence
        end
    else
        if pos.line < 1 then
            pos.line = 1
        elseif pos.line > song.patterns[self.activePattern].number_of_lines then
            pos.line = song.patterns[self.activePattern].number_of_lines
        end
    end
    self.editPos = pos.line
    -- if song.transport.follow_player and not song.transport.edit_mode then
        -- song.transport.playback_pos = pos
    -- else
        song.transport.edit_pos = pos
    -- end
    if self.editPos == 1 then -- fix checking when song.transport.wrapped_pattern_edit is true else lights weird on crossing sequence boundaries
        print("before", Push.control[46].value)
        self.current[46].value = Push.light.button.off -- somehow this is writing to the PUsh table
        print("after", Push.control[46].value)
    elseif self.editPos == song.patterns[self.activePattern].number_of_lines then
        self.current[47].value = Push.light.button.off
    else
        print "in else"
        self.current[46] = nil
        print(self.current[46].value)
        print(Push.control[46].value)
        self.current[47] = nil
        print(self.current[47].value)
    end
    return true
end

function State:setPlaybackPos ()

end

function State:setPatternDisplay (data)
    if data[3] == 0 then return end
    if self.activePattern == nil then return end
    if self.editPos > song.patterns[self.activePattern].number_of_lines then
        print "[PushyPushPush] ERROR: Invalid Line Index for setPatternDisplay"
        return
    end
    local note, line, sharp
    local patt = self.activePattern
    local trk = self.activeTrack
    for i = 36, 99 do
        i = i + 128
        if self.current[i] and self.current[i].hasLED then
            self.current[i].value = Push.light.pad.dark_grey
        end
    end
    if song.patterns[patt].number_of_lines < 9 then
        for i = 0, 7 do
            self.current[(92 - ((self.editPos - 1) * 8)) + 128 + i].value = Push.light.pad.pale_mint_blue
        end
        if song.patterns[patt].is_empty then return end
        if song.tracks[trk].type == renoise.Track.TRACK_TYPE_MASTER
        or song.tracks[trk].type == renoise.Track.TRACK_TYPE_SEND then return end
        for i = 1, song.patterns[patt].number_of_lines do
            if song.patterns[patt].tracks[trk].lines[i]:note_column(1).note_string ~= "---" then
                line = song.patterns[patt].tracks[trk].lines[i]:note_column(1)
                note = note_table[string.sub(line.note_string, 1, 1)]
                sharp = string.find(line.note_string, "#")
                self.current[(92 - ((i - 1) * 8)) + 128 + note].value = sharp and Push.light.pad.strong_purple
                or Push.light.pad.super_blue
            end
        end
    else
        for i = 0, 7 do
            if self.editPos < 5 then
                self.current[(92 - ((self.editPos - 1) * 8)) + 128 + i].value = Push.light.pad.pale_mint_blue
            elseif song.patterns[patt].number_of_lines > 8
            and song.patterns[patt].number_of_lines - self.editPos < 5 then
                self.current[
                    (92 - ((7 - (song.patterns[patt].number_of_lines - self.editPos)) * 8)) + 128 + i
                ].value = Push.light.pad.pale_mint_blue
            else
                self.current[68 + 128 + i].value = Push.light.pad.pale_mint_blue
            end
        end
        if song.patterns[patt].is_empty then return end
        if song.tracks[trk].type == renoise.Track.TRACK_TYPE_MASTER
        or song.tracks[trk].type == renoise.Track.TRACK_TYPE_SEND then
            return
        end
        local pos = self.editPos
        if pos < 5 then pos = 4 elseif song.patterns[patt].number_of_lines > 8
        and (pos > song.patterns[patt].number_of_lines - 4) then
            pos = song.patterns[patt].number_of_lines - 4
        end
        local j = 0
        for i = pos - 3, pos + 4 do
            if song.patterns[patt].tracks[trk].lines[i] then
                line = song.patterns[patt].tracks[trk].lines[i]:note_column(1)
                note = note_table[string.sub(line.note_string, 1, 1)]
                sharp = string.find(line.note_string, "#")
            end
            if note then
                self.current[(92 - (j * 8)) + 128 + note].value = sharp and Push.light.pad.strong_purple
                or Push.light.pad.super_blue
            end
            j = j + 1
        end
    end

end

-- this is just for the nice touchy lights. hopefully one day it will also help playing notes into renoise
function State:receiveNote (data)
    local value = data[2] + 128
    if data[1] == Midi.status.note_on then
        table.insert(self.noteOns, value, self.current[value].value)
        self.current[value].value = Push.light.pad.strong_red
    elseif data[1] == Midi.status.note_off then
        self.current[value].value = self.noteOns[value]
        table.remove(self.noteOns, value)
    end
end

function State:setMasterVolume (data)
    local shift_mult = (self.shiftActive and 0.1) or 1
    local masterTrack = song.tracks[song.sequencer_track_count + 1]
    local val = masterTrack.postfx_volume.value + ((_midi.encoderParse(data, 5) * 0.2) * shift_mult)
    if val < masterTrack.postfx_volume.value_min then val = masterTrack.postfx_volume.value_min
    elseif val > masterTrack.postfx_volume.value_max then val = masterTrack.postfx_volume.value_max end
    masterTrack.postfx_volume.value = val
end

function State:setPlaying ()
    local play = getControlFromType("name", "play")
    if song.transport.playing then
        self.current[play.cc].value = Push.light.button.high
    else
        self.current[play.cc].value = Push.light.button.low
    end
    self.dirty = true
end

function State:setEditing ()
    local edit = getControlFromType("name", "record")
    if song.transport.edit_mode then
        self.current[edit.cc].value = Push.light.button.high
    else
        self.current[edit.cc].value = Push.light.button.low
    end
    self.dirty = true
end

function State:setSequenceIndex ()
    if self.activeSeqIndex ~= song.selected_sequence_index then
        self.activeSeqIndex = song.selected_sequence_index
        self:setActivePattern()
    end
end

function State:setActivePattern ()
    if self.activePattern ~= song.selected_pattern_index then
        self.activePattern = song.selected_pattern_index
        -- setPatternDisplay(self, {0, 0, 1})
        self.dirty = true
    end
end

function State:setActiveTrack ()
    if self.activeTrack ~= song.selected_track_index then
        self.activeTrack = song.selected_track_index
        -- self.display.line[1].zone[1] = song.tracks[self.activeTrack].name
        local z = 1
        self:getTrackRange()
        for i = self.trackRange.from, self.trackRange.to do
            if i == self.activeTrack then
                self.display.line[1].zone[z] = ">" .. song.tracks[i].name
            else
                self.display.line[1].zone[z] = song.tracks[i].name
            end
            z = z + 1
        end
        self:setPatternDisplay {0, 0, 1}
        self.dirty = true
    end
end

function State:setActiveInstrument ()
    if self.activeInstrument ~= song.selected_instrument_index then
        self.activeInstrument = song.selected_instrument_index
        self.display.line[2].zone[2] = (
            song.selected_instrument.name == "" and "un-named"
            ) or song.selected_instrument.name
        self.dirty = true
    end
end

function State:setOctave ()
    if self.octave ~= song.transport.octave then
        self.octave = song.transport.octave
        local cc = getControlFromType("name", "oct_down").cc
        -- this bit with the lights is wrong
        if self.octave % 8 == 0 then
            if self.octave == 8 then
                cc = cc + 1
            end
            self.current[cc].value = Push.light.button.off
        else
            self.current[cc] = nil
            self.current[cc + 1] = nil
        end
    end
    self.dirty = true
end

function State:changeSequence (data)
    if data[3] == 0 then return end
    local pos = (song.transport.follow_player and song.transport.edit_pos) or nil
    -- if song.transport.follow_player then
    --     pos = song.transport.playback_pos
    -- end    local pos = (song.transport.follow_player and song.transport.playback_pos) or nil
    local direction = _midi.encoderParse(data, nil)
    if direction == 0 then return end
    if direction >= 1 then
        if self.activeSeqIndex == song.transport.song_length.sequence then return end
        if song.patterns[song.sequencer:pattern(self.activeSeqIndex + 1)].number_of_lines
        < song.patterns[self.activePattern].number_of_lines then
            self.editPos = song.patterns[song.sequencer:pattern(self.activeSeqIndex + 1)].number_of_lines
        end
        if pos then
            song.transport.edit_pos.sequence = pos.sequence + 1
            song.transport.playback_pos.sequence = pos.sequence + 1
        end
        song.selected_sequence_index = self.activeSeqIndex + 1
    elseif direction < 0 then
        if self.activeSeqIndex == 1 then return end
        if song.patterns[song.sequencer:pattern(self.activeSeqIndex - 1)].number_of_lines
        < song.patterns[self.activePattern].number_of_lines then
            self.editPos = song.patterns[song.sequencer:pattern(self.activeSeqIndex - 1)].number_of_lines
        end
        if pos then
            song.transport.edit_pos.sequence = pos.sequence - 1
            song.transport.playback_pos.sequence = pos.sequence - 1
        end
        song.selected_sequence_index = self.activeSeqIndex - 1
    end
    -- print("change seq, seq: ", self.activeSeqIndex)
    -- print("change seq, pattern: ", self.activePattern)
end

function State:changePattern (data)
    if data[3] == 0 then return end
    local direction = _midi.encoderParse(data, nil)
    if direction == 0 then return end
    if direction >= 1 then
        if self.activePattern == 999 then return end
        song.selected_pattern_index = self.activePattern + 1
    elseif direction < 0 then
        if self.activePattern == 1 then return end
        song.selected_pattern_index = self.activePattern - 1
    end
end

function State:changePatternLength (data)
    if data[3] == 0 then return end
    local direction = _midi.encoderParse(data, 3)
    if direction == 0 then return end
    local lines = song.patterns[self.activePattern].number_of_lines
    local shift_mult = (self.shiftActive and 4) or 1
    local value
    if direction >= 1 then
        if lines == renoise.Pattern.MAX_NUMBER_OF_LINES then return end
        value = lines + (1 * shift_mult)
        if value > renoise.Pattern.MAX_NUMBER_OF_LINES then value = renoise.Pattern.MAX_NUMBER_OF_LINES end
        song.patterns[self.activePattern].number_of_lines = value
    elseif direction < 0 then
        if lines == 1 then return end
        value = lines - (1 * shift_mult)
        if value < 1 then value = 1 end
        song.patterns[self.activePattern].number_of_lines = value
    end
    self.display.line[2].zone[3] = " Length:"
    self.display.line[3].zone[3] = "   " .. value
end

function State:changeTrack (data)
    if data[3] == 0 then return end
    if data[2] >= 20 and data[2] <= 27 then
        song.selected_track_index = (data[2] - 20) + self.trackRange.from
        self:setActiveTrack()
    else
        local direction
        -- if data[2] == 71 then
        --     direction = _midi.encoderParse(data, 8)
        -- else
        direction = (data[2] == 45 and 1) or -1
        -- end
        -- if direction == 0 then return end
        if direction == 1 then
            if self.activeTrack == song.sequencer_track_count then return end
            -- self.current[44].value = (self.current[44].value == 0 and Push.light.button.low) or self.current[44].value
            song:select_next_track()
        elseif direction == -1 then
            if self.activeTrack == 1 then return end
            -- self.current[45].value = (self.current[45].value == 0 and Push.light.button.low) or self.current[45].value
            song:select_previous_track()
        end
    end
    self.current[45].value = (self.activeTrack == (song.sequencer_track_count)
    and Push.light.button.off) or Push.light.button.low
    self.current[44].value = (self.activeTrack == 1 and Push.light.button.off) or Push.light.button.low
end

function State:changeInstrument (data)
    if data[3] == 0 then return end
    local direction = _midi.encoderParse(data, 8)
    if direction == 0 then return end
    if direction >= 1 then
        if self.activeInstrument == renoise.Song.MAX_NUMBER_OF_INSTRUMENTS
        or self.activeInstrument + 1 > self.instrumentCount then return end
        song.selected_instrument_index = song.selected_instrument_index + 1
    elseif direction < 0 then
        if self.activeInstrument == 1 then return end
        song.selected_instrument_index = song.selected_instrument_index  - 1
    end
end

function State:changeOctave (data)
    if data[3] == 0 then return end
    local octave = song.transport.octave
    if (data[2] - 54) == 0 then
        octave = octave - 1
        if octave < 0 then
            octave = 0
        end
    else
        octave = octave + 1
        if octave > 8 then
            octave = 8
        end
    end
    song.transport.octave = octave
end

function State:setSharp (data) -- this is probably now redundant and can be removed...
    if data[3] == 0 then return end
    if not song.transport.edit_mode then return false end
    local note, line, sharp, no_funny_business
    local pattn = song.patterns[self.activePattern]
    local trk = self.activeTrack
    line = 7 - (data[2] - 36)
    if data[3] > 0 and self.current[data[2]].value == Push.light.note_val.off then
        if pattn.number_of_lines < 9 or self.editPos < 4 then
            line = line + 1
            if line > pattn.number_of_lines or line < 1 then return false end
            no_funny_business = true
        else
            if self.editPos > (pattn.number_of_lines - 4) then
                line = (pattn.number_of_lines - 7) + line
                no_funny_business = true
            else
                line = line - 3
            end
        end
        if no_funny_business then
            note = pattn.tracks[trk].lines[line].note_columns[1].note_string
            if note == "---" or note == "OFF" or string.find(note, "[EB]%-%d") then return end
            pattn.tracks[trk].lines[line].note_columns[1].note_string = string.gsub(note, "-", "#")
        else
            note = pattn.tracks[trk].lines[self.editPos + line].note_columns[1].note_string
            if note == "---" or note == "OFF" or string.find(note, "[EB]%-%d") then return end
            pattn.tracks[trk].lines[self.editPos + line].note_columns[1].note_string = string.gsub(note, "-", "#")
        end
        self.current[data[2]].value = Push.light.note_val.orange
    else
        if pattn.number_of_lines < 9 or self.editPos < 4 then
            line = line + 1
            if line > pattn.number_of_lines or line < 1 then return false end
            no_funny_business = true
        else
            if self.editPos > (pattn.number_of_lines - 4) then
                line = (pattn.number_of_lines - 7) + line
                no_funny_business = true
            else
                line = line - 3
            end
        end
        if no_funny_business then
            note = pattn.tracks[trk].lines[line].note_columns[1].note_string
            if note == "---" or note == "OFF" then return end
            pattn.tracks[trk].lines[line].note_columns[1].note_string = string.gsub(note, "#", "-")
        else
            note = pattn.tracks[trk].lines[self.editPos + line].note_columns[1].note_string
            if note == "---" or note == "OFF" then return end
            pattn.tracks[trk].lines[self.editPos + line].note_columns[1].note_string = string.gsub(note, "#", "-")
        end
        self.current[data[2]].value = Push.light.note_val.off
    end
end

function State:insertNote (data)
    --renoise note value 0 = C-0 119, = B-9
    local trk = self.activeTrack
    if data[3] == 0
    or song.tracks[trk].type == renoise.Track.TRACK_TYPE_MASTER
    or song.tracks[trk].type == renoise.Track.TRACK_TYPE_SEND
    or not song.transport.edit_mode then
        return false
    end
    local note, line, basic, n_str, o_str
    local sharp = "-"
    local pattn = song.patterns[self.activePattern]
    if data[1] == Midi.status.note_on then
        note = note_table[(data[2] - 36) % 8]
        line = math.floor((99 - data[2]) / 8)
        if self.shiftActive then
            if note ~= "E" and note ~= "B" then sharp = "#" end
        end
    else
        return false
    end
    if pattn.number_of_lines < 9 or self.editPos < 4 then
        line = line + 1
        if line > pattn.number_of_lines or line < 1 then return false end
        basic = true
    else
        if self.editPos > (pattn.number_of_lines - 4) then
            line = (pattn.number_of_lines - 7) + line
            basic = true
        else
            line = line - 3
        end
    end
    o_str = pattn.tracks[trk].lines[line].note_columns[1].note_string
    if o_str == "---" then
        o_str = "%-%-%-"
    else
        o_str = string.gsub(o_str, "(%a)[#-](%d)", "%1[#-]%2")
    end
    if not basic then line = self.editPos + line end
    if note == "OFF" then
        if note == pattn.tracks[trk].lines[line].note_columns[1].note_string then
            pattn.tracks[trk].lines[line].note_columns[1].note_string = "---"
            pattn.tracks[trk].lines[line].note_columns[1].instrument_value = 255
        else
            pattn.tracks[trk].lines[line].note_columns[1].note_string = note
            pattn.tracks[trk].lines[line].note_columns[1].instrument_value = self.activeInstrument - 1
        end
    elseif note then
        n_str = note .. sharp .. self.octave
        if string.find(n_str, o_str) then
            pattn.tracks[trk].lines[line].note_columns[1].note_string = "---"
            pattn.tracks[trk].lines[line].note_columns[1].instrument_value = 255
        else
            pattn.tracks[trk].lines[line].note_columns[1].note_string = n_str
            pattn.tracks[trk].lines[line].note_columns[1].instrument_value = self.activeInstrument - 1
        end
    end
    return true
    --set current line if flag is true
    --play note if flag is true
end

