import Graphics.Element exposing (Element, show)
import Keyboard         exposing (presses)
import Char             exposing (fromCode)
import String           exposing (toInt, fromChar)


toResultInt : Char -> Result String Int
toResultInt c =
  c |> String.fromChar |> String.toInt


toMaybeInt : Char -> Maybe Int
toMaybeInt c =
  case toResultInt c of
    Ok  value -> Just value
    Err _     -> Nothing

-- add up pressed numbers

-- Signal KeyCode
--   |> Signal Char
--   |> Signal Int
--   |> Signal Int (past dependant signal)
--   |> Signal Element
main : Signal Element
main =
  Keyboard.presses
    |> Signal.map Char.fromCode
    |> Signal.filterMap toMaybeInt 0
    |> Signal.foldp (+) 0 -- Sum the numbers pressed
    |> Signal.map Graphics.Element.show
