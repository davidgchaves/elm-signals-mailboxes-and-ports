import Graphics.Element exposing (Element, show)
import Mouse            exposing (clicks)


-- MODEL
type alias Model = Int


initialModel : Model
initialModel = 0


model : Signal Model
model =
  Signal.foldp (\_ count -> count + 1) initialModel Mouse.clicks


main : Signal Element
main =
  Signal.map Graphics.Element.show model
