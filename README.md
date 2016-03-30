# Notes on *Mike Clark's Course: Elm Signals, Mailboxes & Ports*

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

### What is a `Mailbox`?

A `Mailbox` is a communication hub that can receive **messages** of a given type.

### What are `mailboxes` for?

In an `HTML` application we don't have built-in `Signals` to **react** to HTML inputs such us `buttons` and `forms`. That's what `mailboxes` are for (**react** to `HTML` inputs).

### What is a `Mailbox` made up of?

A `Mailbox` is made up of:

- An `Address` that you can send **messages** of type `a` to.
- A `Signal` of **messages** of type `a` sent to the `mailbox`.

```elm
type alias Mailbox a =
  { address : Address a,
    signal : Signal a
  }
```

### How does a `Mailbox` operate?

From a `Mailbox`'s associated `Signal` standpoint:

- The associated `Signal` is updated with the **message**, when a **message** is sent to the `Mailbox`'s `address`.
- The associated `Signal` contains all the **messages** sent to that `Mailbox`'s `address`.

### How to think about `Mailboxes`

You can think about `Mailboxes` as `Signals` that have an `address` you can send `messages` to.

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

#### 3. Send a message to the `Mailbox` when something happens

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

#### 4. Send a message to the `Mailbox` when something happens refactored (i)

It's more idiomatic to pass the `Signal`'s `address` into the `view` function instead of explicitly access `inbox.address`:

```elm
view : Signal.Address String -> String -> Html
view address greeting =
  div []
    [ button
        [ on "click" targetValue (\_ -> Signal.message address "Hello") ]
        [ text "Click for English" ],
      p [ ] [ text greeting ]
    ]
```

#### 5. Send a message to the `Mailbox` when something happens refactored (ii)

In this case we could also hide some of the boilerplate using the `onClick` handler

```elm
view : Signal.Address String -> String -> Html
view address greeting =
  div []
    [ button
        [ onClick address "Hello" ]
        [ text "Click for English" ],
      p [ ] [ text greeting ]
    ]
```

### `on "click"` vs `onClick`

```elm
[ on "click" targetValue (\_ -> Signal.message address "Hello") ]
[ onClick                                      address "Hello" ]
```

### From `on "click"` to `onClick` passing through `messageOn`

#### `on`

[`on`](http://package.elm-lang.org/packages/evancz/elm-html/4.0.2/Html-Events#on), defined in the `Html.Events` module:

```elm
on : String -> Json.Decoder a -> (a -> Signal.Message) ->
     Html.Attribute
on =
  VirtualDom.on
```

- 1st argument (`String`):
	- the name of the event to attach (`"click"`).
- 2nd argument (`Json.Decoder a`):
	- the decoder used to convert the JavaScript event to Elm ([`targetValue`](http://package.elm-lang.org/packages/evancz/elm-html/4.0.2/Html-Events#targetValue), a `Json.Decoder` for grabbing `event.target.value` from the triggered event).
- 3rd argument (`(a -> Signal.Message)`):
	- a function specifying what to do with the event when it occurs (`(\_ -> Signal.message address "Hello")`, sends the `"Hello"` message to the specified `address`).
- Return (`Html.Attribute`).

#### `onClick`
[`onClick`](http://package.elm-lang.org/packages/evancz/elm-html/4.0.2/Html-Events#onClick), defined in the `Html.Events` module:

```elm
onClick : Signal.Address a -> a -> Html.Attribute
onClick =
  messageOn "click"
```

#### `messageOn`

[`messageOn`](https://github.com/evancz/elm-html/blob/master/src/Html/Events.elm#L132), undocumented utility function used in every `onXXX` function

```elm
messageOn : String -> Signal.Address a -> a -> Html.Attribute
messageOn name address msg =
  on name value (\_ -> Signal.message address message)
```

where [`value`](http://package.elm-lang.org/packages/elm-lang/core/3.0.0/Json-Decode#value)

```elm
value : Decoder Value
value =
    Native.Json.decodeValue
```

#### Conclusion

So `onXXX` is just a wrapper around the primitive `on` function, which uses the `messageOn` utility function underneath.

### `Mailbox` related types

#### The `Mailbox` itself

```elm
Signal.Mailbox a
```

#### The associated `address`

```elm
Signal.Address a
```

#### The associated `signal`

```elm
Signal a
```

### Type constructors for `Mailbox` and `Address`

`Signal.Mailbox` and `Signal.Address` are type constructors, since you always have to give it another type as an argument (the `a`), such as `String` or `Int`, so:

- When we declare `Signal.Mailbox String` we get a type for a `mailbox` that has values (**messages**) of type `String`.
- When we declare `Signal.Address String` we get a type for an `address` where we can send values (**messages**) of type `String`.


## 12. `HTML` App Example

How to maintain state in an `HTML` application

### Workflow

#### 1. Create a `Mailbox` for `Actions` and initialize it

```elm
inbox : Signal.Mailbox Action
inbox =
  Signal.mailbox NoOp
```

#### 2. Tune in to its `Signal`

```elm
actions : Signal Action
actions =
  inbox.signal
```

#### 3. Update the `model` when new `actions` arrive

Every time we get an `action` on the `mailbox`'s `signal` we need to update our `Model` based on its previous state (hint: `foldp`)

```elm
model : Signal Model
model =
  Signal.foldp update initialModel actions
```

`model` always represents the current state of the app.

#### 4. Update `main` to use the `model` `Signal`

**Before**

```elm
main : Html
main =
  view initialModel
```

**After**

```elm
main : Signal Html
main =
  Signal.map view model
```

#### 5. Explicitly pass the `address` to the `view`

```elm
view : Signal.Address Action -> Model -> Html
```

#### 6. Fix `main` to explicitly pass the `address` to the `view`

```elm
main : Signal Html
main =
  Signal.map (view inbox.address) model
```

### The 3 `signals` of every `HTML` application

There's at least 3 `signals` in every `HTML` application that mantains state:

- `Signal Action`
	- Associated with the `Mailbox`.
	- Updates when `actions` are sent to the `Mailbox` in response to user events (i.e. a button click).
- `Signal Model`
	- `foldp` over the `Signal Action`.
	- Transforms the `model` to reflect updates in `Signal Action`.
- `Signal Html`
	- Renders the values on the `Signal Model` by applying the `view` function.

### Understanding `StartApp.Simple.start`

`StartApp.Simple.start`:

- Creates a `Mailbox`.
- Calls `foldp` with our `update` function.
- Uses our `initialModel` as the initial value of the `foldp`.
- Applies our `view` function to the resulting `Signal Model` to render new models.


We can think of `StartApp` as a wrapper around this boilerplate:

- Use `StarApp` if you can.
- Go full `Mailbox` + `Signals` if you need it.

### `StartApp` vs Explicit `Mailbox`

#### `StarApp`

```elm
import StartApp.Simple

main : Signal Html
main =
  StartApp.Simple.start
    { model = initialModel,
      view = view,
      update = update
    }
```

#### Explicit `Mailbox`

```elm
inbox : Signal.Mailbox Action
inbox =
  Signal.mailbox NoOp

actions : Signal Action
actions =
  inbox.signal

model : Signal Model
model =
  Signal.foldp update initialModel actions

main : Signal Html
main =
  Signal.map (view inbox.address) model
```

### Naming Conventions

#### With a `Signal Action`

```elm
inbox : Signal.Mailbox Action
inbox =
  Signal.mailbox NoOp

actions : Signal Action
actions =
  inbox.signal

model : Signal Model
model =
  Signal.foldp update initialModel actions
```

####  Without a `Signal Action`

```elm
actions : Signal.Mailbox Action
actions =
  Signal.mailbox NoOp

model : Signal Model
model =
  Signal.foldp update initialModel actions.signal
```


## 13. `Ports`

Another common use case for `Signals` in an `HTML App` is to communicate with Javascript, using `Ports`:

- Sending messages from Javascript into `Elm` through an **incoming `port`**.
- Sending messages from `Elm` to Javascript through an **outgoing `port`**.


### Embedding (integrating) `Elm` in an existing Javascript project

We need to:

1. Reference the compiled version of our `Elm App` (`thumbs.js`).
2. Have a placeholder to embed our `Elm App`.
3. Call `Elm.embed` to attach the `Elm App` into its `HTML` container (quite similar to `ReactDOM`'s `render` method).


```html
(1)
<head>
  <script type="text/javascript" src="thumbs.js"></script>
</head>

(2)
<body>
  <div id="elm-app-lives-here"></div>
</body>

(3)
<script type="text/javascript">
  Elm.embed(
    Elm.Thumbs,
    document.getElementById('elm-app-lives-here')
  );
</script>
```

### `Elm.embed`

Takes three arguments:

1. The name of the module where our `Elm App` is defined (remember that in Javascript land every `Elm Module` is namespaced with `Elm`, like in `Elm.Thumbs`).
2. The `HTML` element we want to embed our `Elm App` into.
3. **(OPTIONAL)** An object to give `Ports` an initial value.

### Create the compiled version of our `Elm App`

```console
✔ elm make Thumbs.elm --output thumbs.js
```

### Incoming `port` Example

1. Define the incoming `port` in your `Elm App` (you can name your `port` however you deem fit).
2. Give an initial value to the `signal` associated to your `port` (from your `Javascript App`).
3. Send messages to the `signal` from Javascript land using the `send()` function.

```elm
(1)
port comments : Signal String
```

```javascript
var elmApp = Elm.embed(
  Elm.Thumbs,
  document.getElementById('elm-app-lives-here'),
  (2)
  { comments: '' }
);

(3)
elmApp.ports.comments.send('My first comment');
```

### Outgoing `port` Example

1. Define the outgoing `port` in your `Elm App` (you can name your `port` however you deem fit).
2. Define the outgoing `port`.
3. Subscribe to the `port` from your `Javascript App`.

```elm
(1)
port modelChanges : Signal Model

(2)
port modelChanges =
  model

-- Where `model` was previously defined as
model : Signal Model
model =
  Signal.foldp update initialModel actions
```

```javascript
(3)
elmApp.ports.modelChanges.subscribe((model) => console.log(model));
```

### `Ports` and `Signals`

Elm `Ports` don't have to be Elm `Signals`, but they usually are.


## 14. Next Steps


### Elm Guides

- [The Elm Architecture Tutorial](https://github.com/evancz/elm-architecture-tutorial/).
- [The Reactivity Guide](http://elm-lang.org/guide/reactivity): More on `Signals` and `Tasks` premier.
- [The Interop Guide](http://elm-lang.org/guide/interop): More `Ports` examples.
- [The Elm Mailing List](https://groups.google.com/forum/#!forum/elm-discuss).

### Html Apps

- [Introducing Elm to a JS React/Flux Web App](http://tech.noredink.com/post/126978281075/walkthrough-introducing-elm-to-a-js-web-app): From `Flux` to Elm.
- Real World Elm [Part 1](http://engineering.truqu.com/2015/08/19/real-world-elm-part-1.html) and [Part 2](http://engineering.truqu.com/2015/09/25/real-world-elm-part-2.html) tutorials.

### Games

- [Switching from imperative to functional programming with games in Elm](https://github.com/Dobiasd/articles/blob/master/switching_from_imperative_to_functional_programming_with_games_in_Elm.md).
- [Making Pong: An intro to games in Elm](http://elm-lang.org/blog/making-pong).
- [Pong](http://elm-lang.org/examples/pong).
- [Breakout](https://github.com/Dobiasd/Breakout).
- [Asteroids clone](https://github.com/irh/asteroids).
- [Destroid](https://github.com/BlackBrane/destroid).
- [PewPew](https://github.com/FireflyLogic/pewpew).
- [Elm Street 404](https://github.com/zalando/elm-street-404).
