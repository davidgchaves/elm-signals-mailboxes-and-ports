import Graphics.Element exposing (Element, show)
import Time             exposing (every, second)


-- display a count of the seconds the program has been running so far

-- Signal Time
--   |> Signal Int (past dependant signal)
--   |> Signal Element
main : Signal Element
main =
  Time.every Time.second
    |> Signal.foldp (\_ count -> count + 1) 0 -- STATE!
    |> Signal.map Graphics.Element.show
