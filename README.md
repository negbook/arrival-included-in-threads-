# fxserver-arrival
Arrival utilities for FXServer


[DEPENDENCIES]
[Threads](https://forum.cfx.re/t/lib-threads-good-for-loops/2089076)



[INSTALLATION] 

Set it as a dependency in you fxmanifest.lua
make sure fx_version up to 'adamant' version
``` (optional)
client_script '@arrival/arrival.lua'
```

``` (must)
dependencies {
    'threads',
    'arrival'
}
```

[FUNCTION EXPORTS/EVENT]
```
Arrival.Register(positions,range,cb(result)) --result.data result.data_source result.action 
exports.arrival:Register(positions,range,cb(result)) --result.data result.data_source result.action 
TriggerEvent('Arrival:AddPositions',positions,range,cb(result) --result.data result.data_source result.action 

```

[EXAMPLE]

```

```

