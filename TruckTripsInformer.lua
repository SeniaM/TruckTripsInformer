
script_name("Truck Trips Informer - TTI")
script_author("")
script_description("Задача скрипта показывать актуальную информацию о заказах и заработке")

require "lib.moonloader" 

local sampev = require ("lib.samp.events")
local encoding = require 'encoding'
local string = require 'string'

---------Stats--------
local moneyBox = 0
local numberOfTrips = 0
local percent = 0
--------EndStats------
local storeTextItem
local Text
local pickEd
local sumForEd
local sumEarn
local decodedString

local isPrintStat = false
local isDialog1   = false
local isDialog2   = false
local isShowDial  = false
encoding.default  = 'cp1251' -- set the same encoding as script file
u8 = encoding.UTF8

function sampev.onServerMessage(color, text)
    if text:find("Вы загрузили") and color == 865730559 then
        pickEd = tonumber(string.match(text, "{FFAA00}(%d+)"))
        if percent ~=0 then
            sumEarn = (pickEd * sumForEd) - ((pickEd * sumForEd) * percent / 100)
        else
            sumEarn = (pickEd * sumForEd)
        end
        isDialog2 = true
    end
    if text:find("Вы привезли") and color == 865730559 then
        local file = io.open(getGameDirectory().."//moonloader//file.txt", "a")
        file:write(text)
        file:close()

        local pattern1 = "{FFAA00}(%d+)"
        local res1 = string.match(text, pattern1)
        local money = tonumber(string.match(text, "{00cc99}(%d+)"))
        local commissionInDollar = tonumber(string.match(text, "{ff8080}(%d+)"))
        
        if commissionInDollar ~= 0 then
            percent = math.floor(commissionInDollar / (money / 100))
        end
        moneyBox = moneyBox + money
        numberOfTrips = numberOfTrips + 1

        isPrintStat = true
    end

end

function onSendRpc(id, bitStream, priority, reliability, orderingChannel, shiftTs)
    if id == 62 then
        local wDialogID = raknetBitStreamReadInt16(bitStream)
        if wDialogID == 3079 then
            local bResponse    = raknetBitStreamReadInt8(bitStream)
            local wListItem    = raknetBitStreamReadInt16(bitStream)
            local bTextLength  = raknetBitStreamReadInt8(bitStream)
                  Text         = raknetBitStreamReadString(bitStream, bTextLength)
            local textItem     = sampGetListboxItemText(wListItem)
            local res          = get_line_from_list(decodedString, wListItem + 1)
            local pattern1 = "(%d+$)"

            local pattern2 = "(%d+)/" 
            local pattern3 = "/(%d+)"
            
            Text = string.sub(Text, 1, #Text-4)
            local sum = string.match(res, pattern1)
            sum = string.sub(sum, 1, #sum-1)
            local ed1 = string.match(res, pattern2)
            local ed2 = string.match(res, pattern3)

            sumForEd = tonumber(sum)

            if bResponse == 1 then
                isDialog1 = true
            end
        end
    end
    return {id, bitStream, priority, reliability, orderingChannel, shiftTs}
end

function onReceiveRpc(id, bs) 
    if id == 61 then
        local wDialogID    = raknetBitStreamReadInt16(bs)
        if wDialogID == 3079 then
            local bDialogStyle    = raknetBitStreamReadInt8(bs)
            local bTitleLength    = raknetBitStreamReadInt8(bs)
            local szTitle         = raknetBitStreamReadString(bs, bTitleLength)
            local bButton1Len     = raknetBitStreamReadInt8(bs)
            local szButton1       = raknetBitStreamReadString(bs, bButton1Len)
            local bButton2Len     = raknetBitStreamReadInt8(bs)
            local szButton2       = raknetBitStreamReadString(bs, bButton2Len)
            decodedString = raknetBitStreamDecodeString(bs, 4096)
        end
   end
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then
         return end
    while not isSampAvailable() do wait(100) end
    
    sampAddChatMessage("Truck Trips Informer загружен!", 0xFFFF00)
    

    while true do wait(0)
        if isKeyJustPressed(VK_CONTROL) then
        end

        if isDialog1 == true and isDialog2 == true then
            sayTextInfo(Text, pickEd, sumEarn)
            isDialog1 = false
            isDialog2 = false
        end

        if isPrintStat == true then
            printStat()
            isPrintStat = false
        end
    end
end

function get_line_from_list(str, line_number)
    local lines = {}
    local first_line_processed = false
    for line in str:gmatch("([^\n]*)\n?") do
        if not first_line_processed then
            first_line_processed = true
        else
            table.insert(lines, line)
        end
    end
    return lines[line_number]
end

function sayTextInfo(order, amount, price)
    sampSendChat(string.format("/do Пета взял заказ со следующими характеристиками: "))
    sampSendChat(string.format("/do Маршрут: %s", order))
    sampSendChat(string.format("/do Стоимостью $%s за единицу весом %sкг на общую сумму $%s", tostring(sumForEd), tostring(amount), tostring(price)))
    sampSendChat(string.format("/do Ожидаемая общая прибыль составит: $%d", price + moneyBox))
end

function printStat()
    sampSendChat(string.format("/do Пета сдал груз. Статистика на текущий момент:"))
    sampSendChat(string.format("/do Завершенных поездок: " .. tostring(numberOfTrips) .. ". Заработано налички: $" .. tostring(moneyBox)))
end