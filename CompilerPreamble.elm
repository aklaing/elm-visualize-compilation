port module CompilerUI exposing (..)

import Dict exposing (Dict, fromList, update, keys)
import Array exposing (fromList, get)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Html exposing (..)
import Html.App as HtmlApp

type State
    = Unready
    | Ready
    | Compiling
    | Failed
    | Succeeded

type alias Model = Dict String State

type alias CompilerUpdate = {file: String, state: String}

type Msg
    = ChangeState CompilerUpdate

-- Just a way to obtain an ordering on the states.
stateList: List State
stateList = [Unready, Ready, Compiling, Failed, Succeeded]

colorTranslator =
  Array.fromList
    [ "0", "1", "2", "3", "4", "5", "6", "7"
    , "8", "9", "a", "b", "c", "d", "e", "f"
    ]

toHex: Int -> String
toHex decimal =
  let
    loByte = decimal % 16
    hiByte = decimal // 16
    hiChar = Maybe.withDefault "0" (Array.get hiByte colorTranslator)
    loChar = Maybe.withDefault "0" (Array.get loByte colorTranslator)
  in
    hiChar ++ loChar

hexColor: Int -> Int -> Int -> String
hexColor r g b = "#" ++ toHex r ++ toHex g ++ toHex b

                 
lightenColor : Int -> Int -> Int -> String
lightenColor r g b =
  let 
    clamp v = if v >= 255 then 255 else v
    convert x = clamp (x + round(0.85 * toFloat(255 - x)))
    newR = convert r
    newG = convert g
    newB = convert b
  in
    hexColor newR newG newB

colorCodes: List (State, String)
colorCodes =
   [ (Unready, lightenColor 255 255 255)
   , (Ready, lightenColor 128 128 128)
   , (Compiling,  lightenColor 128 128   0)
   , (Failed,     lightenColor 255   0   0)
   , (Succeeded,  lightenColor   0 255   0)
   ]

getColorCode: Model -> String -> String
getColorCode model forFile =
   let
       forState = Dict.get forFile model |> Maybe.withDefault Unready
       search alist =
           case alist of
               (state, color)::tl -> 
                    if state == forState then
                        color
                    else
                        search tl
               [] -> lightenColor 0 0 0
   in search colorCodes

main : Program Never
main =
    HtmlApp.program
        { init = init
        , view = view
        , update = update
        , subscriptions =
            (\_ -> Sub.batch [ compilerUpdates ChangeState ])
        }

port compilerUpdates : (CompilerUpdate -> msg) -> Sub msg

init: ( Model, Cmd Msg )
init =
    (Dict.fromList
        (List.map (\filename -> (filename, Unready))
             (Dict.keys fileDependencies))
    , Cmd.none
    )

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        ChangeState {file, state} ->
            let
                newState = 
                    case state of
                        "Unready" -> Unready
                        "Ready" -> Ready
                        "Compiling" -> Compiling
                        "Failed" -> Failed
                        "Succeeded" -> Succeeded
                        _ -> Unready
            in
               (Dict.update
                   file
                   (Maybe.map (\_ -> newState))
                   model) ! []


