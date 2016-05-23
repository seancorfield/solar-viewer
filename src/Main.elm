import Html exposing (Html, button, div, text)
import Html.App as App
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Http
import Regex
import String
import Svg exposing (line, svg)
import Svg.Attributes exposing (x1, x2, y1, y2, stroke, viewBox, width)
import Task
import Time exposing (Time)

size = 300

main =
  App.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model =
  { usage : List Float
  , latest : PowerUsage
  }

init : (Model, Cmd Msg)
init =
  (Model [] (PowerUsage 0.0 0.0 0.0 0.0), getPanelData)

type alias PowerUsage =
  { current : Float
  , today : Float
  , week : Float
  , life : Float
  }

power : String -> Float
power s =
  let
    vs =
      case List.head (Regex.find (Regex.AtMost 1) (Regex.regex "[.0-9]+") s) of
        Just m -> m.match
        Nothing -> "0"
    v =
      case String.toFloat vs of
        Err _ -> 0.0
        Ok  v -> v
    u =
      case List.head (Regex.find (Regex.AtMost 1) (Regex.regex "k?Wh?</td>") s) of
        Just m -> m.match
        Nothing -> "?"
  in
    if String.startsWith "W" u then v * 0.001 else v

powerUsage : List String -> PowerUsage
powerUsage ss =
  case (List.map power ss) of
    [c, t, w, l] -> PowerUsage c t w l
    _ -> PowerUsage 0.0 0.0 0.0 0.0

addUsage : Model -> Float -> Model
addUsage model n =
  let
    usage = (if List.length model.usage > size then List.drop 1 model.usage else model.usage) ++ [n]
  in
    { model | usage = usage }

-- UPDATE

type Msg
  = FetchFail Http.Error
  | FetchSucceed String
  | Tick Time

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of

    FetchFail _ ->
      init

    FetchSucceed page ->
      let
        pu = powerUsage (List.map .match (Regex.find Regex.All (Regex.regex "<tr>.*?</tr>") page))
        model' = addUsage model pu.current
      in
        ({ model' | latest = pu }, Cmd.none)

    Tick t ->
      (model, getPanelData)

-- VIEW

draw x y =
  line [ x1 (toString (2 * x))
       , y1 "400"
       , x2 (toString (2 * x))
       , y2 (toString (399 - (50 * y)))
       , stroke "#ff7700"
       ] []

view : Model -> Html Msg
view model =
  div [ style [("margin", "auto"), ("height", "400px"), ("width", "800px"), ("border", "1px solid blue")] ]
    [ div [ style [("float", "left")] ]
      [ svg [ viewBox "0 0 600 400", width "600px" ] (List.indexedMap draw model.usage) ]
    , div [ style [("float", "right"), ("width", "200px")] ]
      [ div [] [ text ("Current " ++ toString model.latest.current) ]
      , div [] [ text ("Today " ++ toString model.latest.today) ]
      , div [] [ text ("This Week " ++ toString model.latest.week) ]
      , div [] [ text ("Lifetime " ++ toString model.latest.life) ]
      ]
    ]

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Time.every Time.minute Tick

-- HTTP

getPanelData : Cmd Msg
getPanelData =
  Task.perform FetchFail FetchSucceed (Http.getString "http://10.0.0.11/production?locale=en")
