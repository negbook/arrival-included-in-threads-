local Arrival = {}
Arrival.zonedata_full = {}
Arrival.currentzonedata = {}


Arrival.ped = nil
Arrival.pedcoords = vector3(0.0,0.0,0.0)
Arrival.pedzone = ''
Arrival.debuglog = true
RegisterNetEvent('Arrival:RegisterInit')
AddEventHandler('Arrival:RegisterInit', function(datas,rangeorcb,_cb) 
    print('here')
    Arrival.Register(datas,rangeorcb,_cb)
end)

Arrival.Register = function (datas,rangeorcb,_cb)
    local fntotable = function(fn) return setmetatable({},{__index=function(t,k) return 'isme' end ,__call=function(t,...) return fn(...) end })  end 
    local cooked_cb = function(sdata,action)
        local name = tostring(sdata)
        --local result = {data=sdata,data_source=datas[sdata.index],killer=setmetatable({},{__call = function(t,data) if Threads.IsActionOfLoopAlive(name) then Threads.KillActionOfLoop(name) end  end}),spamer=setmetatable({},{__call = function(t,data) Threads.CreateLoop(name,0,data) end}),action=action}
        --result.spamkiller = result.killer
        local result = {data=sdata,data_source=datas[sdata.index],action=action}
        
        return _cb(result) 
    end 
    local range,cb = 1.0,cooked_cb
    if rangeorcb and type(rangeorcb)=='number' then 
        range = rangeorcb 
    else 
        cb = rangeorcb 
    end 
    local data = Arrival.ConvertData(datas)  -- to .x .y .z .index 
    local zonelist,zonedata = Arrival.CollectZoneData(data,range)
    for i,v in pairs (zonedata) do 
        local zone = v.zone
        v.arrival = fntotable(cb)
        v.range = range
        if not Arrival.zonedata_full[zone] then Arrival.zonedata_full[zone]={} end 
        table.insert(Arrival.zonedata_full[zone],v)
    end 
    
    if  GetCurrentResourceName() ~= resourceName or Arrival.debuglog then
        Threads.CreateLoopOnce('inits',528,function(delay)
            Arrival.ped = PlayerPedId()
            Arrival.pedcoords = GetEntityCoords(Arrival.ped)
            if Arrival.pedzone ~= Arrival.GetHashMethod(Arrival.pedcoords.x,Arrival.pedcoords.y,Arrival.pedcoords.z,range) then 
                local old = Arrival.pedzone
                if old and #old>0 then 
                    local zonedatas = Arrival.zonedata_full[old]
                    if zonedatas and #zonedatas>0 then 
                        for i=1,#zonedatas do 
                            local v = zonedatas[i]
                            local pos = vector3(v.x,v.y,v.z)
                            local distance = #(pos-Arrival.pedcoords)
                            if distance < v.range then
                                if not v.enter then 
                                    v.enter = true 
                                    if v.arrival then v.arrival(v,'enter') end 
                                end 
                                if v.exit~=nil and v.exit == true then 
                                    v.exit = false 
                                end 
                                
                            else 
                                if v.enter~=nil and v.enter == true then 
                                    v.enter = false 
                                    v.exit = true
                                    if v.arrival then v.arrival(v,'exit') end 
                                end 
                                
                            end 
                        end 
                    end 
                end 
            end 
            Arrival.pedzone = Arrival.GetHashMethod(Arrival.pedcoords.x,Arrival.pedcoords.y,Arrival.pedcoords.z,range)
            local zonedatas = Arrival.zonedata_full[Arrival.pedzone]
            if zonedatas and #zonedatas>0 then 
                for i=1,#zonedatas do 
                    local v = zonedatas[i]
                    local pos = vector3(v.x,v.y,v.z)
                    local distance = #(pos-Arrival.pedcoords)
                    if distance < v.range then
                        if not v.enter then 
                            v.enter = true 
                            if v.arrival then v.arrival(v,'enter') end 
                        end 
                        if v.exit~=nil and v.exit == true then 
                            v.exit = false 
                        end 
                        
                    else 
                        if v.enter~=nil and v.enter == true then 
                            v.enter = false 
                            v.exit = true
                            if v.arrival then v.arrival(v,'exit') end 
                        end 
                        
                    end 
                end 
            end 
        end)
    end 
end 

exports('Register', function(...)
  Arrival.Register(...)
end)


Arrival.getnearzones = function(...)
    local _pos = {...}
    if #{...} == 3 then 
        _pos = vector3(_pos[1],_pos[2],_pos[3])
    else 
        _pos = _pos[1]
    end 
    local nearzones = {}
    local included = function(zone) 
        local found = false 
        for i=1,#nearzones do 
            if nearzones[i]==zone then 
                found = true 
            end 
        end 
        return found 
    end 
    
        local pos = _pos
    local temp_y = 0.0
  
        pos = GetObjectOffsetFromCoords(pos,0.0, 0.0, temp_y ,0.0)
        temp_y = temp_y + 8.0
    if not included(GetNameOfZone(pos)) then table.insert(nearzones,GetNameOfZone(pos)) end 
    local pos = Arrival.pedcoords
    local temp_x = 0.0
    
        pos = GetObjectOffsetFromCoords(pos.x,pos.y,pos.z,0.0, temp_x, 0.0 ,0.0)
        temp_x = temp_x + 8.0
   
    if not included(GetNameOfZone(pos)) then table.insert(nearzones,GetNameOfZone(pos)) end 
    local pos = Arrival.pedcoords
    local temp_y = 0.0

        pos = GetObjectOffsetFromCoords(pos,0.0, 0.0, temp_y ,0.0)
        temp_y = temp_y - 8.0
    
    if not included(GetNameOfZone(pos)) then table.insert(nearzones,GetNameOfZone(pos)) end 
    local pos = Arrival.pedcoords
    local temp_x = 0.0
 
        pos = GetObjectOffsetFromCoords(pos,0.0, temp_x, 0.0 ,0.0)
        temp_x = temp_x - 8.0
 
    if not included(GetNameOfZone(pos)) then table.insert(nearzones,GetNameOfZone(pos)) end 
    return nearzones
end 
Arrival.CollectZoneData = function(datatable,range) --vector3 or {x=1.0,y=2.0,z=3.0}
    local isVector3 = type(datatable[1])=='vector3'
    local zonelist = {}
    local zonedata = {}
    local included = function(zone) 
        local found = false 
        for i=1,#zonelist do 
            if zonelist[i] == zone then 
                found = true 
                break 
            end 
        end 
        return found
    end 
    
    for i=1,#datatable do 
        local v = datatable[i]
        
        local zone = Arrival.GetHashMethod(v.x,v.y,v.z,range)
        table.insert(zonedata,{data=v.data,index=v.index,x=v.x,y=v.y,z=v.z,zone=zone})
        if not included(zone) then 
            table.insert(zonelist,zone) 
        end 
    end 
    
    return zonelist,zonedata
end 
Arrival.ConvertData = function(datatable) 
    local tp = nil
    local result = {}
    local tofloat = function(x) return tonumber(x)+0.0 end 
    if #datatable > 0 then
        if type(datatable) == 'table' then 
            local t = datatable[1]
            if type(t) == 'vector3' then 
                tp = 3
                local rt = {}
                for i=1,#datatable do 
                    table.insert(rt,{x = tofloat(datatable[i].x),y = tofloat(datatable[i].y),z = tofloat(datatable[i].z),index=i,data=datatable})
                end 
                result = rt 
            elseif t.x and t.y and t.z then 
                tp = 1
                local rt = {}
                for i=1,#datatable do 
                    table.insert(rt,{x = tofloat(datatable[i].x),y = tofloat(datatable[i].y),z = tofloat(datatable[i].z),index=i,data=datatable})
                end 
                result = rt 
            elseif #t >=3 then 
                local found = false 
                local i = 2 
                while not found and i+1 <=#t do 
                    local tl,tm,tr = t[i-1],t[i],t[i+1]
                    if tl and tm and tr then 
                        if type(tl) == 'number' and type(tm) == 'number' and type(tr) == 'number' then 
                            if math.type(tl) == 'float' and math.type(tm) == 'float' and math.type(tr) == 'float' then 
                                tp = 2
                                found = true 
                                local rt = {}
                                for idx=1,#datatable do 
                                    table.insert(rt,{x = tofloat(tl) , y = tofloat(tm) , z = tofloat(tr),index=idx,data=datatable})
                                end 
                                result = rt 
                            else 
                                found = false 
                                --error('data style not supported',2)
                            end 
                        end 
                    else 
                        found = false 
                        --error('data style not supported',2)
                    end 
                    i = i + 1
                end 
            end 
        else 
            error('Arrival.ConvertData(table)',2)
        end 
    else 
        error('data style not supported',2)
    end 
    if not tp then 
        error('data style not supported',2)
    else 
        
    end 

    return result --3 vector3,2 normal,1 .x .y .z
end 

Arrival.GetHashMethod = function(x,y,z,range)
    local pos = vector3(x,y,z)
    local range = range or 1.0
    local range2 = range*4 > 50.0 and 50.0 or range*4
    result = GetNameOfZone(pos) .. tostring(math.floor(GetHeightmapTopZForArea(pos.x-range,pos.y-range,pos.x+range,pos.y+range))) .. tostring(math.floor(GetHeightmapBottomZForArea(pos.x-range*2,pos.y-range*2,pos.x+range*2,pos.y+range*2))) .. tostring(math.floor(GetHeightmapBottomZForArea(pos.x-range2,pos.y-range2,pos.x+range2,pos.y+range2)))
    --print(result)
    return result 
end 

RegisterNetEvent('Arrival:AddPositions')
AddEventHandler('Arrival:AddPositions', function(datas,rangeorcb,_cb) --
    Arrival.Register(datas,rangeorcb,_cb)
end)
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