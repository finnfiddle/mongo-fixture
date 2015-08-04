_ = require('lodash')
test = require('tape')
path = require('path')
MongoClient = require('mongodb').MongoClient
fixture = require('../index')

test('fixture', (t) ->
  t.plan(14)

  MongoClient.connect('mongodb://127.0.0.1:27017/mongo_fixture_test', (err, db) ->
    t.error(err)

    find = (query, colName, next) ->
      collection = db.collection(colName)
      collection.find({}, (err, cursor) ->
        cursor.toArray((err, result) ->
          t.error(err)
          next(result)
        )
      )

    where = (arr, query, num) ->
        t.equal(_.where(arr, query).length, num)

    fixture(path.join(__dirname, './data.json'), () ->
      find({}, 'User', (users) ->
        t.equal(users.length, 4)
        where(users, {username: 'User A'}, 1)
        where(users, {username: 'User B'}, 1)
        where(users, {username: 'User C'}, 1)
        where(users, {username: 'User D'}, 1)
        where(users, {age: 20}, 2)

        find({}, 'Plan', (plans) ->
          t.equal(plans.length, 2)

          find({}, 'SpecialOffer', (offers) ->
            t.equal(offers.length, 2)

            find({}, 'OtherThing', (things) ->
              t.equal(things.length, 1)

              db.close()
            )
          )
        )
      )
    )
  )
)