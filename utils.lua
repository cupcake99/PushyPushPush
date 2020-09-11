function getControlFromType (want, data)
    local index = data
    if want == "note" then
        if data >= 0 and data < 9 then
            index = index + 71
        elseif data == 9 or data == 10 then
            index = index + 5
        else
            index = index + 128
        end
        if Push.control[index] ~= nil and Push.control[index].hasNote and Push.control[index].note == data then
            return table.copy(Push.control[index]), index
        end
    elseif want == "cc" then
        if Push.control[index] ~= nil and Push.control[index].hasCC and Push.control[index].cc == data then
            return table.copy(Push.control[index]), index
        end
    elseif want == "name" then
        if Push.control_by_name[index] ~= nil then
            index = Push.control_by_name[index]
            return table.copy(Push.control[index]), index
        end
    end
    return nil
end

function printSelf (object)
    print(string.format("[PushyPushPush]: [%s] self:", type(object)), object)
end

