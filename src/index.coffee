_ = require('lodash')

module.exports = (fileName, next) ->
	data = require(fileName)
	objs = {}
	refs = {}

	getRefs = (d) ->
		if d.__ref?
			refs[d.__collection] ?= {}
			refs[d.__collection][d.__ref] = d
		_.forIn(d, (v, k, o) ->
			if typeof v is 'object'
				getRefs(v)
		)		

	analyseObj = (d) ->
		ref = d.__ref
		col = d.__collection
		objs[col] ?= []
		objs[col].push(d)

		_.forIn(d, (v, k, o) ->
			if typeof v is 'object'
				analyseObj(v)
		)

	drop = () ->
		# drop collections

	populate = () ->
		_.forIn(objs, (v, k , o) ->
			_.each(v, (d) ->
				# new [k](d)
			)
		)

	_.each(data, (d) ->
		getRefs(d)
	)

	_.each(data, (d) ->
		analyseObj(d)
	)
	console.log(objs)

	# replace sub objects with ids
	drop()
	populate()

	next()
