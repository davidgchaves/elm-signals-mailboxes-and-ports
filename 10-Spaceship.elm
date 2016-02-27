module Spaceship where

import Graphics.Element exposing (..)
import Graphics.Collage exposing (..)
import Color exposing (..)

import Keyboard
import Window
import Time


-- MODEL

type alias Model =
  { position: Int,
    powerLevel: Int,
    isFiring: Bool
  }


initialShip : Model
initialShip =
  { position = 0,
    powerLevel = 10,
    isFiring = False
  }


-- UPDATE

type Action
  = NoOp
  | Left
  | Right


update : Action -> Model -> Model
update action ship =
  case action of
    NoOp ->
      ship
    Left ->
      { ship | position = ship.position - 1 }
    Right ->
      { ship | position = ship.position + 1 }


-- VIEW

view : (Int, Int) -> Model -> Element
view (w, h) ship =
  let
    (w', h') = (toFloat w, toFloat h)
  in
    collage w h
      [ drawGame w' h',
        drawShip h' ship,
        toForm (show ship)
      ]


drawGame : Float -> Float -> Form
drawGame w h =
  rect w h
    |> filled gray


drawShip : Float -> Model -> Form
drawShip gameHeight ship =
  let
    shipColor =
      if ship.isFiring then red else blue
  in
    ngon 3 30
      |> filled shipColor
      |> rotate (degrees 90)
      |> move ((toFloat ship.position), (50 - gameHeight / 2))
      |> alpha ((toFloat ship.powerLevel) / 10)


{-
The Signal Transfomation:

Signal {x: Int, y: Int}
  |> Signal Int
  |> Signal Action
  |> Signal Action
  |> Signal Model
  |> Signal Element

Keyboard.arrows
  |> Signal.map .x                            -- direction
  |> Signal.map toAction                      -- direction
  |> Signal.sampleOn delta                    -- direction
  |> Signal.foldp update initialShip          -- model
  |> Signal.map2 view Window.dimensions model -- main
-}

direction : Signal Action
direction =
  let
    delta = Time.fps 30
    toAction n =
      case n of
        -1 -> Left
        1 -> Right
        _ -> NoOp
  in
    Keyboard.arrows
      |> Signal.map .x
      |> Signal.map toAction
      |> Signal.sampleOn delta


model : Signal Model
model =
  Signal.foldp update initialShip direction


main : Signal Element
main =
  Signal.map2 view Window.dimensions model
