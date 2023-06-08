# usbnew - modular P2 USB Input driver

This is a USB Host driver for Parallax Propeller 2 focused on HID input devices. It extensively utilizes constant overrides and conditional assembly to reduce binary bloat to a minimum.

** Warning: Documentation under construction**

## Known errata

 - Currently usbnew only compiles with recent version of flexspin.
 - Some hubs don't correctly work with low-speed devices
 - Some devices (mostly wireless receiver dongles) expose both a keyboard and a mouse interface, which will take up the single device slots in usbnew even if only a mouse/keyboard is actually connected.
 - The scroll wheel on many mice currently can't be read.
 - For detailed compatibility info, see [the wiki](https://github.com/Wuerfel21/usbnew)

## General options

These options should be set using the Spin2 constant override syntax:

|||
|-|-|
|`OVERLAP_MEMORY`|If true, overlaps temporary buffers with code only needed on startup. Reduces memory usage at expense of not being able to restart usbnew.|
|`NUMLOCK_DEFAULT_STATE`|Default state of numlock|

**TODO**



## Keyboard state interface

The Keyboard state interface lets you check the current state of any key on the connected keyboard, as well as the state of the modifier LEDs. The state interface is always enabled.

|||
|-|-|
|`keystate(key) : r`|Get current pressed state of a keyboard key|
|`ledstates() : r`|Get current state of the keyboard LEDs|

## Keyboard queue interface

The Keyboard queue interface provides ordered keyboard events.
The queue interface is enabled by setting a value to `KEYQUEUE_SIZE` (recommended: 32).

|||
|-|-|
|`get_key() : r`|Return key event from buffer if there is one|
|`peek_key() : r`|Peek top of key event buffer (returns 0 if no pending event)|

Key events are 32-bit values composed as such:
```
bit     31 = 0 pressed, 1 released
    30..17 = unused
        18 = scroll-lock state 
        17 = caps-lock state
        16 = num-lock state 
     15..8 = key modifiers state
      7..0 = scancode
```

Scancodes are standard USB scancodes (usbnew defines KEY_\* constants for them). They notably are _not_ ASCII characters.

## Mouse interface

**TODO**

## HIDPad interface

The HIDpad interface

## EmuPad interface

The EmuPad interface provides an ultra-low-overhead interface for simple game inputs (digital directions + 10 buttons).

In particular, the driver handles:
 - Mapping of devices to player slots
 - Combining keyboard and gamepad inputs
 - Analog axis to to digital conversion
 - Applying per-device controller maps
 - Canceling conflicting direction inputs
 - Placing reports in a given buffer

The EmuPad interface is enabled by setting `EMUPAD_MAX_PLAYER` to the number

|||
|-|-|
|`set_emupad_ptr(ptr)`|Set the location to which emupad reports will be written. Must be called before starting the driver.|
|`get_emupad_rule_buffer() : r`|Get the buffer into which gamepad mapping rules can be loaded. Should be done before starting the driver.|

When active, the EMUPAD_MAX_PLAYER longs at the configured pointer are updated in real-time with input data.

Connected game controllers will be mapped to player slots based on the port number they are connected to. The keyboard always controls player 1, possibly at the same time as the first game controller. For example, if there is a gamepad on port 1, a keyboard on port 2 and another gamepad on port 4, the first gamepad and the keyboard will both control player 1 and the second controller will control player 2. If there are more than EMUPAD_MAX_PLAYER controllers connected, the extraneous ones are ignored.

The details of the report format can be configured through a set of constants (**TODO document**)

### Gamepad mapping

Since gamepads in general don't agree on which logical button corrosponds to which physical button, there needs to be an ability to load user-defined per-device mappings. EmuPad makes it easy to implement [the PADMAP.TXT standard](https://github.com/Wuerfel21/usbnew/wiki/PADMAP.TXT-Format-and-the-reference-gamepad):

```spin
'' This example uses flexspin's libc for file access
_CLKFREQ = 200_000_000
OBJ
  usb: "usbnew" | EMUPAD_MAX_PLAYER = 1
  padmap: "padmap_parser"
  c: "libc"
VAR
  long emupad_report
PUB main() | f
  usb.set_emupad_ptr(@emupad_data)
  _mount(@"/sd",c._vfs_open_sdcard())
  f := c.fopen(@"/sd/PADMAP.TXT",@"r")
  if f
    padmap.parse(usb.get_emupad_rule_buffer(),usb.EMUPAD_MAX_RULES,@c.fgetc,f,@"yourappname")
    c.fclose(f)
  else
    debug("Couldn't load PADMAP")

  repeat
    ' Now do something with the data
    debug(ubin_long(emupad_report))

```

