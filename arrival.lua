Arrival = {}
Arrival.CallWhenArrived = {}
Arrival.CallWhenLeave = {}
Arrival.CallSpam = {}
Arrival.PlayerPed = nil
Arrival.PlayerCoords = nil
Arrival.ZoneItems = {} 
Arrival.CurrentZone = '' 
Arrival.CurrentNearZones = {}



Arrival.CurrentCallbackItemData = {}

Arrival.SpamCanDraw = nil 

--debuglog = true 
CreateThread(function()
Arrival.PlayerPed = PlayerPedId()
Threads.CreateLoop('zone',1000,function()
     Arrival.PlayerPed = PlayerPedId()
     Arrival.PlayerCoords = GetEntityCoords(Arrival.PlayerPed)
     local nearZones = GetNearZonesFromCoords(Arrival.PlayerCoords)
     Arrival.CurrentNearZones = nearZones                                
     Arrival.CurrentZone = Arrival.CurrentNearZones[5]

     
end)

end)

Arrival.RegisterCallback = function(ntype, onEnter,onExit ,onSpam, callbackdistance)
    Arrival.PlayerPed = PlayerPedId()
    local entered = false 
    
    Threads.CreateLoopCustom(function()
        if Arrival.PlayerPed then 
            
            local itemData,Distance = Arrival.FindPlayerClosestItem(ntype)
            if itemData and itemData.ntype and Distance then 
                local _ntype = itemData.ntype
                local change = Arrival.CurrentCallbackItemData[ntype] and Arrival.CurrentCallbackItemData[ntype].x ~= itemData.x 
                Arrival.CurrentCallbackItemData[ntype] = itemData
             
                if change then 
                end 
                if Distance < callbackdistance then 
                    if not entered then 
                        entered = true
                        if onSpam then 
                            Threads.CreateLoopOnce('onSpam',0,function()
                                if Arrival.SpamCanDraw and Arrival.CallSpam and Arrival.CallSpam[Arrival.SpamCanDraw[1]] then 
                                    Arrival.CallSpam[Arrival.SpamCanDraw[1]](Arrival.SpamCanDraw[2])
                                end 
                            end)
                        end 
                        itemData.enter = true
                        itemData.exit = false 
                        Arrival.SpamCanDraw = {_ntype,itemData} 
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
                        Threads.KillLoop('onSpam')
                        itemData.enter = false
                        itemData.exit = true 
                        Arrival.SpamCanDraw = nil
                        if itemData.ncb then 
                            itemData.ncb(itemData)
                        end 
                        if Arrival.CallWhenLeave and Arrival.CallWhenLeave[_ntype] then 
                            Arrival.CallWhenLeave[_ntype](itemData)
                        end 
                    end 
                end 
                

                local waittime = 33 + math.ceil(Distance*10)
                if waittime > 350 then 
                    waittime = 350
                end
                Wait(waittime)
            else 
            Wait(350)
          
            end 
        else 
            Wait(350)
           
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
function GetPlayerCoords()
    if Arrival.PlayerCoords then return Arrival.PlayerCoords 
    else 
        Arrival.PlayerCoords  = GetEntityCoords(PlayerPedId())
        return Arrival.PlayerCoords  
    end 
    
end 

Arrival.FindPlayerNearItems  = function()
    local objs = {}
    for i=1,#Arrival.CurrentNearZones do 
        local nearZone = Arrival.CurrentNearZones[i] and Arrival.ZoneItems[Arrival.CurrentNearZones[i]]  or {}
        if Arrival.CurrentNearZones[i] and #nearZone>0 then 
            for i=1 , #nearZone do 
                if GetPlayerCoords() then 
                    local objCoords = vector3(nearZone[i].x,nearZone[i].y,nearZone[i].z)
                    nearZone[i].distance = math.ceil(#(Arrival.PlayerCoords - objCoords))
                end 
                table.insert(objs,nearZone[i])
            end 
        end 
    end 
    
    return objs
end

Arrival.FindPlayerNearItemsByNType  = function(ntype)
        local _objs = Arrival.FindPlayerNearItems()

        local objs = {}
        for i,v in pairs(_objs) do
            if v.ntype == ntype then 
                table.insert(objs,v)
            end 
        end 

    return objs
end 

Arrival.FindPlayerClosestItem = function(ntype)
    Arrival.PlayerPed = PlayerPedId()
    if Arrival.PlayerPed then 
        local coords = GetEntityCoords(Arrival.PlayerPed)
        local closestDistance = -1
        local closestObject   = {}
        local objs = Arrival.FindPlayerNearItemsByNType(ntype)
        for i=1, #objs do
            local data = objs[i]
            local objectCoords = vector3(data.x,data.y,data.z)
            local distance     = #(objectCoords - coords)
            if closestDistance == -1 or closestDistance > distance then
                closestObject   = objs[i]
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
    local _hash1 = GetNameOfZone(x,y,z)
    local zone = _hash1
    data.zone = zone
    
    --case : zone (Distance: 0~10)
    if Arrival.ZoneItems[zone] == nil then 
        Arrival.ZoneItems[zone] = {}
    end
    table.insert(Arrival.ZoneItems[zone],data)
   
end 

Arrival.Add = function( ntype, data )
    if not data then return print("Error on Arrival resource: no any data")  end 
	return Arrival.formatData(ntype,data)
end

Arrival.GetZoneItems = function(zone)
    return Arrival.ZoneItems[zone] 
end 



Arrival.GetItemsByDistanceByNType = function(ntype,distance)
    local tbl = {}
    local tbl2 = Arrival.FindPlayerNearItemsByNType(ntype)
    for i=1,#tbl2 do 
        if tbl2[i].distance <= distance then 
            table.insert(tbl,tbl2[i])
        end 
    end 
    
    return tbl
end 

Arrival.RegisterTargets = function(ntype, datatable)

        Arrival.PlayerPed = PlayerPedId()

        if datatable.itemlist and type(datatable.itemlist) == 'table' then 
            for i,v in pairs(datatable.itemlist) do 
                Arrival.Add(ntype,v)
              
            end 
        else 
            print('itemlist not defined or empty')
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


function GetNearZonesFromCoords(...) -- ugly scripting by negbook
    local x,y,z 
    if #{...} == 3 then 
        x,y,z = ...
    else 
        x,y,z = (...).x,(...).y,(...).z 
    end 
    local zone = GetNameOfZone(x,y,z) 
    local NearZones = {}
    local pos = GetObjectOffsetFromCoords(x,y,z,0.0, 0.0, 0.0 ,0.0)
    local temp_y = 0.0
    while GetNameOfZone(pos.x,pos.y,pos.z) == zone do 
        pos = GetObjectOffsetFromCoords(pos.x,pos.y,pos.z,0.0, 0.0, temp_y ,0.0)
        temp_y = temp_y + 8.0
        NearZones[1] = GetNameOfZone(pos.x,pos.y,pos.z)
        --NearZones[1] = {}
        --NearZones[1].zone = GetNameOfZone(pos.x,pos.y,pos.z)
        --NearZones[1].pos = pos
    end 
    local pos = GetObjectOffsetFromCoords(x,y,z,0.0, 0.0, 0.0 ,0.0)
    local temp_x = 0.0
    while GetNameOfZone(pos.x,pos.y,pos.z) == zone do 
        pos = GetObjectOffsetFromCoords(pos.x,pos.y,pos.z,0.0, temp_x, 0.0 ,0.0)
        temp_x = temp_x + 8.0
        NearZones[2] = GetNameOfZone(pos.x,pos.y,pos.z)
        --NearZones[2] = {}
        --NearZones[2].zone = GetNameOfZone(pos.x,pos.y,pos.z)
        --NearZones[2].pos = pos
    end 
    local pos = GetObjectOffsetFromCoords(x,y,z,0.0, 0.0, 0.0 ,0.0)
    local temp_y = 0.0
    while GetNameOfZone(pos.x,pos.y,pos.z) == zone do 
        pos = GetObjectOffsetFromCoords(pos.x,pos.y,pos.z,0.0, 0.0, temp_y ,0.0)
        temp_y = temp_y - 8.0
        NearZones[3] = GetNameOfZone(pos.x,pos.y,pos.z)
        --NearZones[3] = {}
        --NearZones[3].zone = GetNameOfZone(pos.x,pos.y,pos.z)
        --NearZones[3].pos = pos
    end 
    local pos = GetObjectOffsetFromCoords(x,y,z,0.0, 0.0, 0.0 ,0.0)
    local temp_x = 0.0
    while GetNameOfZone(pos.x,pos.y,pos.z) == zone do 
        pos = GetObjectOffsetFromCoords(pos.x,pos.y,pos.z,0.0, temp_x, 0.0 ,0.0)
        temp_x = temp_x - 8.0
        NearZones[4] = GetNameOfZone(pos.x,pos.y,pos.z)
        --NearZones[4] = {}
        --NearZones[4].zone = GetNameOfZone(pos.x,pos.y,pos.z)
        --NearZones[4].pos = pos
    end 
    NearZones[5] = GetNameOfZone((...).x,(...).y,(...).z )
    
    return NearZones
end 

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