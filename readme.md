# Test Entities for testing Slate functionality

> Entities for testing Slate components, e.g. Query Engine, Command Helper.

## Install

### Elm

Since the Elm Package Manager doesn't allow for Native code and most everything we write at Panoramic Software has some native code in it,
you have to install this library directly from GitHub, e.g. via [elm-github-install](https://github.com/gdotdesign/elm-github-install) or some equivalent mechanism. It's just not worth the hassle of putting libraries into the Elm package manager until it allows native code.

## Purpose

This repo servers 2 purposes:

1. Provide Entity implementations for testing reads and writes of Slate Events
2. Example of how to implement Entities

Entities have 3 parts:

1. Implementation
2. Schema
3. Command Processor (API)


## Entity Implementation

The Entity Implementation contains the following:

1. Entire Entity - This is the Entire Entity with all of its Properties. All properties are defined as `Maybes` except `Lists` since they can be empty.
2. Entire Entity Dictionary - This is just for convenience so code that uses the Entity won't have to constantly define this.
3. Default Entire Entity - This is also for convenience so Projection code can have default values. Usually, `Strings` are empty, `Ints` are invalid values, `Dictionaries` are `Dict.empty` and `Lists` are empty. This is also used for `Schema Migration`. In that case, default values are usually non-empty to support older versions of an Entity.
4. Value objects - Value Object definitions for all Value Object Properties.
5. Entire Entity Shell - An empty Entire Entity as a starting point for mutations. Used internally, but also exported for convenience.
6. Entire Entity Encode Function - This function takes an Entire Entity and produces a JSON String.
7. Entire Entity Decode Function - This function takes a JSON String and produces Entire Entity (wrapped in a `Result`).
8. Handle Mutation Function - This function mutates the appropriate Entity in an Entire Entity Dictionary based on the specified Event.
9. Mutate - This function mutates a single Entity based on the specified Event.

Here is the Person Entity's module definition (Note here `Name` is a `Value Object`):

```elm
module Slate.TestEntities.PersonEntity
    exposing
        ( EntirePerson
        , EntirePersonDict
        , DefaultEntirePerson
        , Name
        , entirePersonShell
        , defaultEntirePerson
        , entirePersonEncode
        , entirePersonDecode
        , handleMutation
        , mutate
        )
```
## Mutation Interface

The mutation functions signatures are dependent on the structure of the Entity and its relationships.


### handleMutation

This function mutates the appropriate Entity in an Entire Entity Dictionary based on the specified Event.

Here is Address Entity's `handleMutation` function:

```elm
handleMutation : EntireAddressDict -> Event -> Result String EntireAddressDict
handleMutation dict event =
```

It takes an `EntireAddress` dictionary, a mutation event and returns a new dictionary wrapped in a `Result`.

This is as simple as it gets.

A more complex example is Person's `handleMutation`:

```elm
handleMutation : EntirePersonDict -> EntireAddressDict -> Event -> ( Result String EntirePersonDict, Maybe CascadingDelete )
handleMutation dict addresses event
```

Notice that since `Person` has a relationship with the `Address` Entity it needs the dictionary of Addresses (2nd parameter).

Also, since Person has an ownership relationship (see [Person Schema](#person-schema)), it returns a tuple where the first is the new `Person` dictionary and the second is a `Maybe CascadingDelete` that may contain information that describes how to delete an owned Entity.


### mutate

This function mutates a single Entity based on the specified Event. This is called internally by `handleMutation` but is exported in case the App wants to do processing on a single Entity.

Here is Address Entity's `mutate` function:

```elm
mutate : Event -> EntireAddress -> Result String (Maybe EntireAddress)
mutate event entity =
```

It takes the Event, the Entire Entity to mutate and returns a new Entire Entity.

Doesn't get simpler than this.

Person's `mutate` is only slightly more complex:

```elm
mutate : Event -> EntirePerson -> EntireAddressDict -> ( Result String (Maybe EntirePerson), Maybe CascadingDelete )
mutate event entity addresses =
```

In addition to the usual suspects, it also takes an Entire Address dictionary. This is because it has a relationship with `Address`. An Entity that has relationships will have an **extra parameter** like this **for each relationship**.

It also returns an extra return value for optional cascading delete information.

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
