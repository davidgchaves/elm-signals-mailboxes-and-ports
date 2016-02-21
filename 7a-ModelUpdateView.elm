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


-- VIEW
view : Model -> Element
view model =
  Graphics.Element.show model


-- GLUE IT ALL TOGETHER!
main : Signal Element
main =
  Signal.map view model
