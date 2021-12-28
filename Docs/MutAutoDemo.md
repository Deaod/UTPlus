# MutAutoDemo
This mutator starts recording demos automatically when a match starts. Skips warmup if possible. Server can also force clients to record demos. Can be used to automatically record server-side demos.

## Client Settings
These settings can be found in AutoDemo.ini in your System folder.

```ini
[Settings]
bEnable=False
DemoMask="%l_[%y_%m_%d_%t]_[%c]_%e"
DemoPath=
DemoChar=
```

### bEnable
**Type: bool**  

If `True`, automatically record demos on game start. If `False`, do nothing unless forced by server to record. If

### DemoMask
**Type: string**  

Template for the name of automatically recorded demos.  
The following (case-insensitive) placeholders will be replaced with match-specific details:

- `%E` ➜ Name of the map file
- `%F` ➜ Title of the map
- `%D` ➜ Day (two digits)
- `%M` ➜ Month (two digits)
- `%Y` ➜ Year
- `%H` ➜ Hour
- `%N` ➜ Minute
- `%T` ➜ Combined Hour and Minute (two digits each)
- `%C` ➜ Clan Tags (detected by determining common prefix of all players on a team, or "Unknown")
- `%L` ➜ Name of the recording player
- `%%` ➜ Replaced with a single %

### DemoPath
**Type: string**  

Prefix for the name of automatically started demos.

### DemoChar
**Type: string**  

Characters filesystems can not handle are replaced with this.

## Server Settings
These settings can be found in AutoDemo.ini in your System folder.

```ini
[UTPlus.MutAutoDemo]
bForceRecord=False
```

### bForceRecord
**Type: bool**  

If `True`, forces all players to record client-side demos. If `False`, does nothing.

## Installation and Use

1. Add UTPlus to ServerPackages
2. Add `UTPlus.MutAutoDemo` to list of enabled mutators
