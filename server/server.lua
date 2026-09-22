local function isAdmin(source)
    return IsPlayerAceAllowed(source, 'rp_admin.use')
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
    function(targetId, action)

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

RegisterNetEvent('rp_admin:sendAnnouncement', function(message)

    local src = source

    print('^2[RP_ADMIN SERVER] ANNOUNCEMENT EVENT RECEIVED!^7')
    print('^3[RP_ADMIN SERVER] Player: ' .. tostring(src) .. '^7')
    print('^3[RP_ADMIN SERVER] Message: ' .. tostring(message) .. '^7')

    if not isAdmin(src) then
        print('^1[RP_ADMIN SERVER] Permission denied.^7')
        return
    end

    message = tostring(message or ''):sub(1, 200)

    if message == '' then
        return
    end

    print('^2[RP_ADMIN SERVER] Broadcasting announcement!^7')

    TriggerClientEvent(
        'rp_admin:receiveAnnouncement',
        -1,
        message
    )

end)