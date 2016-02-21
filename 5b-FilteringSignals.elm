import Graphics.Element exposing (..)
import Keyboard
import Char


-- Signal KeyCode |> Signal Char |> Signal Char |> Signal Char |> Signal Element
main : Signal Element
main =
  Keyboard.presses
    |> Signal.map Char.fromCode
    |> Signal.filter Char.isDigit '0'
    |> Signal.dropRepeats
    |> Signal.map show
