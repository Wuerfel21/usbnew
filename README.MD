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

**TODO more**


