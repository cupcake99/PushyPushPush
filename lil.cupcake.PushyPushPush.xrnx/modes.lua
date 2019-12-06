-- all the main action for the modes in here.
Mode = {
    cc = {
        [50] = "sequencer",
        [112] = "track",
        [110] = "instrument",
        [51] = "matrix",
        [49] = "shift"
    },
    sequencer = {
        name = "sequencer",
        cc = 50,
        setActive = function (obj)
            for i = 0, 127 do
                if obj.controlCurrent.cc[i] and obj.controlCurrent.cc[i].hasLED then
                    obj.controlCurrent.cc[i].value = (Mode.sequencer.LEDs[i] and Mode.sequencer.LEDs[i].value) or Push.control.cc[i].value
                end
            end

            obj.controlCurrent.cc[60].value = ((song.tracks[obj.activeTrack].mute_state ~= 1) and Push.button_light.high + Push.blink.slow) or Push.button_light.low
            obj.controlCurrent.cc[44].value = (obj.activeTrack == 1 and Push.button_light.off) or Push.button_light.low 
            obj.controlCurrent.cc[45].value = (obj.activeTrack == (song.sequencer_track_count + song.send_track_count + 1) and Push.button_light.off) or Push.button_light.low 

            writeSequence(obj, {0, 0, 0})
            
            obj.displayState.line[1].zone[1] = song.tracks[obj.activeTrack].name
           
        end,
        action = function (obj, data)
            if (data[1] == 144 or data[1] == 128) and data[2] > 35 and data[2] < 100 then
                insertNote(obj, data)
                writeSequence(obj, {0, 0, 0})
            elseif data[1] == 176 and data[2] == 85 then
                Mode.play.action(obj, data[3])
            elseif data[1] == 176 and data[2] == 86 then
                Mode.edit.action(obj, data[3])
            elseif data[1] == 176 and data[2] == 14 then
                writeSequence(obj, data)
            elseif data[1] == 176 and data[2] == 60 then
                local muted = song.tracks[obj.activeTrack].mute_state ~= 1
                if data[3] > 0 then
                    if muted then song.tracks[obj.activeTrack]:unmute() else song.tracks[obj.activeTrack]:mute() end
                    obj.controlCurrent.cc[data[2]].value = ((song.tracks[obj.activeTrack].mute_state ~= 1) and Push.button_light.high + Push.blink.slow) or Push.button_light.low
                end
            elseif data[1] == 176 and (data[2] == 46 or data[2] == 47) then
                writeSequence(obj, data)
            elseif data[1] == 176 and (data[2] == 44 or data[2] == 45) then
                changeTrack(obj, data)
            else
                return
            end
            obj.dirty = true
        end,
        LEDs = {
            [29] = {name = "stop", value = Push.button_light.off},
            [50] = {name = "note", value = Push.button_light.high},
            [43] = {name = "x32t", value = Push.button_light.off},
            [42] = {name = "x32", value = Push.button_light.off},
            [41] = {name = "x16t", value = Push.button_light.off},
            [40] = {name = "x16", value = Push.button_light.off},
            [39] = {name = "x8t", value = Push.button_light.off},
            [38] = {name = "x8", value = Push.button_light.off},
            [37] = {name = "x4t", value = Push.button_light.off},
            [36] = {name = "x4", value = Push.button_light.off},
        }
    },
    track = {
        name = "track",
        setActive = function (obj)
            for i = 102, 109 do 
                Mode.track.LEDs[i].value = ((song.tracks[obj.activeTrack + i - 102].mute_state == 1) and Push.pad_light.pink) or 0
            end
            for i = 0, 127 do
                if obj.controlCurrent.cc[i] and obj.controlCurrent.cc[i].hasLED then
                    obj.controlCurrent.cc[i].value = (Mode.track.LEDs[i] and Mode.track.LEDs[i].value) or Push.control.cc[i].value
                end
                if obj.controlCurrent.note[i] and obj.controlCurrent.note[i].hasLED then
                    obj.controlCurrent.note[i].value = 0
                end
            end
            for i = 1, 4 do
                for j = 1, 8 do
                    obj.displayState.line[i].zone[j] = ""
                end
            end
        end,
        action = function (obj, data)
            if (data[1] == 144 or data[1] == 128) and data[2] > 35 and data[2] < 100 then
                receiveNote(obj, data)
            elseif data[1] == 176 and data[2] == 85 then
                Mode.play.action(obj, data[3])
            elseif data[1] == 176 and data[2] == 86 then
                Mode.edit.action(obj, data[3])
            elseif data[1] == 176 and data[2] >= 102 and data[2] <= 109 then
                local muted = song.tracks[obj.activeTrack + data[2] - 102].mute_state ~= 1
                if data[3] > 0 then
                    if muted then song.tracks[obj.activeTrack + data[2] - 102]:unmute() else song.tracks[obj.activeTrack + data[2] - 102]:mute() end
                    obj.controlCurrent.cc[data[2]].value = ((song.tracks[obj.activeTrack + data[2] - 102].mute_state == 1) and Push.pad_light.pink) or 0
                end
            else
                return
            end
            obj.dirty = true
        end,
        LEDs = {
            [79] = {name = "volume", value = Push.button_light.low},
            [14] = {name = "tempo", value = Push.button_light.low},
            [15] = {name = "swing", value = Push.button_light.low},
            [3] = {name = "tap_tempo", value = Push.button_light.low},
            [9] = {name = "metronome", value = Push.button_light.low},
            [119] = {name = "undo", value = Push.button_light.low},
            [118] = {name = "delete", value = Push.button_light.low},
            [117] = {name = "double", value = Push.button_light.low},
            [116] = {name = "quantize", value = Push.button_light.low},
            [90] = {name = "fixed_length", value = Push.button_light.low},
            [89] = {name = "automation", value = Push.button_light.low},
            [88] = {name = "duplicate", value = Push.button_light.low},
            [87] = {name = "new", value = Push.button_light.low},
            [86] = {name = "record", value = Push.button_light.low},
            [85] = {name = "play", value = Push.button_light.low},
            [28] = {name = "master", value = Push.button_light.low},
            [29] = {name = "stop", value = Push.button_light.low},
            [43] = {name = "x32t", value = Push.button_light.low},
            [42] = {name = "x32", value = Push.button_light.low},
            [41] = {name = "x16t", value = Push.button_light.low},
            [40] = {name = "x16", value = Push.button_light.low},
            [39] = {name = "x8t", value = Push.button_light.low},
            [38] = {name = "x8", value = Push.button_light.low},
            [37] = {name = "x4t", value = Push.button_light.low},
            [36] = {name = "x4", value = Push.button_light.low},
            [114] = {name = "volume", value = Push.button_light.low},
            [115] = {name = "pan_send", value = Push.button_light.low},
            [112] = {name = "track", value = Push.button_light.high},
            [113] = {name = "clip", value = Push.button_light.low},
            [110] = {name = "device", value = Push.button_light.low},
            [111] = {name = "browse", value = Push.button_light.low},
            [62] = {name = "level_down", value = Push.button_light.low},
            [63] = {name = "level_up", value = Push.button_light.low},
            [60] = {name = "mute", value = Push.button_light.low},
            [61] = {name = "solo", value = Push.button_light.low},
            [58] = {name = "scales", value = Push.button_light.low},
            [59] = {name = "user", value = Push.button_light.low},
            [56] = {name = "_repeat", value = Push.button_light.low},
            [57] = {name = "accent", value = Push.button_light.low},
            [54] = {name = "oct_down", value = Push.button_light.low},
            [55] = {name = "oct_up", value = Push.button_light.low},
            [52] = {name = "add_effect", value = Push.button_light.low},
            [53] = {name = "add_track", value = Push.button_light.low},
            [50] = {name = "note", value = Push.button_light.low},
            [51] = {name = "session", value = Push.button_light.low},
            [48] = {name = "select", value = Push.button_light.low},
            [49] = {name = "shift", value = Push.button_light.low},
            [46] = {name = "csr_up", value = Push.button_light.low},
            [47] = {name = "csr_down", value = Push.button_light.low},
            [44] = {name = "csr_left", value = Push.button_light.low},
            [45] = {name = "csr_right", value = Push.button_light.low},
            [20] = {name = "softkey1A", value = Push.button_light.low},
            [21] = {name = "softkey2A", value = Push.button_light.low},
            [22] = {name = "softkey3A", value = Push.button_light.low},
            [23] = {name = "softkey4A", value = Push.button_light.low},
            [24] = {name = "softkey5A", value = Push.button_light.low},
            [25] = {name = "softkey6A", value = Push.button_light.low},
            [26] = {name = "softkey7A", value = Push.button_light.low},
            [27] = {name = "softkey8A", value = Push.button_light.low},
            [102] = {name = "softkey1B", value = Push.button_light.low},
            [103] = {name = "softkey2B", value = Push.button_light.low},
            [104] = {name = "softkey3B", value = Push.button_light.low},
            [105] = {name = "softkey4B", value = Push.button_light.low},
            [106] = {name = "softkey5B", value = Push.button_light.low},
            [107] = {name = "softkey6B", value = Push.button_light.low},
            [108] = {name = "softkey7B", value = Push.button_light.low},
            [109] = {name = "softkey8B", value = Push.button_light.low}
        }
    },
    instrument = {
        name = "instrument",
        setActive = function (obj)
            for i = 0, 127 do
                if obj.controlCurrent.cc[i] and obj.controlCurrent.cc[i].hasLED then
                    obj.controlCurrent.cc[i].value = Mode.instrument.LEDs[i].value
                end
                if obj.controlCurrent.note[i] and obj.controlCurrent.note[i].hasLED then
                    obj.controlCurrent.note[i].value = 0
                end
            end
            for i = 1, 4 do
                for j = 1, 8 do
                    obj.displayState.line[i].zone[j] = ""
                end
            end
        end,
        action = function (obj, data)
            if (data[1] == 144 or data[1] == 128) and data[2] > 35 and data[2] < 100 then
                receiveNote(obj, data)
            elseif data[1] == 176 and data[2] == 85 then
                Mode.play.action(obj, data[3])
            elseif data[1] == 176 and data[2] == 86 then
                Mode.edit.action(obj, data[3])
            else
                return
            end
            obj.dirty = true
        end,
        LEDs = {
            [79] = {name = "volume", value = Push.button_light.low},
            [14] = {name = "tempo", value = Push.button_light.low},
            [15] = {name = "swing", value = Push.button_light.low},
            [3] = {name = "tap_tempo", value = Push.button_light.low},
            [9] = {name = "metronome", value = Push.button_light.low},
            [119] = {name = "undo", value = Push.button_light.low},
            [118] = {name = "delete", value = Push.button_light.low},
            [117] = {name = "double", value = Push.button_light.low},
            [116] = {name = "quantize", value = Push.button_light.low},
            [90] = {name = "fixed_length", value = Push.button_light.low},
            [89] = {name = "automation", value = Push.button_light.low},
            [88] = {name = "duplicate", value = Push.button_light.low},
            [87] = {name = "new", value = Push.button_light.low},
            [86] = {name = "record", value = Push.button_light.low},
            [85] = {name = "play", value = Push.button_light.low},
            [28] = {name = "master", value = Push.button_light.low},
            [29] = {name = "stop", value = Push.button_light.low},
            [43] = {name = "x32t", value = Push.button_light.low},
            [42] = {name = "x32", value = Push.button_light.low},
            [41] = {name = "x16t", value = Push.button_light.low},
            [40] = {name = "x16", value = Push.button_light.low},
            [39] = {name = "x8t", value = Push.button_light.low},
            [38] = {name = "x8", value = Push.button_light.low},
            [37] = {name = "x4t", value = Push.button_light.low},
            [36] = {name = "x4", value = Push.button_light.low},
            [114] = {name = "volume", value = Push.button_light.low},
            [115] = {name = "pan_send", value = Push.button_light.low},
            [112] = {name = "track", value = Push.button_light.low},
            [113] = {name = "clip", value = Push.button_light.low},
            [110] = {name = "device", value = Push.button_light.high},
            [111] = {name = "browse", value = Push.button_light.low},
            [62] = {name = "level_down", value = Push.button_light.low},
            [63] = {name = "level_up", value = Push.button_light.low},
            [60] = {name = "mute", value = Push.button_light.low},
            [61] = {name = "solo", value = Push.button_light.low},
            [58] = {name = "scales", value = Push.button_light.low},
            [59] = {name = "user", value = Push.button_light.low},
            [56] = {name = "_repeat", value = Push.button_light.low},
            [57] = {name = "accent", value = Push.button_light.low},
            [54] = {name = "oct_down", value = Push.button_light.low},
            [55] = {name = "oct_up", value = Push.button_light.low},
            [52] = {name = "add_effect", value = Push.button_light.low},
            [53] = {name = "add_track", value = Push.button_light.low},
            [50] = {name = "note", value = Push.button_light.low},
            [51] = {name = "session", value = Push.button_light.low},
            [48] = {name = "select", value = Push.button_light.low},
            [49] = {name = "shift", value = Push.button_light.low},
            [46] = {name = "csr_up", value = Push.button_light.low},
            [47] = {name = "csr_down", value = Push.button_light.low},
            [44] = {name = "csr_left", value = Push.button_light.low},
            [45] = {name = "csr_right", value = Push.button_light.low},
            [20] = {name = "softkey1A", value = Push.button_light.low},
            [21] = {name = "softkey2A", value = Push.button_light.low},
            [22] = {name = "softkey3A", value = Push.button_light.low},
            [23] = {name = "softkey4A", value = Push.button_light.low},
            [24] = {name = "softkey5A", value = Push.button_light.low},
            [25] = {name = "softkey6A", value = Push.button_light.low},
            [26] = {name = "softkey7A", value = Push.button_light.low},
            [27] = {name = "softkey8A", value = Push.button_light.low},
            [102] = {name = "softkey1B", value = Push.button_light.low},
            [103] = {name = "softkey2B", value = Push.button_light.low},
            [104] = {name = "softkey3B", value = Push.button_light.low},
            [105] = {name = "softkey4B", value = Push.button_light.low},
            [106] = {name = "softkey5B", value = Push.button_light.low},
            [107] = {name = "softkey6B", value = Push.button_light.low},
            [108] = {name = "softkey7B", value = Push.button_light.low},
            [109] = {name = "softkey8B", value = Push.button_light.low}
        }
    },
    matrix = {
        name = "matrix",
        setActive = function (obj)
            for i = 0, 127 do
                if obj.controlCurrent.cc[i] and obj.controlCurrent.cc[i].hasLED then
                    obj.controlCurrent.cc[i].value = Mode.matrix.LEDs[i].value
                end
                if obj.controlCurrent.note[i] and obj.controlCurrent.note[i].hasLED then
                    obj.controlCurrent.note[i].value = 0
                end
            end
            for i = 1, 4 do
                for j = 1, 8 do
                    obj.displayState.line[i].zone[j] = ""
                end
            end
        end,
        action = function (obj, data)
            if (data[1] == 144 or data[1] == 128) and data[2] > 35 and data[2] < 100 then
                receiveNote(obj, data)
            elseif data[1] == 176 and data[2] == 85 then
                Mode.play.action(obj, data[3])
            elseif data[1] == 176 and data[2] == 86 then
                Mode.edit.action(obj, data[3])
            else
                return
            end
            obj.dirty = true
        end,
        LEDs = {
            [79] = {name = "volume", value = Push.button_light.low},
            [14] = {name = "tempo", value = Push.button_light.low},
            [15] = {name = "swing", value = Push.button_light.low},
            [3] = {name = "tap_tempo", value = Push.button_light.low},
            [9] = {name = "metronome", value = Push.button_light.low},
            [119] = {name = "undo", value = Push.button_light.low},
            [118] = {name = "delete", value = Push.button_light.low},
            [117] = {name = "double", value = Push.button_light.low},
            [116] = {name = "quantize", value = Push.button_light.low},
            [90] = {name = "fixed_length", value = Push.button_light.low},
            [89] = {name = "automation", value = Push.button_light.low},
            [88] = {name = "duplicate", value = Push.button_light.low},
            [87] = {name = "new", value = Push.button_light.low},
            [86] = {name = "record", value = Push.button_light.low},
            [85] = {name = "play", value = Push.button_light.low},
            [28] = {name = "master", value = Push.button_light.low},
            [29] = {name = "stop", value = Push.button_light.low},
            [43] = {name = "x32t", value = Push.button_light.low},
            [42] = {name = "x32", value = Push.button_light.low},
            [41] = {name = "x16t", value = Push.button_light.low},
            [40] = {name = "x16", value = Push.button_light.low},
            [39] = {name = "x8t", value = Push.button_light.low},
            [38] = {name = "x8", value = Push.button_light.low},
            [37] = {name = "x4t", value = Push.button_light.low},
            [36] = {name = "x4", value = Push.button_light.low},
            [114] = {name = "volume", value = Push.button_light.low},
            [115] = {name = "pan_send", value = Push.button_light.low},
            [112] = {name = "track", value = Push.button_light.low},
            [113] = {name = "clip", value = Push.button_light.low},
            [110] = {name = "device", value = Push.button_light.low},
            [111] = {name = "browse", value = Push.button_light.low},
            [62] = {name = "level_down", value = Push.button_light.low},
            [63] = {name = "level_up", value = Push.button_light.low},
            [60] = {name = "mute", value = Push.button_light.low},
            [61] = {name = "solo", value = Push.button_light.low},
            [58] = {name = "scales", value = Push.button_light.low},
            [59] = {name = "user", value = Push.button_light.low},
            [56] = {name = "_repeat", value = Push.button_light.low},
            [57] = {name = "accent", value = Push.button_light.low},
            [54] = {name = "oct_down", value = Push.button_light.low},
            [55] = {name = "oct_up", value = Push.button_light.low},
            [52] = {name = "add_effect", value = Push.button_light.low},
            [53] = {name = "add_track", value = Push.button_light.low},
            [50] = {name = "note", value = Push.button_light.low},
            [51] = {name = "session", value = Push.button_light.high},
            [48] = {name = "select", value = Push.button_light.low},
            [49] = {name = "shift", value = Push.button_light.low},
            [46] = {name = "csr_up", value = Push.button_light.low},
            [47] = {name = "csr_down", value = Push.button_light.low},
            [44] = {name = "csr_left", value = Push.button_light.low},
            [45] = {name = "csr_right", value = Push.button_light.low},
            [20] = {name = "softkey1A", value = Push.button_light.low},
            [21] = {name = "softkey2A", value = Push.button_light.low},
            [22] = {name = "softkey3A", value = Push.button_light.low},
            [23] = {name = "softkey4A", value = Push.button_light.low},
            [24] = {name = "softkey5A", value = Push.button_light.low},
            [25] = {name = "softkey6A", value = Push.button_light.low},
            [26] = {name = "softkey7A", value = Push.button_light.low},
            [27] = {name = "softkey8A", value = Push.button_light.low},
            [102] = {name = "softkey1B", value = Push.button_light.low},
            [103] = {name = "softkey2B", value = Push.button_light.low},
            [104] = {name = "softkey3B", value = Push.button_light.low},
            [105] = {name = "softkey4B", value = Push.button_light.low},
            [106] = {name = "softkey5B", value = Push.button_light.low},
            [107] = {name = "softkey6B", value = Push.button_light.low},
            [108] = {name = "softkey7B", value = Push.button_light.low},
            [109] = {name = "softkey8B", value = Push.button_light.low}
        }
    },
    shift = {
        name = "shift",
        setActive = function (obj, value)
            if value == 0 then
                obj.shiftActive = false
            else 
                obj.shiftActive = true
            end
        end
    },
    play = {
        name = "play",
        setActive = function (obj)
            if song.transport.playing then
                obj.controlCurrent.cc[85].value = 4
            else 
                obj.controlCurrent.cc[85].value = 1
            end
            obj.dirty = true
        end,
        action = function (obj, value)
            if value == 0 then return end
            local playing = song.transport.playing and obj.controlCurrent.cc[85].value == 4
            if playing then
                song.transport:stop()
                obj.controlCurrent.cc[85].value = 1
            else
                local mode
                if obj.shiftActive then
                    mode = renoise.Transport.PLAYMODE_CONTINUE_PATTERN
                else 
                    mode = renoise.Transport.PLAYMODE_RESTART_PATTERN
                end
                song.transport:start(mode)
                obj.controlCurrent.cc[85].value = 4
            end
        end
    },
    edit = {
        name = "edit",
        setActive = function (obj)
            if song.transport.edit_mode then
                obj.controlCurrent.cc[86].value = 4
            else 
                obj.controlCurrent.cc[86].value = 1
            end
            obj.dirty = true
        end,
        action = function (obj, value)
            if value == 0 then return end
            local editing = song.transport.edit_mode and obj.controlCurrent.cc[86].value == 4
            if editing then
                song.transport.edit_mode = false
                obj.controlCurrent.cc[86].value = 1
            else
                song.transport.edit_mode = true
                obj.controlCurrent.cc[86].value = 4
            end
        end
    }
}

function encoderParse (value)
    if value == 0 then return 0
    elseif value < 64 then return value else return -1 * (128 - value) end
end

function receiveNote (obj, data)
    if data[1] == 144 then 
        table.insert(obj.noteOns, data[2], obj.controlCurrent.note[data[2]].value)
        obj.controlCurrent.note[data[2]].value = 5
    elseif data[1] == 128 then
        obj.controlCurrent.note[data[2]].value = obj.noteOns[data[2]]
        table.remove(obj.noteOns, data[2])
    end
end

function setLine (obj, data)
    local pos = song.transport.playback_pos
    local shift_mult = (obj.shiftActive and 10) or 1
    if data[2] == 14 then 
        pos.line = pos.line + encoderParse(data[3]) * shift_mult
    elseif (data[2] == 46 or data[2] == 47) and data[3] > 0 then
        pos.line = pos.line + (((data[2] - 46 == 1) and 1) or -1) * shift_mult
    end
    if pos.line < 1 then 
        pos.line = 1 
    elseif pos.line > song.patterns[pos.sequence].number_of_lines then 
        pos.line = song.patterns[pos.sequence].number_of_lines 
    end
    song.transport.playback_pos = pos
    return pos
end

function writeSequence (obj, data)
    local pos = setLine(obj, data)
    for i = 36, 99 do
        if obj.controlCurrent.note[i] and obj.controlCurrent.note[i].hasLED then
            obj.controlCurrent.note[i].value = 1
        end
    end
    for i = 0, 7 do
        if pos.line < 5 then 
            obj.controlCurrent.note[(92 - ((pos.line - 1) * 8)) + i].value = Push.pad_light.pale_mint_blue
        elseif song.patterns[pos.sequence].number_of_lines > 8 and song.patterns[pos.sequence].number_of_lines - pos.line < 5 then 
            obj.controlCurrent.note[(92 - ((7 - (song.patterns[pos.sequence].number_of_lines - pos.line)) * 8)) + i].value = Push.pad_light.pale_mint_blue
        else
            obj.controlCurrent.note[68 + i].value = Push.pad_light.pale_mint_blue
        end
    end
    if pos.line == 1 then 
        obj.controlCurrent.cc[46].value = Push.button_light.off
    elseif pos.line == song.patterns[pos.sequence].number_of_lines then
        obj.controlCurrent.cc[47].value = Push.button_light.off
    else
        obj.controlCurrent.cc[46].value = Push.button_light.low
        obj.controlCurrent.cc[47].value = Push.button_light.low
    end
    if pos.line < 5 then pos.line = 4 elseif song.patterns[pos.sequence].number_of_lines > 15 and (pos.line > song.patterns[pos.sequence].number_of_lines - 7) then pos.line = song.patterns[pos.sequence].number_of_lines - 7 end
    if song.patterns[1].is_empty then return end
    if song.tracks[obj.activeTrack].type == renoise.Track.TRACK_TYPE_MASTER or song.tracks[obj.activeTrack].type == renoise.Track.TRACK_TYPE_SEND then return end
    local j = 0
    for i = pos.line - 3, pos.line + 4 do   
        local note      
        local line
        if song.patterns[1].tracks[obj.activeTrack].lines[i] then 
            line = song.patterns[1].tracks[obj.activeTrack].lines[i]:note_column(1) 
            note = Push.note_table[string.sub(line.note_string, 1, 1)]
        end
        if note then obj.controlCurrent.note[(92 - (j * 8)) + note].value = Push.pad_light.super_blue end
        j = j + 1
    end
end

function setActiveTrack (obj) 
    obj.activeTrack = song.selected_track_index
    obj.displayState.line[1].zone[1] = song.tracks[obj.activeTrack].name
    writeSequence(obj, {0, 0, 0})
    obj.dirty = true 
end

function changeTrack (obj, data)
    if data[3] == 0 then return end
    if data[2] == 45 then
        if obj.activeTrack == song.sequencer_track_count + song.send_track_count + 1 then return end
        obj.controlCurrent.cc[45].value = (obj.activeTrack + 1 == (song.sequencer_track_count + song.send_track_count + 1) and Push.button_light.off) or Push.button_light.low 
        obj.controlCurrent.cc[44].value = (obj.controlCurrent.cc[44].value == 0 and Push.button_light.low) or obj.controlCurrent.cc[44].value
        song:select_next_track()
    elseif data[2] == 44 then
        if obj.activeTrack == 1 then return end
        obj.controlCurrent.cc[44].value = (obj.activeTrack - 1 == 1 and Push.button_light.off) or Push.button_light.low 
        obj.controlCurrent.cc[45].value = (obj.controlCurrent.cc[45].value == 0 and Push.button_light.low) or obj.controlCurrent.cc[45].value
        song:select_previous_track()
    end
end

function insertNote (obj, data)
    --renoise note value 0 = C-0 119, = B-9
    local pos = setLine(obj, {0,0,0})
    local note = Push.note_table[(data[2] - 36) % 8]
    local line = math.floor((99 - data[2]) / 8)
    if pos.line < 4 then 
        line = line - (pos.line - 1) 
    elseif pos.line > (song.patterns[pos.sequence].number_of_lines - 4) then 
        line = line - (7 + (song.patterns[pos.sequence].number_of_lines - pos.line))
    else 
        line = line - 3 
    end
    if data[1] == 144 then 
        print(note, line) 
        if note == "OFF" then
            if note == song.patterns[1].tracks[obj.activeTrack].lines[pos.line + line].note_columns[1].note_string then song.patterns[1].tracks[obj.activeTrack].lines[pos.line + line].note_columns[1].note_string = "---"
            else
                song.patterns[1].tracks[obj.activeTrack].lines[pos.line + line].note_columns[1].note_string = note 
            end
        elseif note then 
            local str = note .. "-" .. song.transport.octave
            if str == song.patterns[1].tracks[obj.activeTrack].lines[pos.line + line].note_columns[1].note_string then song.patterns[1].tracks[obj.activeTrack].lines[pos.line + line].note_columns[1].note_string = "---"
            else
                song.patterns[1].tracks[obj.activeTrack].lines[pos.line + line].note_columns[1].note_string = str
            end
        end
    end
    --respect record state
    --set current line if flag is true
    --play note if flag is true
end