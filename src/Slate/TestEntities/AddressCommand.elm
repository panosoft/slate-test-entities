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
import Slate.TestEntities.Common.Helper as Helper exposing (InternalFunction, ProcessCmd)


-- API


{-|
    Internal function dictionary.
-}
internalDict : Dict String (InternalFunction msg)
internalDict =
    Helper.buildInternalDict addressSchema addressProperties


{-|
    Process Cmd dictionary.
-}
processDict : Dict String (ProcessCmd msg)
processDict =
    Helper.buildProcessDict addressSchema addressProperties
