module Home exposing (header, layout, main, markdown)

import Elmstatic exposing (..)
import Html exposing (..)
import Html.Attributes exposing (alt, attribute, class, href, src)
import Markdown


markdown : String -> Html Never
markdown s =
    let
        mdOptions : Markdown.Options
        mdOptions =
            { defaultHighlighting = Just "elm"
            , githubFlavored = Just { tables = False, breaks = False }
            , sanitize = False
            , smartypants = True
            }
    in
    Markdown.toHtmlWith mdOptions [ attribute "class" "markdown" ] s


header : List (Html Never)
header =
    [ div [ class "header-logo" ]
        [ img [ alt "Author's blog", src "/img/logo.png", attribute "width" "100" ]
            []
        ]
    , div [ class "navigation" ]
        [ ul []
            [ li []
                [ a [ href "/posts" ]
                    [ text "Posts" ]
                ]
            , li []
                [ a [ href "/about" ]
                    [ text "About" ]
                ]
            , li []
                [ a [ href "/contact" ]
                    [ text "Contact" ]
                ]
            ]
        ]
    ]


layout : String -> List (Html Never) -> List (Html Never)
layout title contentItems =
    header
        ++ [ div [ class "content" ]
                (h1 [ class "unifrakturmaguntia-regular text-6xl" ] [ text title ] :: contentItems)
           , Elmstatic.stylesheet "/styles.css"
           ]


main : Elmstatic.Layout
main =
    Elmstatic.layout Elmstatic.decodePage <|
        \content ->
            Ok <| layout content.title [ markdown content.content ]
