module.exports = {
  title: "wago config options"
  type: "object"
  properties:{
    visuFile:
      description: "name of the visu file used to check variable addresses"
      type: "string"
      default: "datatransfer"
    addressPLC:
      description: "Address of your PLC"
      type: "string"
      default: "192.168.1.3"
    readInterval:
      description: "Collecting all requests to WAGO and sending them at a given interval"
      type: "integer"
      default: 1000
  }
}
