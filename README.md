pimatic-wago
=======================

Adds elements to communicate with a WAGO PLC 750- series
Build to work with the pimatic-echo plugin :) i.e. to add voice control the PLC-based home automation

### Installation

Add the followig to config.json under plugins:

    {
      "plugin": "wago",
      "addressPLC": "192.168.1.3",
      "visuFile": "v_datatransfer"
    }

Check if pimatic installed the latest available version of plugin.  If not, update manually by running in your main pimatic directory:

```sh
sudo npm install pimatic-wago
```
    
The plugin has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| addressPLC        | -        | String  | IP address of your PLC without http or '/'  |
| visuFile          | -        | String  | Name of the visualization element used to transfer addresses|
| readInterval      | 1000     | Integer | Interval for reading data from the PLC |

The readInterval requires additional explanation.  Each device in Pimatic triggers a loop of state-refresh events.  In installations with many devices that would create much traffic thwarting communication.  To solve this the underlying wago-common plugin collects all read requests and executes them in one statement at intervals set by readInterval property.

## Device Configuration

The plugin offers 3 devices:

* WagoSwitch - working as a wall switch to control a given output (light)
* WagoSensor - used to read temperatures from a given variable
* WagoPresence - used to monitor data from presence sensors

Device configuration parameters are to be found in device-config-schema-coffee under "properties" of each device

### Preparing your PLC for communication

1. Create a new visualization in CoDeSys in your program (for example "datatransfer")
2. Create elements which should be controlled via pimatic (for example a rectangle, which changes color together with .OUT1) variable and which taps or clicks Visu1 : BOOL variable, which in turn switches the light connected to .OUT1.
3. Make sure that your new visualization is available as web visu.
4. Make sure the visualizations are compressed.
4. Place the name of the new visualization in the plugin config
5. Add a device in pimatic and enter the name of variables, which were used in the visu (for example Visu1 and .OUT1)

The underlying wago-common plugin will download your visualization file (datatransfer_xml.zip), unpack it (->datatransfer.xml), parse the file searching for variables (Visu1 and .OUT1) and assign addresses found in the xml file.
