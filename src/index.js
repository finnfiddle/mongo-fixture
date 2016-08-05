const _ = require('lodash');
const mongo = require('mongodb');
const itsSet = require('its-set').itsSet;
const async = require('async');
const MongoClient = mongo.MongoClient;
const ObjectID = mongo.ObjectID;

export default (...args) => {
  let data;
  if (_.isString(args[0])) {
    data = require(args[0]);
  }
  else {
    data = args[0];
  }
  const objs = {};
  const refs = {};
  let options;
  let next;

  if (args.length === 2) {
    next = args[1];
    options = {};
  }
  else {
    next = args[2];
    options = args[1] || {};
  }

  const opts = _.merge({
    host: '127.0.0.1',
    port: 27017,
    db: 'mongo_fixture_test',
    drop: true,
  }, options);

  const getRefs = d => {
    if (itsSet(d.__ref)) {
      refs[d.__collection] = refs[d.__collection] || {};
      refs[d.__collection][d.__ref] = d;
    }
    _.forIn(d, v => _.isObject(v) ? getRefs(v) : null);
  };

  const analyseObj = d => {
    const col = d.__collection;
    if (itsSet(col)) {
      objs[col] = objs[col] || [];
      objs[col].push(d);
    }

    _.forIn(d, v => {
      if (_.isObject(v)) {
        analyseObj(v);
      }
    });
  };

  const assignIds = d => {
    if (!itsSet(d.__duplicate) && itsSet(d.__collection)) {
      d._id = new ObjectID();
    }
    Object.keys(d).forEach(k => {
      const v = d[k];
      if (_.isObject(v) && k !== '_id') {
        if (itsSet(v.__id) && itsSet(v.__id.__collection) && itsSet(v.__id.__ref)) {
          d[k] = refs[v.__id.__collection][v.__id.__ref]._id;
        }
        else {
          assignIds(v);
        }
      }
    });
  };

  const flatten = d => {
    Object.keys(d).forEach(k => {
      const v = d[k];
      if (_.isObject(v)) {
        const dup = v.__duplicate;
        const col = v.__collection;
        if (itsSet(col)) {
          if (itsSet(dup)) {
            const dupObj = _.findWhere(objs[col], {__ref: dup});
            if (!itsSet(dupObj)) {
              next(new Error("#{col} with '__ref': #{dup} can't be found"));
            }
            d[k] = dupObj._id;
          }
          else {
            d[k] = v._id;
          }
        }
        else {
          flatten(v);
        }
      }
    });
  };

  const clean = arr => {
    let i = -1;
    const cleanNext = () => {
      if (i++ < arr.length) {
        const d = arr[i];
        if (_.isObject(d)) {
          delete d.__ref;
          delete d.__collection;
          if (itsSet(d.__duplicate)) {
            arr.splice(i, 1);
            i--;
          }
        }
        cleanNext();
      }
    };
    cleanNext();
  };

  const drop = (db, next2) => {
    _.forIn(objs, (v, k) => {
      const collection = db.collection(k);
      collection.drop();
    });
    next2();
  };

  const populate = (db, next2) => {
    async.forEachOf(objs, (v, k, next3) => {
      const collection = db.collection(k);
      async.eachSeries(v, (d, next4) => {
        collection.insert(d, next4);
      }, next3);
    }, next2);
  };

  _.each(data, (d) => getRefs(d));

  _.each(data, (d) => analyseObj(d));

  _.forIn(objs, v => _.each(v, (obj) => assignIds(obj)));

  _.forIn(objs, v => _.each(v, (obj) => flatten(obj)));

  _.forIn(objs, v => clean(v));

  MongoClient.connect(`mongodb://${opts.host}:${opts.port}/${opts.db}`, (err, db) => {
    if (itsSet(err)) throw err;
    if (opts.drop) {
      drop(db, () => {
        populate(db, () => {
          db.close();
          next(null);
        });
      });
    }
    else {
      populate(db, () => {
        db.close();
        next(null);
      });
    }
  });
};
