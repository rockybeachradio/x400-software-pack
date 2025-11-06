################################################################################################
# File: at24c_eeprom.py
# Location: ~/klipper/klippy/extras/
# Author: Eryone, Andreas
# Date: 202500602, 20251106
# Purpose: Extension to allow Klipper to controll the at24xx chip which is added by Eryone for PLR (PowerLossRecovery)
################################################################################################
import math

from . import bus

################################################################################################
### How to test ###
#
# Test Commands:
#   M406 D1234   ; write 123.4 mm
#   M408 A0      ; read back
#   M407         ; sync + status
#
# Expected Mainsail output:
#   EEPROM: 1234 → 123.400 mm
#   Saved: 120.5
# 
# Do it again and change M406 command to updated to 123.5


### ToDo ###
#
# Replace: self.gcode.respond_info(...)  -  with: gcmd.respond_info(...)
# self.gcode is the dispatcher. gcmd is created from that dispatcher → gcmd.respond_info just calls the same method.
#
################################################################################################


class at24cxx:  # Constructor of your at24cxx class — the first method that runs when Klipper creates an instance of your EEPROM module.
    ##############################################################
    def __init__(self, config):                         # Called automatically by load_config()
                                                        #   self - The new object being created
                                                        #   config - The [at24c_eeprom] section from printer.cfg
        self.printer = config.get_printer()             # Integration with Klipper (events, objects, config);   config gets the [at24c_eeprom] section from printer.cfg. get_printer() returns the main Printer object
        self.reactor = self.printer.get_reactor()       # Timing & safety (non-blocking delays, startup sync);   get_reactor() returns Klipper’s event scheduler (the "reactor")
        
        # MCU-attached I2C
        address = config.getint('address', 0)
        speed = config.getint('speed', 0)
        self.i2c = bus.MCU_I2C_from_config(config, address, speed)
        
        self.gcode = self.printer.lookup_object('gcode')                            # Retrieve the global G-code dispatcher from Klipper and stores it in self.gcode for later use.

        # Define M commands
        self.gcode.register_command('M406', self.cmd_write)                         # Register a custom G-code command M406o that when Klipper receives M406 in a G-code stream (from slicer, Mainsail, macro, etc.), it automatically calls your method self.cmd_write.
                                                                                    # M406: Writes Z to EEPROM
        self.gcode.register_command('M407', self.cmd_read_write_variable)           # M407: Read + Compare + Sync with save_variables
        self.gcode.register_command('M408', self.cmd_read)                          # Added: M408 is a debug command. The EEPROM can be read manually at any time, without relying on M407 or macros.
                                                                                    #   M406 D=1234 - Write 123.4 mm
                                                                                    #   M408 A=0    - Read address 0 --> should show [210, 4] or 1234
                                                                                    #               Output in Mainsail: addr: 0 , read data: bytearray(b'\xd2\x04')
        
        self.printer.register_event_handler('klippy:ready', self._handle_ready)     # Subscribes the at24cxx class to Klipper’s klippy:ready event, so that _handle_ready() is automatically called when Klipper finishes startup and is fully ready.
        #self.vars = []                                                             # initializes self.vars as an empty list (by eryone)
        self.vars = {}                                                              # initializes self.vars as an empty directory


    ##############################################################
    def _handle_ready(self):
        # Schedule EEPROM sync AFTER reactor is fully ready
        self.reactor.register_callback(self._do_startup_sync)               # Schedules _do_startup_sync() to run in the background as soon as Klipper’s reactor (event loop) is ready to process non-blocking tasks.

    ##############################################################
    def _do_startup_sync(self, eventtime):
        try:
            sv = self.printer.lookup_object('save_variables', None)         # Retrieves the save_variables module (if it exists) and stores it in sv. Don’t crash if it’s missing → return None instead
            if sv:
                self.vars = sv.get_status(eventtime).get('variables', {})   # Extracts the current dictionary of saved variables from the save_variables module and stores it in self.vars.
        except Exception as e:                                              # Catches any unexpected error that occurs in the try block above, and stores the error in the variable e.
            logging.warning(f"at24c_eeprom: save_variables error: {e}")     # Logs a non-critical error to Klipper’s log file (klippy.log) when something goes wrong with save_variables, without crashing the printer.

        try:
            raw = self.read_register(0x00, 2)           # Reads 2 bytes from the AT24Cxx EEPROM at address 0x00 and stores the result in raw.
            eeprom_z = raw[0] | (raw[1] << 8)           # Combines two bytes from the EEPROM (raw[0] and raw[1]) into a single 16-bit integer using bitwise operations.
                                                        #   raw[1] << 8 --> 4 << 8 = 4 * 256 = 1024
                                                        #   raw[0] | 1024 --> 210 | 1024 = 1234
                                                        #   --> eeprom_z = 1234
            eeprom_mm = eeprom_z / 10.0                 # converts the 16-bit integer (eeprom_z) from the EEPROM into millimeters by dividing by 10.0
            if 'power_resume_z' in self.vars:
                saved = self.vars['power_resume_z']                             # Retrieves the Z-height value that was previously saved in variables.cfg via [save_variables].
                if abs(eeprom_mm - saved) > 0.01:                               # Checks if the Z-height from the EEPROM differs significantly from the value stored in variables.cfg.
                    z_str = f"{eeprom_mm:.10f}".rstrip('0').rstrip('.')         # Converts the floating-point Z-height (eeprom_mm) into a clean, human-readable string for saving in variables.cfg.
                    self.gcode.run_script_from_command(
                        f"SAVE_VARIABLE VARIABLE=power_resume_z VALUE={z_str}"
                    )                                                           # Executes a Klipper G-code command from Python to permanently save the cleaned Z-height string (z_str) into variables.cfg using the [save_variables] system.
                                                                                #   self.gcode                      The G-code dispatcher
                                                                                #   .run_script_from_command(...)   Runs a string as if it were G-code
                                                                                #   SAVE_VARIABLE ...               Built-in Klipper command to write to variables.cfg
                                                                                #   VARIABLE=power_resume_z         Key name
                                                                                #   VALUE={z_str                    }Value --> e.g. "123.4"
        except Exception as e:
            logging.exception(f"at24c_eeprom startup sync failed: {e}")

    ##############################################################
    def read_register(self, address, read_len):
        # read a single register
        params = self.i2c.i2c_read([address], read_len)     # Sends an I²C read command to the AT24Cxx EEPROM via the MCU (Skipr) and receives the raw response.
        return bytearray(params['response'])                # Sends this bytearray back to the caller (like cmd_read or startup sync).

    ##############################################################
    def write_register(self, address, data):
        if type(data) is not list:
            data = [data]
        data.insert(0, address)
        self.i2c.i2c_write(data)

        # Schedule 5ms delay in background          # Added: Non-blocking 5ms delay via callback
        self.reactor.register_callback(
            lambda et: None,  # no-op
            self.reactor.monotonic() + 0.005
        )

    ##############################################################
    def cmd_read(self, gcmd):
        address = gcmd.get_int('A', 0)                                               # Added: , 0
        #raw = self.read_register(0x00, 2)
        raw = self.read_register(address, 2)                                         # Replaced line above
        
        gcmd.respond_info(f"addr: {address} , read data: {raw}")
        val = raw[0] | (raw[1] << 8)                                                 # Added for debuging
        gcmd.respond_info(f"EEPROM[0x{address:02X}] = {val} → {val/10.0:.3f} mm")    # Added for debuging

    ##############################################################
    def cmd_write(self, gcmd):
        val = gcmd.get_int('D', minval=0, maxval=65535)                     # Changed variable name from data to val    # Added: "", minval=0, maxval=65535" This prevents wirting nonsense to the eeprom. The EEPROM stores 2 bytes = 16-bit integer = 0 to 65535.
        data = [val & 0xff,(val >> 8) & 0xff]
        self.write_register(0x00, data)
        
        self.gcode.respond_info(f"write data: {data}")
        gcmd.respond_info(f"EEPROM[0x00] <- {val} → {val/10.0:.2f} mm")     # Added for debugging

    ##############################################################
    def cmd_read_write_variable_by_eryone(self, gcmd):     # eryone version
        address = gcmd.get('A')                         # ignored, always reads addr 0
        raw = self.read_register(0x00, 2)               # Read 2 bytes from EEPROM
        eeprom_z = raw[0]| (raw[1]<<8)                  # Combine into 16-bit int
        
        if 'power_resume_z' in self.vars:
            self.gcode.respond_info(f"raw %d %d eeprom_z:%d  %f"%(raw[0],raw[1],eeprom_z,self.variables['power_resume_z']))     # What’s currently saved in variables.cfg
        # if math.fabs(eeprom_z / 10.0 - self.variables['power_resume_z']) > 0.01:
        
        z_str = str(eeprom_z / 10.0)         # e.g. "123.4"
        self.gcode.respond_info(z_str)
        self.gcode.respond_info(f"{z_str.find('0.')}")
        
        #Clean up decimal formatting for SAVE_VARIABLE
        if z_str.rfind('.0') != -1:
            z_str = z_str[:-2]              # "123.4" → "123" if ends with ".0"
        if z_str.find('0.') == 0:
            z_str = z_str[1:]               # "0.5" → ".5" (rare)
        self.gcode.respond_info(z_str)

    ##############################################################
    def cmd_read_write_variable(self, gcmd):
        raw = self.read_register(0x00, 2)           # Read 2 bytes from EEPROM (Calls read_register() → sends I²C read command to address 0x00, asks for 2 bytes.). Returns a bytearray, e.g. bytearray(b'\xd2\x04') → [210, 4].
        eeprom_z = raw[0] | (raw[1] << 8)           # Combine into 16-bit int. Combines the two bytes into a 16-bit unsigned integer: 210 | (4 << 8) → 210 | 1024 → 1234 --> So: 1234 means 123.4 mm (value × 0.1).
        eeprom_mm = eeprom_z / 10.0                 # Converts to millimeters: 1234 / 10.0 = 123.4
        saved = self.vars.get('power_resume_z')     # Looks up the currently saved Z in variables.cfg (via [save_variables]). self.vars was filled in _handle_ready() from save_variables.

        lines = [                                           # Creates a Python list with two strings:
            f"EEPROM: {eeprom_z} → {eeprom_mm:.3f} mm",     #   "EEPROM: 1234 → 123.400 mm" → Shows raw value from EEPROM + converted to mm (with 3 decimals)
            f"Saved: {saved}"                               #   "Saved: 120.5" → Shows what’s currently stored in variables.cfg
        ]

        if saved is not None and abs(eeprom_mm - saved) > 0.01:         # Only sync if: A value exists in save_variables   &.  Difference is > 0.01 mm (avoids floating-point noise)
            z_str = f"{eeprom_mm:.10f}".rstrip('0').rstrip('.')         # Formats Z as string: "123.400000" → "123.4"  &  Removes trailing zeros and dot → clean for SAVE_VARIABLE
            self.gcode.run_script_from_command(                         # Writes the EEPROM value into variables.cfg. Now RESUME_INTERRUPTED will use the correct Z
                f"SAVE_VARIABLE VARIABLE=power_resume_z VALUE={z_str}"
            )
            lines.append(f"→ Updated to {z_str}")   # .append(...) adds a new item to the list. This line only runs if the EEPROM value differs from the saved one.
        gcmd.respond_info("\n".join(lines))         # Sends a message to Mainsail/Fluidd: EEPROM: 1234 → 123.400 mm | Saved: 120.5

##############################################################
def load_config(config):        # Klipper calls this when it sees [at24c_eeprom] in printer.cfg
                                # config - The full config section (with i2c_mcu, i2c_address, etc.)
    return at24cxx(config)      # Creates and returns an instance of your at24cxx class