# DEPRECATED - Please see [elm-slate/test-entities](https://github.com/elm-slate/test-entities)


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
handleMutation dict event
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
mutate event entity
```

It takes the Event, the Entire Entity to mutate and returns a new Entire Entity.

Doesn't get simpler than this.

Person's `mutate` is only slightly more complex:

```elm
mutate : Event -> EntirePerson -> EntireAddressDict -> ( Result String (Maybe EntirePerson), Maybe CascadingDelete )
mutate event entity addresses
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

## Command Dictionaries

There are 2 types of dictionaries that can be created, Internal and Process.

#### Internal Dictionary

The purpose of this dictionary is to allow the combining of simple CRUD mutations in higher-level API, e.g. to create `Multiple Events` in a `Transaction`. It's values are of type `CommandPartFunction`.

This dictionary has the following default keys:

1. create
2. destroy
3. add
4. remove

Keys `create` and `destroy` are for Entities. Keys `add` and `remove` are for Properites. Any property can be excluded in the dictionary. See `ignoreProperties` in `Slate.TestEntities.PersonCommand`.

Internal Dictionary entries cannot be executed directly. They must be converted to a `CommandFunction` which can be done with the Helper function `process`.

For usage, see `asMultCmds` in `Test.App`.

#### Process Dictionary

This dictionary is derivitave of the `Interal Dictionary`. Each value of this dictionary will create one or more `Events` in a `Transaction`. It has the same keys but the values are of type `CommandFunction`.

For usage, see `asOneCmd` in `Test.App`.

## Helper

The Helper module is a set of routines to make developing most Entity Command Processor code easy. If your Entity has simple CRUD mutations, then there is very little code that needs to be written. This can be seen in `Slate.TestEntities.AddressCommand`.

It also contains code to make usage of Command Processors easy. See `Test.App`.

### Dictionary Definitions

#### CommandFunctionParams

Common command function parameters.

```elm
type alias CommandFunctionParams msg return =
    MutatingEventData -> Config msg -> DbConnectionInfo -> InitiatorId -> return
```

#### CommandPartResults

Result of a CommandPartFunction.

```elm
type alias CommandPartResults =
    ( List String, List EntityReference )
```

#### CommandPartFunction

Command part that can be combined with other command parts to be executed in a single transition.

```elm
type alias CommandPartFunction msg =
    CommandFunctionParams msg CommandPartResults
```

#### CommandToCmdFunction

Function that takes a Command, CommandProcessor model and produces an executable Cmd.

```elm
type alias CommandToCmdFunction msg =
CommandProcessor.Model msg -> ( CommandProcessor.Model msg, Cmd msg, CommandId )
```

#### CommandFunction

Command function to create events in a single transition.

```elm
type alias CommandFunction msg =
    CommandFunctionParams msg (CommandToCmdFunction msg)
```

### Entity Command Development Helpers

#### propertySchema

Retrieves the specified property schema from a list of property schemas. CRASHES if not found to prevent bad events in the DB.

```elm
propertySchema : String -> List PropertySchema -> PropertySchema
propertySchema propName propertySchemas
```
#### createInternal

Create IntenalFunction for "create" event. Not usually used directly but here just in case.

```elm
createInternal : String -> EntitySchema -> CommandPartFunction msg
createInternal
```

#### destroyInternal

Create IntenalFunction for "destroy" event. Not usually used directly but here just in case.

```elm
destroyInternal : String -> EntitySchema -> CommandPartFunction msg
destroyInternal
```

#### addInternal

Create IntenalFunction for "add" event. Not usually used directly but here just in case.

```elm
addInternal : String -> EntitySchema -> CommandPartFunction msg
addInternal
```

#### removeInternal

Create IntenalFunction for "remove" event. Not usually used directly but here just in case.

```elm
removeInternal : String -> EntitySchema -> CommandPartFunction msg
removeInternal
```

#### addPropertyInternal

    Create IntenalFunction for "add" event from an Entity's Properties. Not usually used directly but here just in case.

```elm
addPropertyInternal : String -> List PropertySchema -> String -> CommandPartFunction msg
addPropertyInternal entityType propertySchemas propName
```


#### removePropertyInternal

    Create IntenalFunction for "remove" event from an Entity's Properties. Not usually used directly but here just in case.

```elm
removePropertyInternal : String -> List PropertySchema -> String -> CommandPartFunction msg
removePropertyInternal entityType propertySchemas propName
```

#### buildPartsDict

Build default Internal Dictionary except for specified properties.

```elm
buildPartsDict : EntitySchema -> List PropertySchema -> List String -> Dict String (CommandPartFunction msg)
buildPartsDict entitySchema propertySchemas ignoreProperties
```

#### buildCommandDict

Build default Process Dictionary except for specified properties.

```elm
buildCommandDict : EntitySchema -> List PropertySchema -> List String -> Dict String (CommandFunction msg)
buildCommandDict entitySchema propertySchemas ignoreProperties
```

### App Development Helpers

#### process

Convert an CommandPartFunction to a CommandFunction with an optional Validator by passing it through the CommandProcessor.

```elm
process : Maybe (ValidateTagger CommandProcessor.Msg msg) -> CommandPartFunction msg -> CommandFunction msg
process tagger internal mutatingEventData config dbConnectionInfo initiatorId model
```

__Usage__

See `asMultCmds` in `Test.App`.

#### combine

Combine a List of command part results into a single command part results.

```elm
combine : List ( List String, List EntityReference ) -> ( List String, List EntityReference )
combine operations
```

__Usage__

See `asOneCmd` in `Test.App`.

#### asCmds

Takes a list of CommandToCmdFunctions and passes them sequentially and iteratively the CommandProcessor Model to produce a List of Cmds and a final CommandProcessor Model.

```elm
asCmds : CommandProcessor.Model msg -> List (ProcessToCmdFunction msg) -> ( CommandProcessor.Model msg, List ( CommandId, Cmd msg ) )
asCmds model operations
```

__Usage__

See `asMultCmds` in `Test.App`.

#### createDestroyData

Create mutating event data for a create/destroy event.

```elm
createDestroyData : EntityReference -> MutatingEventData
createDestroyData entityId
```

__Usage__

See `Test.App`.

#### durationData

Create mutating event data for a duration event.

```elm
durationData : EntityReference -> MutatingEventData
durationData entityId
```

__Usage__

See `Test.App`.

#### addRemoveData

Create mutating event data for an add/remove event.

```elm
addRemoveData : EntityReference -> String -> MutatingEventData
addRemoveData entityId value
```

__Usage__

See `Test.App`.

#### addRemoveReferenceData

Create mutating event data for a add/remove reference event.

```elm
addRemoveReferenceData : EntityReference -> EntityReference -> MutatingEventData
addRemoveReferenceData entityId refEntityId
```

__Usage__

See `Test.App`.

#### positionData

Create mutating event data for a position event.

```elm
positionData : EntityReference -> EntityReference -> Int -> Int -> MutatingEventData
positionData entityId propertyId oldPosition newPosition =
```

__Usage__

See `Test.App`.
