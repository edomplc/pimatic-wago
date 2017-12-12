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
      # plugin = @
      wc.initAsync({
          zipFile: @config.visuFile
          wagoAddress: @config.addressPLC
          readInterval: @config.readInterval
        }).then( (result) ->
          info = if result then "Address file retrived with success" else "Addres file failed"
          env.logger.info(info)
          # plugin.emit 'initReady'
        ).catch( (err) ->
          env.logger.error ("error initializing WAGO plugin: " +  err)
        )
      # @on('initReady', () => console.log('test'))

  class WagoSwitch extends env.devices.PowerSwitch

    constructor: (@config, @lastState) ->
      @name = @config.name
      @id = @config.id
      @tapAddr = []
      @stateAddr = []
      wc.getAddress(@config.tapAddr, (err, addr) => @tapAddr.push(addr))
      wc.getAddress(@config.stateAddr, (err, addr) => @stateAddr.push(addr))
          
      @_state = lastState?.state?.value or off
      
      updateValue = =>
        clearTimeout @_updateValueTimeout if @_updateValueTimeout?
        @_updateValueTimeout = null
        
        @updateState().finally( =>
          @_updateValueTimeout = setTimeout(updateValue,  Math.max(1000, @config.interval));
        )
      
      super()
      updateValue()
      

    destroy: () ->
      console.log('destroying ' + @name);
      clearTimeout @_updateValueTimeout if @_updateValueTimeout?
      
      super()

    
    updateState: () ->
      return new Promise (resolve, reject) =>
        wc.addToReadQueue(@stateAddr, (err, value) => 
          if !err
            if value.constructor == Array
              value = value[0]
            if value == '1'
              @_setState(on)
            else
              @_setState(off)

            resolve true
          else
            if err == 'notReady' || 'adr!'
              # ignoring other replies like: 'notReady' -for plugin not initialized or 
              # 'adr!' for wrong value passed to the function.
              # Both 'errors' are a consequence of plugin being not initialized....
              # and we choose to ignore updateState() requests, which happen too early
              
              # @_setState(off)
              @_setState(on)
              resolve true
            else
              # this can only happen if the request() within wago-commmon's executeReadQueue() returns a wrong answer
              env.logger.error "error reading state of WAGO switch #{@name}:", err.message
              env.logger.debug err.stack
              reject err
        )
        
        
    changeStateTo: (state) ->
      assert state is on or state is off
 
      new Promise (resolve, reject) =>
        if state == @_state 
          resolve true
        else
          @_setState(state)  
          wc.tapAsync(@tapAddr).then( (reply) =>
            if reply == 'ok'  
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
      
      wc.getAddress(@config.stateAddr, (err, addr) => @stateAddr.push(addr))
          
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
      return new Promise (resolve, reject) =>
        wc.addToReadQueue(@stateAddr, (error, value) => 
          if !error
            if value.constructor == Array
              value = value[0]
            value = value / @divisor
            @_setTemperature (value)
            
            resolve true
          else
            if error == 'notReady' || 'adr!'
              # ignoring other replies like: 'notReady' -for plugin not initialized or 
              # 'adr!' for wrong value passed to the function.
              # Both 'errors' are a consequence of plugin being not initialized....
              # and we choose to ignore getState() requests, which happen too early
              resolve true
            else
              # this can only happen if the request() within wago-commmon's executeReadQueue() returns a wrong answer
              env.logger.error "error reading state of WAGO switch #{@name}:", error.message
              env.logger.debug error.stack
              reject error
        )     
        
  class WagoPresence extends env.devices.PresenceSensor
     
    constructor: (@config, @lastState) ->
      @name = @config.name
      @id = @config.id
      @stateAddr = []
      
      wc.getAddress(@config.stateAddr, (err, addr) => @stateAddr.push(addr))
          
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
      return new Promise (resolve, reject) =>
        wc.addToReadQueue(@stateAddr, (error, value) => 
          if !error
            if value.constructor == Array
              value = value[0]
            @_setPresence (value == '1')
            resolve true
          else
            if error == 'notReady' || 'adr!'
              # ignoring other replies like: 'notReady' -for plugin not initialized or 
              # 'adr!' for wrong value passed to the function.
              # Both 'errors' are a consequence of plugin being not initialized....
              # and we choose to ignore getState() requests, which happen too early
              resolve true
            else
              # this can only happen if the request() within wago-commmon's executeReadQueue() returns a wrong answer
              env.logger.error "error reading state of WAGO switch #{@name}:", error.message
              env.logger.debug error.stack
              reject error
        )      

  wago = new Wago

  return wago

