GUI               = GUI
tableIterators    = tableIterators
GameObject        = GameObject
basicModule       = basicModule
errorHandling     = errorHandling
Debug             = Debug
Time              = Time
Vector2           = Vector2
Vector3           = Vector3
Vector4           = Vector4
Input             = Input
EnvironmentMaster = EnvironmentMaster

local newID       = "c767ab0e-4ba5-45e1-a6e1-c3e5bde1a136"
local newIDVoice  = "d5e31e55-d8e0-44df-927d-08f7b733d59b"
local changeIDs   = true




local maps = {
    Legacy       = 4,
    Canvas       = 5,
    DesertBridge = 6,
    Polar6       = 7,
    PitValley    = 8,
    Facility     = 9,
    Reminiscence = 10,
    Conspiracy   = 11,
    Afterglow    = 12,
    F2Square     = 13,
    Pillars      = 14,
    Waterpark    = 15,
    -- Duels         = 16,
    -- DisasterIsland = 17,
    -- Town          = 22,
}


local regions = {
    eu     = "Европа",
    sa     = "Бразилия",
    us     = "Америка",
    ru     = "Россия",
    ["in"] = "Индия",
    au     = "Австралия",
    jp     = "Япония",
    tr     = "Турция",
    asia   = "Азия",
}

local regionList = {
    "eu",
    "sa",
    "us",
    "ru",
    "in",
    "au",
    "jp",
    "tr",
    "asia"
}


local goodStates = {
    Joined                  = true,
    ConnectedToMasterServer = true,
    JoinedLobby             = true,
}

local connectionStates = {
    ConnectingToNameServer   = true,
    ConnectingToMasterServer = true,
    Authentication           = true,
}

local colors = {
    "#f66",
    "#f7b",
    "#f7f",
    "#97f",
    "#7af",
    "#46f",
    "#7fb",
    "#5f4",
    "#ff7",
    "#fba",
    "#f75",
}

local selectedColor = basicModule.tonumber(File.GetPlayerPrefsStr("nameColor", math.random(0, 10)))
if selectedColor == nil then
    selectedColor = math.random(0, 10)
    File.SetPlayerPrefsStr("nameColor", selectedColor)
end

local m16 = GameObject.Instantiate("pickUpAbles/M16")
local photonView = m16.GetComponent("photonView")
local componentType = photonView.CallMethod("GetType")
local assembly = componentType.GetField("Assembly")
m16.Destroy()

local allTypes = assembly.CallMethod("GetTypes")

local typeCache = {}

local function findTypeByName(typeName)
    if typeCache[typeName] then
        return typeCache[typeName]
    end
    for _, typeInfo in tableIterators.pairs(allTypes) do
        if typeInfo.CallMethod("get_Name") == typeName then
            typeCache[typeName] = typeInfo
            return typeInfo
        end
    end
    return nil
end


local PhotonNetworkType   = findTypeByName("PhotonNetwork")
local RoomOptionsType     = findTypeByName("RoomOptions")
local EnterRoomParamsType = findTypeByName("EnterRoomParams")


local roomOptionsProto     = RoomOptionsType.CallMethod("GetConstructors")[1].CallMethod("Invoke", {})
local enterRoomParamsProto = EnterRoomParamsType.CallMethod("GetConstructors")[1].CallMethod("Invoke", {})


local PhotonMono    = GameObject.FindAllByComponent("Photon.Pun.PhotonHandler")[1]
local PhotonHandler = PhotonMono.GetComponent("Photon.Pun.PhotonHandler")
local Client        = PhotonHandler.GetField("Client")


local appSettings

local function changeAppID()
    local success, err = errorHandling.pcall(function()
        local serverSettings = PhotonNetworkType.CallMethod("GetMethod", "get_PhotonServerSettings").CallMethod("Invoke",
            nil,
            nil)
        appSettings = serverSettings.GetField("AppSettings")

        if changeIDs then
            appSettings.SetField("AppIdVoice", newIDVoice)
            appSettings.SetField("AppIdRealtime", newID)
            Debug.log("Новый AppId: " .. newID)
            Debug.log("Новый AppIdVoice: " .. newIDVoice)
        end
    end)

    if not success then
        Debug.logError("Ошибка при изменении AppId: " .. basicModule.tostring(err))
    end
end


changeAppID()

local pingMethod = PhotonNetworkType.CallMethod("GetMethod", "GetPing")
local kickMethod = PhotonNetworkType.CallMethod("GetMethod", "CloseConnection")

local getCurrentRoomMethod
local disconnectMethod

local function GetCurrentRoom()
    if not getCurrentRoomMethod then
        getCurrentRoomMethod = PhotonNetworkType.CallMethod("GetMethod", "get_CurrentRoom")
    end
    return getCurrentRoomMethod.CallMethod("Invoke", nil, nil)
end

local function Disconnect()
    if not disconnectMethod then
        disconnectMethod = PhotonNetworkType.CallMethod("GetMethod", "Disconnect")
    end
    disconnectMethod.CallMethod("Invoke", nil, nil)
end


local ModLoader       = GameObject.FindAllByComponent("ModLoader")[1].GetComponent("ModLoader")
local cmaster         = GameObject.FindAllByComponent("ConnectionMaster")[1].GetComponent("ConnectionMaster")
local cmasterActive   = cmaster.Active

local DeviceInfo      = Input.GetDeviceInfo()
local localID         = string.gsub(
    basicModule.tostring(string.sub(DeviceInfo.deviceUniqueIdentifier, 1, 24))
    , "[^%w]", "")

local state           = ""
local address         = ""
local connectedReg    = ""
local ping            = 0
local delta           = 0.01
local fps             = 0
local stateChangeTime = 0


local mpError               = ""
local mpErrorTime           = 0

local connecting            = false
local curRoom               = nil
local curRoomName           = ""
local playersList           = {}
local playersWithSinkedName = {}
local playersProps          = {}
local playersData           = {}
local isMeHost              = false


local joinCode    = ""
local roomName    = "Room"
local mapName     = "Legacy"
local fixMapNum   = 4
local regionName  = regionList[math.random(1, #regionList)]
local regionLoc   = regions[regionName]
local GBRP        = false

local useCustomIK = false
local customIK    = ModLoader.CallMethod("GetIntegrityKey") or ""
local myIK        = ""
local checkIK     = false


local screenSize      = Input.GetScreenRect()
local isMenuOpen      = false
local accountMenuOpen = false
local inMenu          = true
local cors            = {}

local xWidth          = screenSize.x * 0.5
local YWidth          = screenSize.y * 0.6

local sideWidth       = xWidth * 0.25

local menuWidth       = xWidth * 0.5
local buttonHeight    = YWidth * 0.06

local togglePos       = Vector4.New(screenSize.x / 2 - 400, 10, 300, 25)
local AccPos          = Vector4.New(screenSize.x / 2 - 400 + 310, 10, 150, 25)
local areaRect        = Vector4.New(screenSize.x / 2 - menuWidth / 2 - 250, 40, menuWidth, YWidth)
local logoPos         = Vector4.New(screenSize.x / 2 - menuWidth / 2 - 250, YWidth + 50, 50, 50)
local logoPos2        = Vector4.New(screenSize.x / 2 + menuWidth / 2 - 300, YWidth + 45, 50, 60)

local playerScrollPos = Vector2.New(0, 0)

local myStyle         = GUI.NewStyle()
local tex             = Importer.ImportTexture("text.png")
local tex2            = Importer.ImportTexture("servers.png")


local time            = 0
local lastStateUpdate = 0
local lastLoad        = 0
local lastFiveCheck   = 0
local lastStateSync   = 0
local lastDataUpdate  = 0

local function updJoinCode()
    joinCode = string.format("|%s|%s|%s|", regionName, roomName, mapName)
end


local function updStats(code)
    local matchRegName, matchRoom, matchMapName = string.match(code, "|([^|]+)|([^|]+)|([^|]+)|")

    local matchRegLoc = regions[matchRegName]

    local matchMapCode = maps[matchMapName]
    if matchRegLoc ~= nil and matchMapCode ~= nil and matchRoom ~= nil then
        regionName, roomName, mapName = matchRegName, matchRoom, matchMapName
        regionLoc = basicModule.tostring(regions[regionName])
    end
end

function FindChild(obj, childName)
    local objt = obj.Transform
    for i = 0, objt.ChildCount - 1 do
        local childGO = objt.GetChild(i).GameObject
        if childGO.Name == childName then
            return childGO
        else
            FindChild(childGO, childName)
        end
    end
    return false
end

function KickPlayer(playerNam, reason)
    local LuaPlayer = FindPlayer(playerNam)
    if LuaPlayer then
        if reason then
            LuaPlayer.SendAnnouncement("Kicked", reason)
        end

        LuaPlayer.Kick()
        Debug.log("Кикнут " .. playerNam)
    else
        Debug.SendChatMessageError("не удается найти Lua " .. playerNam)
    end
end

function BanPlayer(playerNam, reason)
    local LuaPlayer = FindPlayer(playerNam)
    if LuaPlayer then
        if reason then
            LuaPlayer.SendAnnouncement("Banned", reason)
        end

        LuaPlayer.Ban()
        Debug.log("Забанен " .. playerNam)
    else
        Debug.SendChatMessageError("не удается найти Lua " .. playerNam)
    end
end

function HostToPlayer(playerNam)
    local PInfos = GameObject.FindAllByComponent("PlayerInfo")
    for i = 1, #PInfos do
        local info = PInfos[i]
        local infocomp = info.GetComponent("PlayerInfo")
        local playerll = infocomp.GetField("player")
        if playerll == nil then
            Debug.log(basicModule.tostring(infocomp.GetField("name")) .. " unvalid Pinfo")
        else
            if playerll.GetField("Username") == playerNam then
                infocomp.CallMethod("PressTransferHost")
            end
        end
    end

    Debug.log("Дали хост " .. playerNam)
end

local function OnOffcmaster(enabled)
    if cmaster then
        cmaster.Active = enabled
        cmasterActive  = enabled
    end
end

function GetID(LuaPlayer123)
    local character123 = LuaPlayer123.GetCharacter()
    if not character123 then return false end
    return character123.GameObject.GetComponent("PhotonView").GetAsUnknownType("Owner").GetField("UserId")
end

local function GetName(Pobj)
    return string.sub(string.gsub(string.sub(basicModule.tostring(Pobj), 16, -2), "[#']", ""), 1, 18)
end

function FindPlayer(str)
    local list = Player.GetAllPlayers()
    for i = 1, #list do
        if string.find(list[i].GetName(), str) or string.find(str, list[i].GetName()) then
            return list[i]
        end
    end
end

local function joinOrCreateRoom()
    fixMapNum = maps[mapName] or basicModule.tonumber(mapName)
    if not fixMapNum then return end

    OnOffcmaster(false)

    local roomOpt = roomOptionsProto.CallMethod("MemberwiseClone")
    roomOpt.SetField("MaxPlayers", 32)

    local enterOpt = enterRoomParamsProto.CallMethod("MemberwiseClone")
    enterOpt.SetField("RoomName", roomName .. ", " .. mapName)
    enterOpt.SetField("RoomOptions", roomOpt)

    Client.CallMethod("OpJoinOrCreateRoom", enterOpt)

    --IsMessageQueueRunning

    PhotonNetworkType.CallMethod("GetMethod", "set_IsMessageQueueRunning").CallMethod("Invoke", nil, false)

    OnOffcmaster(false)
    lastLoad = Time.GetRealTimeMs()
    GameObject.FindAllByComponent("GoreBoxMenu")[1].GetComponent("GoreBoxMenu").CallMethod("LoadLevelAsync", fixMapNum,
        true, ModLoader.CallMethod("GetIntegrityKey"))
    --LoadLevel(Int32 levelNumber)
    cmaster.GetField("gameModes").CallMethod("SwitchGameMode", "Custom")
    Debug.log("загрузка карты...")
end

local function leaveRoom()
    Client.CallMethod("OpLeaveRoom", false, false)
end





local function leftPanel()
    local w       = sideWidth * (curRoom and 1.5 or 1)
    local padding = 5
    local rect    = Vector4.New(areaRect.x - w - 10, areaRect.y, w, YWidth * 1.1)

    GUI.BeginArea(rect)
    GUI.Box(Vector4.New(0, 0, w, YWidth * 1.1), "")
    GUI.Space(10)

    if curRoom then
        GUI.BeginHorizontal()
        GUI.Space(padding)
        GUI.Label("<#ffb><b>" .. curRoomName, w - padding * 2, 20)
        GUI.EndHorizontal()

        GUI.BeginHorizontal()
        GUI.Space(padding)
        GUI.Label(
            "<#ccc>Игроков:<b> " .. #playersList .. "/" ..
            basicModule.tostring(curRoom.GetField("MaxPlayers")), w - padding * 2, 20)
        GUI.EndHorizontal()

        GUI.Space(5)

        playerScrollPos = GUI.BeginScrollView(playerScrollPos, w, YWidth)
        for i = 1, #playersList do
            GUI.BeginHorizontal()
            GUI.Space(padding * 1.5)
            local currName = GetName(playersList[i])
            GUI.Label(
                (i % 2 == 1 and "<#fff>" or "<#eee>") ..
                currName ..
                (playersData[currName] ~= nil and "   " .. basicModule.tostring(playersData[currName].state) .. "<b>" .. (playersData[currName].host and " <color=yellow>[host]</color> " or "") .. (playersData[currName].mods and " <color=red>[mod]</color>" or "") or ""),
                300,
                20)
            GUI.EndHorizontal()

            if playersData[currName] and playersData[currName].mods then
                GUI.BeginHorizontal()
                GUI.Space(padding * 1.25)
                if GUI.Button("<b>Лог", 40, 20) then
                    Debug.log("Mods of " .. currName .. ": " .. playersData[currName].modList)
                end
                GUI.Label("Моды: " .. playersData[currName].modList, 1000, 20)
                GUI.EndHorizontal()
            end

            if isMeHost then
                GUI.BeginHorizontal()
                GUI.Space(padding * 2)

                if GUI.Button("<#fd0>Передать хоста", 100, 20) then
                    HostToPlayer(currName)
                    Server.SendChatMessage("<color=yellow>Хост передан игроку " .. currName, 15)
                end
                if GUI.Button("<#f90><b>Кик", 50, 20) then
                    KickPlayer(currName, "Хост кикнул вас.")
                    Server.SendChatMessage("<color=yellow>" .. currName .. " Был кикнут", 10)
                end
                if GUI.Button("<#f40><b>Бан", 50, 20) then
                    BanPlayer(currName, "Хост забанил вас.")
                    Server.SendChatMessage("<color=yellow>" .. currName .. " Был забанен", 10)
                end

                GUI.EndHorizontal()
            end
            GUI.Space(10)
        end


        GUI.EndScrollView()
    else
        GUI.BeginHorizontal()
        GUI.Space(padding)
        GUI.Label("<#ffb><b>Выбор карты (" .. mapName .. ")", w - padding * 2, 20)
        GUI.EndHorizontal()

        for minimap in tableIterators.pairs(maps) do
            GUI.BeginHorizontal()
            GUI.Space(padding)
            if GUI.Button((minimap == mapName and "<b><#bfb>" .. minimap or minimap), w - padding * 2, buttonHeight / 1.15) then
                mapName = minimap
                updJoinCode()
            end
            GUI.EndHorizontal()
        end
    end

    GUI.EndArea()
end


local function rightPanel()
    local w       = sideWidth
    local padding = 5
    local rect    = Vector4.New(areaRect.x + menuWidth + 10, areaRect.y, w, YWidth * 1.1)

    GUI.BeginArea(rect)
    GUI.Box(Vector4.New(0, 0, w, YWidth * 1.1), "")
    GUI.Space(10)

    GUI.BeginHorizontal()
    GUI.Space(padding)
    GUI.Label(
        "<#ffb><b>Выбрать регион (" .. basicModule.tostring(regionLoc) .. " | " .. basicModule.tostring(regionName) .. ")",
        w - padding * 2, 20)
    GUI.EndHorizontal()

    for regCode, regTitle in tableIterators.pairs(regions) do
        GUI.BeginHorizontal()
        GUI.Space(padding)
        if GUI.Button((regTitle == regionLoc and "<b><#bfb>" .. regTitle or regTitle), w - padding * 2, buttonHeight / 1.15) then
            regionName = regCode
            regionLoc = regTitle
            updJoinCode()
        end
        GUI.EndHorizontal()
    end

    GUI.EndArea()
end


local function centerPanel()
    local contentW = menuWidth * 0.85
    local padding  = (menuWidth - contentW) / 2

    GUI.BeginArea(areaRect)
    GUI.Box(Vector4.New(0, 0, menuWidth, YWidth), "")
    GUI.Space(20)

    GUI.BeginHorizontal()
    GUI.Space(padding)
    GUI.Label(
        "<align=center>GBPS by Пробел.", contentW, 20)
    GUI.EndHorizontal()

    GUI.BeginHorizontal()
    GUI.Space(padding)
    GUI.Label(
        (goodStates[state] and "<#bfb>" or "") .. "Статус: " .. state,
        contentW, 20)
    GUI.EndHorizontal()

    --if state == "Disconnected" then
    --    GUI.BeginHorizontal()
    --    GUI.Space(padding)
    --    if GUI.Button((changeIDs and "<b>" or "") .. "Change AppId: " .. (changeIDs and "✓" or "X"), contentW, buttonHeight * 0.8) then
    --        changeIDs = not changeIDs
    --        changeAppID()
    --    end
    --    GUI.EndHorizontal()
    --    if changeIDs then
    --        GUI.BeginHorizontal()
    --        GUI.Label("AppId: ", contentW/8, 20)
    --        newID = GUI.TextField(newID, 32, contentW, 25)
    --        GUI.EndHorizontal()
    --        GUI.BeginHorizontal()
    --        GUI.Label("Voice Id: ", contentW/8, 20)
    --        newIDVoice = GUI.TextField(newIDVoice, 32, contentW, 25)
    --        GUI.EndHorizontal()
    --    end
    --end



    GUI.BeginHorizontal()
    GUI.Space(padding)
    GUI.Label(
        "Адрес сервера: " .. address ..
        " (<b>" .. connectedReg .. "</b>) | пинг: " .. ping,
        contentW + 50, 20)
    GUI.EndHorizontal()


    GUI.Space(10)

    GUI.BeginHorizontal()
    GUI.Space(padding)
    if GUI.Button((checkIK and "<#bfb>" or "") .. "[Хост] кикнуть из игры при несоответствии модов: " .. (checkIK and "✓" or "X"), contentW, buttonHeight * 0.8) then
        checkIK = not checkIK
    end
    GUI.EndHorizontal()



    if checkIK then
        GUI.BeginHorizontal()
        GUI.Space(padding)
        if GUI.Button((useCustomIK and "<#bfb>" or "") .. "Использовать свой IK: " .. (useCustomIK and "✓" or "X") .. " (Отключить автоматическое чтение.)", contentW, buttonHeight * 0.75) then
            useCustomIK = not useCustomIK
        end
        GUI.EndHorizontal()

        if useCustomIK then
            GUI.BeginHorizontal()
            GUI.Space(padding)
            customIK = GUI.TextField(customIK, 2048, contentW, 20)
            GUI.EndHorizontal()
        end
    else
        GUI.BeginHorizontal()
        GUI.Space(padding)
        GUI.Label("<b>↑  Если эта функция отключена, игроки могут читерить или выходить из игры.", contentW, 25)
        GUI.EndHorizontal()
    end

    GUI.Space(5)



    GUI.BeginHorizontal()
    GUI.Space(padding)
    if GUI.Button((GBRP and "<#bfb>" or "") .. "[Хост] Выключить GBRP: " .. (GBRP and "✓" or "X"), contentW, buttonHeight * 0.8) then
        GBRP = not GBRP
        lastDataUpdate = 0
        lastFiveCheck = 0
    end
    GUI.EndHorizontal()


    --GUI.Space(10)
    --if state ~= "Joined" and not (goodStates[state] and regionName == connectedReg) then
    --    GUI.BeginHorizontal()
    --    GUI.Space(padding)
    --    if GUI.Button((state == "Disconnected" and "<#efe>" or "") .. "Connect" .. (connectionStates[state] and "ing" or "") .. " to " .. basicModule.tostring(regionLoc), contentW, buttonHeight) then
    --        OnOffcmaster(false)
    --        Client.CallMethod("ConnectUsingSettings", appSettings)
    --        Client.CallMethod("ConnectToRegionMaster", regionName)
    --    end
    --    GUI.EndHorizontal()
    --end

    --GUI.Space(5)
    --if state ~= "Disconnected" then
    --    GUI.BeginHorizontal()
    --    GUI.Space(padding)
    --    if GUI.Button("<#fbb>Disconnect", contentW, buttonHeight) then
    --        Disconnect()
    --    end
    --    GUI.EndHorizontal()
    --end

    GUI.Space(10)

    GUI.BeginHorizontal()
    GUI.Space(padding)

    GUI.Label("Название сервера:", contentW, 20)
    GUI.EndHorizontal()
    GUI.BeginHorizontal()
    GUI.Space(padding)
    local oldRoomName = roomName
    roomName = GUI.TextField(roomName, 32, contentW, 25)
    if roomName ~= oldRoomName then
        updJoinCode()
    end
    GUI.EndHorizontal()

    GUI.Space(5)

    --if state == "JoinedLobby" or state == "ConnectedToMasterServer" then
    GUI.BeginHorizontal()
    GUI.Space(padding)
    if GUI.Button((connecting and "<#dfd>joining to " or "<#dfd>Зайдите/Создайте сервер ") .. roomName, contentW, buttonHeight) then
        if not connecting then
            local x
            x = coroutine.create(function()
                connecting = true
                local connectCount = 0
                local tryCount = 0
                local function wait(waittime)
                    cors[x] = time + waittime
                    coroutine.yield()
                end
                while true do
                    tryCount = tryCount + 1
                    if tryCount > 10 then
                        break
                    end
                    local newState = basicModule.tostring(Client.GetField("State") or "Unknown")
                    if newState ~= state then
                        state = newState
                        stateChangeTime = time
                    end

                    if state == "Disconnected" then
                        connectCount = connectCount + 1
                        if connectCount > 5 then
                            mpError = "<#fbb>Не удалось подключиться к серверу. Попробуйте ещё раз или смените регион."
                            mpErrorTime = time
                            connecting = false
                            return
                        end
                        OnOffcmaster(false)
                        Client.CallMethod("ConnectUsingSettings", appSettings)
                        Client.CallMethod("ConnectToRegionMaster", regionName)
                    end

                    if state == "ConnectedToMasterServer" or state == "JoinedLobby" then
                        joinOrCreateRoom()
                        connecting = false
                        break
                    end

                    if state == "Joined" then
                        connecting = false
                        break
                    end

                    wait(1000)
                end
            end)
            cors[x] = 0
        end
    end
    GUI.EndHorizontal()
    --end

    GUI.BeginHorizontal()
    GUI.Space(padding)
    GUI.Label("Если этого сервера не существует, он будет создан.", contentW, 25)
    GUI.EndHorizontal()

    if time < mpErrorTime + 15000 then
        GUI.BeginHorizontal()
        GUI.Space(padding)
        GUI.Label(mpError, contentW, 60)
        GUI.EndHorizontal()
    else
        GUI.Space(5)
    end
        GUI.BeginHorizontal()
        GUI.Space(padding)
        GUI.Label("Код подключения:", contentW, 20)
        GUI.EndHorizontal()
        GUI.BeginHorizontal()
        GUI.Space(padding)
        local newJoinCode = GUI.TextField(joinCode, 32, contentW, 25)
        if joinCode ~= newJoinCode then
            updStats(newJoinCode)
            joinCode = newJoinCode
        else
            updJoinCode()
        end
        GUI.EndHorizontal()
    if state == "Joined" then
        GUI.BeginHorizontal()
        GUI.Space(padding)
        if GUI.Button("<#fbb>Выйти с сервера", contentW, buttonHeight) then
            leaveRoom()
        end
        GUI.EndHorizontal()
    end

    --GUI.Space(5)

    --GUI.BeginHorizontal()
    --GUI.Space(padding)
    --if GUI.Button("Ресет игры.", contentW, buttonHeight) then
    --    GameObject.FindAllByComponent("LoadingScreen")[1].GetComponent("LoadingScreen").CallMethod("DoLoading", 0, 0, 1,
    --        true, false, true, "Intro", "", "", "")
    --end
    --GUI.EndHorizontal()

    GUI.EndArea()
end

function OnGUIOver()
    if inMenu or PlayerMaster.InUI then
        if GUI.ButtonRect(togglePos, "GBPS") then
            isMenuOpen = not isMenuOpen
            if isMenuOpen then
                accountMenuOpen = false
            end
        end
    end

    if inMenu then
        if GUI.ButtonRect(AccPos, "Я") then
            accountMenuOpen = not accountMenuOpen
            if accountMenuOpen then
                isMenuOpen = false
            end
        end
    end

    if isMenuOpen then
        if GUI.ButtonRect(logoPos, "", myStyle) then
            local comp = GameObject.Create("linkOpener").AddComponent("BrowserLink")
            comp.SetField("url", "https://t.me/Gap_Zip")
            comp.CallMethod("OpenLink")
            comp.GameObject.Destroy()
        end
        GUI.DrawTexture(logoPos, tex, "StretchToFill", true, 1)

        if GUI.ButtonRect(logoPos2, "", myStyle) then
            local comp = GameObject.Create("linkOpener").AddComponent("BrowserLink")
            comp.SetField("url", "https://discord.gg/p4KnZEVPgT")
            comp.CallMethod("OpenLink")
            comp.GameObject.Destroy()
        end
        GUI.DrawTexture(logoPos2, tex2, "StretchToFill", true, 1)

        leftPanel()
        rightPanel()
        centerPanel()
    end

    if accountMenuOpen then
        local contentW = menuWidth * 0.85
        local padding  = (menuWidth - contentW) / 2

        GUI.BeginArea(areaRect)
        GUI.Box(Vector4.New(0, 0, menuWidth, YWidth), "")
        GUI.Space(10)

        GUI.BeginHorizontal()
        GUI.Space(padding)
        GUI.Label("<#ffb><b>Select name color", contentW - padding * 2, 20)
        GUI.EndHorizontal()

        GUI.BeginHorizontal()
        GUI.Space(padding)
        if GUI.Button("<b>Random", contentW, buttonHeight / 1.15) then
            selectedColor = math.random(0, 10)
            File.SetPlayerPrefsStr("nameColor", selectedColor)
        end
        GUI.EndHorizontal()

        for colorCode, colorHex in tableIterators.ipairs(colors) do
            GUI.BeginHorizontal()
            GUI.Space(padding)
            if GUI.Button("<" .. colorHex .. "><b>" .. (colorCode - 1 == selectedColor and "> " or "") .. "Пробел", contentW, buttonHeight / 1.15) then
                selectedColor = colorCode - 1
                File.SetPlayerPrefsStr("nameColor", selectedColor)
            end
            GUI.EndHorizontal()
        end

        GUI.EndArea()
    end
end

local delTransfer = false

function Update()
    time = Time.GetRealTimeMs()
    delta = delta + (Time.UnscaledDeltaTime - delta) * 0.02


    if time > lastStateUpdate + (inMenu and 500 or 1500) then
        lastStateUpdate = time

        local newState = basicModule.tostring(Client.GetField("State") or "Unknown")
        if newState ~= state then
            state = newState
            stateChangeTime = time
        end
        address      = basicModule.tostring(Client.GetField("CurrentServerAddress") or "Not Connected")
        connectedReg = basicModule.tostring(Client.GetField("CloudRegion"))
        ping         = pingMethod.CallMethod("Invoke", nil, nil) or 0
        curRoom      = GetCurrentRoom()
        if curRoom then
            curRoomName = string.gsub(curRoom.GetField("Name"), "§.*", "")
            playersList = curRoom.GetField("players") or {}

            for i = 1, #playersList do
                playersList[i] = playersList[i].GetField("value")
            end

            if EnvironmentMaster.GetCurrentScene() == "sys_Menu" then
                if not inMenu then
                    lastDataUpdate = 0


                    OnOffcmaster(true)
                end
                inMenu = true
            else
                if inMenu then
                    inMenu = false
                    lastDataUpdate = 0
                    lastFiveCheck = 0
                    PhotonNetworkType.CallMethod("GetMethod", "set_IsMessageQueueRunning").CallMethod("Invoke", nil,
                        true)
                    accountMenuOpen = false
                    isMenuOpen      = false
                    myIK            = ModLoader.CallMethod("GetIntegrityKey")
                    OnOffcmaster(false)


                    local GameMaster = GameObject.FindAllByComponent("GameMaster")[1].Transform

                    local button1 = GameMaster.Find("GameCanvas-3/PanelManager/MenuPanel/ReturnMenu/Button")
                        .GameObject
                        .GetComponent("UnityEngine.UI.Button")
                    local button2 = GameMaster.Find(
                            "GameCanvas-3/PanelManager/MenuPanel (NewRestricted)/ReturnMenu/Button").GameObject
                        .GetComponent(
                            "UnityEngine.UI.Button")
                    if button1 then
                        button1.GetField("onClick").AddListener(function()
                            OnOffcmaster(true)
                        end)
                    else
                        Debug.log("no button1")
                    end
                    if button2 then
                        button2.GetField("onClick").AddListener(function()
                            OnOffcmaster(true)
                        end)
                    else
                        Debug.log("no button2")
                    end

                    local infoPrefab = GameObject.FindAllByComponent("ServerPanel")[1].GetComponent("ServerPanel")
                        .GetField("infoPrefab").GameObject

                    local TransferHostButton = infoPrefab.Transform.Find("Options (OBD)/TransferHost")
                    if TransferHostButton then
                        TransferHostButton.LocalScale = Vector3.Zero
                    end
                end
                inMenu = false
            end
        else
            inMenu                = true
            curRoomName           = ""
            playersList           = {}
            playersData           = {}
            playersWithSinkedName = {}
        end
    end




    if delTransfer then
        delTransfer = false
        local PInfos = GameObject.FindAllByComponent("PlayerInfo")
        for i = 1, #PInfos do
            local info = PInfos[i]
            local infocomp = info.GetComponent("PlayerInfo")
            local playerll = infocomp.GetField("player")
            if playerll == nil then
                Debug.log(basicModule.tostring(infocomp.GetField("name")) .. " unvalid Pinfo")
            else
                local TransferHostButton = info.Transform.Find("Options (OBD)/TransferHost")
                if TransferHostButton then
                    if playerll.GetField("IsLocal") then
                        TransferHostButton.GameObject.Destroy()
                    end
                end
            end
        end
    end

    if Input.GetKeyDown("Escape") or Input.GetButtonDown("Menu") then
        isMenuOpen = false
        delTransfer = true
    end

    if state == "LeavingRoom" or state == "Disconnecting" then
        OnOffcmaster(true)
    end



    if time > lastFiveCheck + 5000 then
        lastFiveCheck = time + 20000 --будет ждать 20 сек если ошибка
        local x
        x             = coroutine.create(function()
            local function wait(waittime)
                cors[x] = time + waittime
                coroutine.yield()
            end

            local localPlayer = Client.GetField("LocalPlayer")
            local localProps  = localPlayer.GetAsUnknownType("CustomProperties")
            if time > lastDataUpdate + 60000 then
                local activeMods = ""

                local activeModsList = GameObject.FindAllByComponent("LuaScriptController")

                for i = 1, #activeModsList do
                    activeMods = activeMods .. (i ~= 1 and ", " or "") .. activeModsList[i].Name
                end

                Debug.log("Активны моды: " .. activeMods)

                lastDataUpdate = time
                if localProps.CallMethod("ContainsKey", "IK") then
                    localProps.CallMethod("set_Item", "IK", myIK)
                else
                    localProps.CallMethod("Add", "IK", myIK)
                end
                if localProps.CallMethod("ContainsKey", "Mods") then
                    localProps.CallMethod("set_Item", "Mods", activeMods)
                else
                    localProps.CallMethod("Add", "Mods", activeMods)
                end
                if localProps.CallMethod("ContainsKey", "ID") then
                    localProps.CallMethod("set_Item", "ID", localID)
                else
                    localProps.CallMethod("Add", "ID", localID)
                end
                if localProps.CallMethod("ContainsKey", "I") then
                    localProps.CallMethod("set_Item", "I", selectedColor)
                else
                    localProps.CallMethod("Add", "I", selectedColor)
                end
                if localProps.CallMethod("ContainsKey", "GBRP") then
                    localProps.CallMethod("set_Item", "GBRP", GBRP)
                else
                    localProps.CallMethod("Add", "GBRP", GBRP)
                end
            end
            localPlayer.CallMethod("SetCustomProperties", localProps, nil, nil)
            localPlayer.SetField("i", selectedColor)
            isMeHost = localPlayer.GetField("isHost")
            wait(0)
            if not curRoom then return end
            for i = 1, #playersList do
                wait(0)

                local realPlayer = playersList[i]
                local realName   = GetName(realPlayer)



                if not playersData[realName] then
                    playersData[realName] = {}
                end

                local props                 = realPlayer.GetAsUnknownType("CustomProperties")
                playersProps[realName]      = props
                playersData[realName].state = basicModule.tostring(props.CallMethod("get_Item", "State"))
                playersData[realName].fps   = basicModule.tostring(props.CallMethod("get_Item", "FPS"))
                playersData[realName].host  = realPlayer.GetField("isHost")
                if playersData[realName].host == true then
                    local isGBRP = props.CallMethod("get_Item", "GBRP")
                    if isGBRP ~= nil then
                        local gbrpt = GameObject.FindAllByComponent("AdditionalGamemodeMaster")[1].transform.Find(
                            "OS/GBRP")
                        if gbrpt ~= nil then
                            gbrpt.gameObject.active = isGBRP
                            gbrpt.parent.gameObject.active = isGBRP
                        end
                    end
                end

                if not playersWithSinkedName[realName] then
                    local realID = basicModule.tostring(props.CallMethod("get_Item", "ID"))
                    local realColor = basicModule.tostring(props.CallMethod("get_Item", "I"))
                    playersData[realName].id = realID

                    realPlayer.SetField("Username", realName)
                    realPlayer.SetField("i", realColor)
                    realPlayer.SetField("UserId", realID)
                    if isMeHost then
                        local GameRules = GameObject.FindAllByComponent("GameRules")[1].GetComponent("GameRules")
                        local EnvMaster = GameObject.FindAllByComponent("EnvironmentMaster")[1].GetComponent(
                            "EnvironmentMaster")
                        GameRules.CallMethod("SendSyncGamemode", realPlayer)
                        EnvMaster.CallMethod("SendSyncWeather", realPlayer)
                        Debug.log("Sended weather and perms to " .. realName)
                        Server.SendChatMessage("<color=yellow>" .. realName .. " joined the server", 20)
                    end

                    playersWithSinkedName[realName] = true
                end
                playersData[realName].mods = false
                local kick = false
                if true then
                    local playerIK                = basicModule.tostring(props.CallMethod("get_Item", "IK"))
                    playersData[realName].ik      = playerIK
                    playersData[realName].modList = basicModule.tostring(props.CallMethod("get_Item", "Mods"))

                    if useCustomIK then
                        if playersData[realName].ik ~= customIK then
                            kick = true
                        end
                    else
                        if playersData[realName].ik ~= myIK then
                            kick = true
                        end
                    end
                    if kick then
                        playersData[realName].mods = true
                        if isMeHost and checkIK then
                            if localPlayer.GetField("Username") ~= realName then
                                local msg = "<color=red><b>" ..
                                    realName .. "</b> Использование модов кик.</color>"
                                Server.SendChatMessage(msg, 20)
                                Debug.log(msg)
                                kickMethod.CallMethod("Invoke", nil, realPlayer)
                                local result = KickPlayer(realName,
                                    "Ваши моды не совпадают с модами хоста. (Хост не разрешил различия в модах.)")
                                if not result then
                                    Server.SendChatMessage("Ошибка при выполнении удара ногой.", 20)
                                end
                            end
                        end
                    else
                        playersData[realName].mods = false
                    end
                end
            end

            lastFiveCheck = Time.GetRealTimeMs()

            --[[
    LuaUnknownType(#01 'Пробел')
        _isFriend: LuaUnknownType(False)
        _isSpeaking: LuaUnknownType(False)
        actorNumber: LuaUnknownType(1)
        ActorNumber: 1
        criminality: 0
        Criminality: 0
        CustomProperties: table: 008CEAA0
          LuaUnknownType([ID, C2C551C7E416D8A4])
          LuaUnknownType([I, 8])
          LuaUnknownType([C, -1])
        ghost: LuaUnknownType(False)
        Ghost: LuaUnknownType(False)
        hadLocalContract: LuaUnknownType(False)
        hasContractOnLocal: LuaUnknownType(False)
        HasRejoined: nil
        i: 8
        IsFriend: LuaUnknownType(False)
        isHost: true
        IsInactive: LuaUnknownType(False)
        IsLocal: true
        IsMasterClient: LuaUnknownType(True)
        isMuted: LuaUnknownType(False)
        isOriginalHost: true
        IsSpeaking: LuaUnknownType(False)
        nickName: LuaUnknownType(Пробел)
        NickName: Пробел
        PI: nil
        PN: Component(PlayerName)
        sentRequest: LuaUnknownType(False)
        TagObject: nil
        UserId: nil
        Username: Пробел
        Int32 Bounty()
        Void ChangeLocalID(Int32 newID)
        Int32 CriminalityLevel()
        String CriminalityStars()
        Int32 GetMoney()
        PlayerMaster GetPlayer()
        Void InternalCacheProperties(Hashtable properties)
        Boolean isCriminal()
        Void SetCriminalSynced(Single value)
        Boolean SetCustomProperties(Hashtable propertiesToSet, Hashtable expectedValues, WebFlags webFlags)
        Boolean SetPlayerNameProperty()
        String ToStringFull()]]
        end)
        cors[x]       = 0
    end

 

    for corout, cortime in tableIterators.pairs(cors) do
        if time > cortime then
            cors[corout] = nil
            local succes, error = coroutine.resume(corout)
            if not succes then
                Debug.logError("Ошибка подключения (GBPS): " .. error)
            end
        end
    end

    if time > lastStateSync + 20000 then
        lastStateSync = time

        if curRoom then
            fps               = math.ceil(1 / delta)
            local pingfps     = ping .. " ms; " .. fps .. " fps"
            local localPlayer = Client.GetField("LocalPlayer")
            local localProps  = localPlayer.GetAsUnknownType("CustomProperties")
            if localProps.CallMethod("ContainsKey", "State") then
                localProps.CallMethod("set_Item", "State", pingfps)
            else
                localProps.CallMethod("Add", "State", pingfps)
            end
            localPlayer.CallMethod("SetCustomProperties", localProps, nil, nil)
        end
    end
end
