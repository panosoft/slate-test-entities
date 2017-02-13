module Slate.TestEntities.Common.Helper
    exposing
        ( InternalFunctionParams
        , InternalFunction
        , ProcessCmdParams
        , ProcessCmd
        , propertySchema
        , createInternal
        , destroyInternal
        , addInternal
        , removeInternal
        , addPropertyInternal
        , removePropertyInternal
        , buildInternalDict
        , buildProcessDict
        , process
        , combine
        , asCmds
        , createDestroyData
        , durationData
        , addRemoveData
        , addRemoveReferenceData
        , positionData
        )

import String exposing (..)
import String.Extra as StringE
import Dict exposing (Dict)
import StringUtils exposing (..)
import Utils.Ops exposing (..)
import Slate.Command.Processor as CommandProcessor exposing (Config, Model)
import Slate.Command.Common.Command exposing (..)
import Slate.Command.Common.Validator exposing (..)
import Slate.Common.Db exposing (..)
import Slate.Common.Schema exposing (..)
import Slate.Common.Event exposing (..)
import Slate.Common.Entity exposing (..)
import Slate.Common.Utils exposing (..)


createDestroyAddRemoveInternal : (schema -> Event -> Event) -> String -> String -> String -> String -> schema -> InternalFunction msg
createDestroyAddRemoveInternal validateFunction eventOp commandPrefix commandSuffix entityType schema mutatingEventData config dbConnectionInfo initiatorId =
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


createDestroyInternal : String -> String -> String -> String -> EntitySchema -> InternalFunction msg
createDestroyInternal =
    createDestroyAddRemoveInternal validateEntityEventName


addRemoveInternal : String -> String -> String -> String -> PropertySchema -> InternalFunction msg
addRemoveInternal =
    createDestroyAddRemoveInternal validatePropertyEventName


internalEntries : EntitySchema -> List PropertySchema -> List String -> List ( String, InternalFunction msg )
internalEntries entitySchema propertySchemas ignoreProperties =
    let
        entityType =
            entitySchema.type_
    in
        List.append
            [ ( "create", createInternal entityType entitySchema )
            , ( "destroy", destroyInternal entityType entitySchema )
            ]
            (propertySchemas
                |> List.filter (not << flip List.member ignoreProperties << .name)
                |> List.map
                    (\schema ->
                        [ ( "add" ++ (StringE.toTitleCase schema.name), addPropertyInternal entityType propertySchemas schema.name )
                        , ( "remove" ++ (StringE.toTitleCase schema.name), removePropertyInternal entityType propertySchemas schema.name )
                        ]
                    )
                |> List.concat
            )



-- API


type alias InternalFunctionParams msg return =
    MutatingEventData -> Config msg -> DbConnectionInfo -> InitiatorId -> return


type alias InternalFunction msg =
    InternalFunctionParams msg ( List String, List EntityReference )


type alias ProcessCmdParams msg return =
    MutatingEventData -> Config msg -> DbConnectionInfo -> InitiatorId -> Model msg -> return


type alias ProcessCmd msg =
    ProcessCmdParams msg ( Model msg, Cmd msg, CommandId )



-- used by Entity Command implementation


propertySchema : String -> List PropertySchema -> PropertySchema
propertySchema propName propertySchemas =
    (List.head <|
        List.filter
            (\propSchema -> propSchema.name == propName)
            propertySchemas
    )
        ?!= (\_ -> Debug.crash <| "Invalid property name:" +-+ propName)


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


buildInternalDict : EntitySchema -> List PropertySchema -> List String -> Dict String (InternalFunction msg)
buildInternalDict entitySchema propertySchemas ignoreProperties =
    Dict.fromList <| internalEntries entitySchema propertySchemas ignoreProperties


buildProcessDict : EntitySchema -> List PropertySchema -> List String -> Dict String (ProcessCmd msg)
buildProcessDict entitySchema propertySchemas ignoreProperties =
    Dict.fromList <| List.map (\( name, f ) -> ( name, process Nothing f )) <| internalEntries entitySchema propertySchemas ignoreProperties



-- used by Apps or higher-level APIs


process : Maybe (ValidateTagger CommandProcessor.Msg msg) -> InternalFunction msg -> ProcessCmd msg
process tagger internal mutatingEventData config dbConnectionInfo initiatorId model =
    let
        ( events, lockEntityIds ) =
            internal mutatingEventData config dbConnectionInfo initiatorId
    in
        CommandProcessor.process config dbConnectionInfo tagger lockEntityIds events model


combine : List ( List String, List EntityReference ) -> ( List String, List EntityReference )
combine operations =
    let
        ( listEvents, listLockEntityIds ) =
            operations
                |> List.foldr (\( events, lockEntityIds ) ( allEvents, allLockEntityIds ) -> ( events :: allEvents, lockEntityIds :: allLockEntityIds )) ( [], [] )
    in
        ( List.concat listEvents, List.concat listLockEntityIds )


asCmds : CommandProcessor.Model msg -> List (Model msg -> ( Model msg, Cmd msg, CommandId )) -> ( Model msg, List ( CommandId, Cmd msg ) )
asCmds model operations =
    List.foldl
        (\createProcessCmd ( model, commands ) ->
            let
                ( commandProcessorModel, cmd, commandId ) =
                    createProcessCmd model
            in
                ( commandProcessorModel, List.append commands [ ( commandId, cmd ) ] )
        )
        ( model, [] )
        operations


createDestroyData : EntityReference -> MutatingEventData
createDestroyData entityId =
    MutatingEventData entityId Nothing Nothing Nothing Nothing Nothing


durationData : EntityReference -> MutatingEventData
durationData entityId =
    MutatingEventData entityId Nothing Nothing Nothing Nothing Nothing


addRemoveData : EntityReference -> String -> MutatingEventData
addRemoveData entityId value =
    MutatingEventData entityId (Just value) Nothing Nothing Nothing Nothing


addRemoveReferenceData : EntityReference -> EntityReference -> MutatingEventData
addRemoveReferenceData entityId refEntityId =
    MutatingEventData entityId Nothing (Just refEntityId) Nothing Nothing Nothing


positionData : EntityReference -> EntityReference -> Int -> Int -> MutatingEventData
positionData entityId propertyId oldPosition newPosition =
    MutatingEventData entityId Nothing Nothing (Just propertyId) (Just oldPosition) (Just newPosition)
