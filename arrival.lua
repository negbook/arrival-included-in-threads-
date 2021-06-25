this = {}
this.scriptName = "arrival"

if GetCurrentResourceName() ~= this.scriptName then 
Arrival = {}
end 


Arrival.Register = function(datas,rangeorcb,_cb)
    exports.arrival:Register(datas,rangeorcb,_cb)
end 

