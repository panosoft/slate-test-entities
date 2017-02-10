module Slate.TestEntities.Common.Helper
    exposing
        ( InternalFunctionParams
        , InternalFunction
        , ProcessCmd
        , createDestroyData
        , addRemoveData
        , addRemoveReferenceData
        , buildInternalDict
        , buildProcessDict
        )

import String exposing (..)
import String.Extra as StringE
import Dict exposing (Dict)
import StringUtils exposing (..)
import Utils.Ops exposing (..)
import Slate.Command.Processor as CommandProcessor exposing (Config, Model)
import Slate.Command.Common.Command exposing (..)
import Slate.Common.Db exposing (..)
import Slate.Common.Schema exposing (..)
import Slate.Common.Event exposing (..)
import Slate.Common.Entity exposing (..)
import Slate.Common.Utils exposing (..)


createDestroyAddRemoveInternal : (schema -> Event -> Event) -> String -> String -> String -> String -> schema -> InternalFunction msg
createDestroyAddRemoveInternal validateFunction eventOp commandPrefix commandSuffix entityType schema mutatingEventData config dbConnectionInfo initiatorId model =
    let
        paddedCommandSuffix =
            (commandSuffix == "") ? ( "", " " ++ commandSuffix )
    in
        ( List.map (encodeMutatingEvent << validateFunction schema)
            [ { name = entityType +-+ eventOp
              , version = Nothing
              , data = Mutating <| mutatingEventData
              , metadata = { initiatorId = initiatorId, command = commandPrefix +-+ (toLower entityType) ++ paddedCommandSuffix }
              }
            ]
        , []
        )


propertySchema : String -> List PropertySchema -> PropertySchema
propertySchema propName propertySchemas =
    (List.head <|
        List.filter
            (\propSchema -> propSchema.name == propName)
            propertySchemas
    )
        ?!= (\_ -> Debug.crash <| "Invalid property name:" +-+ propName)


createDestroyInternal : String -> String -> String -> String -> EntitySchema -> InternalFunction msg
createDestroyInternal =
    createDestroyAddRemoveInternal validateEntityEventName


addRemoveInternal : String -> String -> String -> String -> PropertySchema -> InternalFunction msg
addRemoveInternal =
    createDestroyAddRemoveInternal validatePropertyEventName


createInternal : String -> EntitySchema -> InternalFunction msg
createInternal =
    createDestroyInternal "created" "Create" ""


destroyInternal : String -> EntitySchema -> InternalFunction msg
destroyInternal =
    createDestroyInternal "destroyed" "Destroy" ""


addInternal : String -> String -> PropertySchema -> InternalFunction msg
addInternal propName =
    addRemoveInternal (propName +-+ "added") "Add" (toLower propName)


removeInternal : String -> String -> PropertySchema -> InternalFunction msg
removeInternal propName =
    addRemoveInternal (propName +-+ "removed") "Remove" (toLower propName)


addPropertyInternal : String -> List PropertySchema -> String -> InternalFunction msg
addPropertyInternal entityType propertySchemas propName =
    addInternal propName entityType (propertySchema propName propertySchemas)


removePropertyInternal : String -> List PropertySchema -> String -> InternalFunction msg
removePropertyInternal entityType propertySchemas propName =
    removeInternal propName entityType (propertySchema propName propertySchemas)


process : InternalFunction msg -> ProcessCmd msg
process internal mutatingEventData config dbConnectionInfo initiatorId model =
    let
        ( events, lockEntityIds ) =
            internal mutatingEventData config dbConnectionInfo initiatorId model
    in
        CommandProcessor.process config dbConnectionInfo Nothing lockEntityIds events model


internalEntries : EntitySchema -> List PropertySchema -> List ( String, InternalFunction msg )
internalEntries entitySchema propertySchemas =
    let
        entityType =
            entitySchema.type_
    in
        List.append
            [ ( "create", createInternal entityType entitySchema )
            , ( "destroy", destroyInternal entityType entitySchema )
            ]
            (List.concat <|
                List.map
                    (\schema ->
                        [ ( "add" ++ (StringE.toTitleCase schema.name), addPropertyInternal entityType propertySchemas schema.name )
                        , ( "remove" ++ (StringE.toTitleCase schema.name), removePropertyInternal entityType propertySchemas schema.name )
                        ]
                    )
                    propertySchemas
            )



-- API


type alias InternalFunctionParams msg return =
    MutatingEventData -> Config msg -> DbConnectionInfo -> InitiatorId -> Model msg -> return


type alias InternalFunction msg =
    InternalFunctionParams msg ( List String, List EntityReference )


type alias ProcessCmd msg =
    InternalFunctionParams msg ( Model msg, Cmd msg, CommandId )


createDestroyData : EntityReference -> MutatingEventData
createDestroyData entityId =
    MutatingEventData entityId Nothing Nothing Nothing Nothing Nothing


addRemoveData : EntityReference -> String -> MutatingEventData
addRemoveData entityId value =
    MutatingEventData entityId (Just value) Nothing Nothing Nothing Nothing


addRemoveReferenceData : EntityReference -> EntityReference -> MutatingEventData
addRemoveReferenceData entityId refEntityId =
    MutatingEventData entityId Nothing (Just refEntityId) Nothing Nothing Nothing


buildInternalDict : EntitySchema -> List PropertySchema -> Dict String (InternalFunction msg)
buildInternalDict entitySchema propertySchemas =
    Dict.fromList <| internalEntries entitySchema propertySchemas


buildProcessDict : EntitySchema -> List PropertySchema -> Dict String (ProcessCmd msg)
buildProcessDict entitySchema propertySchemas =
    Dict.fromList <| List.map (\( name, f ) -> ( name, process f )) <| internalEntries entitySchema propertySchemas
