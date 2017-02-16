module Slate.TestEntities.AddressCommand
    exposing
        ( partsDict
        , commandDict
        )

{-|
    Address Commands.

@docs  partsDict, commandDict
-}

import Dict exposing (Dict)
import Slate.TestEntities.AddressSchema exposing (..)
import Slate.TestEntities.Common.Helper as Helper exposing (CommandPartFunction, CommandFunction)


ignoreProperties : List String
ignoreProperties =
    []



-- API


{-|
    Command parts dictionary.
-}
partsDict : Dict String (CommandPartFunction msg)
partsDict =
    Helper.buildPartsDict addressSchema addressProperties ignoreProperties


{-|
    Command dictionary.
-}
commandDict : Dict String (CommandFunction msg)
commandDict =
    Helper.buildCommandDict addressSchema addressProperties ignoreProperties
