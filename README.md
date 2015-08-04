Mongo Fixture
=============

Easily populate a Mongo db using nested json for development and testing purposes.
Configure which nested objects are created as separate documents in seperate collections.
Relationships are preserved by referencing ObjectId's of child documents.

Install
-------

```
npm install --save-dev mongo-fixture
```

Usage
-----

```
fixture = require('mongo-fixture');

fixture('data.json', function(error){
	if(err){
		throw err;
	} 
});
```

Example JSON file
-----------------

```
[
	{
		"__collection": "User",
		"username": "User A",
		"age": 20,
		"active": false,
		"nonCollection": {
			"propA": "A"
		},
		"plan": {
			"__collection": "Plan",
			"__ref": "1",
			"name": "Plan A",
			"price": 100,
			"private": true,
			"specialOffer": {
				"__collection": "SpecialOffer",
				"propX": "X"
			},
			"otherProp": {
				"__collection": "OtherThing",
				"propR": "R",
				"__ref": "1"
			}
		}
	},
	{
		"__collection": "User",
		"username": "User B",
		"age": 20,
		"active": true,
		"plan": {
			"__collection": "Plan",
			"__duplicate": "1"
		}
	},
	{
		"__collection": "User",
		"username": "User C",
		"age": 32,
		"active": true,
		"plan": {
			"__collection": "Plan",
			"__ref": "2",
			"name": "Plan B",
			"price": 200,
			"private": false,
			"specialOffer": {
				"__collection": "SpecialOffer",
				"propX": "Y"
			},
			"otherProp": {
				"__collection": "OtherThing",
				"__duplicate": "1"
			}
		}
	},
	{
		"__collection": "User",
		"username": "User D",
		"age": 33,
		"active": true,
		"plan": {
			"__collection": "Plan",
			"__duplicate": "2"
		}
	}
]
```

Child Documents
---------------

Child documents are simple JSON objects with a `__collection` attribute.
The child objects become ObjectId references when the db is populated.

Eg:

```
{
	"__collection": "ParentCollection",
	child: {
		"__collection": "ChildCollection",
		"keyX": "valueX"
	}
}
```
Becomes the following documents:
```
// ParentCollection Doc
{
	child: ObjectId("55c0ade6b47164eb35a544a1")
}
// ChildCollection Doc
{
	"keyX": "valueX"
}
```

Duplicates
----------
Children can belong to multiple parents using `__ref` and `__duplicate` attributes.
Defined a common child once and give it a unique `__ref` value of your choice.
Then in another parent object reference the child by specifying the `__duplicate` attribute and setting it to the value of the `__ref` of the original.

Eg:
```
[
	{
		"__collection": "ParentCollection",
		"child": {
			"__collection": "ChildCollection",
			"_ref": "1",
			"otherProp": "X"
		}
	},
	{
		"__collection": "ParentCollection",
		"child": {
			"__collection": "ChildCollection",
			"_duplicate": "1"
		}
	}
]
```
NB: always specify the `__collection` attribute.

Testing
-------
```
npm test
```

Contributing
------------
Pull requests, check the current source code for style. Its in coffeescript. And cheers