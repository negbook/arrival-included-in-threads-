Arrival = {}
Arrival.zonedata_full = {}
Arrival.currentzonedata = {}
Arrival.currentfocusdata = FlowDetector.Create('currentfocusdata',{})

Arrival.ped = nil
Arrival.pedcoords = FlowDetector.Create('coords',vector3(0.0,0.0,0.0)) 
Arrival.nearzones = FlowDetector.Create('zones',{})
Arrival.inzone = FlowDetector.Create('inzone',false)
Arrival.currentarrivaldata_enter  = FlowDetector.Create('currentarrivaldata_enter',{})
Arrival.currentarrivaldata_exit  = FlowDetector.Create('currentarrivaldata_exit',{})

FlowDetector.Register("currentarrivaldata_enter",'change',function(name,old,new,isLinked)
    if #new>0 then 
        for i=1,#(new) do 
            local v = new[i]
            if v.arrival then v.arrival(v,'enter') end 
        end 
    end 
end )
FlowDetector.Register("currentarrivaldata_exit",'change',function(name,old,new,isLinked)
    if #new>0 then 
        for i=1,#(new) do 
            local v = new[i]
            if v.arrival  then v.arrival(v,'exit') end 
        end 
    end 
end )
FlowDetector.Link('coords','currentfocusdata')
FlowDetector.Register("currentfocusdata",'change',function(name,old,new,isLinked)
    
    if Arrival.currentfocusdata and #Arrival.currentfocusdata > 0 then 
        Threads.CreateLoopOnceCustom('currentfocusdata',0,function(delay)
            local k = 1000
            local cal = {1000}
            local arrivaldataEnter = {} 
            local arrivaldataExit = {} 
            
            for i=1,#Arrival.currentfocusdata do 
                local v = Arrival.currentfocusdata[i]
                local distance = v.distance
                if distance < v.range then
                    v.enter = true 
                    table.insert(arrivaldataEnter,v)
                    if v.exit~=nil and v.exit == true then 
                        v.exit = false 
                    end 
                    table.insert(cal,distance)
                else 
                    if v.enter~=nil and v.enter == true then 
                        v.enter = false 
                        v.exit = true
                        table.insert(arrivaldataExit,v)
                    end 
                    
                end 
                
            end 
            Arrival.currentarrivaldata_enter = FlowDetector.Check('currentarrivaldata_enter',arrivaldataEnter)
            Arrival.currentarrivaldata_exit = FlowDetector.Check('currentarrivaldata_exit',arrivaldataExit)
            local k = 332 + math.min(table.unpack(cal))*20
            local waittime = k > 1000 and 1000 or k
            delay.setter(waittime)
        end,"freshfocus")
        Threads.SetLoopCustom("freshcurrentzone",0)
        Threads.SetLoopCustom("freshfocus",0)
        
    end 
    
end )
FlowDetector.Register("inzone",'change',function(name,old,new,isLinked)
    if new == false then 
        Arrival.currentzonedata = {}
        Threads.KillLoopCustom('checkcurrentzonedatadistance',1000)
        Arrival.currentfocusdata = FlowDetector.Check('currentfocusdata',{})
    else 
        Arrival.currentzonedata = Arrival.zonedata_full[new]
        if Arrival.currentzonedata and #Arrival.currentzonedata > 0 then 
        Threads.CreateLoopOnceCustom('checkcurrentzonedatadistance',0,function(delay)
            local k = 1000
            local cal = {1000}
            local arrivalfocusdata = {}
            
            for i=1,#Arrival.currentzonedata do 
                local v = Arrival.currentzonedata[i]
                local pos = vector3(v.x,v.y,v.z)
                local distance = #(pos-Arrival.pedcoords)
                if distance < 50.0 then 
                    v.distance = distance
                    table.insert(arrivalfocusdata,v)
                    table.insert(cal,distance)
                end 
                
            end 
            
            Arrival.currentfocusdata = FlowDetector.Check('currentfocusdata',arrivalfocusdata)
            local k = 660 + math.min(table.unpack(cal))*80
            local waittime = k > 5000 and 5000 or k
            
            delay.setter(waittime)
        end,"freshcurrentzone")
    end 
    end 
end )

FlowDetector.Register("zones",'change',function(name,old,new,isLinked)
    local zone = GetNameOfZone(Arrival.pedcoords)
    Arrival.inzone =  FlowDetector.Check('inzone',Arrival.zonedata_full[zone] and zone or false)
        --print(isLinked,name,old,new,json.encode(new))
end )
FlowDetector.Register("coords",'change',function(name,old,new,isLinked)
    Arrival.nearzones =  FlowDetector.Check("zones", Arrival.getnearzones())
end )

local GetHashMethod = function(...)
    local pack = {...}
    result = GetNameOfZone(table.unpack(pack)) -- .. (id and tostring(id) or '')
   
    return result 
end 


Arrival.Register = function (datas,rangeorcb,_cb)
    local fntotable = function(fn) return setmetatable({},{__index=function(t,k) return 'isme' end ,__call=function(t,...) return fn(...) end })  end 
    local cooked_cb = function(sdata,action)
        local name = tostring(sdata)
        local result = {data=sdata,data_source=datas[sdata.index],killer=setmetatable({},{__call = function(t,data) if Threads.IsLoopAlive(name) then Threads.KillActionOfLoop(name) end  end}),spamer=setmetatable({},{__call = function(t,data) Threads.CreateLoopOnce(name,0,data) end}),action=action}
        return _cb(result) 
    end 
    local range,cb = 1.0,cooked_cb
    if rangeorcb and type(rangeorcb)=='number' then 
        range = rangeorcb 
    else 
        cb = rangeorcb 
    end 
    local data = Arrival.ConvertData(datas)  -- to .x .y .z .index 
    local zonelist,zonedata = Arrival.CollectZoneData(data)
    for i,v in pairs (zonedata) do 
        local zone = v.zone
        v.arrival = fntotable(cb)
        v.range = range
        if not Arrival.zonedata_full[zone] then Arrival.zonedata_full[zone]={} end 
        table.insert(Arrival.zonedata_full[zone],v)
    end 
    Threads.CreateThreadOnce(function()
        local zone = GetNameOfZone(Arrival.pedcoords)
        Arrival.inzone =  FlowDetector.Check('inzone',Arrival.zonedata_full[zone] and zone or false)
        Arrival.currentzonedata = Arrival.zonedata_full[zone]
    end)
    
end 
CreateThread(function()

    Arrival.ped = PlayerPedId()
    Arrival.pedcoords = FlowDetector.Check('coords',GetEntityCoords(Arrival.ped)) 
    Arrival.nearzones =  FlowDetector.Check('zones',Arrival.getnearzones())
    
    Threads.CreateLoopCustom('inits',500,function(delay)
        Arrival.ped = PlayerPedId()
        Arrival.pedcoords = FlowDetector.Check("coords", GetEntityCoords(Arrival.ped))
        local k = math.random(332,664)
        delay.setter(k)
    end)
    
    
    
end)

Arrival.getnearzones = function()
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
    local pos = Arrival.pedcoords
    local temp_y = 0.0
    while included(GetHashMethod(pos)) do 
        pos = GetObjectOffsetFromCoords(pos,0.0, 0.0, temp_y ,0.0)
        temp_y = temp_y + 8.0
    end 
    nearzones[1] = GetHashMethod(pos)
    local pos = Arrival.pedcoords
    local temp_x = 0.0
    while included(GetHashMethod(pos)) do 
        pos = GetObjectOffsetFromCoords(pos.x,pos.y,pos.z,0.0, temp_x, 0.0 ,0.0)
        temp_x = temp_x + 8.0
    end 
    nearzones[2] = GetHashMethod(pos)
    local pos = Arrival.pedcoords
    local temp_y = 0.0
    while included(GetHashMethod(pos)) do 
        pos = GetObjectOffsetFromCoords(pos,0.0, 0.0, temp_y ,0.0)
        temp_y = temp_y - 8.0
    end 
    nearzones[3] = GetHashMethod(pos)
    local pos = Arrival.pedcoords
    local temp_x = 0.0
    while included(GetHashMethod(pos)) do 
        pos = GetObjectOffsetFromCoords(pos,0.0, temp_x, 0.0 ,0.0)
        temp_x = temp_x - 8.0
    end 
    nearzones[4] = GetHashMethod(pos)
    return nearzones
end 
Arrival.CollectZoneData = function(datatable) --vector3 or {x=1.0,y=2.0,z=3.0}
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
        
        local zone = GetHashMethod(v.x,v.y,v.z)
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