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

{-|
    Person Entity.

@docs EntirePerson , EntirePersonDict , DefaultEntirePerson , Name , entirePersonShell , defaultEntirePerson , entirePersonEncode , entirePersonDecode , handleMutation , mutate
-}

import Dict exposing (..)
import Json.Encode as JE exposing (..)
import Json.Decode as JD exposing (..)
import Utils.Json as JsonU exposing ((///), (<||))
import Slate.Common.Entity exposing (..)
import Slate.Common.Mutation exposing (..)
import Slate.Common.Event exposing (..)
import Slate.Common.Reference exposing (..)
import Slate.TestEntities.PersonSchema exposing (..)
import Slate.TestEntities.AddressEntity exposing (..)
import Utils.Ops exposing (..)


-- Entity


{-| Entire Person
-}
type alias EntirePerson =
    { name : Maybe Name
    , age : Maybe Int
    , address : Maybe EntityReference
    }


{-| Entire Person Dictionary
-}
type alias EntirePersonDict =
    EntityDict EntirePerson


{-| Starting point for all subSets of Person
    since events are applied one at a time to build the final subSet entity
-}
entirePersonShell : EntirePerson
entirePersonShell =
    { name = Nothing
    , age = Nothing
    , address = Nothing
    }


{-| Default Entire Person Type
-}
type alias DefaultEntirePerson =
    { name : Name
    , age : Int
    , address : EntityReference
    }


{-| Default Entire Person
-}
defaultEntirePerson : DefaultEntirePerson
defaultEntirePerson =
    { name = defaultName
    , age = -1
    , address = ""
    }



-- Value Objects


{-|
    Person's name.
-}
type alias Name =
    { first : String
    , middle : String
    , last : String
    }


{-|
    Default Person's name.
-}
defaultName : Name
defaultName =
    { first = ""
    , middle = ""
    , last = ""
    }


{-|
    Name encode.
-}
nameEncode : Name -> JE.Value
nameEncode name =
    JE.object
        [ ( "first", JE.string name.first )
        , ( "middle", JE.string name.middle )
        , ( "last", JE.string name.last )
        ]


{-|
    Name decoder.
-}
nameDecoder : JD.Decoder Name
nameDecoder =
    JD.succeed Name
        <|| ("first" := JD.string)
        <|| ("middle" := JD.string)
        <|| ("last" := JD.string)



-- encoding/decoding


{-|
    Encode an Entire Person.
-}
entirePersonEncode : EntirePerson -> String
entirePersonEncode person =
    JE.encode 0 <|
        JE.object <|
            (List.filter (\( _, value ) -> value /= JE.null))
                [ ( "name", JsonU.encMaybe nameEncode person.name )
                , ( "age", JsonU.encMaybe JE.int person.age )
                , ( "address", JsonU.encMaybe entityReferenceEncode person.address )
                ]


{-|
    Decode an Entire Person.
-}
entirePersonDecode : String -> Result String EntirePerson
entirePersonDecode json =
    JD.decodeString
        ((JD.succeed EntirePerson)
            <|| ("name" := JD.maybe nameDecoder)
            <|| ("age" := JD.maybe JD.int)
            <|| ("address" := JD.maybe entityReferenceDecoder)
        )
        json


{-|
    Mutate Entire Address Dictionary based on an event.
-}
handleMutation : EntirePersonDict -> EntireAddressDict -> Event -> ( Result String EntirePersonDict, Maybe CascadingDelete )
handleMutation dict addresses event =
    case event.data of
        Mutating mutatingEventData ->
            let
                ( mutationResult, maybeDelete ) =
                    mutate event (lookupEntity dict event entirePersonShell) addresses
            in
                ( mutationResult
                    |??>
                        (\maybePerson ->
                            maybePerson
                                |?> (\person -> Dict.insert mutatingEventData.entityId person dict)
                                ?= Dict.remove mutatingEventData.entityId dict
                        )
                , maybeDelete
                )

        NonMutating _ ->
            ( Err "Cannot mutate with a non-mutating event", Nothing )


{-|
    Mutate the Person based on an event.
-}
mutate : Event -> EntirePerson -> EntireAddressDict -> ( Result String (Maybe EntirePerson), Maybe CascadingDelete )
mutate event entity addresses =
    let
        decodeName event =
            getConvertedValue (JD.decodeString nameDecoder) event

        setName value entity =
            { entity | name = value }

        setAge value entity =
            { entity | age = value }

        setAddress value entity =
            { entity | address = value }

        maybeDelete =
            buildCascadingDelete "Address" "Address destroyed" event.name entity.address personProperties

        maybeEntirePerson =
            case event.name of
                "Person created" ->
                    Ok <| Just entity

                "Person destroyed" ->
                    Ok Nothing

                "Person name added" ->
                    Result.map Just <| updatePropertyValue decodeName setName event entity

                "Person name removed" ->
                    Ok <| Just <| setName Nothing entity

                "Person age added" ->
                    Result.map Just <| updatePropertyValue getIntValue setAge event entity

                "Person age removed" ->
                    Ok <| Just <| setAge Nothing entity

                "Person address added" ->
                    Result.map Just <| updatePropertyReference setAddress event entity

                "Person address removed" ->
                    Ok <| Just <| setAddress Nothing entity

                _ ->
                    Debug.crash <| "You forgot to implement a handler for event name: " ++ event.name
    in
        ( maybeEntirePerson, maybeDelete )
