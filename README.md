pimatic-wago
=======================

Adds elements to communicate with a WAGO PLC 750- series

### Installation

Simply add to pimatic config.json under plugins:

    {
      "plugin": "wago",
      "addressPLC": "192.168.1.3",
      "visuFile": "v_datatransfer"
    }
    
The plugin has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| addressPLC        | -        | String  | IP address of your PLC without http or '/'  |
| visuFile          | -        | String  | Name of the visualization element used to transfer addresses|
| readInterval      | 1000     | Integer | Interval for reading data from the PLC |

## Device Configuration

The plugin offers 3 devices:

  WagoSwitch - working as a wall switch to control a given output (light)
  WagoSensor - used to read temperatures from a given variable
  WagoPresence - used to monitor data from presence sensors

Device configuration parameters are to be found in device-config-schema-coffe under "properties" of each device


