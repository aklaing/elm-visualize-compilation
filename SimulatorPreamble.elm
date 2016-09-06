port module Simulator exposing (..)

import Dict exposing (Dict, fromList, update, keys, map, empty)
import Set exposing (Set, empty, member, insert, remove)
import Array exposing (fromList, get)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Html exposing (..)
import Html.App as HtmlApp
import Time exposing (Time, second)
import Random

type State
    = Unready
    | Ready
    | Compiling
    | Failed
    | Succeeded

type alias Model =
    { unreadyNodes: Set String
    , readyNodes: Set String
    , compileTimes: Dict String Int
    , failedNodes: Set String
    , succeededNodes: Set String
    , nodeDependencies: Dict String (List String)
    , stasisCountdown: Int -- countdown for resting time between builds
    , maxCompilation: Int -- max duration of a compilation in ticks
    , inverseProbFailure: Int -- one node will fail 50:50 on average
    , maxNumThreads: Int -- max num simultaneous simulated compilations
    }

type Msg
    = Tick Time
    | RandListPair (List Int, List Int)

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

getColorCode: Model -> String -> String
getColorCode model forFile =
  let
      (r, g, b) =
          if Set.member forFile model.unreadyNodes then
              (255, 255, 255)  -- Unready/White
          else if Set.member forFile model.readyNodes then
              (128, 128, 128)  -- Ready/Gray
          else if Dict.member forFile model.compileTimes then
              (255, 255,   0)  -- Compiling/Yellow
          else if Set.member forFile model.failedNodes then
              (255,   0,   0)  -- Failed/Red
          else
              (  0, 255,   0)  -- Succeeded/Green
  in
      lightenColor r g b

main : Program Never
main =
    HtmlApp.program
        { init = init
        , view = view
        , update = update
        , subscriptions = 
            (\_ -> Time.every second Tick)
        }

dictLength: Dict String (List String) -> Int
dictLength dict = Dict.foldl (\ key val acc -> acc + 1) 0 dict

        
init: ( Model, Cmd Msg )
init =
   ({ unreadyNodes = Dict.keys fileDependencies |> Set.fromList
    , readyNodes = Set.empty
    , compileTimes = Dict.empty
    , failedNodes = Set.empty
    , succeededNodes = Set.empty
    , nodeDependencies = fileDependencies
    , stasisCountdown = 8 -- Number of ticks till restarting build.
    , maxCompilation = 5 -- longest possible compilation in ticks.
    , inverseProbFailure = 2 * (dictLength fileDependencies)
                           -- If there are N nodes, the probability of
                           -- a single node failure is set to 1/(2*N).
    , maxNumThreads = 4 -- pretending that the degree of parallelism
                        -- is bounded by the number of cores, which is
                        -- set to 4.
    }
   , Cmd.none
   )

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Tick time ->
            ( { model
                  | compileTimes =
                    decrementCompileTimes(model.compileTimes)
              }
            , Random.generate
                RandListPair
                  (Random.pair
                     (Random.list
                        model.maxNumThreads
                        (Random.int 1 model.maxCompilation))
                     (Random.list
                        model.maxNumThreads
                        (Random.int 0 model.inverseProbFailure))))

        RandListPair (durationList, flipList) ->
            ( model
                |> decideSuccessOrFailure flipList
                |> annotateNewReadyNodes
                |> chooseNodesToRun durationList
            , Cmd.none
            ) |> checkForBuildCompletion

-- Decrement every compile time.
decrementCompileTimes: Dict String Int -> Dict String Int
decrementCompileTimes compileTimes =
    Dict.map
        (\ nodeName nodeTime -> nodeTime - 1)
            compileTimes

-- Nodes whose compile time has become zero have finished compiling,
-- and we flip a coin to decide whether they succeeded or failed.  It
-- is a weighted coin that is likely to fail about one node per build
-- with a probablilty of 1/2, on average.  This ensures that on
-- average half of the builds fail and half of them succeed.
decideSuccessOrFailure: List Int -> Model -> Model
decideSuccessOrFailure flipList model =
    let
        newCompileTimes =
            Dict.filter
                (\ nodeName compileTime -> compileTime /= 0)
                model.compileTimes
        finishedCompileTimes =
            Dict.filter
                (\ nodeName compileTime -> compileTime == 0)
                model.compileTimes
        succeededOrFailed =
            List.map2
                (\flip nodeName ->
                     if flip == 0 then
                         (nodeName, Failed)
                     else
                         (nodeName, Succeeded))
                flipList
                (Dict.keys finishedCompileTimes)
        succeeded =
            List.filter
                (\ (nodeName, result) -> result == Succeeded)
                succeededOrFailed
            |> List.map fst
        failed =
            List.filter
                (\ (nodeName, result) -> result == Failed)
                succeededOrFailed
            |> List.map fst
    in
        { model
            | compileTimes = newCompileTimes
            , failedNodes =
                 Set.union model.failedNodes (Set.fromList failed)
            , succeededNodes =
                 Set.union model.succeededNodes (Set.fromList succeeded)
        }


computeNewlyReadySet: Model -> Set String
computeNewlyReadySet model =
    Set.filter
        (\ nodeName ->
             let
               dependencies =
                 Dict.get nodeName model.nodeDependencies
                   |> Maybe.withDefault []
             in
               List.all
                 (\nodeName ->
                   Set.member nodeName model.succeededNodes )
                 dependencies)
        model.unreadyNodes

-- Find and label nodes which can run -- they are the ones whose
-- ancestors have all succeeded.
annotateNewReadyNodes: Model -> Model
annotateNewReadyNodes model =
    let
        newlyReady = computeNewlyReadySet model
    in 
        { model
            | unreadyNodes =
                Set.diff model.unreadyNodes newlyReady
            , readyNodes =
                Set.union model.readyNodes newlyReady
        }

-- Among the nodes which can run we choose a few to run, to make the
-- number of running threads up to the maxNumThreads, at most.
chooseNodesToRun: List Int -> Model -> Model
chooseNodesToRun durationList model =
    let
        numSlots = clamp 0 model.maxNumThreads
                      (model.maxNumThreads -
                          (List.length (Dict.toList model.compileTimes)))
                   
        availableSlots = List.take numSlots durationList
        newRunners =
            List.map2
                (,)
                (Set.toList model.readyNodes)
                availableSlots
    in
        { model
            | readyNodes =
                newRunners
                |> List.map fst
                |> Set.fromList
                |> Set.diff model.readyNodes
            , compileTimes =
                Dict.union
                    model.compileTimes
                    (Dict.fromList newRunners)
        }

-- Check whether it is possible for anything to change on the next
-- round.  If not, we manage the stasisCountdown to ensure a short delay
-- followed by a restart.
checkForBuildCompletion: (Model, Cmd Msg) -> (Model, Cmd Msg)
checkForBuildCompletion (model, cmdMsg) =
    let
        buildHasStopped = -- There are no ready, or compiling nodes, or
                          -- nodes which can become ready in the next round.
            List.length(Set.toList model.readyNodes) +
            List.length(Dict.toList model.compileTimes) +
            List.length(Set.toList (computeNewlyReadySet model)) == 0
    in
        if buildHasStopped then
            if model.stasisCountdown == 0 then
                init -- start a new simulation
            else
                ({ model | stasisCountdown = model.stasisCountdown - 1 },
                     Cmd.none)
        else
            (model, cmdMsg)

