# usbnew - modular P2 USB Input driver

This is a USB Host driver for Parallax Propeller 2 focused on HID input devices. It extensively utilizes constant overrides and conditional assembly to reduce binary bloat to a minimum.

** Warning: Documentation under construction**

## Known errata

 - Currently usbnew only compiles with recent version of flexspin.
 - Some hubs don't correctly work with low-speed devices
 - Some devices (mostly wireless receiver dongles) expose both a keyboard and a mouse interface, which will take up the single device slots in usbnew even if only a mouse/keyboard is actually connected.
 - The scroll wheel on many mice currently can't be read.
 - For detailed compatibility info, see [the wiki](https://github.com/Wuerfel21/usbnew)

## Configurable options

These options should be set using the Spin2 constant override syntax:

|||
|-|-|
|`USB_BASEPIN`|Base pin of the USB port to use. Only one port is used.|
|`USB_ENABLE_OFFSET`|Offset of the port protection enable pin from the basepin. May be -1 if no port protection chip is used|
|`USB_DMINUS_OFFSET`|Offset of the D- pin from the basepin. D+ is always the pin immediately after D-. D- must also be even-numbered.|
|`NUMLOCK_DEFAULT_STATE`|Default state of NumLock|
|`ACTIVITY_LED`|Pin for activity LED (-1 to disable)|
|`ERROR_LED`|Pin for error LED (-1 to disable)|
|`KEYQUEUE_SIZE`|Size of the keyboard queue. 0 disables the interface|
|`HAVE_MOUSE`|Mouse interface enable flag|
|`HAVE_HIDPAD`|HIDPad interface enable flag|
|`EMUPAD_MAX_PLAYER`|EmuPad player count. 0 disables the interface.|
|`EMUPAD_MAX_RULES`|Size of the EmuPad mapping rule buffer. Only relevant when EmuPad is enabled.|
|`EMUPAD_BUILTIN_RULES`|Load builtin rules (see below)|
|`OVERLAP_MEMORY`|If true, overlaps temporary buffers with code only needed on startup. Reduces memory usage at expense of not being able to restart usbnew.|
|`CLKFREQ_PTR`|Where CLKFREQ lives (don't change if you don't know what you're doing)|

## Startup methods

|||
|-|-|
|`start() : r`|Start driver cog with current configuration|
|`stop()`|Stop driver cog|
|`current_cog()`|Get current driver cog or -1 if not running|
|`set_basepin(pin)`|Runtime override for `USB_BASEPIN`. Must be called before `start()`|
|`set_pins_explicit(enable,dminus)`|Finer-grained runtime override for USB pins. Must be called before `start()`|

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

The mouse interface provides access to a mouse. It is enabled by setting `HAVE_MOUSE`.

|||
|-|-|
|`mouse_xy() : x,y`|Get mouse coordinates|
|`mouse_scroll() : x,y`|Get mouse scroll position|
|`mouse_move(x,y)`|Emulate mouse movement|
|`mouse_buttons() : r`|Get mouse buttons state|
|`mouse_set_limits(xlim,ylim)`|Set limits for mouse movement|
|`mouse_set_outptr(ptr)`|Set pointer for "hardware" sprite control (see below)|

When mouse limits are set, the X/Y coordinates are constrained between 0 and the configured limit. If the limits are zero (the default), the mouse coordinates accumulate freely.

The `mouse_set_outptr` function is provided to allow updating the position of a mouse cursor sprite provided by a video driver independently of your main loop. When a non-zero pointer is set, the lower 16 bits of the X and Y position are written to it whenever they update. You should set the mouse limits appropriately to your screen resolution when using this.

## HIDPad interface

The HIDPad interface provides access to game controllers (contrary to the name, not just HID-class, but also Xbox360-style XInput). The HIDPad interface is enabled by setting `HAVE_HIDPAD`.

**Warning: Do not pass a `dev` value greater or equal to `MAX_DEVICES` into any hidpad function!**

|||
|-|-|
|`hidpad_id(dev) : r`|Get VID/PID pair for connected device. 0 means disconnected|
|`hidpad_getcaps(dev) : r`|Get device capabilites. These are often false-positive. (see below)|
|`hidpad_buttons(dev) : r `|Get all button states for a device|
|`hidpad_button(dev,bnum) : r`|Get state of one button|
|`hidpad_axis(dev,axnum) : r`|Get state of an axis (normalized between -32768 and 32767)|
|`hidpad_hat(dev,hatnum) : r`|Get state of a hat|

The format for `hidpad_getcaps`:
```
xxxxxxxx_xxrrrzyx_hhhhaaaa_bbbbbbbb
           zyx||| |||||||| ++++++++ n. buttons
           |||||| ||||++++--------- n. axes
           |||||| ++++------------- n. hats
           ++++++------------------ valid axes
```

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

The details of the report format can be configured through a set of constants: The `EMUPAD_xxx_BIT` ones specify the bit (0..31) in the report long to which the direction or button is to be mapped. The directions are required, but the buttons can be set to -1 to disable them from the report format entirerly. `EMUPAD_TYPE_NIBBLE` specifies the nibble in the report long that contains the device type. Currently the only possible values for this are `EMUPAD_TYPE_KBD` if _only_ a keyboard is connected, `EMUPAD_TYPE_PAD` if a gamepad is conncected and zero if nothing is connected. (The gamepad's type always overrides the keyboard's type). This mechanism is intended to be hacked for custom behaviour (MegaYume sets it based on whether the controller has enough buttons mapped to emulate a 6-button controller).

### Gamepad mapping

Since gamepads in general don't agree on which logical button corrosponds to which physical button, there needs to be an ability to load user-defined per-device mappings. EmuPad and the `padmap_parser.spin2` provided in this repo make it easy to implement [the PADMAP.TXT standard](https://github.com/Wuerfel21/usbnew/wiki/PADMAP.TXT-Format-and-the-reference-gamepad):

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

  usb.start()

  repeat
    ' Now do something with the data
    debug(ubin_long(emupad_report))

```

By setting `EMUPAD_BUILTIN_RULES`, precompiled rules from a `padmap_builtin.dat` will be built into the driver. `padmap_builtin.rb` can be used to generate such a file.

