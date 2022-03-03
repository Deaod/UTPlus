# MutIGEnhanced

## Client Settings
These settings can be found in IGEnhanced.ini in your System folder

```ini
[Settings]
BeamOriginMode=BAM_Precise
BeamDestinationMode=BAM_Precise
BeamType=BT_Default
bBeamHideOwn=False
bBeamClientSide=False
BeamScale=0.450000
BeamDuration=0.750000
BeamFadeCurve=4.000000
ExplosionType=ET_Default
```

### BeamOriginMode
**Type: EBeamAttachMode**  

Influences the way the origin location of shots is determined.

#### BAM_Precise
Shots always originate from where the server determined the shot was fired.

#### BAM_Attached
Shots originate from a location that is calculated using a given offset from the shooter and the location of the shooter on the client. This is useful if it's jarring to you to see shots originating from somewhere that is not really close to the shooter.

### BeamDestinationMode
**Type: EBeamAttachMode**  

Influences the way the destination of shots is determined.

#### BAM_Precise
Shots always end exactly where the server determined they did.

#### BAM_Attached
Shots that hit players will end at a given offset from the target. 

### BeamType
**Type: EBeamType**  

The style of beams.

#### BT_None
No beams.

#### BT_Default
Default UT99 Instagib beams. Ignores settings BeamScale, BeamDuration, BeamFadeCurve.

#### BT_TeamColored
Team colored beams (red for red team, blue for blue team). 

#### BT_Instant
Team colored beams that dont look like a projectile, but instantly connect with the destination.

### bBeamHideOwn
**Type: bool**  

If `True`, hides beams of your own shots, regardless of the values of BeamType. If `False`, apply BeamType to your own shots as well.

### bBeamClientSide
**Type: bool**  

If `True`, play effects of shots immediately on your client. Useful if ping compensation is enabled.

If `False`, server controls when effects are played. Potentially distracting if ping compensation is enabled.

### BeamScale
**Type: float**  

Size of the beam.

### BeamDuration
**Type: float**  

How long a beams visual effects last

### BeamFadeCurve
**Type: float**  

The brightness of beam effects fades over time. This setting controls the curve with which the brightness fades. Higher values than 1 mean the brightness decays quickly, but then takes a long time to fully disappear. Values between 0 and 1 mean the effects stay bright for a long time, then quickly disappear near the end of the duration. 0 or lower is invalid.

Let `c` be equal to BeamFadeCurve.  
Let `x` be equal to the percentage of remaining duration.  
Brightness function `f(x) = x^c`

### ExplosionType
**Type: EExplosionType**  

The kind of effect that is shown at the destination of a beam.

#### ET_None
Nothing except a scorch mark is shown.

#### ET_Default
A red explosion is shown.

#### ET_TeamColored
An explosion with the color of the shooter's team is shown.
