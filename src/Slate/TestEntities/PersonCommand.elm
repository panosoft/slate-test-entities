module Slate.TestEntities.PersonCommand
    exposing
        ( partsDict
        , commandDict
        , addName
        , removeName
        )

{-|
    Person Commands.

@docs  partsDict, commandDict
-}

import Dict exposing (Dict)
import Slate.TestEntities.PersonSchema exposing (..)
import Slate.TestEntities.Common.Helper as Helper exposing (..)
import Slate.Common.Event exposing (..)
import Slate.Common.Utils exposing (..)
import StringUtils exposing (..)
import String exposing (..)
import Slate.Common.Schema exposing (..)


schema : EntitySchema
schema =
    personSchema


propSchema : List PropertySchema
propSchema =
    personProperties


entityType : String
entityType =
    schema.type_


ignoreProperties : List String
ignoreProperties =
    [ "name" ]



-- API


{-|
    Command parts dictionary.
-}
partsDict : Dict String (CommandPartFunction msg)
partsDict =
    Helper.buildPartsDict personSchema personProperties ignoreProperties


{-|
    Command dictionary.
-}
commandDict : Dict String (CommandFunction msg)
commandDict =
    Helper.buildCommandDict personSchema personProperties ignoreProperties


{-|
    Manually written add property with validation.
-}
addName : CommandPartFunction msg
addName mutatingEventData config dbConnectionInfo initiatorId =
    --addPropertyInternal personSchema.type_ personProperties "name"
    let
        propName =
            "name"
    in
        ( List.map (encodeMutatingEvent << (validatePropertyEventName <| propertySchema propName propSchema))
            [ { name = entityType +-+ propName +-+ "added"
              , version = Nothing
              , data = Mutating <| mutatingEventData
              , metadata = { initiatorId = initiatorId, command = "Add" +-+ (toLower entityType) ++ propName }
              }
            ]
        , [ "Person addName lock" ]
        )


{-|
    Manually written remove property.
-}
removeName : CommandPartFunction msg
removeName =
    removePropertyInternal personSchema.type_ personProperties "name"
