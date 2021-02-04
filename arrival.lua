Arrival = {}
Arrival.CallWhenArrived = {}
Arrival.CallWhenLeave = {}
Arrival.CallSpam = {}
Arrival.PlayerPed = nil
Arrival.StreetItems = {} 
Arrival.CurrentStreet = '' 
Arrival.CurrentFrontStreet = '' 
Arrival.CurrentBackStreet = '' 
Arrival.CurrentCallbackItemData = {}
SpamCanDraw = nil 

--debuglog = true 
CreateThread(function()
Threads.CreateLoop('street',1000,function()
     Arrival.PlayerPed = PlayerPedId()
     local coords = GetEntityCoords(Arrival.PlayerPed)
     local hash,hash2 = GetStreetNameAtCoord(coords.x,coords.y,coords.z)
     Arrival.CurrentStreet = hash or hash2
     local fcoords = GetOffsetFromEntityInWorldCoords(Arrival.PlayerPed,0.0,2.5 ,0.0)
     local hash3,hash4 = GetStreetNameAtCoord(fcoords.x,fcoords.y,fcoords.z)
     Arrival.CurrentFrontStreet = hash3 or hash4
     local bcoords = GetOffsetFromEntityInWorldCoords(Arrival.PlayerPed,0.0,-2.5 ,0.0)
     local hash5,hash6 = GetStreetNameAtCoord(bcoords.x,bcoords.y,bcoords.z)
     Arrival.CurrentBackStreet = hash5 or hash6
end)
end)
Arrival.RegisterCallback = function(ntype, onEnter,onExit ,onSpam, callbackdistance)
    local entered = false 
    if onSpam then 
        Threads.CreateLoop('onSpam',0,function()
            if SpamCanDraw and Arrival.CallSpam then 
                Arrival.CallSpam[SpamCanDraw[1]](SpamCanDraw[2])
            end 
        end)
    end 
    Threads.CreateLoopSimple(function()
            if Arrival.PlayerPed then 
                
                local itemData,Distance = Arrival.FindClosestItem(ntype)
                if itemData and itemData.ntype and Distance then 
                    local _ntype = itemData.ntype
                    local change = Arrival.CurrentCallbackItemData[ntype] and Arrival.CurrentCallbackItemData[ntype].x ~= itemData.x 
                    Arrival.CurrentCallbackItemData[ntype] = itemData
                    if change then 
                    end 
                    itemData.distance = math.ceil(Distance)
                    if Distance < callbackdistance then 
                        if not entered then 
                            entered = true
                            itemData.enter = true
                            itemData.exit = false 
                            SpamCanDraw = {_ntype,itemData} 
                            if itemData.ncb then 
                                itemData.ncb(itemData)
                            end 
                            if Arrival.CallWhenArrived and Arrival.CallWhenArrived[_ntype] then 
                                Arrival.CallWhenArrived[_ntype](itemData)
                            end 
                        end 
                    else 
                        if entered then 
                            entered = false 
                            itemData.enter = false
                            itemData.exit = true 
                            SpamCanDraw = nil
                            if itemData.ncb then 
                                itemData.ncb(itemData)
                            end 
                            if Arrival.CallWhenLeave and Arrival.CallWhenLeave[_ntype] then 
                                Arrival.CallWhenLeave[_ntype](itemData)
                            end 
                        end 
                    end 
                    

                    local waittime = math.ceil(Distance*10)
                    if waittime < 33 then 
                        waittime = 33
                        
                    else
                        if waittime > 2500 then 
                            waittime = 2500
                        end
                    end 
                    Wait(waittime)
                end 
            else 
                Wait(2500)
            end 
    end )
    if onEnter then 
        Arrival.CallWhenArrived[ntype] = function(data)
            local status, err = pcall(function()
                onEnter(data)
            end)
            if err then
                print("error during Arrival callback " .. ntype .. ": " .. err .. "\n")
            end
        end
    end 
    if onExit then 
    Arrival.CallWhenLeave[ntype] = function(data)
		local status, err = pcall(function()
			onExit(data)
		end)
		if err then
			print("error during Arrival callback " .. ntype .. ": " .. err .. "\n")
		end
	end
    end 
    if onSpam then 
    Arrival.CallSpam[ntype] = function(data)
		local status, err = pcall(function()
			onSpam(data)
		end)
		if err then
			print("error during Arrival callback " .. ntype .. ": " .. err .. "\n")
		end
	end
    end 
end 
Arrival.FindClosestItem = function(ntype)
    if Arrival.PlayerPed then 
        local coords = GetEntityCoords(Arrival.PlayerPed)
        local Bobjects = {}
        if Arrival.CurrentStreet and #Arrival.StreetItems[Arrival.CurrentStreet] > 0 then  
            for i=1 , #Arrival.StreetItems[Arrival.CurrentStreet] do 
                table.insert(Bobjects,Arrival.StreetItems[Arrival.CurrentStreet][i])
            end 
        end 
       
        if Arrival.CurrentFrontStreet and Arrival.CurrentStreet ~= Arrival.CurrentFrontStreet and #Arrival.StreetItems[Arrival.CurrentFrontStreet]>0 then 
            for i=1 , #Arrival.StreetItems[Arrival.CurrentFrontStreet] do 
                table.insert(Bobjects,Arrival.StreetItems[Arrival.CurrentFrontStreet][i])
            end 
        end 
       
        if Arrival.CurrentBackStreet and Arrival.CurrentStreet ~= Arrival.CurrentBackStreet and #Arrival.StreetItems[Arrival.CurrentBackStreet]>0 then 
            for i=1 , #Arrival.StreetItems[Arrival.CurrentBackStreet] do 
                table.insert(Bobjects,Arrival.StreetItems[Arrival.CurrentBackStreet][i])
            end 
        end 
      
        local closestDistance = -1
        local closestObject   = {}
        local Sobjects = {}
        for i,v in pairs(Bobjects) do
            if v.ntype == ntype then 
                table.insert(Sobjects,v)
            end 
        end 
        for i=1, #Sobjects do
            local data = Sobjects[i]
            local objectCoords = vector3(data.x,data.y,data.z)
            local distance     = #(objectCoords - coords)
            if closestDistance == -1 or closestDistance > distance then
                closestObject   = Sobjects[i]
                closestDistance = distance
            end
        end
	return closestObject,closestDistance
    end 
end
Arrival.formatData = function(ntype, data)
    if not data.x or not data.y or not data.z then 
        print("data should have x,y,z infomations")
    end 
    local x,y,z = data.x,data.y,data.z
    data.ntype = ntype
    local cb = data.cb
    data.ncb = cb
    local _hash1,_hash2 = GetStreetNameAtCoord(x,y,z)
    local street = _hash1 or _hash2
    --case : street (Distance: 0~10)
    if not Arrival.StreetItems[street] then 
        Arrival.StreetItems[street] = {}
    end
    table.insert(Arrival.StreetItems[street],data)
end 

Arrival.Add = function( ntype, data )
    if not data then return print("Error on Arrival resource: no any data")  end 
	Arrival.formatData(ntype,data)
end
Arrival.RegisterTargets = function(ntype, datatable)
    if datatable.itemlist and type(datatable.itemlist) == 'table' then 
        for i,v in pairs(datatable.itemlist) do 
            Arrival.Add(ntype,v)
        end 
    end 
	local status, err = pcall(function()
        if datatable.onEnter or datatable.onExit or datatable.onSpam then 
            local distance = datatable.range or 1.0
            local EnterCallback = datatable.onEnter  
            local ExitCallback = datatable.onExit 
            local SpamCallback = datatable.onSpam   
            Arrival.RegisterCallback(ntype,EnterCallback,ExitCallback,SpamCallback,distance)
        end 
	end)
	if err then
		Citizen.Trace("error during Arrival.RegisterTargets " .. ntype .. ": \n" .. err .. "\n")
	end
end
--[======[
Arrival.RegisterTargets ('new_banking_atms',{ 
    itemlist = atms,
    callback = 
                        function(data)
                            local distance = data.distance
                            print('NEW '..data.ntype.."is arrived ,pos:"..data.x ..' '.. data.y ..' '.. data.z)
                        end
    ,
    range = 2.5
})
--]======]
--debug 
--[======[
if debuglog then 
local thisname = "arrival"
CreateThread(function()
	if IsDuplicityVersion() then 
		if GetCurrentResourceName() ~= thisname then 
			print('\x1B[32m[server-utils]\x1B[0m'..thisname..' is used on '..GetCurrentResourceName().." \n\x1B[32m[\x1B[33m"..thisname.."\x1B[32m]\x1B[33m"..GetResourcePath(GetCurrentResourceName())..'\x1B[0m')
		end 
		RegisterServerEvent(thisname..':log')
		AddEventHandler(thisname..':log', function(strings,sourcename)
			print(strings.." player:"..GetPlayerName(source).." \n\x1B[32m[\x1B[33m"..thisname.."\x1B[32m]\x1B[33m"..GetResourcePath(sourcename)..'\x1B[0m')
		end)
	else 
		if GetCurrentResourceName() ~= thisname then 
			TriggerServerEvent(thisname..':log','\x1B[32m[client-utils]\x1B[0m'..thisname..'" is used on '..GetCurrentResourceName(),GetCurrentResourceName())
		end 
	end 
end)
end 
--]======]