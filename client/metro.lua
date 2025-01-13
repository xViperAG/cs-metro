local IsPlayerInMetro = false
local ticketUI = false
local playerState = LocalPlayer.state

local TicketMachines = {'prop_train_ticket_02', 'prop_train_ticket_02_tu', 'v_serv_tu_statio3_'}
local anim = "mini@atmenter"

local MetroStopBlips = {
	Config.Blips
}

local function Notify(title, description, type, duration, icon)
	lib.notify({
		title = title,
		description = description,
		type = type,
		duration = duration,
		icon = icon
	})
end

local function openTicketUI()
    ticketUI = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openUI",
    })
end

local function exit()
    ticketUI = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "closeUI",
    })
end

local function buyMetroTicket()
	local isPay = lib.callback.await(Config.Banking ..':server:metroPay', false)

	if not isPay then
		exit()
		Notify('Metro Station', Config.Locales[Config.SelectedLocale]["notEnoughMoney"]["description"], 'error', 5000, 'fas fa-train-tram')
		return
	end

	exit()

	if GetResourceState('qb-phone'):match('started') then
		TriggerServerEvent('qb-phone:server:sendNewMail', {
			sender = Config.Locales[Config.SelectedLocale]["PhoneMessage"]["sender"],
			subject = Config.Locales[Config.SelectedLocale]["PhoneMessage"]["title"],
			message = Config.Locales[Config.SelectedLocale]["PhoneMessage"]["message"],
			button = {}
		})
	else
		Notify(Config.Locales[Config.SelectedLocale]["PhoneMessage"]["title"], Config.Locales[Config.SelectedLocale]["PhoneMessage"]["message"], 'success', 10000, 'fas fa-train-tram')
	end

	playerState.ShowedLeaveMetroHelper = false
	playerState.TicketInvalidated = false
	playerState.PlayerHasMetroTicket = true
end

RegisterNUICallback("exit", function(_)
    SetNuiFocus(false, false)
end)

RegisterNUICallback('NUIFocusOff', function()
	ticketUI = false
	SetNuiFocus(false, false)
	SendNUIMessage({
		type = "closeUI"
	})
end)

RegisterNUICallback('openTicketUI', function(_, cb)
    openTicketUI()
    cb('ok')
end)

RegisterNUICallback('buy', function(_, cb)
    buyMetroTicket()
    cb('ok')
end)

RegisterNUICallback('exit', function()
	exit()
end)

local symbol = Config.MoneySymbol
local price = Config.TicketPrice

local function setPrice(priceValue)
    SendNUIMessage({
        type = "setPrice",
		symbol = symbol,
        price = priceValue,
    })
end

local function getMetroTicket(entity)
	if playerState.PlayerHasMetroTicket then return end

	lib.requestAnimDict("mini@atmbase")
	lib.requestAnimDict(anim)

	local coords = GetEntityCoords(entity)

	SetCurrentPedWeapon(cache.ped, GetHashKey("weapon_unarmed"), true)
	TaskLookAtEntity(cache.ped, entity, 2000, 2048, 2)
	Wait(500)
	TaskGoStraightToCoord(cache.ped, coords.x, coords.y, coords.z, 0.1, 4000, GetEntityHeading(entity), 0.5)
	Wait(2000)
	TaskPlayAnim(cache.ped, anim, "enter", 8.0, 1.0, -1, 0, 0.0, false, false, false)
	RemoveAnimDict(anim)
	Wait(4000)
	TaskPlayAnim(cache.ped, "mini@atmbase", "base", 8.0, 1.0, -1, 0, 0.0, false, false, false)
	RemoveAnimDict("mini@atmbase")
	Wait(500)
	openTicketUI() -- opens ticket UI
	PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)

	lib.requestAnimDict("mini@atmexit")
	TaskPlayAnim(cache.ped, "mini@atmexit", "exit", 8.0, 1.0, -1, 0, 0.0, false, false, false)
	RemoveAnimDict("mini@atmexit")
	Wait(500)
	if not ticketUI then openTicketUI() end
end

local function createMetroTarget()
	exports.ox_target:addModel(TicketMachines, {
		{
			id = 'ticket_machine',
			label = Config.Locales[Config.SelectedLocale]["TextUI"]["all"],
			icon = 'fas fa-train-tram',
			onSelect = function(data)
				getMetroTicket(data.entity)
			end,
			canInteract = function(_, distance)
				return distance <= 2.5
			end
		}
	})

	--[[
	exports.ox_target:addSphereZone({
		coo
	})
	]]
end

AddEventHandler('Renewed-Lib:client:PlayerLoaded', function()
	createMetroTarget()
end)

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		setPrice(price)
		createMetroTarget()
	end
end)

CreateThread(function()
	for _, info in pairs(Config.Blips) do
		info.blip = AddBlipForCoord(info.x, info.y, info.z)
		SetBlipSprite(info.blip, info.id)
		SetBlipDisplay(info.blip, 4)
		SetBlipScale(info.blip, 0.4)
		SetBlipColour(info.blip, info.colour)
		SetBlipAsShortRange(info.blip, true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(info.title)
		EndTextCommandSetBlipName(info.blip)
	end
end)

CreateThread(function()
	while true do
		Wait(550)
		IsPlayerInMetro = IsPedInAnyTrain( cache.ped )
		if IsPlayerInMetro then
			if playerState.PlayerHasMetroTicket then
				if not playerState.ShowedLeaveMetroHelper then
					Wait(500)
					Notify('Metro Station', Config.Locales[Config.SelectedLocale]["Notifications"]["voidticket"]["description"], 'error', 5000, 'fas fa-train-tram')
					playerState.ShowedLeaveMetroHelper = true
					playerState.TicketInvalidated = true
					playerState.PlayerHasMetroTicket = false
				end
			else
				if not playerState.TicketInvalidated then
					Notify('Metro Station', Config.Locales[Config.SelectedLocale]["Notifications"]["noticket"]["description"], 'error', 5000, 'fas fa-train-tram')
					Wait(Config.PoliceAlert)
					if Config.CallPolice == true and IsPedInAnyTrain( cache.ped ) then
						exports['ps-dispatch']:Metro()
					end
					Wait(3500)
				end
			end
		end
	end
end)
