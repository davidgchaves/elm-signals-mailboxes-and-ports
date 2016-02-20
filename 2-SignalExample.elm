import Graphics.Element exposing (show)
import Mouse
import Window
import Keyboard
import Time

main =
  -- show: a -> Element
  -- map: (a -> result) -> Signal a -> Signal result

  -- Keyboard.wasd : Signal { x : Int, y : Int }
  -- show: { x: Int, y: Int } -> Element
  -- map: ({ x: Int, y: Int } -> Element) -> Signal { x: Int, y: Int } -> Signal Element
  Signal.map show Keyboard.wasd
