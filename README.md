# Vityamod

Vityamod is a mod for WEBFISHING inspired by [Mega Hack by Absolute](https://youtu.be/_fgQr0SSIys). It provides neat, fun and useful features that does not involve anything exploitive or potentially harmful for other players.
The goal of this mod is to deliver a mod menu that provides help on stuff you can't do in the unmodded WEBFISHING client, while keeping it safe from potentially harming the game experience. <br><br>

<p align="center">
  <img src="https://github.com/danyairwing/webfishing-vityamod/blob/main/previews/20250525161538_1.jpg?raw=true" />
</p>

# Installation 
0. Install [GDWeave](https://github.com/NotNite/GDWeave) and [BlueberryWolfi's APIs](https://github.com/BlueberryWolf/APIs)
1. Install the latest Vityamod version in the releases (NOT the code button)
2. Extract the zip file in GDWeave mod folder (WEBFISHING/GDWeave/Mods/) <br>
Vityamod is also available on Thunderstore.
# Current Features
* Rejoin lobby on crash (you still have to relaunch the game)
* RP + Trolling features such as "skamtebord", "catbark", "copy outfit", "player size", "spinbot" and "ballspin"
* Greet and goodbye messages, rainclouds
* Teleport + spectate other players
* Enable lighting for campfires
* And other.

# FAQ
Q: Can this be specified as hacking menu? <br>
A: The goal of Vityamod is to provide handy, customizable and fun features. Vityamod is not going to contain features that break the game. <s>(although its possible to break the game in the nastiest ways possible)</s> <br>
Q: Is forking an option? <br>
A: If you want to create a similiar but different menu - sure. Just be aware that it is possible to create an "extention" that loads its own classes into Vityamod, in that case forking is unnessesary and could cause problems with updates, etc. <br>
If you have issues with the mod, bugs, errors, anything - contact me through my discord server - https://discord.com/FmZ98UQW2v.

# Development
You can either use the classes outside the Vityamod container in your own mod, or make your own class. Example:
```gdscript

var vitya = get_node_or_null("/root/danyairwingvityamod")

# loading your own extention
var my_cool_class = load("res://mods/mymod/whatever/hello_development.gd")

vitya.load_class("the extention class i've made B)", my_cool_class)

# using loaded classes (CURRENTLY - supported quite terribly, UI does not update depending on calls. Not recommended)

print(vitya.classes.keys())
> ["utils","players","gameplay","hud","world","server"]
vitya.classes.hud.open_discord() # will open my discord!
vitya.utils.join(923990) # will join a lobby... depending on steamID of the lobby
vitya.utils.rejoin() # will rejoin the current lobby

```
A reference about creating your custom classes is explained in detail in example.gd class.
