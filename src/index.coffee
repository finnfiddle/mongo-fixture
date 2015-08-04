_ = require('lodash')
mongo = require('mongodb')
async = require('async')
MongoClient = mongo.MongoClient
ObjectID = mongo.ObjectID

module.exports = (data) ->
  if _.isString(data)
    data = require(fileName)
  objs = {}
  refs = {}
  index = 0

  args = Array.prototype.slice.call(arguments)
  if args.length is 2
    next = args[1]
    options = {}
  else
    next = args[2]
    options = args[1] || {}

  opts = _.merge({
    host: '127.0.0.1'
    port: 27017
    db: 'mongo_fixture_test'
    drop: true
  }, options)

  getRefs = (d) ->
    if d.__ref?
      refs[d.__collection] ?= {}
      refs[d.__collection][d.__ref] = d
    _.forIn(d, (v, k, o) ->
      if _.isObject(v)
        getRefs(v)
    )   

  analyseObj = (d) ->
    ref = d.__ref
    col = d.__collection
    if col?
      objs[col] ?= []
      objs[col].push(d)

    _.forIn(d, (v, k, o) ->
      if _.isObject(v)
        analyseObj(v)
    )

  assignIds = (d) ->
    if !d.__duplicate? and d.__collection?
      d._id = new ObjectID()
    _.forIn(d, (v, k, o) ->
      if _.isObject(v)
        assignIds(v)
    )

  flatten = (d) ->
    _.forIn(d, (v, k, o) ->
      if _.isObject(v) 
        dup = v.__duplicate
        col = v.__collection
        if col?
          if dup?
            dupObj = _.findWhere(objs[col], {__ref: dup})
            if !dupObj?
              next(new Error("#{col} with '__ref': #{dup} can't be found"))
            o[k] = dupObj._id
          else
            o[k] = v._id
        else
          flatten(v)
    )

  clean = (arr) ->
    i = -1
    cleanNext = () ->
      if i++ < arr.length
        d = arr[i]
        if _.isObject(d) 
          delete d.__ref
          delete d.__collection
          if d.__duplicate?
            arr.splice(i, 1)
            i--
        cleanNext()
    cleanNext()

  drop = (db, next) ->
    _.forIn(objs, (v, k, o) ->
      collection = db.collection(k)
      collection.drop()
    )
    next()

  populate = (db, next) ->
    async.forEachOf(objs, (v, k , next) ->
      collection = db.collection(k)
      async.eachSeries(v, (d, next) ->
        collection.insert(d, next)
      , next)
    , next)

  _.each(data, (d) ->
    getRefs(d)
  )

  _.each(data, (d) ->
    analyseObj(d)
  )

  _.forIn(objs, (v, k, o) ->
    _.each(v, (obj) ->
      assignIds(obj)
    )
  )

  _.forIn(objs, (v, k, o) ->
    _.each(v, (obj) ->
      flatten(obj)
    )
  )

  _.forIn(objs, (v, k, o) ->
    clean(v)
  )

  MongoClient.connect("mongodb://#{opts.host}:#{opts.port}/#{opts.db}", (err, db) ->
    if err? then throw err
    if opts.drop
      drop(db, () ->
        populate(db, () ->
          db.close()
          next(null)
        )
      )
    else
      populate(db, () ->
        db.close()
        next(null)
      )
  )


