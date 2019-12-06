class "Sysex"

-- template for writing to screen - must be 77 bytes long even if empty
Sysex.write_line = { 240, 71, 127, 21, 0, 0, 69, 0, 
32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 
32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 
32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 
32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 
32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 
32, 32, 32, 32, 32, 32, 32, 32,
247 }

-- template for clearing line
Sysex.clear_line = { 240, 71, 127, 21, 0, 0, 0, 247 }

-- table of bytes to address each line in write/clear message - sequential line 1-4 for each
Sysex.line_number = {
    write = { 24, 25, 26, 27 },
    clear = { 28, 29, 30, 31 }
}

-- offset for each 'zone' under the encoders - sequential 1-8
Sysex.zone = { 0, 9, 17, 26, 34, 43, 51, 60 }

-- format sysex table for writing to display. Byte 5 is always line number. Can write up to 68 characters long, byte values 0-127. 
-- Function is variadic, (format, text, line, zone). First three are required, zone is optional.
function Sysex:formatLine (format, text, ...)
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
    if s then s[5] = Sysex.line_number.write[line] else return nil end
    if Sysex.zone[zone] then 
      local j = 0
      if length < 8 then
          for i = length, 8 do
              text = text .. " "
          end
      end
      for i = Sysex.zone[zone], Sysex.zone[zone] + 7  do
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
function Sysex.clearDisplay (obj, ...)
    local m = {}
    if select('#', ...) == 1 then
        m = table.copy(Sysex.clear_line)
        m[5] = Sysex.line_number.clear[select(1, ...)]
        obj:sendMidi(m)
    else
        for i = 1, 4 do
            m[i] = table.copy(Sysex.clear_line)
            m[i][5] = Sysex.line_number.clear[i]
            obj:sendMidi(m[i])
        end
    end
end
