print('^2[RP_ADMIN SERVER] server.lua LOADED successfully^7')
local function isAdmin(source)

    return IsPlayerAceAllowed(
        source,
        'rp_admin.use'
    )
end


-- =========================================
-- GET PLAYERS
-- =========================================

local function getPlayers()

    local players = {}

    local qboxPlayers =
        exports.qbx_core:GetQBPlayers()


    for source, player in pairs(qboxPlayers) do

        local data =
            player.PlayerData


        local firstname =
            data.charinfo
            and data.charinfo.firstname
            or ''


        local lastname =
            data.charinfo
            and data.charinfo.lastname
            or ''


        local characterName =
            (firstname .. ' ' .. lastname)
            :gsub('^%s*(.-)%s*$', '%1')


        if characterName == '' then

            characterName =
                data.name
                or GetPlayerName(source)
                or 'Unknown'

        end


        local jobLabel =
            'Civilian'


        if data.job then

            jobLabel =
                data.job.label
                or data.job.name
                or 'Civilian'

        end


        players[#players + 1] = {

            id = source,

            name = characterName,

            job = jobLabel,

            citizenid =
                data.citizenid
                or 'N/A',

            ping =
                GetPlayerPing(source)

        }

    end


    table.sort(
        players,
        function(a, b)

            return a.id < b.id

        end
    )


    return players
end


-- =========================================
-- SEND PLAYERS
-- =========================================

RegisterNetEvent(
    'rp_admin:requestPlayers',
    function()

        local source = source

        TriggerClientEvent(
            'rp_admin:receivePlayers',
            source,
            getPlayers()
        )

    end
)


-- =========================================
-- PLAYER ACTIONS
-- =========================================

RegisterNetEvent(
    'rp_admin:playerAction',
    function(targetId, action, value, itemAmount)

        local adminSource = source


        -- SECURITY CHECK

        if not isAdmin(adminSource) then

            print(
                ('[RP_ADMIN] %s attempted admin action without permission: %s')
                :format(
                    adminSource,
                    tostring(action)
                )
            )

            TriggerClientEvent(
                'rp_admin:actionResult',
                adminSource,
                false,
                'You do not have permission.'
            )

            return
        end


        targetId =
            tonumber(targetId)


        if not targetId then

            return
        end


        local targetPlayer =
            exports.qbx_core:GetPlayer(
                targetId
            )


        if not targetPlayer then

            TriggerClientEvent(
                'rp_admin:actionResult',
                adminSource,
                false,
                'Player is no longer online.'
            )

            return
        end


        -- =================================
        -- TELEPORT TO
        -- =================================

        if action == 'teleport' then

            local targetPed =
                GetPlayerPed(targetId)


            if targetPed == 0 then

                return
            end


            local coords =
                GetEntityCoords(
                    targetPed
                )


            local heading =
                GetEntityHeading(
                    targetPed
                )


            TriggerClientEvent(
                'rp_admin:teleport',
                adminSource,
                coords.x,
                coords.y,
                coords.z,
                heading
            )


            TriggerClientEvent(
                'rp_admin:actionResult',
                adminSource,
                true,
                'Teleported to player.'
            )


        -- =================================
        -- BRING
        -- =================================

        elseif action == 'bring' then

            local adminPed =
                GetPlayerPed(adminSource)


            if adminPed == 0 then

                return
            end


            local coords =
                GetEntityCoords(
                    adminPed
                )


            local heading =
                GetEntityHeading(
                    adminPed
                )


            TriggerClientEvent(
                'rp_admin:teleport',
                targetId,
                coords.x,
                coords.y,
                coords.z,
                heading
            )


            TriggerClientEvent(
                'rp_admin:actionResult',
                adminSource,
                true,
                'Player brought to you.'
            )


        -- =================================
        -- FREEZE
        -- =================================

        elseif action == 'freeze' then

            TriggerClientEvent(
                'rp_admin:toggleFreeze',
                targetId
            )


            TriggerClientEvent(
                'rp_admin:actionResult',
                adminSource,
                true,
                'Freeze toggled.'
            )

            -- =================================
            -- KICK
            -- =================================
            elseif action == 'kick' then



                -- =================================
                -- SPECTATE
                -- =================================

            elseif action == 'spectate' then

         TriggerClientEvent(
          'rp_admin:startSpectate',
            adminSource,
          targetId
    )

    TriggerClientEvent(
        'rp_admin:actionResult',
        adminSource,
        true,
        'Spectate started.'
    )


        -- =================================
        -- REVIVE
        -- =================================

        elseif action == 'revive' then

            local success =
                pcall(function()

                    exports.qbx_medical:Revive(
                        targetId
                    )

                end)


            if success then

                TriggerClientEvent(
                    'rp_admin:actionResult',
                    adminSource,
                    true,
                    'Player revived.'
                )

            else

                TriggerClientEvent(
                    'rp_admin:actionResult',
                    adminSource,
                    false,
                    'qbx_medical is not available.'
                )

            end


        -- =================================
        -- SPECTATE
        -- =================================

        elseif action == 'spectate' then

            TriggerClientEvent(
                'rp_admin:startSpectate',
                adminSource,
                targetId
            )

            TriggerClientEvent(
                'rp_admin:actionResult',
                adminSource,
                true,
                'Spectate started.'
            )


        -- =================================
        -- GIVE MONEY
        -- =================================

        elseif action == 'give_money' then

            local amount = tonumber(value)

            if not amount or amount <= 0 or amount > 10000000 then
                TriggerClientEvent('rp_admin:actionResult', adminSource, false, 'Invalid money amount.')
                return
            end

            local success = exports.qbx_core:AddMoney(targetId, 'cash', math.floor(amount), 'RP Admin')

            TriggerClientEvent(
                'rp_admin:actionResult',
                adminSource,
                success == true,
                success and ('Gave $' .. math.floor(amount) .. ' cash.') or 'Failed to give money.'
            )


        -- =================================
        -- GIVE ITEM
        -- =================================

        elseif action == 'give_item' then

            local itemName = tostring(value or ''):lower():gsub('%s+', '')
            local amount = 1

            if itemName == '' or #itemName > 80 then
                TriggerClientEvent('rp_admin:actionResult', adminSource, false, 'Invalid item name.')
                return
            end

            amount = math.floor(amount)
            if amount < 1 or amount > 1000 then amount = 1 end

            local success = targetPlayer.Functions.AddItem(itemName, amount)

            TriggerClientEvent(
                'rp_admin:actionResult',
                adminSource,
                success == true,
                success and ('Gave ' .. amount .. 'x ' .. itemName .. '.') or 'Failed to give item.'
            )


        -- =================================
        -- KICK
        -- =================================

        elseif action == 'kick' then

            local playerName =
                GetPlayerName(targetId)
                or 'Player'


            DropPlayer(
                targetId,
                'You have been kicked by an administrator.'
            )


            print(
                ('[RP_ADMIN] %s kicked %s [%s]')
                :format(
                    GetPlayerName(adminSource)
                    or tostring(adminSource),
                    playerName,
                    targetId
                )
            )


            TriggerClientEvent(
                'rp_admin:actionResult',
                adminSource,
                true,
                'Player kicked.'
            )

        end

    end
)

-- =========================================
-- VEHICLE ADMIN ACTIONS
-- =========================================

RegisterNetEvent(
    'rp_admin:vehicleAction',
    function(action, model)

        local source = source

        -- SECURITY

        if not isAdmin(source) then

            TriggerClientEvent(
                'rp_admin:actionResult',
                source,
                false,
                'You do not have permission.'
            )

            return
        end

        if action == 'spawn' then

            model = tostring(model or ''):lower()

            if model == '' then
                TriggerClientEvent(
                    'rp_admin:actionResult',
                    source,
                    false,
                    'Vehicle model is required.'
                )
                return
            end

            TriggerClientEvent(
                'rp_admin:spawnVehicle',
                source,
                model
            )

            TriggerClientEvent(
                'rp_admin:actionResult',
                source,
                true,
                'Spawning ' .. model .. '...'
            )

            return
        end


        -- =================================
        -- SPAWN
        -- =================================

        if action == 'spawn' then

            model = tostring(model or '')
                :lower()
                :gsub('%s+', '')


            if model == '' then

                return
            end


            local modelHash =
                GetHashKey(model)


            local vehicles =
                exports.qbx_core:GetVehiclesByHash(
                    modelHash
                )


            if not vehicles
                or not next(vehicles)
            then

                TriggerClientEvent(
                    'rp_admin:actionResult',
                    source,
                    false,
                    'Vehicle model was not found.'
                )

                return
            end


            local success, result =
                pcall(function()

                    return qbx.spawnVehicle({
                        model = modelHash,

                        spawnSource =
                            GetPlayerPed(source),

                        warp = true
                    })

                end)


            if not success or not result then

                TriggerClientEvent(
                    'rp_admin:actionResult',
                    source,
                    false,
                    'Failed to spawn vehicle.'
                )

                return
            end


            local vehicle =
                result.entity


            if vehicle and vehicle ~= 0 then

                pcall(function()

                    exports.qbx_vehiclekeys:GiveKeys(
                        source,
                        vehicle,
                        true
                    )

                end)

            end


            TriggerClientEvent(
                'rp_admin:actionResult',
                source,
                true,
                'Vehicle spawned.'
            )


            return
        end


        -- =================================
        -- CURRENT VEHICLE
        -- =================================

        TriggerClientEvent(
            'rp_admin:vehicleAction',
            source,
            action
        )

    end
)

RegisterNetEvent('rp_admin:serverAction', function(action, message)

    local source = source

    print('^3[RP_ADMIN] serverAction received from ID ' .. tostring(source) .. '^7')
    print('^3[RP_ADMIN] Action: ' .. tostring(action) .. '^7')
    print('^3[RP_ADMIN] Message: ' .. tostring(message) .. '^7')

    if not isAdmin(source) then
        print('^1[RP_ADMIN] Permission denied for ID ' .. tostring(source) .. '^7')
        return
    end

    if action == 'announcement' then

        message = tostring(message or ''):sub(1, 200)

        if message == '' then
            print('^1[RP_ADMIN] Empty announcement^7')
            return
        end

        print('^2[RP_ADMIN] Broadcasting announcement: ' .. message .. '^7')

        TriggerClientEvent(
            'rp_admin:receiveAnnouncement',
            -1,
            message
        )

    end

end)

RegisterNetEvent('rp_admin:giveSpawnedVehicleKeys', function(netId)

    local source = source

    if not isAdmin(source) then
        return
    end

    local vehicle = NetworkGetEntityFromNetworkId(
        tonumber(netId)
    )

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        print('^1[RP_ADMIN] Could not find spawned vehicle for keys.^7')
        return
    end

    exports.qbx_vehiclekeys:GiveKeys(
        source,
        vehicle,
        true
    )

    print(
        '^2[RP_ADMIN] Vehicle keys granted to player '
        .. tostring(source)
        .. '^7'
    )

end)

RegisterNetEvent('rp_admin:testServerEvent', function(message)
    local src = source

    print('^2========================================^7')
    print('^2[RP_ADMIN SERVER] EVENT RECEIVED!^7')
    print('^3Player ID: ' .. tostring(src) .. '^7')
    print('^3Message: ' .. tostring(message) .. '^7')
    print('^2========================================^7')
end)