import Graphics.Element exposing (Element, show)
import Mouse            exposing (clicks)


state : Signal Int
state =
  Signal.foldp (\_ count -> count + 1) 0 Mouse.clicks


main : Signal Element
main =
  Signal.map Graphics.Element.show state
