-- Display a string representing all the keypress characters.
-- Example:
--   after pressing 'a', 'b' and 'c'
--   the displayed string should be "abc".
import Graphics.Element exposing (Element, show)
import Keyboard         exposing (presses)
import Char             exposing (KeyCode, fromCode)
import String           exposing (fromChar)


-- MODEL
type alias Model = String


initialModel : Model
initialModel = ""


model : Signal Model
model =
  Signal.foldp update initialModel Keyboard.presses


-- UPDATE
update : KeyCode -> Model -> Model
update key model =
  let
    toString keyCode =
      keyCode |> Char.fromCode |> String.fromChar
  in
    model ++ toString key


-- VIEW
view : Model -> Element
view model =
  Graphics.Element.show model


-- GLUE IT ALL TOGETHER!
main : Signal Element
main =
  Signal.map view model
