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
import Slate.Common.Entity exposing (..)


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
processDict : Dict String (ProcessCmd msg)
processDict =
    Helper.buildProcessDict personSchema personProperties ignoreProperties


{-|
    Manually written property add.
-}
addName : InternalFunction msg
addName =
    addPropertyInternal personSchema.type_ personProperties "name"


{-|
    Manually written property remove.
-}
removeName : InternalFunction msg
removeName =
    removePropertyInternal personSchema.type_ personProperties "name"
