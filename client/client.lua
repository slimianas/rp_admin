print('^2[RP_ADMIN] client.lua loaded^7')

local adminOpen = false


-- =========================================
-- OPEN ADMIN PANEL
-- =========================================

RegisterCommand('admin', function()

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
            action
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

-- =========================================
-- SERVER ACTION NUI CALLBACK
-- =========================================

RegisterNUICallback('serverAction', function(data, cb)

    local action = tostring(data.action or '')
    local message = tostring(data.message or '')

    print('^3[RP_ADMIN] Server action: ' .. action .. '^7')
    print('^3[RP_ADMIN] Message: ' .. message .. '^7')

    if action == 'announcement' then

        TriggerServerEvent(
            'rp_admin:sendAnnouncement',
            message
        )

    end

    cb('ok')
end)


RegisterNetEvent('rp_admin:receiveAnnouncement', function(message)

    message = tostring(message or '')

    print('^2[RP_ADMIN CLIENT] ANNOUNCEMENT RECEIVED!^7')
    print('^2[RP_ADMIN CLIENT] Message: ' .. message .. '^7')

    -- Send to our custom NUI notification
    SendNUIMessage({
        action = 'announcement',
        message = message
    })

    -- GTA notification sound
    PlaySoundFrontend(
        -1,
        'CONFIRM_BEEP',
        'HUD_MINI_GAME_SOUNDSET',
        true
    )

end)