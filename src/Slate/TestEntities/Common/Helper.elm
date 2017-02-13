module Slate.TestEntities.Common.Helper
    exposing
        ( InternalFunction
        , ProcessToCmdFunction
        , ProcessFunction
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

{-|
    Helper functions for developing Entity Command Processors and their usage easy.
@docs InternalFunction , ProcessToCmdFunction , ProcessFunction , propertySchema , createInternal , destroyInternal , addInternal , removeInternal , addPropertyInternal , removePropertyInternal , buildInternalDict , buildProcessDict , process , combine , asCmds , createDestroyData , durationData , addRemoveData , addRemoveReferenceData , positionData
-}

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


{-|
    Internal function that can be combined with other internal functions to create multiple events in a single transition.
-}
type alias InternalFunction msg =
    MutatingEventData -> Config msg -> DbConnectionInfo -> InitiatorId -> ( List String, List EntityReference )


{-|
    Process function that takes a CommandProcessor model and produces an executable Cmd.
-}
type alias ProcessToCmdFunction msg =
    CommandProcessor.Model msg -> ( CommandProcessor.Model msg, Cmd msg, CommandId )


{-|
    Process function to create a single event in a single transition.
-}
type alias ProcessFunction msg =
    MutatingEventData -> Config msg -> DbConnectionInfo -> InitiatorId -> ProcessToCmdFunction msg



-- used by Entity Command implementation


{-|
    Retrieves the specified property schema from a list of property schemas. CRASHES if not found to prevent bad events in the DB.
-}
propertySchema : String -> List PropertySchema -> PropertySchema
propertySchema propName propertySchemas =
    (List.head <|
        List.filter
            (\propSchema -> propSchema.name == propName)
            propertySchemas
    )
        ?!= (\_ -> Debug.crash <| "Invalid property name:" +-+ propName)


{-|
    Create IntenalFunction for "create" event. Not usually used directly but here just in case.
-}
createInternal : String -> EntitySchema -> InternalFunction msg
createInternal =
    createDestroyInternal "created" "Create" ""


{-|
    Create IntenalFunction for "destroy" event. Not usually used directly but here just in case.
-}
destroyInternal : String -> EntitySchema -> InternalFunction msg
destroyInternal =
    createDestroyInternal "destroyed" "Destroy" ""


{-|
    Create IntenalFunction for "add" event. Not usually used directly but here just in case.
-}
addInternal : String -> String -> PropertySchema -> InternalFunction msg
addInternal propName =
    addRemoveInternal (propName +-+ "added") "Add" (toLower propName)


{-|
    Create IntenalFunction for "remove" event. Not usually used directly but here just in case.
-}
removeInternal : String -> String -> PropertySchema -> InternalFunction msg
removeInternal propName =
    addRemoveInternal (propName +-+ "removed") "Remove" (toLower propName)


{-|
    Create IntenalFunction for "add" event from an Entity's Properties. Not usually used directly but here just in case.
-}
addPropertyInternal : String -> List PropertySchema -> String -> InternalFunction msg
addPropertyInternal entityType propertySchemas propName =
    addInternal propName entityType (propertySchema propName propertySchemas)


{-|
    Create IntenalFunction for "remove" event from an Entity's Properties. Not usually used directly but here just in case.
-}
removePropertyInternal : String -> List PropertySchema -> String -> InternalFunction msg
removePropertyInternal entityType propertySchemas propName =
    removeInternal propName entityType (propertySchema propName propertySchemas)


{-|
    Build default Internal Dictionary except for specified properties.
-}
buildInternalDict : EntitySchema -> List PropertySchema -> List String -> Dict String (InternalFunction msg)
buildInternalDict entitySchema propertySchemas ignoreProperties =
    Dict.fromList <| internalEntries entitySchema propertySchemas ignoreProperties


{-|
    Build default Process Dictionary except for specified properties.
-}
buildProcessDict : EntitySchema -> List PropertySchema -> List String -> Dict String (ProcessFunction msg)
buildProcessDict entitySchema propertySchemas ignoreProperties =
    Dict.fromList <| List.map (\( name, f ) -> ( name, process Nothing f )) <| internalEntries entitySchema propertySchemas ignoreProperties



-- used by Apps or higher-level APIs


{-|
    Convert an InternalFunction to a ProcessFunction with an optional Validator by passing it through the CommandProcessor.
-}
process : Maybe (ValidateTagger CommandProcessor.Msg msg) -> InternalFunction msg -> ProcessFunction msg
process tagger internal mutatingEventData config dbConnectionInfo initiatorId model =
    let
        ( events, lockEntityIds ) =
            internal mutatingEventData config dbConnectionInfo initiatorId
    in
        CommandProcessor.process config dbConnectionInfo tagger lockEntityIds events model


{-|
    Combine a List of events and entity references tuple into a single tuple of events and entity references.
-}
combine : List ( List String, List EntityReference ) -> ( List String, List EntityReference )
combine operations =
    let
        ( listEvents, listLockEntityIds ) =
            operations
                |> List.foldr (\( events, lockEntityIds ) ( allEvents, allLockEntityIds ) -> ( events :: allEvents, lockEntityIds :: allLockEntityIds )) ( [], [] )
    in
        ( List.concat listEvents, List.concat listLockEntityIds )


{-|
    Takes a list of Process to Cmd functions and passes them sequentially and iteratively the CommandProcessor Model to produce a List of Cmds and a final CommandProcessor Model.
-}
asCmds : CommandProcessor.Model msg -> List (ProcessToCmdFunction msg) -> ( CommandProcessor.Model msg, List ( CommandId, Cmd msg ) )
asCmds model operations =
    List.foldl
        (\createProcessCmd ( model, commands ) ->
            let
                ( newModel, cmd, commandId ) =
                    createProcessCmd model
            in
                ( newModel, List.append commands [ ( commandId, cmd ) ] )
        )
        ( model, [] )
        operations


{-|
    Create mutating event data for a create/destroy event.
-}
createDestroyData : EntityReference -> MutatingEventData
createDestroyData entityId =
    MutatingEventData entityId Nothing Nothing Nothing Nothing Nothing


{-|
    Create mutating event data for a duration event.
-}
durationData : EntityReference -> MutatingEventData
durationData entityId =
    MutatingEventData entityId Nothing Nothing Nothing Nothing Nothing


{-|
    Create mutating event data for an add/remove event.
-}
addRemoveData : EntityReference -> String -> MutatingEventData
addRemoveData entityId value =
    MutatingEventData entityId (Just value) Nothing Nothing Nothing Nothing


{-|
    Create mutating event data for a add/remove reference event.
-}
addRemoveReferenceData : EntityReference -> EntityReference -> MutatingEventData
addRemoveReferenceData entityId refEntityId =
    MutatingEventData entityId Nothing (Just refEntityId) Nothing Nothing Nothing


{-|
    Create mutating event data for a position event.
-}
positionData : EntityReference -> EntityReference -> Int -> Int -> MutatingEventData
positionData entityId propertyId oldPosition newPosition =
    MutatingEventData entityId Nothing Nothing (Just propertyId) (Just oldPosition) (Just newPosition)
