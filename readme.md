# flyx_vehiclesharing
## Information
The VehicleSharing script allows players to share ownership of their vehicles with other players. It introduces a co-owner system, where the vehicle owner can add or remove co-owners, giving them access to use the vehicle as if it were their own. 

If you encounter any bugs/issues, please create an issue or dm me on Discord - 3flyx

**Feel free to create pull requests!**

## Dependencies
- [ox_lib](https://github.com/communityox/ox_lib/releases)
- [es_extended](https://github.com/esx-framework/esx_core)
- [oxmysql](https://github.com/communityox/oxmysql/releases)

## PIOTREQ DOJMDT INTEGRATION
For Piotreq's DOJ MDT users:
- Go into ``p_dojmdt/server/bridge/yourframework.lua`` -> Find function ``getVehicleDetails`` and replace part with ``data.info`` with this:
```lua
data.info = {
    {label = locale('plate'), value = plate},
    {label = locale('owner'), citizen = true, value = result and Bridge.getOfflineName(result.owner) or locale('no_data')},
    {label = locale('co_owner'), citizen = true, value = result and Bridge.getOfflineName(result.co_owner) or locale('no_data')},
    {label = locale('vin'), value = result and result.vin or locale('no_data')},
    {label = locale('wanted'), type = 'badge', color = data.wanted and 'red' or 'green', value = data.wanted and locale('yes') or locale('no')},
}
```

## TODO List
- Add p_bridge compatibility **OR** add bridge files for QBOX & QB
- Add confirmation prompt for removing co-owner