RegisterNetEvent('rrp_base:changedPed')
RegisterNetEvent('rrp_base:inVehicle')
RegisterNetEvent('rrp_base:outVehicle')
RegisterNetEvent('rrp_base:inMarker')
RegisterNetEvent('rrp_base:outMarker')

local Markers = {
    --["test"] = {
        --["asd"] = {type = 1, coords = vector3(339.5, -1397.3, 32.5), x = 1.0, y = 1.0, z = 1.0, rgb = {r = 255, g = 0, b = 0, a = 200}, distance = 20.0}
    --}
}

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    Markers[resourceName] = nil
end)
  

RegisterNetEvent('rrp_base:registerMarker', function()

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

local playerCoords = GetEntityCoords(PlayerPedId())
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
                TriggerEvent('rrp_base:inVehicle')
            else
                TriggerEvent('rrp_base:outVehicle')
            end
        end
    
        Wait(500)
    end
end)

Citizen.CreateThread(function()
    while true do
        for resourceName, data in pairs(Markers) do
            for markerId, marker in pairs(data) do
                if #(playerCoords - marker.coords) < marker.distance then
                    drawMarker(resourceName, markerId)
                end
            end
        end
        Wait(100)
    end
end)

function drawMarker(resourceName, markerId)
    Citizen.CreateThread(function()
        local markerCache = Markers[resourceName][markerId]
        removeMarker(resourceName, markerId)
        local coords = markerCache.coords
        local visibilityDistance = markerCache.distance
        local distance = #(playerCoords - coords)
        local markerSize = markerCache.x
        local rgb = markerCache.rgb
        local playerInMarker = false
        while distance <= visibilityDistance do
            if distance < markerSize then
                if playerInMarker == false then
                    playerInMarker = true
                    TriggerEvent("rrp_base:inMarker", resourceName, markerId)
                end
            else
                if playerInMarker == true then
                    playerInMarker = false
                    TriggerEvent("rrp_base:outMarker", resourceName, markerId)
                end
            end

            DrawMarker( markerCache.type, coords, 
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                        markerCache.x, markerCache.y, markerCache.z, 
                        rgb.r, rgb.g, rgb.b, rgb.a, 
                        false, true, 2, false, false, false, false)

            distance = #(playerCoords - coords)
            Wait(0)
        end

        addMarker(resourceName, markerId, markerCache)
    end)
end

-- Test Events: 

AddEventHandler("rrp_base:inMarker", function(resourceName, markerId)
    print("it", resourceName, markerId)
end)

AddEventHandler("rrp_base:outMarker", function(resourceName, markerId)
    print("out", resourceName, markerId)

end)

AddEventHandler("rrp_base:inVehicle", function(resourceName, markerId)
    print("inveh")

end)

AddEventHandler("rrp_base:outVehicle", function(resourceName, markerId)
    print("outveh")

end)

AddEventHandler("rrp_base:changedPed", function(ped)
    print("ped", ped)

end)




