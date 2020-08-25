local _push, _state, _midi
local modenames
local modes = {}

class "Mode"
-- mappings to connect actions from the Push device to the state of the Renoise song

function Mode:__init (m_names)
    self.modes = {}
    modenames = m_names or {
        "sequencer"
    }
end

function Mode:loadModes ()
    for _, name in ipairs(modenames) do
        modes[name] = require("modes."..name)
    end
    for _, modespec in pairs(modes) do
        self:registerMode(modespec)
    end
end

function Mode.setRefs (parent)
    _push = parent
    _state = parent._state
    _midi = parent._midi
end

function Mode:registerMode (modespec)
    local cc = getControlFromType("name", modespec.control).cc
    self.modes[cc] = {name = modespec.name}
    for page, spec in ipairs(modespec.page) do
        local temp = setmetatable({}, {__index = Push.control})
        for name, value in pairs(spec.lights()) do
            local control = getControlFromType("name", name)
            if control then
                temp[control.cc] = control
                temp[control.cc].value = value
            end
        end
        self.modes[cc] = {
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

function Mode:select (cc)
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
--         _state.dirty = true
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
--         _state.dirty = true
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
--         _state.dirty = true
--     end
-- }

