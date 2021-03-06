local _push, _state, _mode

class "Midi"

function Midi:__init ()
    if _OSC then
        self.server = nil
        self.client = nil
        self.address = Midi.OSCAddress
        self.port = Midi.OSCPort
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
    zone = { 0, 9, 17, 26, 34, 43, 51, 60 },

    user_mode = { 240, 71, 127, 21, 98, 0, 1, 1, 247 },

    id_request = { 240, 126, 127, 6, 1, 247 }
}

function Midi.setRefs (parent)
    _push = parent
    _state = parent._state
    _mode = parent._mode
end

function Midi.callAction(data)
    local control, index
    if data[1] == Midi.status.note_on then
        control = getControlFromType("note", data[2])
        if control.hasNote and control.note < 36 then
            return
        elseif control.hasNote and control.note > 35 and control.note < 100 then
            if _state:insertNote(data) then
                _state:setPatternDisplay {0, 0, 1}
            else
                _state:receiveNote(data)
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
                _state:receiveNote(data)
            end
        end
    elseif data[1] == Midi.status.cc then
        control, index = getControlFromType("cc", data[2])
        if _state.activeMode.action[control.name] then
            _state.activeMode.action[control.name](_state, data, index)
        end
    end
    _state.dirty = true
end

function Midi.handleMidi (data)
    assert(#data == 3)
    local control
    if data[1] == Midi.status.note_on then control = getControlFromType("note", data[2])
    elseif data[1] == Midi.status.cc then control = getControlFromType("cc", data[2]) end
    -- if not control then return end
    -- rprint(control)
    if control and control.hasCC then
        if control.name == "shift" then _state:shift(data) return end
        if control.name == "play" then _state:play(data) return end
        if control.name == "record" then _state:edit(data) return end
        if _state:changeMode(data) then return end
    end
    Midi.callAction(data)
end

function Midi.sendMidi (data)
    if _push.output.is_open then
        _push.output:send(data)
    end
end

function Midi.encoderParse (data, thinningLevel)
    if data[3] == 0 then return 0 end
    if #_push.encoderStream ~= 0 and _push.encoderStream[#_push.encoderStream].cc ~= data[2] then
        _push.encoderStream = {}
    end
    if thinningLevel then
        table.insert(_push.encoderStream, {cc = data[2], value = data[3]})
        if #_push.encoderStream == 1 then
            if _push.encoderStream[1].value < 64 then
                return _push.encoderStream[1].value
            else
                return -1 * (128 - _push.encoderStream[1].value)
            end
        elseif #_push.encoderStream == thinningLevel then
            _push.encoderStream = {}
        end
        return 0
    else
        if data[3] < 64 then return data[3] else return -1 * (128 - data[2]) end
    end
end

-- format sysex table for writing to display. Byte 5 is always line number. Can write up to 68 characters long, byte values 0-127.
-- Function is variadic, (format, text, line, zone). First three are required, zone is optional.
function Midi.formatLine (format, text, ...)
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
        print "[PushyPushPush]: Missing or extra arguments to formatLine (format, text, line[, zone])"
        return nil
    end
    if s then s[5] = Midi.sysex.line_number.write[line] else return nil end
    if Midi.sysex.zone[zone] then
        local j = 0
        if length < 8 then
            for i = length, 8 do
                text = text .. " "
            end
        elseif length > 8 then
            text = string.gsub(text, "%s*", "")
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

function Midi:writeText (data, ...)
    local n_args = select('#', ...)
    if data then
        self.sendMidi(data)
        if n_args > 0 then
            local t = {...}
            local line = t[1]
            _state.displaySysexByLine[line] = data
        end
    end
end

-- clear the whole display. Takes an object as argument (the Push object), to access MIDI operations. Line number is optional.
function Midi:clearDisplay (...)
    local m = {}
    if select('#', ...) == 1 then
        m = table.copy(Midi.sysex.clear_line)
        m[5] = Midi.sysex.line_number.clear[select(1, ...)]
        self.sendMidi(m)
    else
        for i = 1, 4 do
            m[i] = table.copy(Midi.sysex.clear_line)
            m[i][5] = Midi.sysex.line_number.clear[i]
            self.sendMidi(m[i])
        end
    end
end

if _OSC then
    Midi.OSCAddress = "localhost"
    Midi.OSCPort = 9999

    function Midi:initOSC ()
        local socket_error
        if not self.server then
            self.server, socket_error = renoise.Socket.create_server(self.address, self.port, renoise.Socket.PROTOCOL_UDP)
        end
        if socket_error then
            renoise.app():show_warning(("[PushyPushPush]: Failed to start the OSC server. Error: '%s'"):format(socket_error))
            return
        end
    end

    function Midi:runServer ()
        self.server:run {
            socket_message = function (socket, data)
                local message_or_bundle, osc_error = renoise.Osc.from_binary_data(data)
                if (message_or_bundle) then
                    if (type(message_or_bundle) == "Message") then
                        print(("Got OSC message: '%s'"):format(tostring(message_or_bundle)))
                    elseif (type(message_or_bundle) == "Bundle") then
                        print(("Got OSC bundle: '%s'"):format(tostring(message_or_bundle)))
                    end
                else
                    print(("Got invalid OSC data, or data which is not OSC data at all. Error: '%s'"):format(osc_error))
                end
            end
        }
        print("server running?", self.server.is_running)
    end

    function Midi:closeServer ()
        self.server:close()
    end
end
