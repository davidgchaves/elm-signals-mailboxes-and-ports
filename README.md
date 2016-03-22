# Notes on Mike Clark's Course: Elm Signals, Mailboxes & Ports

## 2. `Signal`s in Action

In `Elm`:

- A `Signal` is a value that changes over time.
- The `Signal` module is imported by default.


### Mapping `Signal`s with `Signal.map`

#### The types

```elm
Graphics.Element.show: a -> Element
Signal.map: (a -> result) -> Signal a -> Signal result
```

#### The `Mouse.position` `Signal`

```elm
-- Mouse.position: Signal (Int, Int)
-- Graphics.Element.show: (Int, Int) -> Element
-- Signal.map: ((Int, Int) -> Element) -> Signal (Int, Int) -> Signal Element
Signal.map show Mouse.position
```

#### The `Window.dimensions` `Signal`

```elm
-- Window.dimensions: Signal (Int, Int)
-- Graphics.Element.show: (Int, Int) -> Element
-- Signal.map: ((Int, Int) -> Element) -> Signal (Int, Int) -> Signal Element
Signal.map show Window.dimensions
```

#### The `Keyboard.arrows` `Signal`

```elm
-- Keyboard.arrows: Signal { x: Int, y: Int }
-- Graphics.Element.show: { x: Int, y: Int } -> Element
-- Signal.map: ({ x: Int, y: Int } -> Element) -> Signal { x: Int, y: Int } -> Signal Element
Signal.map show Keyboard.arrows
```

#### The `Time.every` function

```elm
-- Time.every: Time -> Signal Time
-- Graphics.Element.show: Time -> Element
-- Signal.map: (Time -> Element) -> Signal Time -> Signal Element
Signal.map show (Time.every Time.second)
```

## 3. Transforming Signals

In order to react to the changing values on a `Signal`, we need to apply a function to the `Signal`.

### Supported types for `main`

```elm
main : Element || Html || Signal Element || Signal Html
main =
```

### Transforming `Window.dimensions`

```elm
area : (Int, Int) -> Int
area (w,h) = w * h

-- Signal (Int,Int) |> Signal Int |> Signal Element
main : Signal Element
main =
  Window.dimensions
    |> Signal.map area
    |> Signal.map show
```

### Transforming `Keyboard.presses`

```elm
-- Signal KeyCode |> Signal Char |> Signal Bool |> Signal Element
main : Signal Element
main =
  Keyboard.presses
    |> Signal.map Char.fromCode
    |> Signal.map Char.isDigit
    |> Signal.map show
```

## 4. Combining Signals with `Signal.map2`

### `Signal.map2`

```elm
Signal.map2 : (a -> b -> c) -> Signal a -> Signal b -> Signal c
```

### Example of `Signal.map2`

```elm
-- Mouse.x      : Signal Int
-- Window.width : Signal Int

leftOrRight : Int -> Int -> Element
leftOrRight x width =
  let
    middle = width // 2
    side   = if x > middle then "Right" else "Left"
  in
    show side

main : Signal Element
main =
  Signal.map2 leftOrRight Mouse.x Window.width
```

## 5. Filtering Signals

A `unit` in `Elm`: **(expand on this)**

```elm
()
```

### Filtering with `Signal.sampleOn`
#### Example: Get the position where the user clicks.

There's 2 different signals involved:

- `Mouse.position`
- `Mouse.clicks`

```elm
-- The current mouse position.
Mouse.position : Signal (Int, Int)

-- Always equal to unit ().
-- Event triggers on every mouse click.
Mouse.clicks : Signal ()
```

We can combine them with `Signal.sampleOn`, which allows us to:

- sample from the second input (`Signal b`)
- every time an event occurs on the first input (`Signal a`)

```elm
Signal.sampleOn : Signal a -> Signal b -> Signal b
```

Order matters, in this case. If we want **the position**, according to the `Signal.sampleOn` type definition, we need `Mouse.position` to be `Signal b`. So `Mouse.clicks` needs to be `Signal a`:

```elm
Signal.sampleOn Mouse.clicks Mouse.position
```

Somehow, we have composed a new `Signal` that only *broadcasts* its `Mouse.position` when the `Mouse.clicks` occurs:

```elm
positionOnClick : Signal (Int, Int)
positionOnClick = Signal.sampleOn Mouse.clicks Mouse.position
```

As usual, if we want to *peek* inside the `Signal` we can `Signal.map` over it:

```elm
main : Signal Element
main = Signal.map show positionOnClick
```

Alternatively we could use the `|>` operator, which I like to use as much as I can:

```elm
-- Signal (Int, Int) |> Signal (Int, Int) |> Signal Element
main : Signal Element
main =
  Mouse.position
    |> Signal.sampleOn Mouse.clicks
    |> Signal.map show
```

### Filtering with `Signal.filter`
#### Example: Detect the numbers pressed by a user

We need to start with `Keyboard.presses`:

```elm
-- The latest key that has been pressed.
Keyboard.presses : Signal KeyCode
```

The **1st transformation** is from `Signal KeyCode` to `Signal Char`. So we can use `Char.fromCode`:

```elm
-- Convert from unicode to actual char value.
Char.fromCode : KeyCode -> Char
```

like this:

```elm
Keyboard.presses
  |> Signal.map Char.fromCode
```

The **2nd tranformation** is from `Signal Char` to `Signal Char`. Here is where we apply the actual **filtering** (anything that's not a number need to go away). So we can use the `Signal.filter` function:

```elm
Signal.filter : (a -> Bool) -> a -> Signal a -> Signal a
```

Which receives:

- A `Predicate` to determine whether to keep a `Signal` value.
- A default value.
- A `Signal` we want to filter on.

As the `Predicate` we could use `Char.isDigit`:

```elm
-- True for ASCII digits [0-9].
Char.isDigit : Char -> Bool
```

The default value could be `'0'` (**GOTCHA**: we need a `Char`, neither a `Number` `0` nor a `String` `"0"`, so `'0'` it is)

The `Signal` to filter on is the result from our **1st transformation**.

We end up with something like this:

```elm
Keyboard.presses
  |> Signal.map Char.fromCode
  |> Signal.filter Char.isDigit "0"
```

The **3rd (and final) transformation** will allow us  to *peek* inside the `Signal` from the **2nd transformation**. From `Signal Char` to `Signal Element`.

We just `Signal.map` `show` over the **2nd transformation**:

```elm
-- Signal KeyCode |> Signal Char |> Signal Char |> Signal Element
main : Signal Element
main =
  Keyboard.presses
    |> Signal.map Char.fromCode
    |> Signal.filter Char.isDigit "0"
    |> Signal.map show
```

#### Example: Detect the numbers pressed by a user with no repeats

We could easily insert a new **transformation** between the **2nd** and the **3rd** to filter out repetitions (pressing several times in a row the same number). We could use `Signal.dropRepeats`:

```elm
-- Drop updates that repeat the current value of the signal.
Signal.dropRepeats : Signal a -> Signal a
```

like this:

```elm
-- Signal KeyCode |> Signal Char |> Signal Char |> Signal Char |> Signal Element
main : Signal Element
main =
  Keyboard.presses
    |> Signal.map Char.fromCode
    |> Signal.filter Char.isDigit "0"
    |> Signal.dropRepeats
    |> Signal.map show
```

#### The `Result` type

A `Result` is:

- `Ok value` (meaning the computation succeeded)
- `Err error` (meaning that there was some failure)

```elm
type Result error value
    = Ok value
    | Err error
```

#### The `Maybe` type

A `Maybe a` is:

- `Just a` (the value exists)
- `Nothing` (the value does not exist)

```elm
type Maybe a
    = Just a
    | Nothing
```

#### Filtering with `Signal.filterMap`

- When the filter function returns
	- `Just a`, we send that `a` value along.
	- `Nothing`, we drop it.
- If the initial value of the incoming signal turns into `Nothing`, we use the default `b` value provided.

```elm
Signal.filterMap : (a -> Maybe b) -> b -> Signal a -> Signal b
```

Ideal to pair with `Maybe` values (swallows the `Nothing`s).


## 6. Maintaining state

In Elm programs we maintain state by creating a past-dependant `Signal` (typically using `Signal.foldp`).

That past-dependant `Signal` always represents the current state and its updated by folding `Signal` values from the past.


### `fold`ing `List`s from `l`eft to right

```elm
--  Reduce a list from the left.
List.foldl : (a -> b -> b) -> b -> List a -> b

-- Example 1
List.foldl (::) [] [1,2,3] == [3,2,1]

-- Example 2
List.foldl (\x acc -> acc + x) 0 [1..3] == 6
```

### `fold`ing `Signal`s from the `p`ast

`Signal.foldp` creates a past-dependent `Signal`:

- Each update from the incoming `Signal`s will be used to step the state forward.
- The outgoing `Signal` represents the current state.

```elm
Signal.foldp : (a -> state -> state) -> state -> Signal a
             -> Signal state
```

### Comparing `List.foldl` and `Signal.foldp` signatures

```elm
List.foldl   : (a -> b -> b) -> b -> List a   -> b
Signal.foldp : (a -> b -> b) -> b -> Signal a -> Signal b
```

In both cases `b` represents the *accumulator* or the *state*.


## 7. Model-Update-View pattern

The `Model-Update-View` pattern is the core of every `Elm` application:

- The `Model` `Signal` represents the current application state.
- The `Update` function transforms the `Model` from one state to the next.
- The `View` function renders the `Model`.

### The `Model` `Signal`

Represents the current application state.

```elm
type alias Model = Int

initialModel : Model
initialModel = 0

model : Signal Model
model =
  Signal.foldp update initialModel Mouse.clicks
```

### The `Update` function

Transforms the `Model` from one state to the next.

```elm
update : a -> Model -> Model
update event model =
  model + 1
```

### The `View` function

Renders the `Model`.

```elm
view : Model -> Element
view model =
  Graphics.Element.show model
```

### The `main` glue function

```Elm
main : Signal Element
main =
  Signal.map view model
```

## 8. Game example

`Signals` play a big role in canvas-based games (you need to react to different inputs).

Plug-in some `Signals` to add dynamics to the game.

### `Signal` transformation

We transform an initial `Signal` of `Keyboard.arrows` into a `Signal Element` so we can **react** to the input keyboard arrows by moving the ship left or right.

```elm
Signal {x: Int, y: Int}
  |> Signal Int                           -- direction
  |> Signal Model                         -- model
  |> Signal Element                       -- main

Keyboard.arrows
  |> Signal.map .x                        -- direction
  |> Signal.foldp update initialShip      -- model
  |> Signal.map view                      -- main
```

The missing piece is the `update` function, that we use to `foldp` the ship's position:

```elm
update : Int -> Model -> Model
update x ship =
  { ship | position = ship.position + x }
```

## 9. Designing with `actions`

In order to make our apps more expresive, we could use a **technique** that consists in designing `signal values` as `actions` that describe the way our `models` can be updated.

**Before**

```elm
update : Int -> Model -> Model
update x ship =
  { ship | position = ship.position + x }
```

**After**

```elm
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

```

- `update` now clearly defines all the ways in which the `model` (the `ship`) can be `update`d.
- Better *separation of concerns* between `Signals` and the `update` function.


## 10. Merging `Signals`

```elm
Signal.merge : Signal a -> Signal a -> Signal a
```
```elm
Signal.mergeMany : List (Signal a) -> Signal a
```

### Add new effects to your App

1. Add a new `Action` type.
2. Pattern match the new `Action` type in the `update` function.
3. Create a `Signal` to produce the new `Action` type values.
4. `merge` or `mergeMany` the new `Signal` to the old ones.

### The `update model input` pattern

```elm
input : Signal Action
input =
  Signal.mergeMany [direction, fire, ticker]


model : Signal Model
model =
  Signal.foldp update initialShip input
```

- `mergeMany` your `Signals` from a same `Action` into an `input` `Signal`.
- `foldp` over them.

### Decoupling `Signals`

You want your `Signals` to live around the edges of your application and not to be intertwined with the Core of your app.

### Constructor functions

```elm
type Action = NoOp | Left | Right | Fire Bool

NoOp : Action
Left : Action
Right : Action

Fire : Bool -> Action
```

`Fire` is a **constructor function** that takes a `Bool` and returns an `Action` (because the Fire value has an associated Bool value).

We can easily `Signal.map` values to `actions`:

```elm
fire = Signal.map (\b -> Fire b) Keyboard.space
fire = Signal.map Fire           Keyboard.space

ticker = Signal.map (\t -> Tick t) (Time.every Time.second)
ticker = Signal.map Tick           (Time.every Time.second)
```

## 11. Mailboxes

In an HTML App we don't have built-in 'Signals' for HTML inputs (such us `buttons`, `forms` ...).

That's what `mailboxes` are for.

To **react** to HTML inputs we use a `mailbox`.

### What is a `Mailbox`?

- A `Mailbox` is a communication hub (can receive messages).

### What is a `Mailbox` made up of?

- A `Mailbox` is made up of:
	- an `Address` that you can send messages to
	- a `Signal` of messages sent to the `mailbox`

```elm
type alias Mailbox a =
  { address : Address a,
    signal : Signal a
  }
```

### How does a `Mailbox` operate?

- When a **message** is sent to a `mailbox`'s `address`, the associated `Signal` is updated with the **message**.
- The associated `Signal` have all the **messages** sent to that `Mailbox`'s `address`.

### The `Mailbox` cycle

#### 1. Create a `Mailbox`

Use `Signal.mailbox`

```elm
-- Create a mailbox you can send messages to
Signal.mailbox : a -> Mailbox a
```

Example

```elm
inbox : Signal.Mailbox String
inbox =
  Signal.mailbox "Waiting...."
```

#### 2. Tune in to its `Signal`

To subscribe to a `Mailbox` we need to tune in to its `Signal`.

Example

```elm
messages : Signal String
messages =
  inbox.signal
```

#### 3. Send a message to the `Mailbox` when something happened


Example: *When we click a button*

```elm
view : String -> Html
view greeting =
  div []
    [ button
        [ on "click" targetValue (\_ -> Signal.message inbox.address "Hello") ]
        [ text "Click for English" ],
      p [ ] [ text greeting ]
    ]
```


### `on "click"` vs `onClick`

```elm
[ on "click" targetValue (\_ -> Signal.message inbox.address "Hello") ]
[ onClick                                      inbox.address "Hello" ]
```

### TODOs:

- Take notes from 11 Mailboxes Notes
- Take notes from 12 Html App Example
- Take notes from 13 Ports
- Take notes from 14 Wrap Up
