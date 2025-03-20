# P3rd ML Mod Manager

A (still early in development) mod manager for [mhp3reload](https://github.com/Kurogami2134/mhp3reload).

## Installing Mods

Copy any number of mod folders into `MODS` and the mod manager should detect them.

The mod manager will allow you to enable and disable any number of code mods. And enable any number of file replacement mods. As of this version, disabling file replacement mods can only be handled by deleting all of the contents from `ms0:/P3rdML/files/`, the mod manager can do this, and reinstall any and all still enabled mods.

## Mod Format

Mods are stored as folders, containing a `mod.ini` file, and any other relevant mod files.

The mod manager currently supports three types of mods.

* At least one example of each type of mod is included in the release.

### Code Mods

Code mods must specify a file to be installed as a mod.

    [MOD INFO]
    Name="MOD NAME"
    Files="FILE"
    Type="Code"

Code mods may also reference multiple files to be enabled as a single mod.

    [MOD INFO]
    Name="MOD NAME"
    Files="FILE1;FILE2;FILE3"
    Type="Code"

### Specific File Replacement

File replacement mods must reference a series of at least one file, and the same number of target ids indicating the files to replace.

    [MOD INFO]
    Name="MOD NAME"
    Files="NEWFILE"
    Target="FILEID"
    Type="File"

Another example, replacing multiple files.

    [MOD INFO]
    Name="MOD NAME"
    Files="NEWFILE;NEWFILE2"
    Target="FILEID;FILEID2"
    Type="File"

### Equipment Replacement

Equipment replacement mods must reference a single file, and do not use a target id. When enabling the mod, the user will choose which equipment piece to replace.

* Models may be used by more than a single piece, in such cases, only the name of the first one in order of game id will be shown.

Equipment mods instead, must append the equipment type to the mod type.

    [MOD INFO]
    Name="MOD NAME"
    Files="NEWFILE"
    Type="EquipTYPE"

Possible equip types are:

|Key|Equipment Type|
|-|-|
|GS|Great Sword|
|LS|Long Sword|
|SNS|Sword and Shield|
|DB|Dual Blades|
|LNC|Lance|
|GL|Gun Lance|
|HMR|Hammer|
|HH|Hunting Horn|
|LBG|Light Bowgun|
|HBG|Heavy Bowgun|
|BOW|Bow|
|SAXE|Switch Axe|
|HEAD|Head armor|
|ARMS|Arm armor|
|BODY|Body/Chest armor|
|WAIST|Waist armor|
|LEGS|Leg armor|
