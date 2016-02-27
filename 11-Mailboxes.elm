import Html exposing (..)
import Html.Events exposing (..)


view : String -> Html
view greeting =
  div []
    [ button
        [ on "click" targetValue (\_ -> Signal.message inbox.address "Hello") ]
        [ text "Click for English" ],
      button
        [ on "click" targetValue (\_ -> Signal.message inbox.address "Salut") ]
        [ text "Click for French" ],
      p [ ] [ text greeting ]
    ]


inbox : Signal.Mailbox String
inbox =
  Signal.mailbox "Waiting...."


messages : Signal String
messages =
  inbox.signal


main : Signal Html
main =
  Signal.map view messages
