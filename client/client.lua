print('^2[RP_ADMIN] client.lua loaded^7')

local adminOpen = false
local spectating = false
local spectateTarget = nil


-- =========================================
-- OPEN ADMIN PANEL
-- =========================================

RegisterCommand('admin', function()

    if spectating then
        TriggerEvent('rp_admin:stopSpectate')
        return
    end

    adminOpen = not adminOpen

    SetNuiFocus(adminOpen, adminOpen)

    SendNUIMessage({
        action = adminOpen and 'open' or 'close'
    })

    if adminOpen then
        TriggerServerEvent('rp_admin:requestPlayers')
    end

end, false)


RegisterKeyMapping(
    'admin',
    'Open RP Admin Panel',
    'keyboard',
    'F10'
)


-- =========================================
-- CLOSE PANEL
-- =========================================

RegisterNUICallback('close', function(_, cb)

    adminOpen = false

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'close'
    })

    cb('ok')

end)


-- =========================================
-- REQUEST PLAYERS FROM NUI
-- =========================================

RegisterNUICallback('requestPlayers', function(_, cb)

    if not adminOpen then
        cb('ok')
        return
    end

    TriggerServerEvent('rp_admin:requestPlayers')

    cb('ok')

end)


-- =========================================
-- RECEIVE PLAYERS FROM SERVER
-- =========================================

RegisterNetEvent('rp_admin:receivePlayers', function(players)

    SendNUIMessage({
        action = 'updatePlayers',
        players = players
    })

end)


-- =========================================
-- PLAYER ACTION NUI CALLBACK
-- =========================================

RegisterNUICallback(
    'playerAction',
    function(data, cb)

        local playerId =
            tonumber(data.playerId)

        local action =
            tostring(data.action)


        if not playerId or not action then

            cb('ok')

            return
        end


        TriggerServerEvent(
            'rp_admin:playerAction',
            playerId,
            action,
            tostring(data.value or '')
        )


        cb('ok')

    end
)


-- =========================================
-- TELEPORT
-- =========================================

RegisterNetEvent(
    'rp_admin:teleport',
    function(x, y, z, heading)

        local ped =
            PlayerPedId()


        SetEntityCoords(
            ped,
            x,
            y,
            z,
            false,
            false,
            false,
            false
        )


        if heading then

            SetEntityHeading(
                ped,
                heading
            )

        end

    end
)


-- =========================================
-- SPECTATE
-- =========================================

RegisterNetEvent('rp_admin:startSpectate', function(targetServerId)

    local targetPlayer = GetPlayerFromServerId(tonumber(targetServerId))

    if targetPlayer == -1 then
        TriggerEvent('qbx_core:Notify', 'Player is not available to spectate.', 'error')
        return
    end

    local targetPed = GetPlayerPed(targetPlayer)

    if targetPed == 0 or not DoesEntityExist(targetPed) then
        TriggerEvent('qbx_core:Notify', 'Player ped is not available.', 'error')
        return
    end

    spectating = true
    spectateTarget = targetPlayer

    NetworkSetInSpectatorMode(true, targetPed)
    SetEntityVisible(PlayerPedId(), false, false)
    TriggerEvent('qbx_core:Notify', 'Spectating player ID ' .. tostring(targetServerId) .. '. Press F10 to stop.', 'inform')
end)

RegisterNetEvent('rp_admin:stopSpectate', function()
    if not spectating then return end

    NetworkSetInSpectatorMode(false, 0)
    SetEntityVisible(PlayerPedId(), true, false)
    spectating = false
    spectateTarget = nil
    TriggerEvent('qbx_core:Notify', 'Stopped spectating.', 'inform')
end)

-- =========================================
-- FREEZE
-- =========================================

local playerFrozen = false


RegisterNetEvent(
    'rp_admin:toggleFreeze',
    function()

        local ped =
            PlayerPedId()


        playerFrozen =
            not playerFrozen


        FreezeEntityPosition(
            ped,
            playerFrozen
        )


        if playerFrozen then

            exports.qbx_core:Notify(
                'You have been frozen by an administrator.',
                'warning'
            )

        else

            exports.qbx_core:Notify(
                'You have been unfrozen.',
                'success'
            )

        end

    end
)


-- =========================================
-- ACTION RESULT
-- =========================================

RegisterNetEvent(
    'rp_admin:actionResult',
    function(success, message)

        print(
            ('^3[RP_ADMIN] %s: %s^7')
            :format(
                success
                and 'SUCCESS'
                or 'ERROR',
                message
            )
        )

    end
)

-- =========================================
-- VEHICLE ACTION CALLBACK
-- =========================================

RegisterNUICallback(
    'vehicleAction',
    function(data, cb)

        local action =
            tostring(data.action or '')

        local model =
            tostring(data.model or '')


        TriggerServerEvent(
            'rp_admin:vehicleAction',
            action,
            model
        )


        cb('ok')

    end
)

-- =========================================
-- CURRENT VEHICLE ACTIONS
-- =========================================

RegisterNetEvent(
    'rp_admin:vehicleAction',
    function(action)

        local ped =
            PlayerPedId()


        local vehicle =
            GetVehiclePedIsIn(
                ped,
                false
            )


        if vehicle == 0 then

            TriggerEvent(
                'qbx_core:notify',
                'You are not inside a vehicle.',
                'error'
            )

            return
        end


        -- REPAIR

        if action == 'repair' then

            SetVehicleFixed(vehicle)

            SetVehicleDeformationFixed(vehicle)

            SetVehicleUndriveable(
                vehicle,
                false
            )

            SetVehicleEngineHealth(
                vehicle,
                1000.0
            )

            SetVehicleBodyHealth(
                vehicle,
                1000.0
            )


        -- CLEAN

        elseif action == 'clean' then

            SetVehicleDirtLevel(
                vehicle,
                0.0
            )


        -- FLIP

        elseif action == 'flip' then

            local coords =
                GetEntityCoords(vehicle)


            SetEntityCoords(
                vehicle,
                coords.x,
                coords.y,
                coords.z + 1.0,
                false,
                false,
                false,
                false
            )


            SetEntityRotation(
                vehicle,
                0.0,
                0.0,
                GetEntityHeading(vehicle),
                2,
                true
            )


        -- DELETE

        elseif action == 'delete' then

            SetEntityAsMissionEntity(
                vehicle,
                true,
                true
            )

            DeleteVehicle(vehicle)


        -- KEYS

        elseif action == 'keys' then

            TriggerServerEvent(
                'rp_admin:giveCurrentVehicleKeys'
            )

        end

    end
)

RegisterNetEvent(
    'rp_admin:giveCurrentVehicleKeys',
    function()

        local source = source


        if not isAdmin(source) then
            return
        end


        local ped =
            GetPlayerPed(source)


        local vehicle =
            GetVehiclePedIsIn(
                ped,
                false
            )


        if vehicle == 0 then
            return
        end


        exports.qbx_vehiclekeys:GiveKeys(
            source,
            vehicle,
            false
        )

    end
)

RegisterNUICallback('serverAction', function(data, cb)
    print('^3[RP_ADMIN] serverAction NUI callback received^7')

    local action = tostring(data.action or '')
    local message = tostring(data.message or '')

    print('^3[RP_ADMIN] Action: ' .. action .. '^7')
    print('^3[RP_ADMIN] Message: ' .. message .. '^7')

    TriggerServerEvent(
        'rp_admin:serverAction',
        action,
        message
    )

    cb('ok')
end)

RegisterNetEvent('rp_admin:receiveAnnouncement', function(message)

    message = tostring(message or '')

    print('^2[RP_ADMIN] Announcement received: ' .. message .. '^7')

    SendNUIMessage({
        action = 'announcement',
        message = message
    })

    PlaySoundFrontend(
        -1,
        'CONFIRM_BEEP',
        'HUD_MINI_GAME_SOUNDSET',
        true
    )

end)

RegisterNUICallback('serverAction', function(data, cb)

    local action = tostring(data.action or '')
    local message = tostring(data.message or '')

    print('^3[RP_ADMIN] Sending server event...^7')

    TriggerServerEvent(
        'rp_admin:testServerEvent',
        action .. ' | ' .. message
    )

    cb('ok')
end)