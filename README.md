# fxserver-arrival
Arrival utilities for FXServer


[DEPENDENCIES]
[Threads](https://forum.cfx.re/t/lib-threads-good-for-loops/2089076)



[INSTALLATION] 

Set it as a dependency in you fxmanifest.lua
make sure fx_version up to 'adamant' version

```
dependencies {
	'threads',
    'arrival'
}
```

[FUNCTION EXPORTS/EVENT]
```
exports.arrival:Register(positions,range,cb(result)) --result.data result.data_source result.action 

TriggerEvent('Arrival:AddPositions',positions,range,cb(result) --result.data result.data_source result.action 

```

[EXAMPLE]

```

```

