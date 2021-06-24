# fxserver-arrival
Arrival utilities for FXServer


[DEPENDENCIES]
[Threads](https://forum.cfx.re/t/lib-threads-good-for-loops/2089076)



[INSTALLATION] 

Set it as a dependency in you fxmanifest.lua
make sure fx_version up to 'adamant' version

(optional)
``` 
client_scripts {
'@threads/threads.lua',
'@arrival/arrival.lua',
...
```

(must)
``` 
dependencies {
    'threads',
    'arrival'
}
```

[FUNCTION EXPORTS/EVENT]
```
Arrival.Register(positions,range,cb(result)) --result.data result.data_source result.action (with optional)
exports.arrival:Register(positions,range,cb(result)) --result.data result.data_source result.action (with dependencies)
TriggerEvent('Arrival:AddPositions',positions,range,cb(result) --result.data result.data_source result.action (with dependencies)

result.action ==> 'enter','exit'

```

[EXAMPLE]

```

```

