import Graphics.Element exposing (Element, show)
import Keyboard         exposing (presses)


-- Signal KeyCode
--   |> Signal Int (past dependant signal -- accumulate the number of key presses)
--   |> Signal ELement
main : Signal Element
main =
  Keyboard.presses
    |> Signal.foldp (\_ count -> count + 1) 0 -- STATE!
    |> Signal.map Graphics.Element.show
