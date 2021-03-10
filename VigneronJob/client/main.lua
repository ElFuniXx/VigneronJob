local HasAlreadyEnteredMarker, LastVigne, LastPart, LastPartNum
local CurrentAction, CurrentActionMsg, CurrentActionData = nil, '', {}
local isDead, isBusy = false, false
local PlayerData,  JobBlips = {}, {}
local publicBlip = false
ESX = nil

RegisterNetEvent('vuzireee:playerLoaded')
AddEventHandler('vuzireee:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    blips()
end)

RegisterNetEvent('vuzireee:setJob')
AddEventHandler('vuzireee:setJob', function(job)
    PlayerData.job = job
    deleteBlips()
    blips()
end)

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('vuzireee:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()
end)


function OpenVigneActionsMenu()
	local elements = {
		{label = _U('deposit_stock'),  value = 'put_stock'},
		{label = _U('withdraw_stock'), value = 'get_stock'}
	}


	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vigne_actions', {
		title    = _U('vigne'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		if data.current.value == 'put_stock' then
			OpenPutStocksMenu()
		elseif data.current.value == 'get_stock' then
			OpenGetStocksMenu()
		end
	end, function(data, menu)
		menu.close()

		CurrentAction     = 'vigne_actions_menu'
		CurrentActionMsg  = _U('open_actions')
		CurrentActionData = {}
	end)
end






function OpenGetStocksMenu()
	ESX.TriggerServerCallback('vuzireee_vignejob:getStockItems', function(items)
		local elements = {}

		for i=1, #items, 1 do
			table.insert(elements, {
				label = 'x' .. items[i].count .. ' ' .. items[i].label,
				value = items[i].name
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('vigne_stock'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					ESX.ShowNotification(_U('invalid_quantity'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('vuzireee_vignejob:getStockItem', itemName, count)

					Citizen.Wait(1000)
					OpenGetStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenPutStocksMenu()
	ESX.TriggerServerCallback('vuzireee_vignejob:getPlayerInventory', function(inventory)
		local elements = {}

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type  = 'item_standard',
					value = item.name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('inventory'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					ESX.ShowNotification(_U('invalid_quantity'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('vuzireee_vignejob:putStockItems', itemName, count)

					Citizen.Wait(1000)
					OpenPutStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

RegisterNetEvent('vuzireee_vignejob:onHijack')
AddEventHandler('vuzireee_vignejob:onHijack', function()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)

	if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
		local vehicle

		if IsPedInAnyVehicle(playerPed, false) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		else
			vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
		end

		local chance = math.random(100)
		local alarm  = math.random(100)

		if DoesEntityExist(vehicle) then
			if alarm <= 33 then
				SetVehicleAlarm(vehicle, true)
				StartVehicleAlarm(vehicle)
			end

			TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)

			Citizen.CreateThread(function()
				Citizen.Wait(10000)
				if chance <= 66 then
					SetVehicleDoorsLocked(vehicle, 1)
					SetVehicleDoorsLockedForAllPlayers(vehicle, false)
					ClearPedTasksImmediately(playerPed)
					ESX.ShowNotification(_U('veh_unlocked'))
				else
					ESX.ShowNotification(_U('hijack_failed'))
					ClearPedTasksImmediately(playerPed)
				end
			end)
		end
	end
end)


function blips()
    if publicBlip == false then
        local blip = AddBlipForCoord(Config.Zones.VigneronActions.Pos.x, Config.Zones.VigneronActions.Pos.y, Config.Zones.VigneronActions.Pos.z)
        SetBlipSprite (blip, 85)
        SetBlipDisplay(blip, 4)
        SetBlipScale  (blip, 1.0)
        SetBlipColour (blip, 19)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString("Vignerons")
        EndTextCommandSetBlipName(blip)
        publicBlip = true
    end

    if PlayerData.job ~= nil and PlayerData.job.name == 'vigne' then

        for k,v in pairs(Config.Zones)do
            if v.Type == 1 then
                local blip2 = AddBlipForCoord(v.Pos.x, v.Pos.y, v.Pos.z)

                SetBlipSprite (blip2, 85)
                SetBlipDisplay(blip2, 4)
                SetBlipScale  (blip2, 1.0)
                SetBlipColour (blip2, 19)
                SetBlipAsShortRange(blip2, true)

                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(v.Name)
                EndTextCommandSetBlipName(blip2)
                table.insert(JobBlips, blip2)
            end
        end
    end
end

RegisterNetEvent('vuzireee_vignejob:onCarokit')
AddEventHandler('vuzireee_vignejob:onCarokit', function()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)

	if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
		local vehicle

		if IsPedInAnyVehicle(playerPed, false) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		else
			vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
		end

		if DoesEntityExist(vehicle) then
			TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_HAMMERING', 0, true)
			Citizen.CreateThread(function()
				Citizen.Wait(10000)
				SetVehicleFixed(vehicle)
				SetVehicleDeformationFixed(vehicle)
				ClearPedTasksImmediately(playerPed)
				ESX.ShowNotification(_U('body_repaired'))
			end)
		end
	end
end)

RegisterNetEvent('vuzireee_vignejob:onFixkit')
AddEventHandler('vuzireee_vignejob:onFixkit', function()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)

	if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
		local vehicle

		if IsPedInAnyVehicle(playerPed, false) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		else
			vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
		end

		if DoesEntityExist(vehicle) then
			TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_BUM_BIN', 0, true)
			Citizen.CreateThread(function()
				Citizen.Wait(20000)
				SetVehicleFixed(vehicle)
				SetVehicleDeformationFixed(vehicle)
				SetVehicleUndriveable(vehicle, false)
				ClearPedTasksImmediately(playerPed)
				ESX.ShowNotification(_U('veh_repaired'))
			end)
		end
	end
end)

RegisterNetEvent('vuzireee:playerLoaded')
AddEventHandler('vuzireee:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)

RegisterNetEvent('vuzireee:setJob')
AddEventHandler('vuzireee:setJob', function(job)
	ESX.PlayerData.job = job
end)


AddEventHandler('vuzireee:onPlayerDeath', function(data) isDead = true end)
AddEventHandler('vuzireee:onPlayerSpawn', function(spawn) isDead = false end)



-- Marker



-- Draw markers & Marker logic
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'vigne' then
			local playerCoords = GetEntityCoords(PlayerPedId())
			local letSleep, isInMarker, hasExited = true, false, false
			local currentVigne, currentPart, currentPartNum

			for VigneNum,Vigne in pairs(Config.Zones) do
				-- Vestiaires
				for k,v in ipairs(Config.Zones.Cloakroom) do
					local distance = #(playerCoords - v)

					if distance < Config.DrawDistance then
						DrawMarker(Config.Marker.type, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.x, Config.Marker.y, Config.Marker.z, Config.Marker.r, Config.Marker.g, Config.Marker.b, Config.Marker.a, false, false, 2, Config.Marker.rotate, nil, nil, false)
						letSleep = false

						if distance < Config.Marker.x then
							isInMarker, currentVigne, currentPart, currentPartNum = true, VigneNum, 'Cloakroombn', k
						end
					end
				end
				-- Stockage
				for k,v in ipairs(Config.Zones.Actions) do
					local distance = #(playerCoords - v)

					if distance < Config.DrawDistance then
						DrawMarker(Config.Marker.type, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.x, Config.Marker.y, Config.Marker.z, Config.Marker.r, Config.Marker.g, Config.Marker.b, Config.Marker.a, false, false, 2, Config.Marker.rotate, nil, nil, false)
						letSleep = false

						if distance < Config.Marker.x then
							isInMarker, currentVigne, currentPart, currentPartNum = true, VigneNum, 'Actions', k
						end
					end
				end
				-- Actions Patron
				if Config.EnablePlayerManagement and ESX.PlayerData.job and ESX.PlayerData.job.grade_name == 'boss' then
					for k,v in ipairs(Config.Zones.Boss) do
						local distance = #(playerCoords - v)
	
						if distance < Config.DrawDistance then
							DrawMarker(Config.Marker.type, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.x, Config.Marker.y, Config.Marker.z, Config.Marker.r, Config.Marker.g, Config.Marker.b, Config.Marker.a, false, false, 2, Config.Marker.rotate, nil, nil, false)
							letSleep = false
	
							if distance < Config.Marker.x then
								isInMarker, currentVigne, currentPart, currentPartNum = true, VigneNum, 'Boss', k
							end
						end
					end
				end				
				-- Vestiaires
				for k,v in ipairs(Config.Zones.Garage) do
					local distance = #(playerCoords - v)

					if distance < Config.DrawDistance then
						DrawMarker(Config.Marker.type, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.x, Config.Marker.y, Config.Marker.z, Config.Marker.r, Config.Marker.g, Config.Marker.b, Config.Marker.a, false, false, 2, Config.Marker.rotate, nil, nil, false)
						letSleep = false

						if distance < Config.Marker.x then
							isInMarker, currentVigne, currentPart, currentPartNum = true, VigneNum, 'Garage', k
						end
					end
				end
				-- Deleter
				for k,v in ipairs(Config.Zones.Deleter) do
					local distance = #(playerCoords - v)

					if distance < Config.DrawDistance then
						DrawMarker(Config.Marker.type, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.x, Config.Marker.y, Config.Marker.z, Config.Marker.r, Config.Marker.g, Config.Marker.b, Config.Marker.a, false, false, 2, Config.Marker.rotate, nil, nil, false)
						letSleep = false

						if distance < Config.Marker.x then
							isInMarker, currentVigne, currentPart, currentPartNum = true, VigneNum, 'Deleter', k
						end
					end
				end
				-- Craft

				for k,v in ipairs(Config.Zones.Harv) do
					local distance = #(playerCoords - v)

					if distance < Config.DrawDistance then
						DrawMarker(Config.Marker.type, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.x, Config.Marker.y, Config.Marker.z, Config.Marker.r, Config.Marker.g, Config.Marker.b, Config.Marker.a, false, false, 2, Config.Marker.rotate, nil, nil, false)
						letSleep = false

						if distance < Config.Marker.x then
							isInMarker, currentVigne, currentPart, currentPartNum = true, VigneNum, 'Harv', k
						end
					end
				end

				for k,v in ipairs(Config.Zones.Craft) do
					local distance = #(playerCoords - v)

					if distance < Config.DrawDistance then
						DrawMarker(Config.Marker.type, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.x, Config.Marker.y, Config.Marker.z, Config.Marker.r, Config.Marker.g, Config.Marker.b, Config.Marker.a, false, false, 2, Config.Marker.rotate, nil, nil, false)
						letSleep = false

						if distance < Config.Marker.x then
							isInMarker, currentVigne, currentPart, currentPartNum = true, VigneNum, 'Craft', k
						end
					end
				end
				

			--vente

			for k,v in ipairs(Config.Zones.Sell) do
				local distance = #(playerCoords - v)

				if distance < Config.DrawDistance then
					DrawMarker(Config.Marker.type, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.x, Config.Marker.y, Config.Marker.z, Config.Marker.r, Config.Marker.g, Config.Marker.b, Config.Marker.a, false, false, 2, Config.Marker.rotate, nil, nil, false)
					letSleep = false

					if distance < Config.Marker.x then
						isInMarker, currentVigne, currentPart, currentPartNum = true, VigneNum, 'Sell', k
					end
				end
			end
			
		end

			-- Logic for exiting & entering markers
			if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastVigne ~= currentVigne or LastPart ~= currentPart or LastPartNum ~= currentPartNum)) then
				if
					(LastVigne ~= nil and LastPart ~= nil and LastPartNum ~= nil) and
					(LastVigne ~= currentVigne or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
				then
					TriggerEvent('lsVigne:hasExitedMarker', LastVigne, LastPart, LastPartNum)
					hasExited = true
				end

				HasAlreadyEnteredMarker, LastVigne, LastPart, LastPartNum = true, currentVigne, currentPart, currentPartNum

				TriggerEvent('lsVigne:hasEnteredMarker', currentVigne, currentPart, currentPartNum)
			end

			if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('lsVigne:hasExitedMarker', LastVigne, LastPart, LastPartNum)
			end

			if letSleep then
				Citizen.Wait(500)
			end
		else
			Citizen.Wait(500)
		end
	end
end)

AddEventHandler('lsVigne:hasEnteredMarker', function(Vigne, part, partNum)
	if part == 'Cloakroombn' then
		CurrentAction = part
		CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour acceder au vestiaires'
		CurrentActionData = {}
	elseif part == 'Actions' then
		CurrentAction = part
		CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour acceder aux Actions'
		CurrentActionData = {}
	elseif part == 'Boss' then
		CurrentAction = part
		CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour acceder à l\'ordinateur'
		CurrentActionData = {}
	elseif part == 'Deleter' then
		CurrentAction = part
		CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour ranger le véhicule.'
		CurrentActionData = {}
	elseif part == 'Harv' then
		CurrentAction = part
		CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour ~r~Récolter.'
		CurrentActionData = {}
	elseif part == 'Craft' then
		CurrentAction = part
		CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour ~r~Traiter.'
		CurrentActionData = {}
	elseif part == 'Sell' then
		CurrentAction = part
		CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour ~r~Vendre.'
		CurrentActionData = {}
	elseif part == 'Garage' then
		CurrentAction = part
		CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour acceder au Garage'
		CurrentActionData = {}
	end
end)

AddEventHandler('lsVigne:hasExitedMarker', function(zone)
	CurrentAction = nil
	ESX.UI.Menu.CloseAll()
end)





-- Key Controls



Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if CurrentAction then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, 38) then
				if CurrentAction == 'Cloakroombn' then
					TriggerEvent('Cloakroombn')
				elseif CurrentAction == 'Boss' then
					TriggerEvent('vuzireee_society:openBossMenu', 'vigne', function(data, menu)
						menu.close()
					end)
				elseif CurrentAction == 'Actions' then
					OpenVigneActionsMenu()
				elseif CurrentAction == 'Garage' then
					TriggerEvent('vigne_garage')
				elseif CurrentAction == 'Harv' then
					TriggerEvent('vigne_harvest')
				elseif CurrentAction == 'Craft' then
					TriggerEvent('craft')
				elseif CurrentAction == 'Sell' then
					TriggerEvent('vigne_sell')
				elseif CurrentAction == 'Deleter' then
					local veh = GetVehiclePedIsIn(PlayerPedId(), false)
					if veh ~= nil then DeleteEntity(veh) end
				end

				CurrentAction = nil
			end

		elseif ESX.PlayerData.job and ESX.PlayerData.job.name == 'vigne' and not isDead then
			if IsControlJustReleased(0, 167) then
				TriggerEvent('vigne_menu')
			end
		else
			Citizen.Wait(500)
		end
	end
end)

