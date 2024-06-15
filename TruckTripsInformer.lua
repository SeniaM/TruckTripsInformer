
script_name("Truck Trips Informer - TTI")
script_author("")
script_description("Задача скрипта показывать актуальную информацию о заказах и заработке")

require "lib.moonloader" 
    
local sampev = require ("lib.samp.events")
local encoding = require 'encoding'
local string = require 'string'

local filePathDuration = getGameDirectory().."\\moonloader\\durationoftrip.txt"
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
--------Timer----------
local timeOfTripFromFile
local startTimer
local endTimer
local currentTimeTrip
--------EndTimer----------
local isPrintStat      = false
local isDialog1        = false
local isDialog2        = false
local isShowDial       = false
local isScriptActivate = false

encoding.default  = 'cp1251' -- set the same encoding as script file
u8 = encoding.UTF8

function sampev.onServerMessage(color, text)
    if isScriptActivate == true then
        if text:find("Вы загрузили") and color == 865730559 then
            startTimer = os.clock()
            
        ----------------------------------------------------------------
            pickEd = tonumber(string.match(text, "{FFAA00}(%d+)"))
            if percent ~=0 then
                sumEarn = tonumber((pickEd * sumForEd) - ((pickEd * sumForEd) * percent / 100))
            else
                sumEarn = pickEd * sumForEd
            end
            isDialog2 = true
        end
        if text:find("Вы привезли") and color == 865730559 then
            endTimer = os.clock()
            currentTimeTrip = endTimer - startTimer
            local isComp = false
            local content = readFileToTable(filePathDuration)    
            for i, line in ipairs(content) do
                if isCompareText(Text .. "=0", line) then
                    isComp = true
                    timeOfTripFromFile = tonumber(string.match(line ,"=(%d*)"))
                    if timeOfTripFromFile < currentTimeTrip then
                        content[i] = Text .. "=" .. currentTimeTrip
                    end
                    sampAddChatMessage(timeOfTripFromFile, 0x0099e5)
                end    
                point1, point2 = splitPointfromText(line)
                sampAddChatMessage(point1, 0x0099e5)
                sampAddChatMessage(point2, 0x0099e5)
                point3, point4 = splitPointfromText(string.format(Text .. "=0"))       
            end

            sampAddChatMessage(point3, 0x0099e5)
            sampAddChatMessage(point4, 0x0099e5)   
            if isComp == true then
                saveTableToString(filePathDuration, content)
            else
                local file = io.open(filePathDuration,"a+")
                file:write(Text .. "=" .. currentTimeTrip .. "\n")
                file:close()
            end
            ---------------------------------------------------------------
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
end

function onSendRpc(id, bitStream, priority, reliability, orderingChannel, shiftTs)
    if isScriptActivate == true then
        if id == 62 then
            local wDialogID = raknetBitStreamReadInt16(bitStream)
            if wDialogID == 3079 then
                local bResponse = raknetBitStreamReadInt8(bitStream)
                if bResponse == 1 then
                    local wListItem    = raknetBitStreamReadInt16(bitStream)
                    local bTextLength  = raknetBitStreamReadInt8(bitStream)
                        Text         = raknetBitStreamReadString(bitStream, bTextLength)
                    local textItem     = sampGetListboxItemText(wListItem)
                    local res          = get_line_from_list(decodedString, wListItem + 1)
                    local pattern1 = "%s(%d*)%$"

                    local pattern2 = "(%d*)/" 
                    local pattern3 = "/(%d*)"
                    
                    Text = string.sub(Text, 1, #Text-4)
                    local sum = tonumber(string.match(res, pattern1))
                    --sum = string.sub(sum, 1, #sum-1)
                    local ed1 = string.match(res, pattern2)
                    local ed2 = string.match(res, pattern3)
                    sampAddChatMessage(res, 0x0099e5)
                    sampAddChatMessage(sum, 0x0099e5)
                    sampAddChatMessage(ed1, 0x0099e5)
                    sampAddChatMessage(ed2, 0x0099e5)
                    sumForEd = sum
                    isDialog1 = true
                end
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
            local file = io.open(getGameDirectory().."//moonloader//List.txt", "a+") --remove this
            file:write(decodedString)
            file:close()
        end
   end
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then
         return end
    while not isSampAvailable() do wait(100) end
    
    sampRegisterChatCommand("tti", activateScript)
    sampAddChatMessage("Truck Trips Informer загружен!", 0xFFFF00)
    

    while true do wait(0)
        if isKeyJustPressed(VK_1) then
        
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
    sampSendChat(string.format("/do Маршрут: %s", order))
    sampSendChat(string.format("/do Стоимостью $%s за единицу весом %sкг на сумму $%s", tostring(sumForEd), tostring(amount), tostring(price)))
    sampSendChat(string.format("/do Ожидаемая общая прибыль составит: $%d", price + moneyBox))
end

function printStat()
    sampSendChat(string.format("/do Вы сдали груз. Статистика на текущий момент:"))
    sampSendChat(string.format("/do Потребовалось времени на доставку: " .. math.floor(currentTimeTrip/60) .. " мин. " 
                                                                         .. math.floor(currentTimeTrip) - (math.floor(currentTimeTrip/60) * 60) .. " сек."))
    sampSendChat(string.format("/do Завершенных поездок: " .. tostring(numberOfTrips) .. ". Заработано налички: $" .. tostring(moneyBox)))
end

function activateScript(arg)
    isScriptActivate = not isScriptActivate

    if isScriptActivate == true then
        sampAddChatMessage(string.match("Нефтезавод - Казино Камелот=0", "(.*)%s%-", 1), 0x0099e5)
        sampAddChatMessage("Truck Trips Informer: {34bf49}[enabled]", 0x0099e5)
    else
        sampAddChatMessage("Truck Trips Informer: {ff4c4c}[diabled]", 0x0099e5)
    end
end

function splitPointfromText(str)
    local point1 = string.match(str, "(.*)%s%-", 1)
    local point2 = string.match(str, "%-%s(.*)=%d*", 1)
    return point1, point2
end

function isCompareText(str1, str2)
    local part1_str1, part2_str1 = splitPointfromText(str1)
    local part1_str2, part2_str2 = splitPointfromText(str2)
    if part1_str1 and part1_str2 and part2_str1 and part2_str2 then
        return (part1_str1 == part1_str2 and part2_str1 == part2_str2) or
               (part1_str1 == part2_str2 and part2_str1 == part1_str2)
    else
        return false
    end
end

function readFileToTable(filePath)
    local file = io.open(filePath, "r")
    if not file then
        print("Не удалось открыть файл для чтения")
        return nil
    end

    local content = {}
    for line in file:lines() do
        table.insert(content, line)
    end
    file:close()
    return content
end

function saveTableToString(filePath, table)
    local file = io.open(filePath, "w")
    if not file then
        print("Не удалось открыть файл для записи")
        return false
    end

    for _, value in ipairs(table) do
        file:write(value .. "\n")
    end

    file:close()
    return true
end