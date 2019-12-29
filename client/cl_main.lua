local entitiesToDraw = {}
local foliageToDraw = {}
local itemsToDraw = {}
local vehiclesToDraw = {}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if IsControlJustReleased(0, 0xA5BDCD3C) then
            SetNuiFocus(true, true)
        end
    end
end)

RegisterNUICallback('loaded', function(data, cb)
    SendNUIMessage({
        type = 'ON_SET_TRACKED',
        entities = Config.TrackEntities,
        foliage = Config.TrackFoliage,
        items = Config.TrackItems,
        vehicles = Config.TrackVehicles,
    })
end)

RegisterNUICallback('set_tracking', function(data)
    if data.value == false then
        Config[data.key] = false
        if data.key == 'TrackEntities' then
            entitiesToDraw = {}
        elseif data.key == 'TrackFoliage' then
            foliageToDraw = {}
        elseif data.key == 'TrackItems' then
            itemsToDraw = {}
        elseif data.key == 'TrackVehicles' then
            vehiclesToDraw = {}
        end
    else
        Config[data.key] = 1
    end
end)

RegisterNUICallback('close_ui', function(data, cb)
    SetNuiFocus(false)
end)

Citizen.CreateThread(function()
    -- UI loop
    while true do
        Citizen.Wait(10)
        DrawCoords()

        DrawTrackedInfo()

        -- Draw Player Location / Spawn Location
        local player = GetPlayerPed()
        local pCoords = GetEntityCoords(player)
        local pDir = GetEntityHeading(player)

        -- Draw Player Location
        TxtAtWorldCoord(pCoords.x, pCoords.y, pCoords.z - 0.85, player .."\n?", 0.2, 2)
        local carriedEntity = Citizen.InvokeNative(0xD806CD2A4F2C2996, player)
        local carriedEntityModel = GetEntityModel(carriedEntity)
        local carriedEntityHash = Citizen.InvokeNative(0x31FEF6A20F00B963, carriedEntity)
        if carriedEntity then
            TxtAtWorldCoord(pCoords.x, pCoords.y, pCoords.z - 0.6, "Carrying: id: " .. carriedEntity .. ' model : ' .. carriedEntityModel .. " | " .. (GetHashName(carriedEntityModel) or ""), 0.175, 1)
            if carriedEntityHash then
                TxtAtWorldCoord(pCoords.x, pCoords.y, pCoords.z - 0.7, "Carrying: " .. carriedEntityHash .. " | " .. (GetHashName(carriedEntityHash) or ""), 0.175, 1)
            end
        end

        -- Draw Spawn Location
        local spawnCoords = GetOffsetFromEntityInWorldCoords(player, 0, 5.0, -0.5)
        TxtAtWorldCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z, "?", 0.2, 2)
    end
end)

Citizen.CreateThread(function()
    -- Surrounding Info / Tracking
    while true do
        Citizen.Wait(10)
        local player = PlayerPedId()

        -- World - Ground / Walls / Rocks
        -- Below Player
        local coords = GetEntityCoords(player)
        local shapeTest = StartShapeTestRay(coords.x, coords.y, coords.z, coords.x, coords.y, coords.z - 5.0, 1, 1)
        local rtnVal, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shapeTest)
        if hit > 0 then
            TxtAtWorldCoord(endCoords.x, endCoords.y, endCoords.z, "Standing On: " .. tostring(entityHit), 0.15, 1)
        end

        -- World - Ground / Walls / Rocks
        -- Infront of Player
        local coordsf = GetOffsetFromEntityInWorldCoords(player, 0.0, 2.5, 0.0)
        local shapeTest = StartShapeTestRay(coords.x, coords.y, coords.z, coordsf.x, coordsf.y, coordsf.z, 1)
        local rtnVal, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shapeTest)
        if hit > 0 then
            TxtAtWorldCoord(endCoords.x, endCoords.y, endCoords.z, "1: " .. tostring(entityHit), 0.3, 1)
        end

        local flags = {
            -- 1,    --    1 World - Ground / Walls / Rocks --  Disabled because the 2 above show below player and in front of player
            2,    --    2 Vehicle
            math.floor(2^2),  --    4 Ped
            math.floor(2^3),  --    8 Entity
            math.floor(2^4),  --   16 Items - Pelts / Buckets / Brooms / Power Poles / Lasso
            math.floor(2^5),  --   32 Pickup Weapon?
            math.floor(2^6),  --   64 Glass - Breakable?
            math.floor(2^7),  --  128 Water
            math.floor(2^8),  --  256 Shrubs / Bushes / Small Trees
            math.floor(2^9),  --  512 Road / Zone ?
            math.floor(2^10), -- 1024 Horse Ped
            math.floor(2^11), -- 2048 Horse Entity
            math.floor(2^12), -- 4096 Not seen
            math.floor(2^13), -- 8192 Not seen
            math.floor(2^14), -- 16384 Not seen
            math.floor(2^15), -- 32768 Not seen
            math.floor(2^16), -- 65536 Not seen
        }

        for key, flag in pairs(flags) do
            local excludeEntity = player
            local loop = { 1, 2 }
            if flag == 1 or flag == 4 or flag == 8 then
                loop = { 1 }
            end
            for _ in pairs(loop) do
                -- local coordsf = GetOffsetFromEntityInWorldCoords(player, 0.0, 2.5, 0.0)
                -- local shapeTest = StartShapeTestRay(coords.x, coords.y, coords.z, coordsf.x, coordsf.y, coordsf.z, flag, excludeEntity)
                local shapeTest = StartShapeTestBox(coords.x, coords.y, coords.z, 5.0, 5.0, 2.0, 0.0, 0.0, 0.0, true, flag, excludeEntity)
                local rtnVal, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shapeTest)
                excludeEntity = entityHit
                -- print(flag, rtnVal, hit, endCoords, surfaceNormal, entityHit)
                if hit > 0 then
                    local str = flag .. ": " .. tostring(entityHit) .. "\n"
                    if flag == 2 then
                        if Config.TrackVehicles == 1 then
                            vehiclesToDraw[entityHit] = true
                        else
                            str = false
                            DrawVehicleInfo(entityHit)
                        end
                    elseif flag == 2^3 or flag == 2^11 then
                        if Config.TrackEntities == 1 then
                            entitiesToDraw[entityHit] = true
                        else
                            str = false
                            DrawEntityInfo(entityHit)
                        end
                    elseif flag == 2^4 then
                        if Config.TrackItems == 1 then
                            itemsToDraw[entityHit] = true
                        else
                            str = false
                            DrawItemInfo(entityHit)
                        end
                    elseif flag == 2^8 then
                        if Config.TrackFoliage == 1 then
                            foliageToDraw[entityHit] = true
                        else
                            str = false
                            DrawFoliageInfo(entityHit)
                        end
                    end
                    if str then
                        TxtAtWorldCoord(endCoords.x, endCoords.y, endCoords.z, str, 0.2, 1)
                    end
                end
            end
        end
    end
end)

function LoadModel(model)
    local attempts = 0
    while attempts < 100 and not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    return IsModelValid(model)
end

function GetStatusText(status)
    local statusTexts = {
        "", -- 1
        "Being Hogtied", -- 2
        "On Ground", -- 3
        "Being Picked Up", -- 4
        "Being Carried", -- 5
        "Being Dropped", -- 6
    }
    if tonumber(status) == nil then
        if status == true then
            status = 1
        else
            status = 0
        end
    end
    if status > 0 and status < 7 then
        return statusTexts[status]
    else
        return status
    end
end

function DrawTrackedInfo()
    for entity, active in pairs(entitiesToDraw) do
        if active and IsEntityOnScreen(entity) then
            DrawEntityInfo(entity)
        end
    end

    for entity, active in pairs(itemsToDraw) do
        if active and IsEntityOnScreen(entity) then
            DrawItemInfo(entity)
        end
    end

    for entity, active in pairs(foliageToDraw) do
        if active and IsEntityOnScreen(entity) then
            DrawFoliageInfo(entity)
        end
    end

    for entity, active in pairs(vehiclesToDraw) do
        if active and IsEntityOnScreen(entity) then
            DrawVehicleInfo(entity)
        end
    end
end

function GetHashName(hash)
    if HASH_MODELS[hash] then
        return HASH_MODELS[hash]
    end
    if HASH_PEDS[hash] then
        return HASH_PEDS[hash]
    end
    if HASH_PROVISIONS[hash] then
        return HASH_PROVISIONS[hash]
    end
    if HASH_VEHICLES[hash] then
        return HASH_VEHICLES[hash]
    end
end

function DrawEntityInfo(entity)
    local str = "ID: " .. tostring(entity)
    local model_hash = GetEntityModel(entity)
    local model_name = GetHashName(model_hash)
    if not model_name  then
        str = str .. " | Model: ~e~" .. tostring(model_hash) .. "~q~\n"
    else
        str = str .. " | Model: " .. tostring(model_hash) .. "\n"
        str = str .. model_name .. "\n"
    end
    str = str .. "MetapedType: " .. tostring(Citizen.InvokeNative(0xEC9A1261BF0CE510, entity))
    str = str .. " | PedType: " .. tostring(GetPedType(entity))
    str = str .. " | Pop Type: ".. tostring(GetEntityPopulationType(entity)) .. "\n"
    str = str .. "Looted: " .. tostring(Citizen.InvokeNative(0x8DE41E9902E85756, entity)) -- Set looted status with 0x6BCF5F3D8FFE988D
    str = str .. " | Visible: " .. tostring(Citizen.InvokeNative(0xC8CCDB712FBCBA92, entity)) .. "\n"
    local entityStatus = Citizen.InvokeNative(0x61914209C36EFDDB, entity)
    str = str .. "Status: " .. GetStatusText(entityStatus) .. "\n"
    str = str .. tostring(Citizen.InvokeNative(0x97F696ACA466B4E0, entity))
    str = str .. " | " .. tostring(Citizen.InvokeNative(0xD21C7418C590BB40, entity)) -- Dead?
    str = str .. " | " .. tostring(Citizen.InvokeNative(0x0FD25587BB306C86, entity))
    local provision_hash = Citizen.InvokeNative(0x31FEF6A20F00B963, entity) -- Provision Hash ? -- Can be set with 0x399657ED871B3A6C
    str = str .. " | " .. tostring(provision_hash)
    if HASH_PROVISIONS[provision_hash] then
        str = str .. "\n" .. HASH_PROVISIONS[provision_hash]
    end
    local carriedEntity = Citizen.InvokeNative(0xD806CD2A4F2C2996, entity)
    local carriedEntityModel = GetEntityModel(carriedEntity)
    local carriedEntityHash = Citizen.InvokeNative(0x31FEF6A20F00B963, carriedEntity)
    if carriedEntity then
        str = str .. "\nCarrying: id : " .. carriedEntity .. " model: " .. carriedEntityModel .. " | " .. (GetHashName(carriedEntityModel) or "")
        if carriedEntityHash then
            str = str .. "\nCarrying: " .. carriedEntityHash .. " | " .. (GetHashName(carriedEntityHash) or "")
        end
    end
    local eCoords = GetEntityCoords(entity)
    local eHeading = GetEntityHeading(entity)
    str = str .. '\nx: ' .. (Floor(eCoords.x * 100) / 100.0) .. ' y: ' .. (Floor(eCoords.y * 100) / 100.0) .. ' z: ' .. (Floor(eCoords.z * 100) / 100.0) .. ' h: ' .. (Floor(eHeading * 100) / 100.0)
    local eRot = GetEntityRotation(entity)
    str = str .. '\nRot: x: ' .. (Floor(eRot.x * 100) / 100.0) .. ' y: ' .. (Floor(eRot.y * 100) / 100.0) .. ' z: ' .. (Floor(eRot.z * 100) / 100.0)
    local zOff = 0
    local mount = GetMount(entity)
    if not (mount == 0) then
        zOff = 1
        str = str .. '\nMounted on: ' .. mount
    end
    local vehicle = GetVehiclePedIsIn(entity)
    if not (vehicle == 0) then
        zOff = 1
        local driver = GetPedInVehicleSeat(vehicle, -1)
        if driver == entity then
            str = str .. '\nVehicle driving: ' .. vehicle
        else
            str = str .. '\nVehicle passenger: ' .. vehicle
        end
    end
    TxtAtWorldCoord(eCoords.x, eCoords.y, eCoords.z + zOff, str, 0.2, 1)
end

function DrawItemInfo(entity)
    local str = "[16] ID: " .. tostring(entity)
    local model_hash = GetEntityModel(entity)
    local model_name = GetHashName(model_hash)
    if not model_name  then
        str = str .. " | Model: ~e~" .. tostring(model_hash) .. "~q~\n"
    else
        str = str .. " | Model: " .. tostring(model_hash) .. "\n"
        str = str .. model_name .. "\n"
    end
    str = str .. "Visible: " .. tostring(Citizen.InvokeNative(0xC8CCDB712FBCBA92, entity)) .. "\n"
    local entityStatus = Citizen.InvokeNative(0x61914209C36EFDDB, entity)
    str = str .. "Status: " .. GetStatusText(entityStatus) .. "\n"
    str = str .. tostring(Citizen.InvokeNative(0x97F696ACA466B4E0, entity))
    str = str .. " | " .. tostring(Citizen.InvokeNative(0xD21C7418C590BB40, entity)) -- Dead?
    str = str .. " | " .. tostring(Citizen.InvokeNative(0x0FD25587BB306C86, entity))
    local provision_hash = Citizen.InvokeNative(0x31FEF6A20F00B963, entity) -- Provision Hash ? -- Can be set with 0x399657ED871B3A6C
    str = str .. " | " .. tostring(provision_hash)
    if HASH_PROVISIONS[provision_hash] then
        str = str .. "\n" .. HASH_PROVISIONS[provision_hash]
    end
    local eCoords = GetEntityCoords(entity)
    -- str = str .. "\nClosestObjectOfType: " .. GetClosestObjectOfType(eCoords.x, eCoords.y, eCoords.z, 1.0, model_hash)
    -- local shapeTest = StartShapeTestBox(eCoords.x, eCoords.y, eCoords.z, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, true, 16)
    -- local rtnVal, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shapeTest)
    -- str = str .. "\nShapeTest: " .. entityHit
    local eHeading = GetEntityHeading(entity)
    str = str .. '\nx: ' .. (Floor(eCoords.x * 100) / 100.0) .. ' y: ' .. (Floor(eCoords.y * 100) / 100.0) .. ' z: ' .. (Floor(eCoords.z * 100) / 100.0) .. ' h: ' .. (Floor(eHeading * 100) / 100.0)
    local eRot = GetEntityRotation(entity)
    str = str .. '\nRot: x: ' .. (Floor(eRot.x * 100) / 100.0) .. ' y: ' .. (Floor(eRot.y * 100) / 100.0) .. ' z: ' .. (Floor(eRot.z * 100) / 100.0)
    TxtAtWorldCoord(eCoords.x, eCoords.y, eCoords.z, str, 0.2, 1)
end

function DrawFoliageInfo(entity)
    local str = "[256] ID: " .. tostring(entity)
    local model_hash = GetEntityModel(entity)
    local model_name = GetHashName(model_hash)
    if not model_name  then
        str = str .. " | Model: ~e~" .. tostring(model_hash) .. "~q~\n"
    else
        str = str .. " | Model: " .. tostring(model_hash) .. "\n"
        str = str .. model_name .. "\n"
    end
    local eCoords = GetEntityCoords(entity)
    local eHeading = GetEntityHeading(entity)
    str = str .. 'x: ' .. (Floor(eCoords.x * 100) / 100.0) .. ' y: ' .. (Floor(eCoords.y * 100) / 100.0) .. ' z: ' .. (Floor(eCoords.z * 100) / 100.0) .. ' h: ' .. (Floor(eHeading * 100) / 100.0)
    local eRot = GetEntityRotation(entity)
    str = str .. '\nRot: x: ' .. (Floor(eRot.x * 100) / 100.0) .. ' y: ' .. (Floor(eRot.y * 100) / 100.0) .. ' z: ' .. (Floor(eRot.z * 100) / 100.0)
    TxtAtWorldCoord(eCoords.x, eCoords.y, eCoords.z, str, 0.2, 1)
end

function DrawVehicleInfo(entity)
    local str = "[2] ID: " .. tostring(entity)
    local model_hash = GetEntityModel(entity)
    local model_name = GetHashName(model_hash)
    if not model_name  then
        str = str .. " | Model: ~e~" .. tostring(model_hash) .. "~q~\n"
    else
        str = str .. " | Model: " .. tostring(model_hash) .. "\n"
        str = str .. model_name .. "\n"
    end
    local eCoords = GetEntityCoords(entity)local eHeading = GetEntityHeading(entity)
    str = str .. 'x: ' .. (Floor(eCoords.x * 100) / 100.0) .. ' y: ' .. (Floor(eCoords.y * 100) / 100.0) .. ' z: ' .. (Floor(eCoords.z * 100) / 100.0) .. ' h: ' .. (Floor(eHeading * 100) / 100.0)
    local eRot = GetEntityRotation(entity)
    str = str .. '\nRot: x: ' .. (Floor(eRot.x * 100) / 100.0) .. ' y: ' .. (Floor(eRot.y * 100) / 100.0) .. ' z: ' .. (Floor(eRot.z * 100) / 100.0)
    TxtAtWorldCoord(eCoords.x, eCoords.y, eCoords.z, str, 0.2, 1)
end

function GetHashKeyIfValid(model_name)
    local model_hash = GetHashKey(model_name)
    local model_valid = IsModelValid(model_hash)
    if model_valid then
        return model_hash
    else
        return false
    end
end

function PrintValidModel(model_name)
    local model_hash = GetHashKeyIfValid(model_name)
    if model_hash then
        if HASH_MODELS[model_hash] then
            print(model_name .. " is valid " .. model_hash)
        else
            print('NEW: ' .. model_name .. " is valid " .. model_hash)
        end
        return true
    end
end

function TestModelSuffix(model_base_name, suffix)
    local model_name
    model_name = model_base_name .. suffix
    local validA = PrintValidModel(model_name)
    model_name = model_name .. 'X'
    local validB = PrintValidModel(model_name)
    model_name = model_base_name .. suffix .. '_L'
    local validC = PrintValidModel(model_name)
    model_name = model_base_name .. suffix .. '_R'
    local validD = PrintValidModel(model_name)
    model_name = model_base_name .. suffix .. '_LG'
    local validE = PrintValidModel(model_name)
    model_name = model_base_name .. suffix .. '_MD'
    local validF = PrintValidModel(model_name)
    model_name = model_base_name .. suffix .. '_SM'
    local validG = PrintValidModel(model_name)
    model_name = model_base_name .. 'LRG' .. suffix
    local validH = PrintValidModel(model_name)
    model_name = model_name .. 'X'
    local validI = PrintValidModel(model_name)
    model_name = model_base_name .. 'MED' .. suffix
    local validJ = PrintValidModel(model_name)
    model_name = model_name .. 'X'
    local validK = PrintValidModel(model_name)
    model_name = model_base_name .. 'SML' .. suffix
    local validL = PrintValidModel(model_name)
    model_name = model_name .. 'X'
    local validM = PrintValidModel(model_name)
    if validA or validB or validC or validD or validE or validF or validG or validH or validI or validJ or validK or validL or validM then
    return true
    else
        return false
    end
end

function ModelSearch(name)
    Citizen.CreateThread(function()
        local letters = { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z' }
        local model_name = ''
        TestModelSuffix(name, '')
        local countSinceLastValid = 0
        local validA, validB, validC, validD, validE, validF
        for i = 1, 999 do
            countSinceLastValid = countSinceLastValid + 1
            -- Don't keep counting higher if there is no lower number values.
            if countSinceLastValid > 9 then
                break
            end
            if i < 10 then
                validA = TestModelSuffix(name, i)
            end
            if i < 100 then
                validB = TestModelSuffix(name, string.format("%02d", i))
            end
            validC = TestModelSuffix(name, string.format("%03d", i))
            -- Letters
            local validLetter = false
            local countSinceLastValidLetter = 0
            for l, letter in pairs(letters) do
                countSinceLastValidLetter = countSinceLastValidLetter + 1
                -- Don't keep counting higher if there is no lower number values.
                if countSinceLastValidLetter > 2 then
                    break
                end
                if i < 10 then
                    validD = TestModelSuffix(name, i .. letter)
                end
                if i < 100 then
                    validE = TestModelSuffix(name, string.format("%02d", i) .. letter)
                end
                validF = TestModelSuffix(name, string.format("%03d", i) .. letter)
                if validD or validE or validF then
                    countSinceLastValidLetter = 0
                end
            end
            if validA or validB or validC or validD or validE or validF then
                countSinceLastValid = 0
            end
        end
    end)
end

RegisterCommand("model_search", function(source, args, rawCommand)
    if args[1] == nil then
        print("Please provide a model prefix for testing")
    else
        ModelSearch(args[1])
        ModelSearch('P_' .. args[1])
        ModelSearch('P_' .. args[1] .. '_')
        ModelSearch('P_GEN_' .. args[1]) -- Double Check accuracy
        ModelSearch('P_GEN_' .. args[1] .. '_') -- Double Check accuracy
        ModelSearch('P_CS_' .. args[1])
        ModelSearch('P_CS_' .. args[1] .. '_')
        ModelSearch('S_' .. args[1])
        ModelSearch('S_' .. args[1] .. '_')
        ModelSearch('S_INV_' .. args[1])
        ModelSearch('S_INV_' .. args[1] .. '_')
    end
end)

RegisterCommand("swap", function(source, args, rawCommand)
    if args[1] == nil or args[2] == nil then
        print("Please provide to models for swapping")
    else
        Citizen.CreateThread(function()
            args[1] = ConvertArg(args[1])
            args[2] = ConvertArg(args[2])
            local player = PlayerPedId()
            local coords = GetEntityCoords(player)
            local model_valid = LoadModel(args[2])
            if model_valid then
                Citizen.InvokeNative(0x10B2218320B6F5AC, coords.x, coords.y, coords.z, 10.0, args[1], args[2])
                print("Swapped " .. args[1] .. " for " .. args[2])
                Citizen.Wait(2500)
                Citizen.InvokeNative(0x824E1C26A14CB817 , coords.x, coords.y, coords.z, 10.0, args[1], args[2])
                print("Removed swap of " .. args[1] .. " for " .. args[2])
                SetModelAsNoLongerNeeded(args[2])
            else
                print("Model not valid")
            end
        end)
    end
end)

function ConvertArg(arg)
    local hashStart = "HASH_"
    if arg:sub(1, #hashStart) == hashStart then
        local hashName = GetTextSubstring(arg, 5, GetLengthOfLiteralString(arg))
        return GetHashKey(hashName)
    elseif arg == "PLAYER_ID" then
        return GetPlayerPed()
    elseif arg == "PLAYER_COORD" then
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        return { coords.x, coords.y, coords.z }
    elseif arg == "true" then
        return true
    elseif arg == "false" then
        return false
    elseif not (nil == tonumber(arg)) then
        return tonumber(arg)
    else
        return arg
    end
end

---
--- Entity Natives
--- 0x61914209C36EFDDB Entity Status? 3 on ground 4 picking up 5 carried 6 dropping
--- 0x96C638784DB4C815 Has a number when target is alive is false after target dies
--- 0xD21C7418C590BB40 -1 when alive 2 when dying / dead
--- 0xAAACB74442C1BED3 number increments every call
--- 0xC8CCDB712FBCBA92 Occluded? Visible on screen?
--- 0x31FEF6A20F00B963 ? Not 100% sure but if I remember correctly it might be a flag of some sort. Same pelts of same quality were identical but different quality pelts were different. Also different pelts of same quality were different.
---

RegisterCommand("native", function(source, args, rawCommand)
    if args[1] == nil then
        print("Please specify a function to call")
    else
        local args2 = {}
        
        for k, v in pairs(args) do
            v = ConvertArg(v)
            if type(v) == 'table' then
                for key, value in pairs(v) do
                    table.insert(args2, value)
                end
            else
                table.insert(args2, v)
            end
        end
        print(table.unpack(args2))

        Citizen.CreateThread(function()
            print(Citizen.InvokeNative(table.unpack(args2)))
            print("----")
        end)
    end
end)

RegisterCommand("golden", function(source, args, rawCommand)
    Citizen.CreateThread(function()
        local player = GetPlayerPed()
        Citizen.InvokeNative(0xC6258F41D86676E0, player, 0, 100) -- SetAttributeCoreValue
        Citizen.InvokeNative(0xC6258F41D86676E0, player, 1, 100) -- SetAttributeCoreValue
        Citizen.InvokeNative(0xC6258F41D86676E0, player, 2, 100) -- SetAttributeCoreValue
        EnableAttributeOverpower(player, 0, 5000.0)
        EnableAttributeOverpower(player, 1, 5000.0)
        EnableAttributeOverpower(player, 2, 5000.0)
        -- 0x103C2F885ABEB00B Is Attribute Overpowered
        -- 0xF6A7C08DF2E28B28 Set Attribute Overpowered Amount
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, player, 0, 5000.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, player, 1, 5000.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, player, 2, 5000.0)
        local mount = GetMount(player)
        if mount then
            Citizen.InvokeNative(0xC6258F41D86676E0, mount, 0, 100) -- SetAttributeCoreValue
            Citizen.InvokeNative(0xC6258F41D86676E0, mount, 1, 100) -- SetAttributeCoreValue
            EnableAttributeOverpower(mount, 0, 5000.0)
            EnableAttributeOverpower(mount, 1, 5000.0)
            Citizen.InvokeNative(0xF6A7C08DF2E28B28, mount, 0, 5000.0)
            Citizen.InvokeNative(0xF6A7C08DF2E28B28, mount, 1, 5000.0)
        end
    end)
end)

RegisterCommand("clear_tracking", function(source, args, rawCommand)
    entitiesToDraw = {}
    itemsToDraw = {}
    foliageToDraw = {}
    vehiclesToDraw = {}
end)

RegisterCommand("weather", function(source, args, rawCommand)
    Citizen.InvokeNative(0x59174F1AFE095B5A, tonumber(args[1]), true, false, true, true, false)
end)

RegisterCommand("weapon", function(source, args, rawCommand) -- GIVES A WEAPON
    if args[1] == nil then
        print("Please set the specific name for weapon")
    else
        local player = GetPlayerPed()
        Citizen.InvokeNative(0xB282DC6EBD803C75, player, GetHashKey(args[1]), 500, true, 0)
    end
end, false)

RegisterCommand('spawn', function(source, args, rawCommand)
    local player = GetPlayerPed()
    local pCoords = GetEntityCoords(player)
    local pDir = GetEntityHeading(player)
    -- 0x405180B14DA5A935 SetPedType(entity, ??) -- Always makes PedType 4

    local spawnCoords = GetOffsetFromEntityInWorldCoords(player, 0, 5.0, 0)

    local modelName = args[1]
    local modelHash = GetHashKey(modelName)
    print(modelName .. " : " .. modelHash)
    print(modelName .. " : " .. Citizen.InvokeNative(0xFD340785ADF8CFB7, modelName))
    print(IsModelInCdimage(modelHash), IsModelAVehicle(modelHash), IsModelAPed(modelHash), IsModelValid(modelHash))
    Citizen.CreateThread(function()
        LoadModel(modelHash)
        local entity = CreatePed(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, pDir, false, false, false, false)
        SetEntityVisible(entity, true)
        SetEntityAlpha(entity, 255, false)
        Citizen.InvokeNative(0x283978A15512B2FE, entity, true)
        SetModelAsNoLongerNeeded(modelHash)
        GetEntityCoords(entity)
        if Config.TrackEntities == 1 then
            entitiesToDraw[entity] = true
        end
    end)
end)

RegisterCommand("delete_entity", function(source, args, rawCommand)
    Citizen.CreateThread(function()
        local entity_id = tonumber(args[1])
        if entity_id then
            SetEntityAsMissionEntity(entity_id, true, true)
            DeletePed(entity_id)
            DeleteEntity(entity_id)
        end
    end)
end)

function SetEntityModel(entity, model)
    entity = tonumber(entity)
    if tonumber(model) == nil then
        model = GetHashKey(model)
    end
    if IsModelValid(model) then
        local entityCoords = GetEntityCoords(entity)
        local entityModel = GetEntityModel(entity)
        LoadModel(model)
        CreateModelSwap(entityCoords.x, entityCoords.y, entityCoords.z, 0.0, entityModel, model)
    else
        print('Invalid Model')
    end
end

RegisterCommand("set_entity_model", function(source, args, rawCommand)
    if not args[1] or not args[2] then
        print("Specify an entity and model")
    else
        Citizen.CreateThread(function()
            SetEntityModel(table.unpack(args))
        end)
    end
end)

function headingDir(entity)
    local hd = GetEntityHeading(entity)
    if hd < 22.5 then
        return "N"
    elseif hd < 67.5 then
        return "NW"
    elseif hd < 112.5 then
        return "W"
    elseif hd < 157.5 then
        return "SW"
    elseif hd < 202.5 then
        return "S"
    elseif hd < 247.5 then
        return "SE"
    elseif hd < 292.5 then
        return "E"
    elseif hd < 337.5 then
        return "NE"
    end
    return "N"
end

function DrawCoords()
    if Config.DrawCoords == 1 then
        local _source = source
        local ent = GetPlayerPed(_source)
        local pp = GetEntityCoords(ent)
        local hd = GetEntityHeading(ent)
        DrawTxt(
            "x = " .. tonumber(string.format("%.2f", pp.x)) .. " y = " .. tonumber(string.format("%.2f", pp.y)) .. " z = " .. tonumber(string.format("%.2f", pp.z)) -- Coordinates
            .. " | H: " .. headingDir(ent) .. " " .. tonumber(string.format("%.2f", hd)) -- Heading
            .. " | T: " .. GetClockHours() .. ':' .. GetClockMinutes() -- Time
            , 0.01, 0.97, 0.3, true, 255, 255, 255, 255, false, 1)
    end
end

function TxtAtWorldCoord(x, y, z, txt, size, font)
    local s, sx, sy = GetScreenCoordFromWorldCoord(x, y ,z)
    if (sx > 0 and sx < 1) or (sy > 0 and sy < 1) then
        local s, sx, sy = GetHudScreenPositionFromWorldPosition(x, y, z)
        DrawTxt(txt, sx, sy, size, true, 255, 255, 255, 255, true, font) -- Font 2 has some symbol conversions ex. @ becomes the rockstar logo
    end
end

function DrawTxt(str, x, y, size, enableShadow, r, g, b, a, centre, font)
    local str = CreateVarString(10, "LITERAL_STRING", str)
    SetTextScale(1, size)
    SetTextColor(math.floor(r), math.floor(g), math.floor(b), math.floor(a))
	SetTextCentre(centre)
    if enableShadow then SetTextDropshadow(1, 0, 0, 0, 255) end
    SetTextFontForCurrentCommand(font)
    DisplayText(str, x, y)
end
