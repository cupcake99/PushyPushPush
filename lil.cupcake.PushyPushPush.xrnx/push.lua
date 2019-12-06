class "Push"

function Push:__init()    
    self.device_name = Push.device_name
    self.output = {}
    self.input = {}
    self.active_mode = ""
    self.activeTrack = nil
    self.displayState = {
        line = {
            {zone = {"", "", "", "", "", "", "", ""}}, 
            {zone = {"", "", "", "", "", "", "", ""}}, 
            {zone = {"", "", "", "", "", "", "", ""}}, 
            {zone = {"", "", "", "", "", "", "", ""}}
        }
    }
    self.displayLineSysex = {}
    self.controlCurrent = table.rcopy(Push.control)
    self.controlLast = self.controlCurrent
    self.shiftActive = false
    self.dirty = false
    self.noteOns = {}
end

Push.device_name = "Ableton Push (User Port)"


-- CC value for the various lighting modes of the button LEDs
Push.button_light = {
    low = 1, 
    high = 4, 
    off = 0
}

Push.noteval_light = {
    dim_red = 1,
    red = 4,
    dim_orange = 7,
    orange = 10,
    dim_yellow = 13,
    yellow = 16,
    dark_green = 19,
    light_green = 22,
    off = 0
}

-- add this to a button or noteval button light setting to get a blink
Push.blink = {
    slow = 1,
    fast = 2
}

-- too many bloody colours to list here until the main programming is done
Push.pad_light = {
    dark_grey = 1, 
    light_grey = 2, 
    white = 3, 
    pink = 4, 
    strong_red = 5, 
    mid_red = 6, 
    dim_red = 7, 
    beige = 8, 
    strong_orange = 9, 
    mid_orange = 10,
    dim_orange = 11,
    pale_yellow = 12,
    strong_yellow = 13,
    mid_yellow = 14,
    dim_yellow = 15,
    pale_pea = 16,
    pea_green = 17,
    mid_pea = 18,
    dim_pea = 19,
    pale_green = 20,
    strong_green = 21,
    mid_green = 22,
    dim_green = 23,
    pale_green_2 = 24,
    neon_green = 25,
    dim_neon_green = 26,
    dim_green_2 = 27,
    pale_green_3 = 28,
    sea_green = 29,
    mid_sea = 30,
    dim_sea = 31,
    pale_teal = 32,
    strong_teal = 33,
    mid_teal = 34,
    dim_teal = 35,
    pale_sky_blue = 36,
    strong_sky_blue = 37,
    mid_sky_blue = 38,
    dim_sky_blue = 39,
    pale_mint_blue = 40,
    strong_mint_blue = 41,
    mid_mint_blue = 42,
    dim_mint_blue = 43,
    pale_blue = 44,
    super_blue = 45,
    mid_super_blue = 46,
    dim_super_blue = 47,
    pale_purple = 48,
    strong_purple = 49,
    mid_purple = 50,
    dim_purple = 51,
    pale_cerise = 52,
    strong_cerise = 53,
    mid_cerise = 54,
    dim_cerise = 55,
    pale_neon_pink = 56,
    neon_pink = 57,
    mid_neon_pink = 58,
    dim_neon_pink = 59,
    
    off = 0
}

-- MIDI channel sets the pad lighting mode. fade goes from white to colour value. Saw oscillates in a saw wave. Square oscillates in 
-- a square wave surprisingly. They are in order from fastest to slowest for each option respectively.
Push.channel = {
    on = 0,
    fade_1 = 1,
    fade_2 = 2,
    fade_3 = 3,
    fade_4 = 4,
    fade_5 = 5,
    saw_1 = 6,
    saw_2 = 7,
    saw_3 = 8,
    saw_4 = 9,
    saw_5 = 10,
    square_1 = 11,
    square_2 = 12,
    square_3 = 13,
    square_4 = 14,
    square_5 = 15
}

Push.control = {
    cc = {
    [71] = {name = "dial1", value = 0, hasLED = false},
    [72] = {name = "dial2", value = 0, hasLED = false},
    [73] = {name = "dial3", value = 0, hasLED = false},
    [74] = {name = "dial4", value = 0, hasLED = false},
    [75] = {name = "dial5", value = 0, hasLED = false},
    [76] = {name = "dial6", value = 0, hasLED = false},
    [77] = {name = "dial7", value = 0, hasLED = false},
    [78] = {name = "dial8", value = 0, hasLED = false},
    [79] = {name = "volume", value = 0, hasLED = false},
    [14] = {name = "tempo", value = 0, hasLED = false},
    [15] = {name = "swing", value = 0, hasLED = false},
    [3] = {name = "tap_tempo", value = Push.button_light.low, hasLED = true},
    [9] = {name = "metronome", value = Push.button_light.low, hasLED = true},
    [119] = {name = "undo", value = Push.button_light.low, hasLED = true},
    [118] = {name = "delete", value = Push.button_light.low, hasLED = true},
    [117] = {name = "double", value = Push.button_light.low, hasLED = true},
    [116] = {name = "quantize", value = Push.button_light.low, hasLED = true},
    [90] = {name = "fixed_length", value = Push.button_light.low, hasLED = true},
    [89] = {name = "automation", value = Push.button_light.low, hasLED = true},
    [88] = {name = "duplicate", value = Push.button_light.low, hasLED = true},
    [87] = {name = "new", value = Push.button_light.low, hasLED = true},
    [86] = {name = "record", value = Push.button_light.low, hasLED = true},
    [85] = {name = "play", value = Push.button_light.low, hasLED = true},
    [28] = {name = "master", value = Push.button_light.low, hasLED = true},
    [29] = {name = "stop", value = Push.button_light.low, hasLED = true},
    [43] = {name = "x32t", value = Push.button_light.low, hasLED = true},
    [42] = {name = "x32", value = Push.button_light.low, hasLED = true},
    [41] = {name = "x16t", value = Push.button_light.low, hasLED = true},
    [40] = {name = "x16", value = Push.button_light.low, hasLED = true},
    [39] = {name = "x8t", value = Push.button_light.low, hasLED = true},
    [38] = {name = "x8", value = Push.button_light.low, hasLED = true},
    [37] = {name = "x4t", value = Push.button_light.low, hasLED = true},
    [36] = {name = "x4", value = Push.button_light.low, hasLED = true},
    [114] = {name = "volume", value = Push.button_light.low, hasLED = true},
    [115] = {name = "pan_send", value = Push.button_light.low, hasLED = true},
    [112] = {name = "track", value = Push.button_light.low, hasLED = true},
    [113] = {name = "clip", value = Push.button_light.low, hasLED = true},
    [110] = {name = "device", value = Push.button_light.low, hasLED = true},
    [111] = {name = "browse", value = Push.button_light.low, hasLED = true},
    [62] = {name = "level_down", value = Push.button_light.low, hasLED = true},
    [63] = {name = "level_up", value = Push.button_light.low, hasLED = true},
    [60] = {name = "mute", value = Push.button_light.low, hasLED = true},
    [61] = {name = "solo", value = Push.button_light.low, hasLED = true},
    [58] = {name = "scales", value = Push.button_light.low, hasLED = true},
    [59] = {name = "user", value = Push.button_light.low, hasLED = true},
    [56] = {name = "_repeat", value = Push.button_light.low, hasLED = true},
    [57] = {name = "accent", value = Push.button_light.low, hasLED = true},
    [54] = {name = "oct_down", value = Push.button_light.low, hasLED = true},
    [55] = {name = "oct_up", value = Push.button_light.low, hasLED = true},
    [52] = {name = "add_effect", value = Push.button_light.low, hasLED = true},
    [53] = {name = "add_track", value = Push.button_light.low, hasLED = true},
    [50] = {name = "note", value = Push.button_light.low, hasLED = true},
    [51] = {name = "session", value = Push.button_light.low, hasLED = true},
    [48] = {name = "select", value = Push.button_light.low, hasLED = true},
    [49] = {name = "shift", value = Push.button_light.low, hasLED = true},
    [46] = {name = "csr_up", value = Push.button_light.low, hasLED = true},
    [47] = {name = "csr_down", value = Push.button_light.low, hasLED = true},
    [44] = {name = "csr_left", value = Push.button_light.low, hasLED = true},
    [45] = {name = "csr_right", value = Push.button_light.low, hasLED = true},
    [20] = {name = "softkey1A", value = Push.button_light.low, hasLED = true},
    [21] = {name = "softkey2A", value = Push.button_light.low, hasLED = true},
    [22] = {name = "softkey3A", value = Push.button_light.low, hasLED = true},
    [23] = {name = "softkey4A", value = Push.button_light.low, hasLED = true},
    [24] = {name = "softkey5A", value = Push.button_light.low, hasLED = true},
    [25] = {name = "softkey6A", value = Push.button_light.low, hasLED = true},
    [26] = {name = "softkey7A", value = Push.button_light.low, hasLED = true},
    [27] = {name = "softkey8A", value = Push.button_light.low, hasLED = true},
    [102] = {name = "softkey1B", value = Push.pad_light.pink, hasLED = true},
    [103] = {name = "softkey2B", value = Push.pad_light.pink, hasLED = true},
    [104] = {name = "softkey3B", value = Push.pad_light.pink, hasLED = true},
    [105] = {name = "softkey4B", value = Push.pad_light.pink, hasLED = true},
    [106] = {name = "softkey5B", value = Push.pad_light.pink, hasLED = true},
    [107] = {name = "softkey6B", value = Push.pad_light.pink, hasLED = true},
    [108] = {name = "softkey7B", value = Push.pad_light.pink, hasLED = true},
    [109] = {name = "softkey8B", value = Push.pad_light.pink, hasLED = true}
    },
    note = {
        [0] = {name = "dial1", value = 0, hasLED = false},
        [1] = {name = "dial2", value = 0, hasLED = false},
        [2] = {name = "dial3", value = 0, hasLED = false},
        [3] = {name = "dial4", value = 0, hasLED = false},
        [4] = {name = "dial5", value = 0, hasLED = false},
        [5] = {name = "dial6", value = 0, hasLED = false},
        [6] = {name = "dial7", value = 0, hasLED = false},
        [7] = {name = "dial8", value = 0, hasLED = false},
        [8] = {name = "volume", value = 0, hasLED = false},
        [9] = {name = "swing", value = 0, hasLED = false},
        [10] = {name = "tempo", value = 0, hasLED = false},
        [36] = {name = "pad01", value = 0, hasLED = true}, 
        [37] = {name = "pad02", value = 0, hasLED = true}, 
        [38] = {name = "pad03", value = 0, hasLED = true}, 
        [39] = {name = "pad04", value = 0, hasLED = true}, 
        [40] = {name = "pad05", value = 0, hasLED = true}, 
        [41] = {name = "pad06", value = 0, hasLED = true}, 
        [42] = {name = "pad07", value = 0, hasLED = true}, 
        [43] = {name = "pad08", value = 0, hasLED = true},
        [44] = {name = "pad09", value = 0, hasLED = true}, 
        [45] = {name = "pad10", value = 0, hasLED = true}, 
        [46] = {name = "pad11", value = 0, hasLED = true}, 
        [47] = {name = "pad12", value = 0, hasLED = true}, 
        [48] = {name = "pad13", value = 0, hasLED = true}, 
        [49] = {name = "pad14", value = 0, hasLED = true}, 
        [50] = {name = "pad15", value = 0, hasLED = true}, 
        [51] = {name = "pad16", value = 0, hasLED = true},
        [52] = {name = "pad17", value = 0, hasLED = true}, 
        [53] = {name = "pad18", value = 0, hasLED = true}, 
        [54] = {name = "pad19", value = 0, hasLED = true}, 
        [55] = {name = "pad20", value = 0, hasLED = true}, 
        [56] = {name = "pad21", value = 0, hasLED = true}, 
        [57] = {name = "pad22", value = 0, hasLED = true}, 
        [58] = {name = "pad23", value = 0, hasLED = true}, 
        [59] = {name = "pad24", value = 0, hasLED = true},
        [60] = {name = "pad25", value = 0, hasLED = true}, 
        [61] = {name = "pad26", value = 0, hasLED = true}, 
        [62] = {name = "pad27", value = 0, hasLED = true}, 
        [63] = {name = "pad28", value = 0, hasLED = true}, 
        [64] = {name = "pad29", value = 0, hasLED = true}, 
        [65] = {name = "pad30", value = 0, hasLED = true}, 
        [66] = {name = "pad31", value = 0, hasLED = true}, 
        [67] = {name = "pad32", value = 0, hasLED = true},
        [68] = {name = "pad33", value = 0, hasLED = true}, 
        [69] = {name = "pad34", value = 0, hasLED = true}, 
        [70] = {name = "pad35", value = 0, hasLED = true}, 
        [71] = {name = "pad36", value = 0, hasLED = true}, 
        [72] = {name = "pad37", value = 0, hasLED = true}, 
        [73] = {name = "pad38", value = 0, hasLED = true}, 
        [74] = {name = "pad39", value = 0, hasLED = true}, 
        [75] = {name = "pad40", value = 0, hasLED = true},
        [76] = {name = "pad41", value = 0, hasLED = true}, 
        [77] = {name = "pad42", value = 0, hasLED = true}, 
        [78] = {name = "pad43", value = 0, hasLED = true}, 
        [79] = {name = "pad44", value = 0, hasLED = true}, 
        [80] = {name = "pad45", value = 0, hasLED = true}, 
        [81] = {name = "pad46", value = 0, hasLED = true}, 
        [82] = {name = "pad47", value = 0, hasLED = true}, 
        [83] = {name = "pad48", value = 0, hasLED = true},
        [84] = {name = "pad49", value = 0, hasLED = true}, 
        [85] = {name = "pad50", value = 0, hasLED = true}, 
        [86] = {name = "pad51", value = 0, hasLED = true}, 
        [87] = {name = "pad52", value = 0, hasLED = true}, 
        [88] = {name = "pad53", value = 0, hasLED = true}, 
        [89] = {name = "pad54", value = 0, hasLED = true}, 
        [90] = {name = "pad55", value = 0, hasLED = true}, 
        [91] = {name = "pad56", value = 0, hasLED = true},
        [92] = {name = "pad57", value = 0, hasLED = true}, 
        [93] = {name = "pad58", value = 0, hasLED = true}, 
        [94] = {name = "pad59", value = 0, hasLED = true}, 
        [95] = {name = "pad60", value = 0, hasLED = true}, 
        [96] = {name = "pad61", value = 0, hasLED = true}, 
        [97] = {name = "pad62", value = 0, hasLED = true}, 
        [98] = {name = "pad63", value = 0, hasLED = true}, 
        [99] = {name = "pad64", value = 0, hasLED = true}
    },
    bender = {
        name = "bender", value = 0, hasLED = true
    }
}
-- for setting pad light in sequencer mode. May disappear somewhere else eventually.
Push.note_table = {
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

 function Push:open() 
    if not table.find(renoise.Midi.available_output_devices(), self.device_name) then
        return false
    end
    
    if self.output.is_open then 
        self.output:close()
        print("closing output")
    end
    
    self.output = renoise.Midi.create_output_device(self.device_name)
    print("opening output")

    if self.input.is_open then 
        self.input:close()
        print("closing input")
    end

    self.input = renoise.Midi.create_input_device(self.device_name, {self, Push.handleMidi})
    print("opening input")
    return true
end

function Push:close()
    if self.output.is_open then 
        self.output:close()
        print("closing output")
    end
    if self.input.is_open then 
        self.input:close()
        print("closing input")
    end
end

function Push:start()
    if not self:open() then 
        print("[PushyPushPush]: Cannot find Ableton Push device") 
        if tool:has_timer({self, Push.start}) then
            return
        else
            tool:add_timer({self, Push.start}, 5000)
        end
        return 
    end
    if tool:has_timer({self, Push.start}) then tool:remove_timer({self, Push.start}) end
    Sysex.clearDisplay(self)
    self.activeTrack = song.selected_track_index
    self:changeMode(Mode.sequencer.cc, 127)
    tool.app_idle_observable:add_notifier(self, self.update)
    song.transport.playing_observable:add_notifier(self, Mode.play.setActive)
    song.transport.edit_mode_observable:add_notifier(self, Mode.edit.setActive)
    song.selected_track_index_observable:add_notifier(self, setActiveTrack)
end

function Push:stop()
    Sysex.clearDisplay(self)

    self:close()

    if tool:has_timer({self, Push.start}) then tool:remove_timer({self, Push.start}) end
    if tool.app_idle_observable:has_notifier(self, self.update) then tool.app_idle_observable:remove_notifier(self, self.update) end
    if song.transport.playing_observable:has_notifier(self, Mode.play.setActive) then song.transport.playing_observable:remove_notifier(self, Mode.play.setActive) end
    if song.transport.edit_mode_observable:has_notifier(self, Mode.edit.setActive) then song.transport.edit_mode_observable:remove_notifier(self, Mode.edit.setActive) end
    if song.selected_track_index_observable:has_notifier(self, setActiveTrack) then song.selected_track_index_observable:remove_notifier(self, setActiveTrack) end
end

function Push:handleMidi(message)
    assert(#message == 3)
    if message[1] == 176 and Mode.cc[message[2]] then 
        if self.shiftActive and message[2] ~= 49 then message[2] = message[2] + 128 end
        self:changeMode(message[2], message[3])
        return
    end
    Mode[self.active_mode].action(self, message)
end

function Push:sendMidi(data)
    if self.output.is_open then
        self.output:send(data)
    end
end

function Push:writeText(data, ...)
    local n_args = select('#', ...)
    if data then 
        self:sendMidi(data)
         if n_args > 0 then 
           local t = {...} 
           local line = t[1]
           self.displayLineSysex[line] = data
         end
    end
end

function Push:changeMode(cc, value)
    if not Mode.cc[cc] then return end
    local name = Mode.cc[cc]
    local mode = Mode[name]
    if mode.name == "shift" then mode.setActive(self, value) return end
    if self.active_mode ~= mode.name and value > 1 then
        mode.setActive(self)
        self.dirty = true
        self.active_mode = mode.name
    end
end

function Push:onAction(data)
    Mode[self.active_mode].action(self, data)
end

function Push:update()
    if self.dirty then 
        local data
        local string = table.copy(Sysex.write_line)
        local dummy
        for i = 0, 127 do
            if self.controlCurrent.cc[i] and self.controlCurrent.cc[i].hasLED then
                data = {176, i, self.controlCurrent.cc[i].value}
                self:sendMidi(data)
            end
            if self.controlCurrent.note[i] and self.controlCurrent.note[i].hasLED then
                data = {144, i, self.controlCurrent.note[i].value}
                self:sendMidi(data)
            end
        end
        for i = 1, 4 do
        dummy = string
            for j = 1, 8 do
                if self.displayState.line[i].zone[j] ~= "" then
                    string = Sysex:formatLine(string, self.displayState.line[i].zone[j], i, j)
                end
                if j == 8 and rawequal(string, dummy) then string = Sysex:formatLine(string, "", i)  end
            end
            self:writeText(string, i)
            string = table.copy(Sysex.write_line)
        end
        self.dirty = false
    end
end

--[[
    128 = "note off"
    144 = "note on"
    160 = "aftertouch"
    176 = "control change"
    192 = ""
    208 = ""
    224 = "pitch bend"
]]

