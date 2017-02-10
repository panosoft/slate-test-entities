module Slate.TestEntities.PersonCommand
    exposing
        ( internalDict
        , processDict
        )

{-|
    Person Commands.

@docs  internalDict, processDict
-}

import Dict exposing (Dict)
import Slate.TestEntities.PersonSchema exposing (..)
import Slate.TestEntities.Common.Helper as Helper exposing (InternalFunction, ProcessCmd)


-- API


{-|
    Internal function dictionary.
-}
internalDict : Dict String (InternalFunction msg)
internalDict =
    Helper.buildInternalDict personSchema personProperties


{-|
    Process Cmd dictionary.
-}
processDict : Dict String (ProcessCmd msg)
processDict =
    Helper.buildProcessDict personSchema personProperties
