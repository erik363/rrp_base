RegisterNetEvent('rrp_base:changedPed')
RegisterNetEvent('rrp_base:isPedInAnyVehicle')
RegisterNetEvent('rrp_base:inMarker')
RegisterNetEvent('rrp_base:outMarker')
RegisterNetEvent('rrp_base:registerMarker')

local Markers = {}
local playerCoords = GetEntityCoords(PlayerPedId())

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        Markers[resourceName] = nil
        return
    end
end)
  
AddEventHandler('rrp_base:registerMarker', function(resourceName, markerId, markerData, onlyShow, cb, key)
    
    local markerdatas = {
        type = markerData.t or 1,
        coords = markerData.coords,
        size = markerData.size or vector3(1.0, 1.0, 1.0),
    
        visDist = markerData.visDist or 20.0,
        cb = cb,
        key = key,
        onlyShow = onlyShow,
        meta = markerData.meta,
        dir = markerData.pos or vector3(0.0, 0.0, 0.0),
        rot = markerData.pos or vector3(0.0, 0.0, 0.0),
        bobUpAndDown = markerData.bobUpAndDown or false,
        faceCamera = markerData.faceCamera or true,
        p19 = markerData.p19 or 2,
        rotate = markerData.rotate or false,
        textureDict = markerData.textureDict or nil,
        textureName = markerData.textureName or nil,
        drawOnEnts = markerData.drawOnEnts or false,
        trigger = markerData.trigger or false,
    }
    if markerData.rgb then
        markerdatas.rgb = {
            r = math.floor(markerData.rgb.r or 0),
            g = math.floor(markerData.rgb.g or 0),
            b = math.floor(markerData.rgb.b or 0),
            a = math.floor(markerData.rgb.a or 0),  
        }
    else
        markerdatas.rgb = {
            r = 100,
            g = 100,
            b = 100,
            a = 200,  
        }
    end
    markerdatas.trueMarkerSize = markerData.trueMarkerSize or markerdatas.size.x * 1.12
    markerdatas.drawing = false
    addMarker(resourceName, markerId, markerdatas)
end)

AddEventHandler('rrp_base:removeMarker', function(resourceName, markerId)
    removeMarker(resourceName, markerId)
    print(resourceName, markerId)
end)

function addMarker(resourceName, markerId, markerdatas)
    if Markers[resourceName] == nil then
        Markers[resourceName] = {}
    end
    Markers[resourceName][markerId]= markerdatas
end

function removeMarker(resourceName, markerId)
    if Markers[resourceName] then
        Markers[resourceName][markerId] = nil
    end
end


local pedInVehicle = false


Citizen.CreateThread(function()
    local playerPed = PlayerPedId()
    local notSended = true
    local inVeh = IsPedInAnyVehicle(playerPed, false)
    while true do
        if playerPed ~= PlayerPedId() then
            playerPed = PlayerPedId()
            TriggerEvent('rrp_base:changedPed', playerPed)
        end
        playerCoords = GetEntityCoords(playerPed)
        if inVeh ~= IsPedInAnyVehicle(playerPed, false) then
            inVeh = IsPedInAnyVehicle(playerPed, false)
            if inVeh then
                pedInVehicle = true
                TriggerEvent('rrp_base:isPedInAnyVehicle', true, GetVehiclePedIsIn(playerPed, false))
            else
                pedInVehicle = false
                TriggerEvent('rrp_base:isPedInAnyVehicle', false, GetVehiclePedIsIn(playerPed, true))
            end
        end
    
        Wait(200)
    end
end)

Citizen.CreateThread(function()
    while true do
        for resourceName, data in pairs(Markers) do
            for markerId, marker in pairs(data) do
                if (( not marker.onlyShow) or (marker.onlyShow == 2 and pedInVehicle) or (marker.onlyShow == 1 and not pedInVehicle)) then
                    if #(playerCoords - marker.coords) < marker.visDist then
                        if marker.drawing == false then
                            marker.drawing = true
                            drawMarker(resourceName, markerId)
                        end
                    end
                end
            end
        end
        Wait(200)
    end
end)

function drawMarker(resourceName, markerId)
    Citizen.CreateThread(function()
        local markerCache = Markers[resourceName][markerId]

        --removeMarker(resourceName, markerId)
        local x,y,z = markerCache.coords.x, markerCache.coords.y, markerCache.coords.z
        local size = markerCache.size
        local sx, sy, sz = size.x, size.y, size.z
        local coords = markerCache.coords
        local visibilityDistance = markerCache.visDist
        local distance = #(playerCoords - coords)
        local markerSize = markerCache.trueMarkerSize
        local rgb = markerCache.rgb
        local playerInMarker = false
        local key = markerCache.key
        local pressed = false
        local inVeh = pedInVehicle
        local markers = Markers[resourceName]
        while distance <= visibilityDistance and inVeh == pedInVehicle and Markers[resourceName] and markers[markerId] do
            if distance < markerSize then
                if playerInMarker == false then
                    playerInMarker = true
                    if markerCache.trigger == true then
                        TriggerEvent("rrp_base:inMarker", resourceName, markerId, markerCache.meta)
                    end
                    if not key and markerCache.cb then
                        pressed = true
                        markerCache.cb(1, markerCache.meta)
                    end
                end
                if key then
                    if IsControlJustReleased(0, key) then
                        markerCache.cb(1, markerCache.meta)
                        pressed = true
                        break
                    end
                end
            else
                if playerInMarker == true then
                    playerInMarker = false
                    if markerCache.trigger == true then
                        TriggerEvent("rrp_base:outMarker", resourceName, markerId, markerCache.meta)
                    end
                    if not key and markerCache.cb then
                        pressed = true
                        markerCache.cb(0, markerCache.meta)
                    end
                end
            end
            if rgb.a > 0 then
                DrawMarker( markerCache.type, x, y, z, 
                            markerCache.dir, markerCache.rot, 
                            sx, sy, sz, 
                            rgb.r, rgb.g, rgb.b, rgb.a, 
                            markerCache.bobUpAndDown, markerCache.faceCamera, markerCache.p19, 
                            markerCache.rotate, markerCache.textureDict, markerCache.textureName, markerCache.drawOnEnts)
            end
            distance = #(playerCoords - coords)
            Wait(0)
        end
        if Markers[resourceName] then
            if Markers[resourceName][markerId] then
                if not pressed and markerCache.cb then
                    markerCache.cb(-1, markerCache.meta)
                end
                --addMarker(resourceName, markerId, markerCache)
                markerCache.drawing = false
            end
        end
    end)
end

-- Test Events: 
--[[
AddEventHandler("rrp_base:inMarker", function(resourceName, markerId)
    print("in", resourceName, markerId)
end)

AddEventHandler("rrp_base:outMarker", function(resourceName, markerId)
    print("out", resourceName, markerId)

end)

AddEventHandler("rrp_base:changedPed", function(ped)
    print("ped", ped)
end)
]]








