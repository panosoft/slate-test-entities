# Test Entities for testing Slate functionality

> Some test entities for testing Slate components, e.g. Query Engine, Command Helper.

## Install

### Elm

Since the Elm Package Manager doesn't allow for Native code and most everything we write at Panoramic Software has some native code in it,
you have to install this library directly from GitHub, e.g. via [elm-github-install](https://github.com/gdotdesign/elm-github-install) or some equivalent mechanism. It's just not worth the hassle of putting libraries into the Elm package manager until it allows native code.

## Person Entity

The `Person` Entity has the following definition:

```elm
type alias EntirePerson =
    { name : Maybe Name
    , age : Maybe Int
    , address : Maybe EntityReference
    }
```

Here `name` is a Value Object:

```elm
type alias Name =
    { first : String
    , middle : String
    , last : String
    }
```

Here address is a reference to another Entity. (Done this way for testing, not necessarily good design.)

## Address Entity

The `Address` Entity has the following definition:

```elm
type alias EntireAddress =
    { street : Maybe String
    , city : Maybe String
    , state : Maybe String
    , zip : Maybe String
    }
```

## Schemas

Entities have properties. So `Schema`s define both Entity schemas and Property schemas. See [slate-common](https://github.com/panosoft/slate-common.git) for more on Schemas.

### Person Schema

#### Entity Schema
```elm
personSchema : EntitySchema
personSchema =
    { type_ = "Person"
    , eventNames =
        [ "Person created"
        , "Person destroyed"
        ]
    , properties = personProperties
    }
```

* type_ - This is the type `Person`.
* eventNames - Event names for creating and destroying a `Person`.
* properties - `Person` property schema (see below)

#### Properties Schema

```elm
personProperties : List PropertySchema
personProperties =
    [ { mtPropSchema
        | name = "name"
        , eventNames =
            [ "Person name added"
            , "Person name removed"
            ]
      }
    , { mtPropSchema
        | name = "age"
        , eventNames =
            [ "Person age added"
            , "Person age removed"
            ]
      }
    , { mtPropSchema
        | name = "address"
        , entitySchema = Just <| SchemaReference addressSchema
        , eventNames =
            [ "Person address added"
            , "Person address removed"
            ]
        , owned = True
      }
    ]
```
Here `mtPropSchema` is a Empty Property Schema that's mutated to make defining Property Schemas terse, i.e. easier.

`Person` has the following properties:

* `name` - The name of the person (Value Object).
* `age` - The age of the person.
* `address` - A Reference to an `Address Entity` (see below).

### Address Schema

#### Entity Schema
```elm
addressSchema : EntitySchema
addressSchema =
    { type_ = "Address"
    , eventNames =
        [ "Address created"
        , "Address destroyed"
        ]
    , properties = addressProperties
    }
```
* type_ - This is the type `Address`.
* eventNames - Event names for creating and destroying an `Address`.
* properties - `Address` property schema (see below)

#### Properties Schema

```elm
addressProperties : List PropertySchema
addressProperties =
    [ { mtPropSchema
        | name = "street"
        , eventNames =
            [ "Address street added"
            , "Address street removed"
            ]
      }
    , { mtPropSchema
        | name = "city"
        , eventNames =
            [ "Address city added"
            , "Address city removed"
            ]
      }
    , { mtPropSchema
        | name = "state"
        , eventNames =
            [ "Address state added"
            , "Address state removed"
            ]
      }
    , { mtPropSchema
        | name = "zip"
        , eventNames =
            [ "Address zip added"
            , "Address zip removed"
            ]
      }
    ]
```
Here `mtPropSchema` is a Empty Property Schema that's mutated to make defining Property Schemas terse, i.e. easier.

`Address` has the following properties:

* `street` - The stree number and name.
* `city` - The name of the city.
* `state` - The state.
* `zip` - The zipcode.
