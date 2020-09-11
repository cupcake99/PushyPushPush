local _push, _state, _midi
local modenames
local modes = {}

class "Mode"

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
    self.modes[cc] = {
        name = modespec.name,
        page = {}
    }
    for page, spec in ipairs(modespec.page) do
        local lights = {}
        for name, value in pairs(spec.lights()) do
            local control = getControlFromType("name", name)
            if control then
                lights[control.cc] = control
                lights[control.cc].value = value
            end
        end
        self.modes[cc].page[page] = {
                    lights = lights,
                    display = modespec.page[page].display,
                    action = modespec.page[page].action
        }
    end
end

function Mode:select (cc)
    return self.modes[cc]
end

