This is just a small collection of some random stuff I've been using to figure things out.

Displays Coordinates, Heading (including compass directions) and Time in the bottom left.

## Commands

`golden` will set your outer bars to overpowered

`weather` can be used to quickly change the weather

`weapon` can be used to give yourself a weapon with ammo

`spawn` can be used to spawn a ped

`swap` can be used to quick swap models in a radius around player. Model is only swapped for a few seconds but is helpful for finding possible model names.

`model_search` can be used to find valid models quickly when they are numbered. It tests a few known numbering systems as a suffix to the input value.

`native` can be used to run native commands fairly easily from in game.

So if you wanted to give yourself a Pump Shotgun with the native command you can run:  
ex. `native 0xB282DC6EBD803C75 PLAYER_ID HASH_WEAPON_SHOTGUN_PUMP 500 true 0`  
This will automatically look up hashes if the string starts with `HASH_`. `PLAYER_ID` will be replaced using GetPlayerPed()

![Native Command](_screenshots/native-command.png)

Lastly this can either display info of surrounding entities or track them as you come into contact with them based on the Config setting, tracking by default.

`clear_tracking` can be used to clear all currently tracked IDs.

You can disable tracking on specific things near the map. Use `]`, right bracket, to allow clicking to toggle the options. Use `Esc` to close focus.

![Entity Info](_screenshots/entity-info.png)
![Entity Info 2](_screenshots/entity-info-2.png)