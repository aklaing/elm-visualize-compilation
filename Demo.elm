
port module Demo exposing (..)

import Html.App as HtmlApp
import Array exposing (fromList, get)
import Dict exposing (Dict, fromList, update)

type State
    = Uncompiled
    | Compiling
    | Failed
    | Succeeded

-- Just a way to obtain an ordering on the states.
stateList: List State
stateList = [Uncompiled, Compiling, Failed, Succeeded]

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
   [ (Uncompiled, lightenColor 255 255 255)
   , (Compiling,  lightenColor 128 128 128)
   , (Failed,     lightenColor 255   0   0)
   , (Succeeded,  lightenColor   0 255   0)
   ]

getColorCode: Model -> String -> String
getColorCode model forFile =
   let
       forState = Dict.get forFile model |> Maybe.withDefault Uncompiled
       search alist =
           case alist of
               (state, color)::tl -> 
                    if state == forState then
                        color
                    else
                        search tl
               [] -> lightenColor 0 0 0
   in search colorCodes

type alias CompilerUpdate = {file: String, state: String}

type Msg
    = ChangeState CompilerUpdate

type alias Model = Dict String State
    
main : Program ()
main =
    HtmlApp.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions =
            (\_ -> Sub.batch [ compilerUpdates ChangeState ])
        }

port compilerUpdates : (CompilerUpdate -> msg) -> Sub msg

init: () -> ( Model, Cmd Msg )
init _ =
    (Dict.fromList
        (List.map (\filename -> (filename, Uncompiled))
             fileList)
    , Cmd.none
    )

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        ChangeState {file, state} ->
            let
                newState = 
                    case state of
                        "Uncompiled" -> Uncompiled
                        "Compiling" -> Compiling
                        "Failed" -> Failed
                        "Succeeded" -> Succeeded
                        _ -> Uncompiled
            in
               (Dict.update
                   file
                   (Maybe.map (\_ -> newState)) -- or: (\_ -> Just newState)
                   model) ! []


-- Above this line is project-indepdendent standard boilerplate.
------------------------------------------------------------------------
-- Below this line is automatically generated based on your project.


fileList: List String
fileList =
    [ "Colors"
    , "Editor"
    , "Common"
    , "Page"
    , "Types"
    , "Board"
    ]


view: Model -> Html Msg
view model =
  Svg.svg
    [ width "246pt"
    , viewBox "0.00 0.00 245.84 332.00"
    , height "332pt"
    ]
    [ g
        [ class "graph"
        , transform "scale(1 1) rotate(0) translate(4 328)"
        , id "graph0"
        ]
        [ Svg.title
            []
            [ Svg.text "project" ]
        , polygon
            [ stroke "none"
            , points "-4,4 -4,-328 241.845,-328 241.845,4 -4,4"
            , fill "white"
            ]
            []
        , g
            [ id "node1"
            , class "node"
            ]
            [ Svg.title
                []
                [ Svg.text "Common" ]
            , ellipse
                [ cy "-306"
                , cx "73.3977"
                , rx "44.393"
                , ry "18"
                , stroke "black"
                , fill (getColorCode model "Common")
                ]
                []
            , Svg.text'
                [ y "-302.3"
                , x "73.3977"
                , fontSize "14.00"
                , fontFamily "Times,serif"
                , textAnchor "middle"
                ]
                [ Svg.text "Common" ]
            ]
        , g
            [ id "node2"
            , class "node"
            ]
            [ Svg.title
                []
                [ Svg.text "Page" ]
            , ellipse
                [ cy "-90"
                , cx "85.3977"
                , rx "27.8951"
                , ry "18"
                , stroke "black"
                , fill (getColorCode model "Page")
                ]
                []
            , Svg.text'
                [ y "-86.3"
                , x "85.3977"
                , fontSize "14.00"
                , fontFamily "Times,serif"
                , textAnchor "middle"
                ]
                [ Svg.text "Page" ]
            ]
        , g
            [ id "edge1"
            , class "edge"
            ]
            [ Svg.title
                []
                [ Svg.text "Common->Page" ]
            , Svg.path
                [ stroke "black"
                , d "M101.552,-292.112C117.266,-283.263 135.435,-269.875 144.398,-252 168.038,-204.853 130.699,-145.853 105.461,-113.986"
                , fill "none"
                ]
                []
            , polygon
                [ stroke "black"
                , points "108.074,-111.652 99.0373,-106.121 102.652,-116.08 108.074,-111.652"
                , fill "black"
                ]
                []
            ]
        , g
            [ id "node3"
            , class "node"
            ]
            [ Svg.title
                []
                [ Svg.text "Types" ]
            , ellipse
                [ cy "-234"
                , cx "103.398"
                , rx "32.4942"
                , ry "18"
                , stroke "black"
                , fill (getColorCode model "Types")
                ]
                []
            , Svg.text'
                [ y "-230.3"
                , x "103.398"
                , fontSize "14.00"
                , fontFamily "Times,serif"
                , textAnchor "middle"
                ]
                [ Svg.text "Types" ]
            ]
        , g
            [ id "edge6"
            , class "edge"
            ]
            [ Svg.title
                []
                [ Svg.text "Common->Types" ]
            , Svg.path
                [ stroke "black"
                , d "M80.6598,-288.055C84.1237,-279.973 88.3456,-270.121 92.2069,-261.112"
                , fill "none"
                ]
                []
            , polygon
                [ stroke "black"
                , points "95.4801,-262.359 96.2024,-251.789 89.0461,-259.602 95.4801,-262.359"
                , fill "black"
                ]
                []
            ]
        , g
            [ id "node4"
            , class "node"
            ]
            [ Svg.title
                []
                [ Svg.text "Board" ]
            , ellipse
                [ cy "-162"
                , cx "43.3977"
                , rx "32.4942"
                , ry "18"
                , stroke "black"
                , fill (getColorCode model "Board")
                ]
                []
            , Svg.text'
                [ y "-158.3"
                , x "43.3977"
                , fontSize "14.00"
                , fontFamily "Times,serif"
                , textAnchor "middle"
                ]
                [ Svg.text "Board" ]
            ]
        , g
            [ id "edge4"
            , class "edge"
            ]
            [ Svg.title
                []
                [ Svg.text "Common->Board" ]
            , Svg.path
                [ stroke "black"
                , d "M69.779,-287.871C64.6435,-263.564 55.1903,-218.819 49.1047,-190.013"
                , fill "none"
                ]
                []
            , polygon
                [ stroke "black"
                , points "52.5207,-189.25 47.0292,-180.189 45.6719,-190.697 52.5207,-189.25"
                , fill "black"
                ]
                []
            ]
        , g
            [ id "node6"
            , class "node"
            ]
            [ Svg.title
                []
                [ Svg.text "Editor" ]
            , ellipse
                [ cy "-18"
                , cx "85.3977"
                , rx "32.4942"
                , ry "18"
                , stroke "black"
                , fill (getColorCode model "Editor")
                ]
                []
            , Svg.text'
                [ y "-14.3"
                , x "85.3977"
                , fontSize "14.00"
                , fontFamily "Times,serif"
                , textAnchor "middle"
                ]
                [ Svg.text "Editor" ]
            ]
        , g
            [ id "edge8"
            , class "edge"
            ]
            [ Svg.title
                []
                [ Svg.text "Common->Editor" ]
            , Svg.path
                [ stroke "black"
                , d "M58.2374,-288.787C33.6786,-260.523 -10.7974,-199.895 2.39765,-144 11.9274,-103.631 41.7117,-65.1225 62.8681,-41.7767"
                , fill "none"
                ]
                []
            , polygon
                [ stroke "black"
                , points "65.6937,-43.878 69.9442,-34.1732 60.5694,-39.1092 65.6937,-43.878"
                , fill "black"
                ]
                []
            ]
        , g
            [ id "edge11"
            , class "edge"
            ]
            [ Svg.title
                []
                [ Svg.text "Page->Editor" ]
            , Svg.path
                [ stroke "black"
                , d "M85.3977,-71.6966C85.3977,-63.9827 85.3977,-54.7125 85.3977,-46.1124"
                , fill "none"
                ]
                []
            , polygon
                [ stroke "black"
                , points "88.8978,-46.1043 85.3977,-36.1043 81.8978,-46.1044 88.8978,-46.1043"
                , fill "black"
                ]
                []
            ]
        , g
            [ id "edge2"
            , class "edge"
            ]
            [ Svg.title
                []
                [ Svg.text "Types->Page" ]
            , Svg.path
                [ stroke "black"
                , d "M101.226,-215.871C98.1587,-191.67 92.523,-147.211 88.87,-118.393"
                , fill "none"
                ]
                []
            , polygon
                [ stroke "black"
                , points "92.3064,-117.67 87.5766,-108.189 85.362,-118.55 92.3064,-117.67"
                , fill "black"
                ]
                []
            ]
        , g
            [ id "edge5"
            , class "edge"
            ]
            [ Svg.title
                []
                [ Svg.text "Types->Board" ]
            , Svg.path
                [ stroke "black"
                , d "M90.0817,-217.465C82.236,-208.311 72.1581,-196.554 63.3752,-186.307"
                , fill "none"
                ]
                []
            , polygon
                [ stroke "black"
                , points "65.8417,-183.807 56.6764,-178.492 60.5269,-188.362 65.8417,-183.807"
                , fill "black"
                ]
                []
            ]
        , g
            [ id "edge9"
            , class "edge"
            ]
            [ Svg.title
                []
                [ Svg.text "Types->Editor" ]
            , Svg.path
                [ stroke "black"
                , d "M109.9,-216.116C120.396,-186.316 138.358,-122.744 122.398,-72 119.064,-61.4023 112.776,-51.075 106.316,-42.3939"
                , fill "none"
                ]
                []
            , polygon
                [ stroke "black"
                , points "108.861,-39.9698 99.9026,-34.3125 103.377,-44.3213 108.861,-39.9698"
                , fill "black"
                ]
                []
            ]
        , g
            [ id "edge3"
            , class "edge"
            ]
            [ Svg.title
                []
                [ Svg.text "Board->Page" ]
            , Svg.path
                [ stroke "black"
                , d "M53.1389,-144.765C58.2808,-136.195 64.7013,-125.494 70.4574,-115.9"
                , fill "none"
                ]
                []
            , polygon
                [ stroke "black"
                , points "73.5655,-117.523 75.7093,-107.147 67.563,-113.921 73.5655,-117.523"
                , fill "black"
                ]
                []
            ]
        , g
            [ id "edge10"
            , class "edge"
            ]
            [ Svg.title
                []
                [ Svg.text "Board->Editor" ]
            , Svg.path
                [ stroke "black"
                , d "M41.6352,-143.736C40.3832,-125.404 40.157,-95.8415 48.3977,-72 52.0269,-61.5 58.3826,-51.1948 64.8132,-42.5041"
                , fill "none"
                ]
                []
            , polygon
                [ stroke "black"
                , points "67.7497,-44.4316 71.1706,-34.4042 62.2432,-40.1097 67.7497,-44.4316"
                , fill "black"
                ]
                []
            ]
        , g
            [ id "node5"
            , class "node"
            ]
            [ Svg.title
                []
                [ Svg.text "Colors" ]
            , ellipse
                [ cy "-90"
                , cx "203.398"
                , rx "34.394"
                , ry "18"
                , stroke "black"
                , fill (getColorCode model "Colors")
                ]
                []
            , Svg.text'
                [ y "-86.3"
                , x "203.398"
                , fontSize "14.00"
                , fontFamily "Times,serif"
                , textAnchor "middle"
                ]
                [ Svg.text "Colors" ]
            ]
        , g
            [ id "edge7"
            , class "edge"
            ]
            [ Svg.title
                []
                [ Svg.text "Colors->Editor" ]
            , Svg.path
                [ stroke "black"
                , d "M181.479,-75.9976C162.901,-64.9764 136.072,-49.0612 115.484,-36.8478"
                , fill "none"
                ]
                []
            , polygon
                [ stroke "black"
                , points "117.187,-33.7886 106.801,-31.6968 113.616,-39.809 117.187,-33.7886"
                , fill "black"
                ]
                []
            ]
        ]
    ]
