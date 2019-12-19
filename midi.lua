class "Midi"

function Midi:__init(parent)
    self.push = parent
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

Midi.status = {
    note_on = 144,
    note_off = 128,
    aftertouch = 160,
    cc = 176,
    pitch_bend = 224
}

-- template for writing to screen - must be 77 bytes long even if empty
Midi.sysex = {
    write_line = {
        240, 71, 127, 21, 0, 0, 69, 0,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32,
        247
    },

    -- template for clearing line
    clear_line = { 240, 71, 127, 21, 0, 0, 0, 247 },

    -- table of bytes to address each line in write/clear message - sequential line 1-4 for each
    line_number = {
        write = { 24, 25, 26, 27 },
        clear = { 28, 29, 30, 31 }
    },

    -- offset for each 'zone' under the encoders - sequential 1-8
    zone = { 0, 9, 17, 26, 34, 43, 51, 60 }
}

function Midi:handleMidi(data)
    assert(#data == 3)
    local control
    if data[1] == Midi.status.note_on then control = getControlFromType("note", data[2])
    elseif data[1] == Midi.status.cc then control = getControlFromType("cc", data[2]) end
    -- if not control then return end
    -- rprint(control)
    if control and control.hasCC then
        if control.name == "shift" then self.push.state:shift(data) return end
        if control.name == "play" then self.push.state:play(data) return end
        if control.name == "record" then self.push.state:edit(data) return end
        if self.push.state:changeMode(data) then return end
    end
    self.push.state.activeMode.action(self.push.modes, data)
end

function Midi:sendMidi(data)
    if self.push.output.is_open then
        self.push.output:send(data)
    end
end

function Midi:encoderParse (data, thinningLevel)
    if data[3] == 0 then return 0 end
    if #self.push.encoderStream ~= 0 and self.push.encoderStream[#self.push.encoderStream].cc ~= data[2] then self.push.encoderStream = {} end
    if thinningLevel then
        table.insert(self.push.encoderStream, {cc = data[2], value = data[3]})
        if #self.push.encoderStream == 1 then
            if self.push.encoderStream[1].value < 64 then return self.push.encoderStream[1].value else return -1 * (128 - self.push.encoderStream[1].value) end
        elseif #self.push.encoderStream == thinningLevel then
            self.push.encoderStream = {}
        end
        return 0
    else
        if data[3] < 64 then return data[3] else return -1 * (128 - data[2]) end
    end
end

function Midi:writeText(data, ...)
    local n_args = select('#', ...)
    if data then
        self:sendMidi(data)
        if n_args > 0 then
            local t = {...}
            local line = t[1]
            self.push.state.displaySysexByLine[line] = data
        end
    end
end

-- format sysex table for writing to display. Byte 5 is always line number. Can write up to 68 characters long, byte values 0-127.
-- Function is variadic, (format, text, line, zone). First three are required, zone is optional.
function Midi:formatLine (format, text, ...)
    local s = table.copy(format)
    local length = string.len(text)
    local n_args = select('#', ...)
    local line, zone = 0, 0
    if n_args == 1 then
        line = select(1, ...)
    elseif n_args == 2 then
        line = select(1, ...)
        zone = select(2, ...)
    else
        print("missing or extra arguments to formatLine (format, text, line[, zone])")
        return nil
    end
    if s then s[5] = Midi.sysex.line_number.write[line] else return nil end
    if Midi.sysex.zone[zone] then
        local j = 0
        if length < 8 then
            for i = length, 8 do
                text = text .. " "
            end
        end
        for i = Midi.sysex.zone[zone], Midi.sysex.zone[zone] + 7  do
            s[9 + i] = string.byte(text, 1 + j)
            j = j + 1
        end
        return s--, line, zone -- not sure if these need to be saved, perhaps find some other way to store them if necessary
    else
        for i = 0, string.len(text) - 1  do
            s[9 + i] = string.byte(text, 1 + i)
        end
        return s--, line
    end
end

-- clear the whole display. Takes an object as argument (the Push object), to access MIDI operations. Line number is optional.
function Midi:clearDisplay (...)
    local m = {}
    if select('#', ...) == 1 then
        m = table.copy(Midi.sysex.clear_line)
        m[5] = Midi.sysex.line_number.clear[select(1, ...)]
        self:sendMidi(m)
    else
        for i = 1, 4 do
            m[i] = table.copy(Midi.sysex.clear_line)
            m[i][5] = Midi.sysex.line_number.clear[i]
            self:sendMidi(m[i])
        end
    end
end
