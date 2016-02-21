import Graphics.Element exposing (Element, show)
import Mouse            exposing (clicks)


-- MODEL
type alias Model = Int


initialModel : Model
initialModel = 0


model : Signal Model
model =
  Signal.foldp update initialModel Mouse.clicks


-- UPDATE
update : a -> Model -> Model
update event model =
  model + 1


main : Signal Element
main =
  Signal.map Graphics.Element.show model
