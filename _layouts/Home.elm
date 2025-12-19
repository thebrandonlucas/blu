module Home exposing (header, layout, main, markdown)

import Elmstatic exposing (..)
import Html exposing (..)
import Html.Attributes exposing (alt, attribute, class, href, src)
import Markdown
import Page
import Post


type alias Link =
    { href : String
    , name : String
    }


type alias Nav =
    List Link


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
    [ viewNav viewNavLinks
    , viewIconLink "Narsil Logo" "/"
    ]


viewNavLinks : Nav
viewNavLinks =
    [ { name = "Articles", href = "/articles" }
    , { name = "Blog", href = "/blog" }
    , { name = "Journal", href = "/journal" }
    , { name = "Quotes", href = "/quotes" }

    -- , { name = "Talks", href = "/talks" }
    -- , { name = "Books", href = "/books" }
    -- , { name = "Travel", href = "/travel" }
    -- , { name = "Software", href = "/software" }
    -- , { name = "Creations", href = "/creations" }
    -- , { name = "Contributions", href = "/contributions" }
    -- , { name = "Websites I Like", href = "/websitesilike" }
    -- , { name = "Languages", href = "/languages" }
    -- , { name = "Contact", href = "/contact" }
    -- , { name = "About Me", href = "/aboutme" }
    -- , { name = "Around the Web", href = "/aroundtheweb" }
    -- , { name = "About this site", href = "/aboutthissite" }
    -- , { name = "Gardening", href = "/gardening" }
    -- , { name = "3D Printing", href = "/3dprinting" }
    ]


viewNav : Nav -> Html Never
viewNav links =
    nav [ class "flex justify-center w-full max-lg:hidden" ]
        [ ul [ class "grid grid-cols-4 justify-around w-full items-center text-center" ]
            (List.map
                (\link ->
                    li [] [ viewLink link.href link.name Nothing ]
                )
                links
            )
        ]


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


viewLink : String -> String -> Maybe String -> Html Never
viewLink link name additionalClass =
    a
        [ href link
        , class
            ("hover:text-[#f7dd5f] transition-all underline "
                ++ (case additionalClass of
                        Nothing ->
                            ""

                        Just c ->
                            c
                   )
            )
        ]
        [ text name ]


viewSubtitle : String -> Html Never
viewSubtitle str =
    h2 [ class "text-xl text-center" ] [ text str ]


layout : String -> List (Html Never) -> List (Html Never)
layout title contentItems =
    header
        ++ [ h1 [ class "unifrakturmaguntia-regular text-6xl" ] [ text title ]
           , div [ class "font-bold text-4xl italic" ] [ text "Βράνδον Λύκας" ]
           , viewSubtitle "Bitcoin Lightning Payments @ voltage.cloud | Bitcoin Privacy & Scalability @ payjoin.org. Love sovereign software & history. Learning Nix, Elm, Rust, Ancient Greek and Latin."
           , node "div"
                [ class "flex flex-col gap-4 w-full" ]
                [ viewInfoSectionGrid contentItems ]

           -- contentItems
           -- [            -- , div [ class "grid lg:grid-cols-2 w-full gap-4" ]
           --     [
           --       text ""
           --     --   viewMarkdownFile files.writingDescription Section
           --     -- , viewQuotes files.quotesDescription files.quotes
           --     -- , viewMarkdownFile files.creationsDescription Section
           --     -- , viewMarkdownFile files.contributionsDescription Section
           --     -- , viewMarkdownFile files.talksDescription Section
           --     -- , viewMarkdownFile files.technologyDescription Section
           --     -- , viewMarkdownFile files.booksDescription Section
           --     -- , viewMarkdownFile files.workDescription Section
           --     --
           --     ]
           , Elmstatic.stylesheet "/styles.css"
           ]


viewInfoSectionGrid : List (Html Never) -> Html Never
viewInfoSectionGrid contentArr =
    contentArr |> List.map viewInfoSection |> div [ class "grid grid-cols-2 gap-4" ]


viewInfoSection : Html Never -> Html Never
viewInfoSection content =
    div
        [ class """flex flex-col gap-4 border border-gray-500
                        p-8 rounded-sm max-h-150 overflow-y-auto text-wrap break-words
                      """
        ]
        [ content ]



-- TODO: if a "post" is under the "snippets" (or if it contains
-- a frontmatter flag indicating it's a snippet): make it render the markdown
-- in the viewInfoSection, not just the frontmatter


main : Elmstatic.Layout
main =
    let
        postItem : Post -> Html Never
        postItem post =
            div []
                [ a [ href ("/" ++ post.link) ] [ h2 [] [ text post.title ] ]
                , Page.markdown post.content
                ]

        postListContent posts =
            if List.isEmpty posts then
                [ text "No posts yet!" ]

            else
                List.map postItem posts

        sortPosts posts =
            List.sortBy .date posts
                |> List.reverse
    in
    Elmstatic.layout Elmstatic.decodePostList <|
        \content ->
            Ok <| layout content.title <| postListContent <| sortPosts content.posts



-- Ok <| layout content.title <| postListContent <| sortPosts content.posts
