import Graphics.Element exposing (..)
import Keyboard
import Char


characters : Signal Char
characters =
  Signal.map Char.fromCode Keyboard.presses


main : Signal Element
main =
  Signal.map show characters
