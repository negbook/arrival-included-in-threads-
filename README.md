# fxserver-arrival(Included into [Threads](https://github.com/negbook/arrival))
Arrival utilities for FXServer(Included into [Threads](https://github.com/negbook/arrival))


[DEPENDENCIES]
[Threads](https://github.com/negbook/arrival)



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
Arrival.Register(positions,range,cb(result)) --result.data result.action result.data_arrival  (with optional)
exports.arrival:Register(positions,range,cb(result)) --result.data result.action result.data_arrival  (with dependencies)
TriggerEvent('Arrival:AddPositions',positions,range,cb(result) --result.data result.action result.data_arrival  (with dependencies)

result.action ==> 'enter' / 'exit'

```

[EXAMPLE]

```

```

