# #Wago device configuration options
module.exports = {
  title: "pimatic-wago device config schemas"
  WagoSwitch: {
    title: "WagoSwitch config options"
    type: "object"
    extensions: ["xConfirm", "xOnLabel", "xOffLabel"]
    properties:
      tapAddr:
        description: "The address to Tap"
        type: "string"
      stateAddr:
        description: "The address to read current state"
        type: "string"
      interval:
        description: "Set default state refresh interval, default 1000ms"
        type: "integer"
        default: 1000
  },

  WagoSensor: {
    title: "WagoSensor config options"
    type: "object"
    properties:
      stateAddr:
        description: "The address to read"
        type: "string"
      interval:
        description: "Set default value refresh interval, default 1000ms"
        type: "integer"
        default: 5000
      divisor:
        description: "Set divisor for the value red from the PLC"
        type: "integer"
        default: 10
  },

  WagoPresence: {
    title: "WagoPresence config options"
    type: "object"
    extensions: ["xPresentLabel", "xAbsentLabel"]
    properties:
      stateAddr:
        description: "The address to read for presence"
        type: "string"
      interval:
        description: "Set default value refresh interval, default 1000ms"
        type: "integer"
        default: 1000
  }
}
