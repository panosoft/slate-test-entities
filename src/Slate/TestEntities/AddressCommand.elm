module Slate.TestEntities.AddressCommand
    exposing
        ( internalDict
        , processDict
        )

{-|
    Address Commands.

@docs  internalDict, processDict
-}

import Dict exposing (Dict)
import Slate.TestEntities.AddressSchema exposing (..)
import Slate.TestEntities.Common.Helper as Helper exposing (InternalFunction, ProcessFunction)


ignoreProperties : List String
ignoreProperties =
    []



-- API


{-|
    Internal function dictionary.
-}
internalDict : Dict String (InternalFunction msg)
internalDict =
    Helper.buildInternalDict addressSchema addressProperties ignoreProperties


{-|
    Process Cmd dictionary.
-}
processDict : Dict String (ProcessFunction msg)
processDict =
    Helper.buildProcessDict addressSchema addressProperties ignoreProperties
