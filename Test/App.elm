port module Test.App exposing (..)

import Dict exposing (Dict)
import Html exposing (..)
import Html.App
import Time exposing (Time, second)
import Process
import Task exposing (Task)
import ParentChildUpdate exposing (..)
import Slate.Common.Db exposing (..)
import Slate.Command.Common.Command exposing (..)
import Slate.Command.Processor as CommandProcessor
import Slate.TestEntities.AddressCommand as AddressCommand
import Slate.TestEntities.PersonCommand as PersonCommand
import Utils.Ops exposing (..)
import Utils.Error exposing (..)
import Utils.Log exposing (..)
import StringUtils exposing ((+-+), (+++))
import DebugF exposing (..)
import Slate.TestEntities.Common.Helper as Helper exposing (..)


port exitApp : Float -> Cmd msg


port externalStop : (() -> msg) -> Sub msg


dbConnectionInfo : DbConnectionInfo
dbConnectionInfo =
    { host = "postgresDBServer"
    , port_ = 5432
    , database = "test_entities"
    , user = "charles"
    , password = "testpassword"
    , timeout = 5000
    }


commandProcessorConfig : CommandProcessor.Config Msg
commandProcessorConfig =
    { routeToMeTagger = CommandProcessorModule
    , errorTagger = CommandProcessorError
    , logTagger = CommandProcessorLog
    , commandErrorTagger = CommandError
    , commandSuccessTagger = CommandSuccess
    }


type alias Model =
    { commandProcessorModel : CommandProcessor.Model Msg
    , commands : List ( CommandId, Cmd Msg )
    }


type Msg
    = Nop
    | DoCmd (Cmd Msg)
    | StartApp
    | NextCommand
    | CommandProcessorError ( ErrorType, ( CommandId, String ) )
    | CommandProcessorLog ( LogLevel, ( CommandId, String ) )
    | CommandProcessorModule CommandProcessor.Msg
    | CommandError ( CommandId, String )
    | CommandSuccess CommandId
    | CommandsComplete


initModel : ( Model, List (Cmd Msg) )
initModel =
    let
        ( commandProcessorModel, commandProcessorCmd ) =
            CommandProcessor.init commandProcessorConfig
    in
        ( { commandProcessorModel = commandProcessorModel
          , commands = []
          }
        , [ commandProcessorCmd ]
        )


init : ( Model, Cmd Msg )
init =
    let
        ( model, cmds ) =
            initModel
    in
        model ! (List.append cmds [ delayUpdateMsg StartApp (1 * second) ])


delayUpdateMsg : Msg -> Time -> Cmd Msg
delayUpdateMsg msg delay =
    Task.perform (\_ -> Nop) (\_ -> msg) <| Process.sleep delay


delayCmd : Cmd Msg -> Time -> Cmd Msg
delayCmd cmd =
    delayUpdateMsg <| DoCmd cmd


main : Program Never
main =
    Html.App.program
        { init = init
        , view = (\_ -> text "")
        , update = update
        , subscriptions = subscriptions
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        updateCommandProcessor =
            ParentChildUpdate.updateChildApp (CommandProcessor.update commandProcessorConfig) update .commandProcessorModel CommandProcessorModule (\model commandProcessorModel -> { model | commandProcessorModel = commandProcessorModel })
    in
        case msg of
            Nop ->
                model ! []

            DoCmd cmd ->
                model ! [ cmd ]

            StartApp ->
                let
                    applyParams3 p1 p2 p3 =
                        ((|>) p1) >> ((|>) p2) >> ((|>) p3)

                    fromDict : Dict String (ProcessCmd Msg) -> String -> ProcessCmd Msg
                    fromDict dict key =
                        Dict.get key dict ?!= (\_ -> Debug.crash ("Unable to find key:" +-+ "in dict:" +-+ dict))

                    fromAddress : String -> ProcessCmd Msg
                    fromAddress =
                        fromDict AddressCommand.processDict

                    fromPerson : String -> ProcessCmd Msg
                    fromPerson =
                        fromDict PersonCommand.processDict

                    ( commandProcessorModel, commands ) =
                        List.foldl
                            (\process ( model, commands ) ->
                                let
                                    ( commandProcessorModel, cmd, commandId ) =
                                        process model
                                in
                                    ( commandProcessorModel, List.append commands [ ( commandId, cmd ) ] )
                            )
                            ( model.commandProcessorModel, [] )
                            (List.map (applyParams3 commandProcessorConfig dbConnectionInfo "999888777")
                                [ (fromPerson "create") (createDestroyData "123")
                                , (fromPerson "create") (createDestroyData "456")
                                , (fromAddress "create") (createDestroyData "789")
                                , (fromPerson "addName") (addRemoveData "123" """{"first": "Joe", "middle": "", "last": "Mama"}""")
                                , (fromPerson "addName") (addRemoveData "456" """{"first": "Mickey", "middle": "", "last": "Mouse"}""")
                                , (fromAddress "addStreet") (addRemoveData "789" "Main Street")
                                , (fromPerson "addAddress") (addRemoveReferenceData "456" "789")
                                , (fromPerson "removeAddress") (addRemoveReferenceData "456" "789")
                                ]
                            )
                in
                    update NextCommand { model | commandProcessorModel = commandProcessorModel, commands = commands }

            NextCommand ->
                case model.commands of
                    ( _, next ) :: rest ->
                        { model | commands = rest } ! [ next ]

                    [] ->
                        update CommandsComplete model

            CommandsComplete ->
                let
                    l =
                        Debug.log "CommandsComplete" ""
                in
                    model ! []

            CommandProcessorError ( errorType, details ) ->
                let
                    l =
                        case errorType of
                            NonFatalError ->
                                DebugF.log "CommandProcessorError" details

                            _ ->
                                Debug.crash <| toString details
                in
                    model ! []

            CommandProcessorLog ( logLevel, details ) ->
                let
                    l =
                        DebugF.log "CommandProcessorLog" (toString logLevel ++ ":" +-+ details)
                in
                    model ! []

            CommandError ( commandId, error ) ->
                let
                    l =
                        Debug.log "CommandError" ( commandId, error )
                in
                    model ! []

            CommandSuccess commandId ->
                let
                    l =
                        Debug.log "CommandSuccess" commandId
                in
                    update NextCommand model

            CommandProcessorModule msg ->
                updateCommandProcessor msg model


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
