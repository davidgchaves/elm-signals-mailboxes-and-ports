import Graphics.Element exposing (..)
import Mouse
import Time


-- Signal (Int, Int) |> Signal (Int, Int) |> Signal Element
main : Signal Element
main =
  Mouse.position
    |> Signal.sampleOn Mouse.clicks
    |> Signal.map show
