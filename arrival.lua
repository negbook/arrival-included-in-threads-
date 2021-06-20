Arrival = {}
Arrival.PlayerPed = nil
Arrival.PlayerCoords = nil
Arrival.PlayerNearZones = {}
Arrival.Ready = nil 
Arrival.ZoneItems = {}
Arrival.Items = {}
Arrival.Data = {}
Arrival.Usages = {}
Arrival.ItemID = 1

--debuglog = true 
Arrival.PlayerNearItems = nil


Arrival.Temp_Usage = false

Arrival.AddGroupData = function(nGroup,ndata)
    Threads.CreateLoopOnce('vars',1000,function()
        Arrival.PlayerPed = PlayerPedId()
        Arrival.PlayerCoords = GetEntityCoords(Arrival.PlayerPed)
        local nearZones = Arrival.GetNearZonesFromCoords(Arrival.PlayerCoords)
        Arrival.PlayerNearZones = nearZones                                
        Arrival.Ready = true
        local objs = {}
        for i=1,#Arrival.PlayerNearZones do 
            local nearZoneitems = Arrival.PlayerNearZones[i] and  Arrival.ZoneItems[Arrival.PlayerNearZones[i]]  or {}
            if Arrival.PlayerNearZones[i] and #nearZoneitems >0 then 
                for i=1 , #nearZoneitems do 
                    local pos = vector3(nearZoneitems[i].nData.x,nearZoneitems[i].nData.y,nearZoneitems[i].nData.z)
                    local distance = #(pos - Arrival.PlayerCoords)
                    nearZoneitems[i].distance = distance
                    table.insert(objs,nearZoneitems[i])
                end 
            end 
        end 
        Arrival.PlayerNearItems = objs
        if Arrival.Temp_Usage then 
            Threads.CreateLoopOnceCustom("arrival",0,function(delay)
                local closingDistances = {}
                local stackedItems = {}
                for i=1,#Arrival.PlayerNearItems do 
                    local item = Arrival.PlayerNearItems[i]
                    local usage = Arrival.Usages[item.nGroup]
                    table.insert(closingDistances,item.distance)
                    if usage and item.distance <= usage.cbrange then 
                        if not stackedItems[item.nGroup] then stackedItems[item.nGroup] = {} end 
                        table.insert(stackedItems[item.nGroup],item.nData)
                        
                        if not item.enter then 
                            item.enter = true 
                            item.exit = false
                            if usage.onEnter then usage.onEnter(stackedItems[item.nGroup]) end 
                            if usage.onSpam then 
                                
                                Threads.CreateLoopOnce("arrivalSpam",0,function()
                                        usage.onSpam(stackedItems[item.nGroup])
                                    if item.distance > usage.cbrange then 
                                        Threads.KillActionOfLoop("arrivalSpam")
                                    end 
                                end)
                                
                                
                                
                            end 
                        end 
                        --print(item.distance,item.nGroup,vector3(item.nData.x,item.nData.y,item.nData.z),item.nZone)
                    else 
                        if item.enter then 
                            item.enter = false 
                            item.exit = true
                            if usage.onExit then usage.onExit(stackedItems and stackedItems[item.nGroup] and stackedItems[item.nGroup]) end 
                        end 
                    end 
                end 
                if #closingDistances > 0 then 
                    local k = 33 + math.min(table.unpack(closingDistances))*10
                    local waittime = k > 350 and 350 or k
                    delay.setter(waittime)
                    
                end 
            end)
        end 
        
    end)
    if not (ndata.x and ndata.y and ndata.z) then 
        print('data empty positions')
    end    
    ndata.arrivalID = Arrival.ItemID
    
    ndata.nGroup = nGroup
    local x,y,z = ndata.x , ndata.y , ndata.z
    local zone = Arrival.GetZonesFromCoords(x,y,z)
    ndata.nZone = zone
    if not Arrival.ZoneItems[zone] then Arrival.ZoneItems[zone] = {} end 
    table.insert(Arrival.ZoneItems[zone],{nGroup = nGroup, nZone = zone, nData = ndata})
    table.insert(Arrival.Items,{nGroup = nGroup, nZone = zone, nData = ndata})
    --print(Arrival.ItemID,x,y,z,zone)
    Arrival.ItemID = Arrival.ItemID + 1
    
end 

Arrival.RegisterGroupUsage = function(nGroup,usagedata)
    
    Arrival.Temp_Usage = true
    if not Arrival.Usages[nGroup] then Arrival.Usages[nGroup] = {} end 
    Arrival.Usages[nGroup].cbrange = usagedata.range or 1.0    
    Arrival.Usages[nGroup].onEnter = usagedata.onEnter   
    Arrival.Usages[nGroup].onExit = usagedata.onExit   
    Arrival.Usages[nGroup].onSpam = usagedata.onSpam  
end 

Arrival.RegisterTargets = function(nGroup, usagedatas)
        if usagedatas.itemlist and type(usagedatas.itemlist) == 'table' then 
            for i,v in pairs(usagedatas.itemlist) do 
                Arrival.AddGroupData(nGroup,v)
            end 
        else 
            print('itemlist not defined or empty')
        end 
        Arrival.RegisterGroupUsage(nGroup, usagedatas)
end

Arrival.GetZonesFromCoords = GetNameOfZone
Arrival.GetNearZonesFromCoords = function(...) -- ugly scripting by negbook
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
    end 
    local pos = GetObjectOffsetFromCoords(x,y,z,0.0, 0.0, 0.0 ,0.0)
    local temp_x = 0.0
    while GetNameOfZone(pos.x,pos.y,pos.z) == zone do 
        pos = GetObjectOffsetFromCoords(pos.x,pos.y,pos.z,0.0, temp_x, 0.0 ,0.0)
        temp_x = temp_x + 8.0
        NearZones[2] = GetNameOfZone(pos.x,pos.y,pos.z)
    end 
    local pos = GetObjectOffsetFromCoords(x,y,z,0.0, 0.0, 0.0 ,0.0)
    local temp_y = 0.0
    while GetNameOfZone(pos.x,pos.y,pos.z) == zone do 
        pos = GetObjectOffsetFromCoords(pos.x,pos.y,pos.z,0.0, 0.0, temp_y ,0.0)
        temp_y = temp_y - 8.0
        NearZones[3] = GetNameOfZone(pos.x,pos.y,pos.z)
    end 
    local pos = GetObjectOffsetFromCoords(x,y,z,0.0, 0.0, 0.0 ,0.0)
    local temp_x = 0.0
    while GetNameOfZone(pos.x,pos.y,pos.z) == zone do 
        pos = GetObjectOffsetFromCoords(pos.x,pos.y,pos.z,0.0, temp_x, 0.0 ,0.0)
        temp_x = temp_x - 8.0
        NearZones[4] = GetNameOfZone(pos.x,pos.y,pos.z)
    end 
    NearZones[5] = zone
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