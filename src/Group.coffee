EventEmitter = require('events').EventEmitter
Promise = require('bluebird')
Pump = require('./Pump')
Buffer = require('./Buffer')

class Group extends EventEmitter
  @STOPPED: 0
  @STARTED: 1
  @ENDED: 2

  constructor: ->
    @_pumps = {}
    @_exposedBuffers = {}
    @_state = Group.STOPPED

  addPump: (name, pump = null) ->
    throw new Error 'Pump already exists' if @_pumps[name]?
    @_pumps[name] = pump ? new Pump
    @_pumps[name].on 'end', => @pumpEnded(name)
    @_pumps[name]

  pumpEnded: (name) ->
    end = true
    for name, pump of @_pumps
      end = false if !pump.isEnded()
    return if !end

    @_state = Group.ENDED
    @emit 'end'

  pump: (name) ->
    throw new Error "Pump #{name} does not exist" if !@_pumps[name]?
    @_pumps[name]

  start: ->
    throw new Error 'Group already started' if @_state != Group.STOPPED
    @_state = Group.STARTED
    do pump.start for name, pump of @_pumps
    @

  isEnded: ->
    @_state == Group.ENDED

  whenFinished: ->
    return new Promise (resolve) =>
      @on 'end', ->
        resolve()

  createBuffer: (options = {}) ->
    new Buffer options

  expose: (exposedName, bufferPath) ->
    throw new Error 'Already exposed a buffer with that name' if @_exposedBuffers[exposedName]?
    @_exposedBuffers[exposedName] = @_getBufferByPath(bufferPath)

  _getBufferByPath: (bufferPath) ->
    items = bufferPath.split('/')
    throw new Error 'bufferPath format must be <pumpName>/<bufferName>' if items.length > 2
    [ pumpName, bufferName ] = items
    @pump(pumpName).buffer(bufferName ? 'output')

  buffer: (name = 'output') ->
    throw new Error("No such buffer: #{name}") if !@_exposedBuffers[name]
    @_exposedBuffers[name]

module.exports = Group