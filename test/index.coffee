MongoClient = require('mongodb').MongoClient
test = require('tape')
path = require('path')
fixture = require('../index')
# ObjectID = require('mongodb').ObjectID


test('fixture', (t) ->
  t.plan(6)

  MongoClient.connect('mongodb://127.0.0.1:27017/mongo_fixture_test', (err, db) ->

    verb = (action, query, colName, next) ->
      collection = db.collection(colName)
      collection[action](query, (err, result) ->
        t.error(err)
        next(result)
      )

    t.error(err)
    verb('remove', {}, 'Users', () ->
      verb('remove', {}, 'Plans', () ->
        verb('remove', {}, 'SpecialOffers', () ->
          fixture(path.join(__dirname, './data.json'), () ->
            verb('count', {}, 'Users', (result) ->
              console.log(result)
              t.equal(result, 3)
            )
            #   collection.insert({a:2}, (err, docs) ->
                
            #     collection.count((err, count) ->
            #       console.log(format("count = %s", count))
            #     )

            #     collection.find().toArray((err, results) ->
            #       console.dir(results)
            #       db.close()
            #     )
            #   )
          )
        )
      )
    )
  )
)