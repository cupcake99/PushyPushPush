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
        if Push.control[index] ~= nil and Push.control[index].hasNote and Push.control[index].note == data then return Push.control[index], index end
    elseif want == "cc" then
        if Push.control[index] ~= nil and Push.control[index].hasCC and Push.control[index].cc == data then return Push.control[index], index end
    elseif want == "name" then
        for i = 1, 120 do
            index = i + 128
            if Push.control[i] ~= nil and Push.control[i].name == data then return Push.control[i], i
            elseif Push.control[index] ~= nil and Push.control[index].name == data then return Push.control[index], index end
        end
    end
    return nil
end

function printSelf (object)
    print(string.format("[%s] self:", type(object)), object)
end

