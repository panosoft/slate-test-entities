module Slate.TestEntities.PersonSchema
    exposing
        ( personSchema
        , personProperties
        )

{-|
    Person Schema.

@docs personSchema , personProperties
-}

import Slate.Common.Schema exposing (..)
import Slate.TestEntities.AddressSchema exposing (..)


{-|
    Person Schema.
-}
personSchema : EntitySchema
personSchema =
    { type_ = "Person"
    , eventNames =
        [ "Person created"
        , "Person destroyed"
        ]
    , properties = personProperties
    }


{-|
    Person Properties.
-}
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
