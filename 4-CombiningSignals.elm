import Graphics.Element exposing (..)
import Mouse
import Window


leftOrRight : Int -> Int -> Element
leftOrRight x width =
  let
    middle = width // 2
    side   = if x > middle then "Right" else "Left"
  in
    show side


topOrBottom : Int -> Int -> Element
topOrBottom y height =
  let
    middle = height // 2
    side   = if y > middle then "Bottom" else "Top"
  in
    show side

-- Signal.map2 : (a -> b -> result) -> Signal a -> Signal b -> Signal result
-- Mouse.x : Signal Int
-- Mouse.y : Signal Int
-- Window.width : Signal Int
-- Window.height : Signal Int
main : Signal Element
main =
  Signal.map2 topOrBottom Mouse.y Window.height
