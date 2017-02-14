module Slate.TestEntities.PersonCommand
    exposing
        ( internalDict
        , processDict
        , addName
        , removeName
        )

{-|
    Person Commands.

@docs  internalDict, processDict
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
    Internal function dictionary.
-}
internalDict : Dict String (InternalFunction msg)
internalDict =
    Helper.buildInternalDict personSchema personProperties ignoreProperties


{-|
    Process Cmd dictionary.
-}
processDict : Dict String (ProcessFunction msg)
processDict =
    Helper.buildProcessDict personSchema personProperties ignoreProperties


{-|
    Manually written add property with validation.
-}
addName : InternalFunction msg
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
removeName : InternalFunction msg
removeName =
    removePropertyInternal personSchema.type_ personProperties "name"
