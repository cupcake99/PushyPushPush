local _push

local Config = {
    prefs = nil,
    gui = nil
}

function Config.getPush (ref)
    _push = ref
end

Config.prefs = renoise.Document.create {
    autostart = true,
    encoder_speed = 3,
    input_device = "",
    output_device = ""
}
tool.preferences = Config.prefs

Config.prefs.input_device:add_notifier(function() print "Input device changed" end)
Config.prefs.output_device:add_notifier(function() print "Output device changed" end)

local function getDeviceIndex (direction)
    local items, name
    if direction == "input" then
        items = renoise.Midi.available_input_devices()
        name = _push.input_device_name:gsub("%((%w+%s*%w*)%)", "%%%(%1%%%)") --have to do this to make string into valid lua pattern
    elseif direction == "output" then
        items = renoise.Midi.available_output_devices()
        name = _push.output_device_name:gsub("%((%w+%s*%w*)%)", "%%%(%1%%%)")
    else
        return
    end
    for i, _ in ipairs(items) do
        if string.find(items[i], name) then
            return i
        end
    end
end

function Config:open_config ()
    local view = renoise.ViewBuilder()
    local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
    local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
    local TEXT_ROW_WIDTH = 60
    local MENU_ROW_WIDTH = 220
    local content_view = view:column {
        margin = DIALOG_MARGIN,
        spacing = CONTENT_SPACING,
        view:horizontal_aligner {
            mode = "center",
            spacing = CONTENT_SPACING,
            view:vertical_aligner {
                mode = "distribute",
                spacing = CONTENT_SPACING,
                view:row {
                    style = "plain",
                    view:text {
                        width = TEXT_ROW_WIDTH,
                        align = "center",
                        text = "input port"
                    }
                },
                view:row {
                    style = "plain",
                    view:text {
                        width = TEXT_ROW_WIDTH,
                        align = "center",
                        text = "output port"
                    }
                }
            },
            view:vertical_aligner {
                mode = "distribute",
                spacing = CONTENT_SPACING,
                view:row {
                    style = "plain",
                    view:popup {
                        -- id = "command",
                        width = MENU_ROW_WIDTH,
                        items = renoise.Midi.available_input_devices(),
                        value = getDeviceIndex("input"),
                        notifier = function (index)
                            _push:close()
                            _push.input_device_name = renoise.Midi.available_input_devices()[index]
                            _push:open()
                        end
                    }
                },
                view:row {
                    style = "plain",
                    view:popup {
                        -- id = "command",
                        width = MENU_ROW_WIDTH,
                        items = renoise.Midi.available_output_devices(),
                        value = getDeviceIndex("output"),
                        notifier = function (index)
                            _push:close()
                            _push.output_device_name = renoise.Midi.available_output_devices()[index]
                            _push:open()
                        end
                    }
                }
            }
        },
        view:vertical_aligner {
            mode = "center",
            spacing = CONTENT_SPACING,
            view:horizontal_aligner {
                mode = "distribute",
                spacing = CONTENT_SPACING,
                view:row {
                    style = "plain",
                    view:text {
                        width = TEXT_ROW_WIDTH,
                        align = "center",
                        text = "autostart"
                    },
                    view:checkbox {
                        value = Config.prefs.autostart.value,
                        notifier = function () Config.prefs.autostart.value = not Config.prefs.autostart.value end
                    }
                }
            },
            view:horizontal_aligner {
                mode = "distribute",
                spacing = CONTENT_SPACING,
                view:row {
                    style = "plain",
                    view:button {
                        text = "restart",
                        pressed = function() if push then _push:stop(); _push:start("sysex") end end
                    }
                }
            }
            -- add status window, restart button, checkboxes for options etc
        }
    }
    self.gui = renoise.app():show_custom_dialog("PushyPushPush Config", content_view)
end

tool:add_menu_entry {
    name = "Main Menu:Tools:PushyPushPush:Open Config",
    invoke = function() Config:open_config() end
}

return Config
