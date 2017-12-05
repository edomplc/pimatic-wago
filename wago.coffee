module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'

  wc = require 'wago-common'
  Promise.promisifyAll(wc)
  
  class Wago extends env.plugins.Plugin
    
    init: (app, @framework, @config) =>
      env.logger.info("Starting pimatic-wago...")
      
      deviceConfigDef = require("./device-config-schema")
      
      @framework.deviceManager.registerDeviceClass("WagoSwitch", {
        configDef: deviceConfigDef.WagoSwitch, 
        createCallback: (config, lastState) => return new WagoSwitch(config, lastState)
      })
      
      @framework.deviceManager.registerDeviceClass("WagoSensor", {
        configDef: deviceConfigDef.WagoSensor,
        createCallback: (config, lastState) => return new WagoSensor(config, lastState)
      })
      
      @framework.deviceManager.registerDeviceClass("WagoPresence", {
        configDef: deviceConfigDef.WagoPresence,
        createCallback: (config, lastState) => return new WagoPresence(config, lastState)
      })

      wc.initAsync({
          zipFile: @config.visuFile
          wagoAddress: @config.addressPLC
          readInterval: @config.readInterval
        }).then( (result) ->
          info = if result then "Address file retrived with success" else "Addres file failed"
          env.logger.info(info)
        ).catch( (err) ->
          env.logger.error ("error initializing WAGO plugin: " +  error)
        )
    

  class WagoSwitch extends env.devices.PowerSwitch

    constructor: (@config, @lastState) ->
      @name = @config.name
      @id = @config.id
      @tapAddr = []
      @stateAddr = []
      wc.getAddressAsync(@config.tapAddr).then( (addr) => @tapAddr.push(addr))
      wc.getAddressAsync(@config.stateAddr).then( (addr) => @stateAddr.push(addr))
          
      @_state = lastState?.state?.value or off
      
      updateValue = =>
        @_updateValueTimeout = null
        @getState().finally( =>
          @_updateValueTimeout = setTimeout(updateValue,  Math.max(1000, @config.interval));
        )
      
      super()
      updateValue()

    destroy: () ->
      clearTimeout @_updateValueTimeout if @_updateValueTimeout?
      super()

    
    getState: () ->
      return wc.addToReadQueueAsync(@stateAddr).then( (value) => 
          if value.constructor == Array
            value = value[0]
          #if value == 'wait'
          #  env.logger.info('WAGO plugin not ready')
          if value == '1'
            @_setState(on)
          else
            @_setState(off)
        ).catch( (error) =>
          env.logger.error "error reading state of WAGO switch #{@name}:", error.message
          env.logger.debug error.stack
        )
        
    changeStateTo: (state) ->
      assert state is on or state is off
 
      if state == @_state 
        new Promise (resolve, reject) =>
          resolve true
      else
        new Promise (resolve, reject) =>
          wc.tapAsync(@tapAddr).then( (reply) =>
              if reply == 'ok'
                @_setState(state)
                resolve true
              else
                reject 'error'
            ).catch( (error) =>
              env.logger.debug error.stack
              env.logger.error "error changing state of WAGO switch #{@name}:", error.message
              reject error
            )
          
    _setBrightness: (bri) ->
      if bri > 0
        @turnOn()
      else
        @turnOff()
  
  class WagoSensor extends env.devices.TemperatureSensor
     
    constructor: (@config, @lastState) ->
      @name = @config.name
      @id = @config.id
      @stateAddr = []
      @divisor = @config.divisor
      
      wc.getAddress(@config.stateAddr, (addr) => @stateAddr.push(addr))
          
      @_temperature = lastState?._temperature?.value or 0
      
      updateValue = =>
        @_updateValueTimeout = null
        @getTemperature().finally( =>
          @_updateValueTimeout = setTimeout(updateValue,  Math.max(1000, @config.interval))
        )
      
      super()
      updateValue()

    destroy: () ->
      clearTimeout @_updateValueTimeout if @_updateValueTimeout?
      super()
    
    getTemperature: () ->
      return wc.addToReadQueueAsync(@stateAddr).then( (value) => 
          if value.constructor == Array
            value = value[0]
          value = value / @divisor
          @_setTemperature (value)
        ).catch( (error) =>
          env.logger.error "error reading state of WAGO temperature sensor #{@name}:", error.message
          env.logger.debug error.stack
        )  
        
  class WagoPresence extends env.devices.PresenceSensor
     
    constructor: (@config, @lastState) ->
      @name = @config.name
      @id = @config.id
      @stateAddr = []
      
      wc.getAddress(@config.stateAddr, (addr) => @stateAddr.push(addr))
          
      @_presence = lastState?._presence?.value or 0
      
      updateValue = =>
        @_updateValueTimeout = null
        @getPresence().finally( =>
          @_updateValueTimeout = setTimeout(updateValue, Math.max(1000, @config.interval))
        )
      
      super()
      updateValue()

    destroy: () ->
      clearTimeout @_updateValueTimeout if @_updateValueTimeout?
      super()
    
    getPresence: () ->
      return wc.addToReadQueueAsync(@stateAddr).then( (value) => 
          if value.constructor == Array
            value = value[0]

          @_setPresence (value == '1')
        ).catch( (error) =>
          env.logger.error "error reading state of WAGO presence sensor #{@name}:", error.message
          env.logger.debug error.stack
        )

  wago = new Wago

  return wago

