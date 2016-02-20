import Graphics.Element exposing (..)
import Mouse
import Window
import Keyboard
import Char

area : (Int, Int) -> Int
area (w,h) = w * h


-- Signal KeyCode |> Signal Char |> Signal Bool |> Signal Element
main : Signal Element
main =
  Keyboard.presses
    |> Signal.map Char.fromCode
    |> Signal.map Char.isDigit
    |> Signal.map show


-- Signal (Int,Int) |> Signal Int |> Signal Element
-- main : Signal Element
-- main =
--   Window.dimensions
--     |> Signal.map area
--     |> Signal.map show
