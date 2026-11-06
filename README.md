# Kamilsemm-vhud

`Kamilsemm-vhud` is a QBCore, ESX and Qbox compatible HUD resource for FiveM. It combines the player
status HUD, vehicle HUD, circular minimap, compass, location information and a
custom waypoint distance indicator in one resource.

## Features

- Health and armour bars
- Hunger and thirst indicators using QBCore metadata updates
- Running-only stamina indicator and underwater oxygen indicator
- PMA Voice proximity, talking and radio state support
- Weapon, ammunition and optional custom crosshair display
- Vehicle speed, gear, fuel, engine condition and light indicators
- Seatbelt and racing harness status from `qb-smallresources`
- Vehicle lock status compatible with `qb-vehiclekeys`
- Circular minimap with a smooth compass, heading, zone and street name
- Custom waypoint direction and distance display in miles
- Safezone calibration warning
- Cinematic mode command

## Requirements

### Framework

Choose one framework in `config.lua`:

```lua
Config.Framework = 'qbcore' -- 'qbcore', 'esx' or 'qbox'
```

- `qbcore` uses `qb-core` metadata and `qb-smallresources` by default.
- `esx` uses `es_extended` with `esx_status` for hunger and thirst.
- `qbox` uses `qbx_core` metadata.

Framework and optional seatbelt resource names can be changed through
`Config.FrameworkResources` and `Config.SeatbeltResources`.

### Recommended integrations

- `pma-voice` for proximity, voice activity and radio activity
- `qb-vehiclekeys` for vehicle locking and unlocking
- A fuel resource that updates GTA's native vehicle fuel level

`qb-smallresources` is declared as a resource dependency, so it must be installed
under that exact resource name. `qb-vehiclekeys` is not a hard dependency because
the HUD reads the vehicle's native lock state and does not call or modify any
vehicle-key exports.

## Installation

1. Copy the folder into your server resources directory and keep its name as
   `Kamilsemm-vhud`.
2. Make sure all required resources are installed.
3. Start dependencies before the HUD in `server.cfg`:

   ```cfg
   ensure qb-core
   ensure qb-smallresources
   ensure qb-vehiclekeys
   ensure pma-voice
   ensure Kamilsemm-vhud
   ```

   `qb-vehiclekeys` and `pma-voice` may be omitted if your server does not use
   those integrations.
4. Disable any other HUD or minimap resource that draws the same elements to
   prevent duplicate UI.
5. Restart the server, or restart the resources in dependency order:

   ```text
   restart qb-smallresources
   restart Kamilsemm-vhud
   ```
6. In GTA display settings, set **Safezone Size** all the way to the right. The
   HUD displays an English calibration warning when the value is below the
   configured requirement.

## Configuration

All supported settings are located in `config.lua`. Every setting listed there is
read by the client code.

### Commands

```lua
Config.Commands = {
    cinematic = 'cinematic'
}
```

`/cinematic` toggles cinematic mode and hides the regular HUD while the cinematic
bars are active. The same behavior is also available through the
`hud:client:ToggleCinematic` client event.

### Update intervals

```lua
Config.Intervals = {
    player = 200,
    vehicle = 50,
    vehicleIdle = 250,
    compassHeading = 25,
    compassDetails = 250,
    minimap = 1000
}
```

All interval values are milliseconds:

- `player`: player status sampling interval.
- `vehicle`: active vehicle sampling interval.
- `vehicleIdle`: vehicle presence check while the player is on foot.
- `compassHeading`: camera heading target update interval. Browser-side
  interpolation keeps rotation smooth between updates.
- `compassDetails`: street, zone and waypoint information interval.
- `minimap`: resolution and safezone validation interval.

The default values are the recommended optimized values. Reducing them increases
update frequency and client CPU usage. Player and vehicle NUI messages are still
sent only when their values change.

### Speed display

```lua
Config.SpeedMultiplier = 2.236936
Config.SpeedUnit = 'MPH'
Config.MaxSpeed = 160
```

The default setup converts GTA metres per second to MPH. For kilometres per hour:

```lua
Config.SpeedMultiplier = 3.6
Config.SpeedUnit = 'KM/H'
Config.MaxSpeed = 260
```

`Config.MaxSpeed` only controls when the coloured outer speed arc becomes full;
it does not limit the vehicle's actual speed.

### Safezone warning

```lua
Config.ShowSafezoneWarning = true
Config.RequiredSafezone = 0.99
```

Set `ShowSafezoneWarning` to `false` to disable the calibration screen.
`RequiredSafezone` is the minimum GTA safezone value accepted by the HUD.

### Custom crosshair

```lua
Config.UseCustomCrosshair = true
```

Set it to `false` to disable the custom aiming crosshair.

## qb-smallresources seatbelt integration

`qb-smallresources` remains the owner of the complete seatbelt system:

- The default `B` key mapping
- The `/toggleseatbelt` command
- Buckle and unbuckle sounds
- Exit-control blocking while buckled
- Crash and ejection behavior
- Racing harness state and durability

`Kamilsemm-vhud` does not register a second seatbelt command. It listens for
`seatbelt:client:ToggleSeatbelt`, then reads the existing `HasSeatbeltOn()` and
`HasHarness()` client exports from `qb-smallresources`. The resulting state is
displayed by the vehicle HUD.

If the `B` key does not respond after installing or updating the resources, first
restart `qb-smallresources`, then restart `Kamilsemm-vhud`. Also verify the
`toggleseatbelt` binding under FiveM key bindings, because player key mappings can
be stored locally.

## qb-vehiclekeys lock integration

No export or edit is required inside `qb-vehiclekeys`. The standard resource
applies its lock changes to the vehicle entity with GTA's native door-lock state.
`Kamilsemm-vhud` reads that state with `GetVehicleDoorLockStatus()` and
`GetVehicleDoorsLockedForPlayer()` while the player is in the vehicle.

This keeps all key ownership and lock permissions inside `qb-vehiclekeys`, while
the HUD only displays whether the current vehicle is locked. The lock icon updates
through the configured active vehicle interval.

## QBCore needs integration

Hunger and thirst are updated through the standard client event:

```lua
TriggerEvent('hud:client:UpdateNeeds', hunger, thirst)
```

Both values must be numbers from `0` to `100`. Standard QBCore metadata and
`qb-smallresources` consumables already use this event.

## PMA Voice integration

The microphone reads the current PMA Voice proximity state from
`LocalPlayer.state.proximity`. Normal talking is detected through the FiveM voice
native, and radio activity is received from:

```lua
pma-voice:radioActive
```

While the player is talking over the radio, only the microphone icon and its outer
ring use the active red state.

## Troubleshooting

- **Original GTA health/armour bars appear below the minimap:** restart
  `Kamilsemm-vhud`. The resource suppresses those scaleform elements every frame.
- **Seatbelt icon does not change:** restart `qb-smallresources` before
  `Kamilsemm-vhud`, then check the `toggleseatbelt` key binding.
- **Vehicle lock icon does not change:** confirm that your vehicle-key resource
  updates the native vehicle door-lock state. Standard `qb-vehiclekeys` does.
- **HUD elements are misaligned:** set GTA Safezone Size to its maximum value.
- **Duplicate HUD elements appear:** stop the other HUD/minimap resource.

## Resource layout

```text
Kamilsemm-vhud/
|-- client/
|   |-- main.lua
|   |-- player.lua
|   |-- vehicle.lua
|   `-- minimap.lua
|-- stream/
|   `-- circlemap.ytd
|-- web/
|   |-- css/
|   |-- fonts/
|   |-- js/
|   `-- index.html
|-- config.lua
|-- fxmanifest.lua
`-- README.md
```
