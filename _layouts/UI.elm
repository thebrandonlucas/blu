module UI exposing (header, viewIconLink)

import Html exposing (..)
import Html.Attributes exposing (..)


header : Html Never
header =
    viewIconLink "Narsil Logo" "/"


viewIconLink : String -> String -> Html Never
viewIconLink name link =
    a [ href link ]
        [ img
            [ src "/images/favicon.png"
            , alt name
            , class "h-20"
            ]
            []
        ]
