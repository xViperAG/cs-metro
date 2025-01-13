lib.callback.register(Config.Banking ..':server:metroPay', function(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if Player.Functions.RemoveMoney(Config.PayType, Config.TicketPrice) then
        return true
    else
        print("false")
        return false
    end
end)

local stateNames = {
    'ShowedLeaveMetroHelper',
    'TicketInvalidated',
    'PlayerHasMetroTicket',
}

AddEventHandler('Renewed-Lib:server:playerRemoved', function(source)
    local playerState = Player(source).state

    for i = 1, #stateNames do
        playerState:set(stateNames[i], false, true)
    end
end)

AddEventHandler('Renewed-Lib:server:playerLoaded', function(source)
    local playerState = Player(source).state

    for i = 1, #stateNames do
        playerState:set(stateNames[i], false, true)
    end
end)