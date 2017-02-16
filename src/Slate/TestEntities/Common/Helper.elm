module Slate.TestEntities.Common.Helper
    exposing
        ( CommandFunctionParams
        , CommandPartResults
        , CommandPartFunction
        , CommandToCmdFunction
        , CommandFunction
        , propertySchema
        , createInternal
        , destroyInternal
        , addInternal
        , removeInternal
        , addPropertyInternal
        , removePropertyInternal
        , buildPartsDict
        , buildCommandDict
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
    Helper functions for developing Entity Command Processors and their usage easily.

@docs CommandFunctionParams, CommandPartResults, CommandPartFunction , CommandToCmdFunction , CommandFunction , propertySchema , createInternal , destroyInternal , addInternal , removeInternal , addPropertyInternal , removePropertyInternal , buildPartsDict , buildCommandDict , process , combine , asCmds , createDestroyData , durationData , addRemoveData , addRemoveReferenceData , positionData
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


createDestroyAddRemoveInternal : (schema -> Event -> Event) -> String -> String -> String -> String -> schema -> CommandPartFunction msg
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


createDestroyInternal : String -> String -> String -> String -> EntitySchema -> CommandPartFunction msg
createDestroyInternal =
    createDestroyAddRemoveInternal validateEntityEventName


addRemoveInternal : String -> String -> String -> String -> PropertySchema -> CommandPartFunction msg
addRemoveInternal =
    createDestroyAddRemoveInternal validatePropertyEventName


partsEntries : EntitySchema -> List PropertySchema -> List String -> List ( String, CommandPartFunction msg )
partsEntries entitySchema propertySchemas ignoreProperties =
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
    Common command function parameters.
-}
type alias CommandFunctionParams msg return =
    MutatingEventData -> Config msg -> DbConnectionInfo -> InitiatorId -> return


{-|
    Result of a CommandPartFunction.
-}
type alias CommandPartResults =
    ( List String, List EntityReference )


{-|
    Command part that can be combined with other command parts to be executed in a single transition.
-}
type alias CommandPartFunction msg =
    CommandFunctionParams msg CommandPartResults


{-|
    Function that takes a Command, CommandProcessor model and produces an executable Cmd.
-}
type alias CommandToCmdFunction msg =
    CommandProcessor.Model msg -> ( CommandProcessor.Model msg, Cmd msg, CommandId )


{-|
    Command function to create events in a single transition.
-}
type alias CommandFunction msg =
    CommandFunctionParams msg (CommandToCmdFunction msg)



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
createInternal : String -> EntitySchema -> CommandPartFunction msg
createInternal =
    createDestroyInternal "created" "Create" ""


{-|
    Create IntenalFunction for "destroy" event. Not usually used directly but here just in case.
-}
destroyInternal : String -> EntitySchema -> CommandPartFunction msg
destroyInternal =
    createDestroyInternal "destroyed" "Destroy" ""


{-|
    Create IntenalFunction for "add" event. Not usually used directly but here just in case.
-}
addInternal : String -> String -> PropertySchema -> CommandPartFunction msg
addInternal propName =
    addRemoveInternal (propName +-+ "added") "Add" (toLower propName)


{-|
    Create IntenalFunction for "remove" event. Not usually used directly but here just in case.
-}
removeInternal : String -> String -> PropertySchema -> CommandPartFunction msg
removeInternal propName =
    addRemoveInternal (propName +-+ "removed") "Remove" (toLower propName)


{-|
    Create IntenalFunction for "add" event from an Entity's Properties. Not usually used directly but here just in case.
-}
addPropertyInternal : String -> List PropertySchema -> String -> CommandPartFunction msg
addPropertyInternal entityType propertySchemas propName =
    addInternal propName entityType (propertySchema propName propertySchemas)


{-|
    Create IntenalFunction for "remove" event from an Entity's Properties. Not usually used directly but here just in case.
-}
removePropertyInternal : String -> List PropertySchema -> String -> CommandPartFunction msg
removePropertyInternal entityType propertySchemas propName =
    removeInternal propName entityType (propertySchema propName propertySchemas)


{-|
    Build default Command Parts Dictionary except for specified properties.
-}
buildPartsDict : EntitySchema -> List PropertySchema -> List String -> Dict String (CommandPartFunction msg)
buildPartsDict entitySchema propertySchemas ignoreProperties =
    Dict.fromList <| partsEntries entitySchema propertySchemas ignoreProperties


{-|
    Build default Command Dictionary except for specified properties.
-}
buildCommandDict : EntitySchema -> List PropertySchema -> List String -> Dict String (CommandFunction msg)
buildCommandDict entitySchema propertySchemas ignoreProperties =
    Dict.fromList <| List.map (\( name, f ) -> ( name, process Nothing f )) <| partsEntries entitySchema propertySchemas ignoreProperties



-- used by Apps or higher-level APIs


{-|
    Convert an CommandPartFunction to a CommandFunction with an optional Validator by passing it through the CommandProcessor.
-}
process : Maybe (ValidateTagger CommandProcessor.Msg msg) -> CommandPartFunction msg -> CommandFunction msg
process tagger internal mutatingEventData config dbConnectionInfo initiatorId model =
    let
        ( events, lockEntityIds ) =
            internal mutatingEventData config dbConnectionInfo initiatorId
    in
        CommandProcessor.process config dbConnectionInfo tagger lockEntityIds events model


{-|
    Combine a List of command part results into a single command part results.
-}
combine : List CommandPartResults -> CommandPartResults
combine parts =
    let
        ( listEvents, listLockEntityIds ) =
            parts
                |> List.foldr (\( events, lockEntityIds ) ( allEvents, allLockEntityIds ) -> ( events :: allEvents, lockEntityIds :: allLockEntityIds )) ( [], [] )
    in
        ( List.concat listEvents, List.concat listLockEntityIds )


{-|
    Takes a list of CommandToCmdFunctions and passes them sequentially and iteratively the CommandProcessor Model to produce a List of Cmds and a final CommandProcessor Model.
-}
asCmds : CommandProcessor.Model msg -> List (CommandToCmdFunction msg) -> ( CommandProcessor.Model msg, List ( CommandId, Cmd msg ) )
asCmds model commands =
    List.foldl
        (\createProcessCmd ( model, commands ) ->
            let
                ( newModel, cmd, commandId ) =
                    createProcessCmd model
            in
                ( newModel, List.append commands [ ( commandId, cmd ) ] )
        )
        ( model, [] )
        commands


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
