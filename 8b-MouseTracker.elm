import Graphics.Element exposing (..)
import Graphics.Collage exposing (..)
import Color exposing (..)
import Mouse
import Window


drawCircle : Float -> Float -> Form
drawCircle x y =
  circle 50
    |> filled red
    |> move (x, y)


view : (Int, Int) -> Element
view (mouseX, mouseY) =
  let
    (w, h) = (300, 300)
    (w', h') = (toFloat w, toFloat h)
    x = toFloat mouseX - (w' / 2)
    y = (h' / 2) - toFloat mouseY
  in
    collage w h [ drawCircle x y ]


main : Signal Element
main =
  Signal.map view Mouse.position
