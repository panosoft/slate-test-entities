module Slate.TestEntities.AddressSchema
    exposing
        ( addressSchema
        , addressProperties
        )

{-|
    Address Schema.

@docs addressSchema , addressProperties
-}

import Slate.Common.Schema exposing (..)


{-|
    Address Schema.
-}
addressSchema : EntitySchema
addressSchema =
    { type_ = "Address"
    , eventNames =
        [ "Address created"
        , "Address destroyed"
        ]
    , properties = addressProperties
    }


{-|
    Address Properties.
-}
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
