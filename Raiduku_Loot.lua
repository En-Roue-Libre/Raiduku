Raiduku.LootWindow = Raiduku:DrawLootWindow()
Raiduku.Loots = {}
Raiduku.Players = {}
Raiduku.SoftResList = {}
Raiduku.LootItemTypes = {
    ["Weapon"] = 2,
    ["Armor"] = 4,
    ["Recipe"] = 9,
    ["Miscellaneous"] = 15
}

Raiduku.LootItemSpecials = {
    [32385] = true,
    [34845] = true
}

Raiduku.LootItemIgnoreList = {
    -- Badge of Justice
    [29434] = true,
    -- Legendaries from TK
    [30316] = true,
    [30313] = true,
    [30318] = true,
    [30319] = true,
    [30320] = true,
    [30312] = true,
    [30311] = true,
    [30317] = true
}

Raiduku.LootItemResources = {
    -- Phase 3 Epic Gems
    [32227] = true,
    [32231] = true,
    [32229] = true,
    [32230] = true,
    [32249] = true,
    [32228] = true,
    -- Mark of the Illidari
    [32897] = true,
    -- Heart of Darkness
    [32428] = true,
    -- Sunmote
    [34664] = true
}

--[[
    Local functions
--]]

local function resetAll()
    Raiduku.Loots = {}
    Raiduku.Players = {}
    Raiduku.SoftResList = {}
    Raiduku.LootWindow.title:SetText(nil)
    Raiduku.LootWindow.content:SetText(nil)
    Raiduku.LootWindow.content:Show()
    Raiduku.LootWindow.image:SetNormalTexture(nil)
    Raiduku.LootWindow.image:SetPushedTexture(nil)
    Raiduku.LootWindow.prioList:SetText(nil)
    Raiduku.LootWindow.softresList:SetText(nil)
    Raiduku.LootWindow.startButton:Show()
    Raiduku.LootWindow.laterButton:Show()
    Raiduku.LootWindow.rollsButton:Hide()
    Raiduku.LootWindow.winnerButton:Hide()
    Raiduku.LootWindow.recycleButton:Hide()
    Raiduku.LootWindow.prioButton:Hide()
    Raiduku.LootWindow:Hide()
end

local function startNextLoot()
    C_Timer.NewTimer(0.2, function()
        if (#Raiduku.Loots > 0) then
            Raiduku.LootWindow.content:Show()
            SendChatMessage(Raiduku.Loots[1].link, Raiduku:GetWarningChatType(), nil, nil)
        end
    end)
end

local function updateIcon(itemId)
    local itemIcon = GetItemIcon(itemId)
    Raiduku.LootWindow.image:SetNormalTexture(itemIcon)
    Raiduku.LootWindow.image:SetPushedTexture(itemIcon)
    Raiduku.LootWindow.image:SetScript("OnEnter", function()
        local itemLink = select(2, GetItemInfo(itemId))
        GameTooltip:SetOwner(Raiduku.LootWindow, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Show()
    end)
    Raiduku.LootWindow.image:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function displaySoftResInfo()
    
    SendChatMessage("{rt2} SoftRes {rt2}", Raiduku:GetChatType(), nil, nil)
    local raiders = {}
    for i = 1, GetNumGroupMembers() do
        local raiderName = GetRaidRosterInfo(i)
        raiders[raiderName] = true
    end
    for _, player in ipairs(Raiduku.SoftResList) do
        if raiders[player.name] then
            SendChatMessage(player.name, Raiduku:GetChatType(), nil, nil)
            Raiduku:AddOrUpdatePlayer(player.name, player.class, 1)
        end
    end
    Raiduku:UpdatePlusRollResults()
end

local function lootLinkedHandler(...)
    local text, name = ...
    local itemId = text:match("|Hitem:(%d+):")
    local playerName = UnitName("player")
    name = strsplit("-", name)
    if name == playerName and itemId and not (text:find("GG") or text:find("{rt1}")) then
        local _, itemLink, itemRarity = GetItemInfo(itemId)
        if itemRarity >= 3 and Raiduku.LootItemIgnoreList[tonumber(itemId)] == nil then
            local prios = Raiduku.db.profile.prios
            itemId = tonumber(itemId)
            tinsert(Raiduku.Loots, {
                link = itemLink,
                index = 1
            })
            Raiduku.Players = {}
            updateIcon(itemId)
            Raiduku.LootWindow.title:SetText(itemLink)
            Raiduku.LootWindow.prioList:SetText(nil)
            Raiduku.LootWindow.softresList:SetText(nil)
            Raiduku.LootWindow.startButton:Hide()
            Raiduku.LootWindow.laterButton:Hide()
            Raiduku.LootWindow.prioButton:Hide()
            Raiduku.LootWindow.rollsButton:Disable()
            Raiduku.LootWindow.winnerButton:Disable()
            Raiduku.LootWindow.rollsButton:Show()
            Raiduku.LootWindow.winnerButton:Show()
            Raiduku.LootWindow.recycleButton:Show()
            if prios[itemId] then
                local prioList = {}
                local raiders = {}
                for i = 1, GetNumGroupMembers() do
                    local raiderName = GetRaidRosterInfo(i)
                    raiders[raiderName] = true
                end
                if Raiduku.db.profile.enableSoftPrio then
                    SendChatMessage("{rt2} Soft Prios {rt2}", Raiduku:GetChatType(), nil, nil)
                    local prioNames = {}
                    for _, prio in ipairs(prios[itemId]) do
                        if prio.name and raiders[prio.name] then
                            tinsert(prioNames, prio.name)
                            Raiduku:AddOrUpdatePlayer(prio.name, prio.class, 1)
                            Raiduku:UpdatePlusRollResults()
                        end
                    end
                    if #prioNames > 0 then
                        SendChatMessage(table.concat(prioNames, ", "), Raiduku:GetChatType(), nil, nil)
                        Raiduku.LootWindow.removeLastPlayerButton:Show()
                    end
                else
                    for _, prio in ipairs(prios[itemId]) do
                        if prio.name and raiders[prio.name] then
                            tinsert(prioList, prio.order .. ": " .. prio.name)
                        end
                    end
                    if #prioList > 0 then
                        SendChatMessage("{rt2} Prios {rt2}", Raiduku:GetChatType(), nil, nil)
                        for _, prio in ipairs(prioList) do
                            SendChatMessage(prio, Raiduku:GetChatType(), nil, nil)
                        end
                        prioList[1] = "|cFF00FF00" .. prioList[1] .. "|r\n"
                        Raiduku.LootWindow.prioList:SetText(table.concat(prioList, "\n"))
                        Raiduku.LootWindow.prioButton:Show()
                        Raiduku.LootWindow.content:Hide()
                    else
                        Raiduku.SoftResList = Raiduku:GetSoftResList(itemId)
                        if #Raiduku.SoftResList > 0 then
                            displaySoftResInfo()
                        end
                    end
                end
            else
                Raiduku.SoftResList = Raiduku:GetSoftResList(itemId)
                if #Raiduku.SoftResList > 0 then
                    displaySoftResInfo()
                end
            end
            Raiduku.LootWindow:Show()
        end
    end
end

local function chatMsgLootHandler(...)
    local loot, receiver = select(1, ...), select(5, ...)
    local itemId = loot:match("|Hitem:(%d+):")
    if itemId then
        local _, itemLink, itemQuality, _, _, itemType = GetItemInfo(itemId)
        if itemQuality >= 3 and (Raiduku.LootItemTypes[itemType] or Raiduku.LootItemSpecials[tonumber(itemId)]) and
            Raiduku.LootItemIgnoreList[tonumber(itemId)] == nil then
            local alreadySaved = false
            for _, loots in next, Raiduku.db.profile.loot do
                for _, row in next, loots do
                    local name, _, curItemId = strsplit(",", row)
                    if receiver == name and itemId == curItemId then
                        alreadySaved = true
                    end
                end
            end
            if not alreadySaved then
                local dialog = StaticPopup_Show("RDK_CONFIRM_SAVE_FOR_TMB", itemLink, receiver)
                if (dialog) then
                    dialog.data = loot
                    dialog.data2 = receiver
                end
            end
        end
    end
end

local function playerRollHandler(...)
    local text = ...
    if Raiduku.Loots[1] and text:find("(1-100)") then
        local roll = tonumber(text:match("(%d+)"))
        local playerName = strsplit(" ", text)
        for _, player in ipairs(Raiduku.Players) do
            if player.name == playerName and player.roll == nil then
                player.roll = roll
            end
        end
        Raiduku:UpdatePlusRollResults()
    end
end

local function playerPlusHandler(...)
    if Raiduku.LootWindow.prioList:GetText() == nil or #Raiduku.LootWindow.prioList:GetText() == 0 then
        local text, player = ...
        local guid = select(12, ...)
        local _, class = GetPlayerInfoByGUID(guid)
        local name = Raiduku:GetPlayerName(player)
        local plus = tonumber(text:match("+%d"))
        if Raiduku.Loots[1] and plus and #text == 2 and #Raiduku.SoftResList == 0 then
            Raiduku:AddOrUpdatePlayer(name, class, plus)
        end
        Raiduku:UpdatePlusRollResults()
    end
end

local function lootOpenedHandler()
    for i = 1, GetNumLootItems() do
        if (LootSlotHasItem(i)) then
            local itemLink = GetLootSlotLink(i)
            if itemLink then
                local itemRarity = select(3, GetItemInfo(itemLink))
                local itemId = itemLink:match("|Hitem:(%d+):")
                if itemRarity >= 3 and Raiduku.LootItemIgnoreList[tonumber(itemId)] == nil
                 and Raiduku.LootItemResources[tonumber(itemId)] == nil then
                    tinsert(Raiduku.Loots, {
                        link = itemLink,
                        index = i
                    })
                end
                if Raiduku.LootItemResources[tonumber(itemId)] then
                    Raiduku:Print(Raiduku.L["auto-awarding"] .. " " .. itemLink)
                    Raiduku:AutoAwardToSelf(i)
                end
                if itemRarity == 2 and Raiduku.db.profile.autoAwardCommon then
                    Raiduku:Print(Raiduku.L["auto-awarding"] .. " " .. itemLink)
                    Raiduku:AutoAwardToRecycler(i)
                end
                if itemRarity == 3 and Raiduku.db.profile.autoAwardRare then
                    Raiduku:Print(Raiduku.L["auto-awarding"] .. " " .. itemLink)
                    Raiduku:AutoAwardToRecycler(i)
                end
            end
        end
    end
    if #Raiduku.Loots > 0 then
        Raiduku.LootWindow:Show()
    end
end

--[[
    Loot Window scripts
--]]

Raiduku.LootWindow.closeButton:SetScript("OnClick", function()
    resetAll()
end)

Raiduku.LootWindow.startButton:SetScript("OnClick", function(self)
    self:Hide()
    Raiduku.LootWindow.laterButton:Hide()
    if #Raiduku.Loots > 0 then
        startNextLoot()
    end
end)

Raiduku.LootWindow.laterButton:SetScript("OnClick", function()
    SendChatMessage(Raiduku.L["loot-later"], Raiduku:GetWarningChatType(), nil, nil)
    while Raiduku.Loots[1] do
        SendChatMessage("{rt1} " .. Raiduku.Loots[1].link, Raiduku:GetChatType(), nil, nil)
        Raiduku:Award(Raiduku.Loots[1].index, UnitName("player"))
    end
    Raiduku.Loots = {}
    Raiduku.LootWindow:Hide()
end)

Raiduku.LootWindow.recycleButton:SetScript("OnClick", function()
    if Raiduku.Loots[1] then
        Raiduku:Award(Raiduku.Loots[1].index, Raiduku.recycler)
    end
    if #Raiduku.Loots > 0 then
        Raiduku.Players = {}
        startNextLoot()
    else
        resetAll()
    end
end)

Raiduku.LootWindow.rollsButton:SetScript("OnClick", function()
    local playerNames = Raiduku:GetMissingRollPlayerNames()
    local message = "{rt3} /roll {rt3} " .. table.concat(playerNames, ", ")
    SendChatMessage(message, Raiduku:GetWarningChatType(), nil, nil)
end)

Raiduku.LootWindow.winnerButton:SetScript("OnClick", function()
    local winner = Raiduku:GetWinner()
    local message = "{rt1} GG "

    message = message .. winner.name .. " [+" .. winner.plus .. "]"

    if winner["roll"] then
        message = message .. " (" .. winner.roll .. ")"
    end

    message = message .. " {rt1} " .. Raiduku.Loots[1].link

    SendChatMessage(message, Raiduku:GetChatType(), nil, nil)

    if Raiduku.Loots[1] then
        Raiduku:SaveLootForTMB(Raiduku.Loots[1].link, winner)
        Raiduku:Award(Raiduku.Loots[1].index, winner.name)
    end
    if #Raiduku.Loots > 0 then
        Raiduku.Players = {}
        startNextLoot()
    else
        resetAll()
    end
end)

Raiduku.LootWindow.prioButton:SetScript("OnClick", function(self)
    local prio = strsplit("\n", Raiduku.LootWindow.prioList:GetText())
    local order = prio:match("|cFF00FF00(%d+):")
    local name = prio:match(": (.+)|r")

    local message = "{rt1} GG "

    message = message .. name .. " (Prio " .. order .. ")"
    message = message .. " {rt1} " .. Raiduku.Loots[1].link
    SendChatMessage(message, Raiduku:GetChatType(), nil, nil)

    if Raiduku.Loots[1] then
        Raiduku:SaveLootForTMB(Raiduku.Loots[1].link, {
            name = name,
            plus = 1
        })
        Raiduku:AwardPrio(name, order)
    end
    if #Raiduku.Loots > 0 then
        Raiduku.Players = {}
        startNextLoot()
    else
        resetAll()
    end
end)

Raiduku.LootWindow.removeLastPlayerButton:SetScript("OnClick", function(self)
    Raiduku.Players[#Raiduku.Players] = nil
    local prioNames = {}
    SendChatMessage("{rt2} Soft Prios (update) {rt2}", Raiduku:GetChatType(), nil, nil)
    for _, player in ipairs(Raiduku.Players) do
        tinsert(prioNames, player.name)
    end
    SendChatMessage(table.concat(prioNames, ", "), Raiduku:GetChatType(), nil, nil)
    Raiduku:UpdatePlusRollResults()
end)

--[[
    Module functions
--]]

function Raiduku:AddOrUpdatePlayer(name, class, plus)
    local playerIndex = nil
    for index, player in ipairs(self.Players) do
        if player.name == name then
            playerIndex = index
            break
        end
    end
    if playerIndex then
        self.Players[playerIndex].plus = plus
    else
        table.insert(self.Players, {
            name = name,
            class = class,
            plus = plus,
            roll = nil,
            loots = {}
        })
    end
end

function Raiduku:GetCurrentAndPreviousDate()
    local loot = self.db.profile.loot
    local dates = {}
    local currentDateIndex = nil
    local index = 0
    for date, _ in next, loot do
        index = index + 1
        tinsert(dates, date)
        if date == Raiduku:GetCurrentDate() then
            currentDateIndex = index
        end
    end
    return dates[currentDateIndex], dates[currentDateIndex - 1]
end

function Raiduku:AutoAwardToRecycler(lootIndex)
    local playerNotFound = true
    for raiderId = 1, GetNumGroupMembers() do
        local raider = GetMasterLootCandidate(lootIndex, raiderId)
        if raider and raider == Raiduku.recycler then
            GiveMasterLoot(lootIndex, raiderId);
            playerNotFound = false
        end
    end
    if playerNotFound then
        self:Print(self.L["cannot-award-to"]:format(Raiduku.recycler))
        StaticPopup_Show("RDK_CONFIRM_RECYCLER", Raiduku.recycler)
    end
end

function Raiduku:AutoAwardToSelf(lootIndex)
    local playerNotFound = true
    for raiderId = 1, GetNumGroupMembers() do
        local raider = GetMasterLootCandidate(lootIndex, raiderId)
        if raider and raider == UnitName("player") then
            GiveMasterLoot(lootIndex, raiderId);
            playerNotFound = false
        end
    end
    if playerNotFound then
        self:Print(self.L["cannot-award-to"]:format(Raiduku.recycler))
        StaticPopup_Show("RDK_CONFIRM_RECYCLER", Raiduku.recycler)
    end
end

function Raiduku:Award(lootIndex, playerName)
    local playerNotFound = true
    local itemId = Raiduku.Loots[1].link:match("|Hitem:(%d+):")
    for raiderId = 1, GetNumGroupMembers() do
        local raider = GetMasterLootCandidate(lootIndex, raiderId)
        if raider and raider == playerName then
            if Raiduku:HasItemInBags(itemId) and playerName ~= UnitName("player") then
                local unitId = Raiduku:GetGroupUnitType() .. raiderId
                -- does not work in group ??\_(???)_/??
                if CheckInteractDistance(unitId, 2) then
                    local bag, slot = Raiduku:GetContainerPosition(itemId)
                    PickupContainerItem(bag, slot)
                    DropItemOnUnit(unitId)
                else
                    SendChatMessage(Raiduku.L["x-come-trade-on-me"]:format(playerName), Raiduku:GetChatType(), nil, nil)
                end
            else
                GiveMasterLoot(lootIndex, raiderId);
            end
            playerNotFound = false
        end
    end
    if playerNotFound then
        self:Print(self.L["cannot-award-to"]:format(playerName))
        GiveMasterLoot(lootIndex, 1);
        if Raiduku:HasItemInBags(itemId) and playerName ~= UnitName("player") then
            SendChatMessage(Raiduku.L["x-come-trade-on-me"]:format(playerName), Raiduku:GetChatType(), nil, nil)
        end
    end
    tremove(self.Loots, 1)
end

function Raiduku:AwardPrio(name, order)
    local itemId = self.Loots[1].link:match("|Hitem:(%d+):")
    local itemLink = self.Loots[1].link
    self:Award(self.Loots[1].index, name)
    tremove(self.db.profile.prios[tonumber(itemId)], order)
    self:Print(Raiduku.L["removed-x-from-prios-for-x"]:format(name, itemLink))
end

function Raiduku:GetSoftResList(itemId)
    local softres = Raiduku.db.profile.softres
    local sotfresList = {}
    if softres[itemId] then
        local raiders = {}
        for i = 1, GetNumGroupMembers() do
            local raiderName = GetRaidRosterInfo(i)
            raiders[raiderName] = true
        end
        for _, resPlayer in next, softres[itemId] do
            if raiders[resPlayer.name] then
                print(resPlayer.name .. " resa for " .. itemId)
                tinsert(sotfresList, {
                    name = resPlayer.name,
                    class = resPlayer.class,
                    plus = resPlayer.plus,
                    roll = nil,
                    loots = {}
                })
            end
        end
    end
    return sotfresList
end

function Raiduku:GetHighestPlus()
    local highest = nil
    for _, player in ipairs(self.Players) do
        if player.plus and highest == nil then
            highest = player.plus
        elseif player.plus and highest and highest > player.plus then
            highest = player.plus
        end
    end
    return highest
end

function Raiduku:GetHighestPlusPlayers()
    local highestPlus = self:GetHighestPlus()
    local highestPlusPlayers = {}
    for _, player in ipairs(Raiduku.Players) do
        if player.plus == highestPlus then
            table.insert(highestPlusPlayers, player)
        end
    end
    return highestPlusPlayers, highestPlus
end

function Raiduku:GetWinner()
    local winner = nil
    local highestPlusPlayers, highestPlus = self:GetHighestPlusPlayers()
    local highestRoll = Raiduku.db.profile.reverseRollOrder and 100 or 0
    if #highestPlusPlayers == 1 then
        return highestPlusPlayers[1]
    end
    for _, player in ipairs(self.Players) do
        if player.plus == highestPlus then
            if Raiduku.db.profile.reverseRollOrder then
                if player.roll and highestRoll > player.roll then
                    highestRoll = player.roll
                    winner = player
                end
            else
                if player.roll and highestRoll < player.roll then
                    highestRoll = player.roll
                    winner = player
                end
            end
        end
    end
    return winner
end

function Raiduku:GetMissingRollPlayerNames()
    local highestPlusPlayers, highestPlus = self:GetHighestPlusPlayers()
    local players = {}
    if #highestPlusPlayers == 1 then
        return players
    end
    for _, player in ipairs(self.Players) do
        if player.plus == highestPlus and player.roll == nil then
            tinsert(players, player.name)
        end
    end
    return players
end

function Raiduku:SaveLootForTMB(loot, winner)
    local currentDate = self:GetCurrentDate()
    local itemId = loot:match("|Hitem:(%d+):")
    local itemName, itemLink = GetItemInfo(itemId)
    local note = winner.plus and winner.plus > 1 and "OS" or ""
    local csvRow = strjoin(",", winner.name, self:GetCurrentDate(), itemId, itemName, note)
    self.db.profile.loot[currentDate] = self.db.profile.loot[currentDate] or {}
    local alreadySaved = false
    for _, loots in next, self.db.profile.loot do
        for _, row in next, loots do
            if row == csvRow then
                alreadySaved = true
            end
        end
    end
    if not alreadySaved then
        tinsert(self.db.profile.loot[currentDate], csvRow)
        local spec = note == "OS" and self.L["off-spec"] or self.L["main-spec"]
        C_Timer.NewTimer(0.2, function()
            self.LootWindow.content:Show()
            self:Print(self.L["saved-for-tmb"]:format(winner.name, itemLink, spec))
        end)
    end
end

function Raiduku:UpdatePlusRollResults()
    local results = "\n"
    local missingRollPlayerNames = self:GetMissingRollPlayerNames()
    local winner = self:GetWinner()
    if #missingRollPlayerNames > 0 then
        self.LootWindow.rollsButton:SetEnabled(true)
        self.LootWindow.winnerButton:Disable()
    else
        self.LootWindow.rollsButton:Disable()
        if winner then
            self.LootWindow.winnerButton:SetEnabled(true)
        end
    end

    -- Sort player by plus, then roll
    table.sort(self.Players, function(left, right)
        local leftRoll = tonumber(left.roll) or 0
        local rightRoll = tonumber(right.roll) or 0
        local leftPlus = tonumber(left.plus) or 0
        local rightPlus = tonumber(right.plus) or 0
        if Raiduku.db.profile.reverseRollOrder then
            if leftPlus == rightPlus then
                return leftRoll < rightRoll
            end
            return leftPlus > rightPlus
        end
        if leftPlus == rightPlus then
            return leftRoll > rightRoll
        end
        return leftPlus < rightPlus
    end)

    for _, player in ipairs(self.Players) do
        results = results .. "|cff" .. self:GetColorByClass(player.class) .. player.name .. "|r"
        if tonumber(player.plus) == 1 then
            results = results .. " [|cFF00FF00+" .. player.plus .. "|r]"
        else
            if tonumber(player.plus) == 2 then
                results = results .. " [|cFF00D9FF+" .. player.plus .. "|r]"
            else
                results = results .. " [+" .. player.plus .. "]"
            end
        end
        if player.roll then
            if winner.name and player.name == winner.name then
                results = results .. " (|cFF00FF00" .. player.roll .. "|r)\n"
            else
                results = results .. " (" .. player.roll .. ")"
            end
        else
            local highestPlusPlayers, highestPlus = self:GetHighestPlusPlayers()
            if player.plus == highestPlus and #highestPlusPlayers == 1 then
                results = results .. " " .. self.L["auto-win"] .. "\n"
            elseif player.plus == highestPlus and #highestPlusPlayers > 1 then
                results = results .. " " .. self.L["waiting-for-roll"]
            else
                results = results .. " " .. self.L["auto-pass"]
            end
        end
        results = results .. "\n"
    end
    self.LootWindow.content:SetText(results)
end

--[[
    Events
--]]

function Raiduku:LootHandlerWrapper(callback, ...)
    local method = GetLootMethod()
    if Raiduku.isML and method == "master" then
        callback(...)
    end
end

function Raiduku:CHAT_MSG_RAID(event, ...)
    Raiduku:LootHandlerWrapper(lootLinkedHandler, ...)
    Raiduku:LootHandlerWrapper(playerPlusHandler, ...)
end

function Raiduku:CHAT_MSG_RAID_LEADER(event, ...)
    Raiduku:LootHandlerWrapper(lootLinkedHandler, ...)
    Raiduku:LootHandlerWrapper(playerPlusHandler, ...)
end

function Raiduku:CHAT_MSG_RAID_WARNING(event, ...)
    Raiduku:LootHandlerWrapper(lootLinkedHandler, ...)
end

function Raiduku:CHAT_MSG_PARTY(event, ...)
    Raiduku:LootHandlerWrapper(lootLinkedHandler, ...)
    Raiduku:LootHandlerWrapper(playerPlusHandler, ...)
end

function Raiduku:CHAT_MSG_PARTY_LEADER(event, ...)
    Raiduku:LootHandlerWrapper(lootLinkedHandler, ...)
    Raiduku:LootHandlerWrapper(playerPlusHandler, ...)
end

function Raiduku:CHAT_MSG_SYSTEM(event, ...)
    Raiduku:LootHandlerWrapper(playerRollHandler, ...)
end

function Raiduku:CHAT_MSG_LOOT(event, ...)
    Raiduku:LootHandlerWrapper(chatMsgLootHandler, ...)
end

function Raiduku:LOOT_OPENED(event, ...)
    Raiduku:LootHandlerWrapper(lootOpenedHandler)
end

function Raiduku:LOOT_CLOSED(event, ...)
    Raiduku:LootHandlerWrapper(resetAll)
end

function Raiduku:TRADE_SHOW(event, ...)
    local tradeTargetName = _G.TradeFrameRecipientNameText:GetText()
    for _, loots in next, self.db.profile.loot do
        for _, row in next, loots do
            local name, _, itemId = strsplit(",", row)
            if name == tradeTargetName then
                if Raiduku:HasItemInBags(itemId) then
                    local bag, slot = Raiduku:GetContainerPosition(itemId)
                    UseContainerItem(bag, slot);
                end
            end
        end
    end
end
