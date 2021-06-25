RegisterNetEvent('Arrival:AddPositions')
RegisterNetEvent('Arrival:getSharedObject')
AddEventHandler('Arrival:AddPositions', function(datas,rangeorcb,_cb) 
    Arrival.Register(datas,rangeorcb,_cb)
end)

AddEventHandler('Arrival:getSharedObject', function(cb) 
    cb(Arrival)
end)