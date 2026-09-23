module Home exposing (layout, main, markdown)

import Elmstatic exposing (..)
import Html exposing (..)
import Html.Attributes exposing (attribute, class)
import Markdown
import Page
import UI exposing (header)



-- type alias Link =
--     { href : String
--     , name : String
--     }
-- type alias Nav =
--     List Link


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



-- viewNavLinks : Nav
-- viewNavLinks =
--     [ { name = "Articles", href = "/articles" }
--     , { name = "Blog", href = "/blog" }
--     , { name = "Journal", href = "/journal" }
--     , { name = "Quotes", href = "/quotes" }
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
-- ]
--
-- viewNav : Nav -> Html Never
-- viewNav links =
--     nav [ class "flex justify-center w-full max-lg:hidden" ]
--         [ ul [ class "grid grid-cols-4 justify-around w-full items-center text-center" ]
--             (List.map
--                 (\link ->
--                     li [] [ viewLink link.href link.name Nothing ]
--                 )
--                 links
--             )
--         ]
--
--
-- viewLink : String -> String -> Maybe String -> Html Never
-- viewLink link name additionalClass =
--     a
--         [ href link
--         , class
--             ("hover:text-[#f7dd5f] transition-all underline "
--                 ++ (case additionalClass of
--                         Nothing ->
--                             ""
--
--                         Just c ->
--                             c
--                    )
--             )
--         ]
--         [ text name ]


viewSubtitle : Html Never
viewSubtitle =
    h2 [ class "text-xl text-center flex flex-col " ]
        [
           span [] [ text "Determinate Computing @ [kai.nix.fun]()" ]
        ,  span [] [ text "Ancient Greek Library @ [lyceum.quest]()" ]
        ,  span [] [ text "Bitcoin Lightning Payments @ voltage.cloud" ]
        , span [] [ text "Bitcoin Privacy & Scalability @ payjoin.org" ]
        ]


viewAboutMe : Html Never
viewAboutMe =
    viewInfoSection
        (span [ class "flex flex-col gap-4" ]
            [ span [ class "text-center" ] [ text "Welcome!" ]
            , span [ class "text-center" ] [ text "An enthusiast about everything, but mostly great software." ]
            , span [ class "text-center" ] [ text "Highlights" ]
            , ul [ class "list-outside ml-8 " ]
                [ li [ class "list-disc" ] [ text "Currently building [Kai](), a friendly frontend for determinate computing" ]
                , li [ class "list-disc" ] [ text "Built one of the world's most comprehensive Ancient Greek web interfaces & open source databases for Ancient Greek" ]
                , li [ class "list-disc" ] [ text "Built [conllu.lyceum.quest](): an open source, accountless, comprehensive PWA visualizer for [CoNLL-U]() files" ]
                , li [ class "list-disc" ] [ text "[First Place Winner]() and later mentor & volunteer @ [MIT Bitcoin Hackathon]()" ]
                , li [ class "list-disc" ] [ text "Payjoin contributor: Presented Async Payjoin @ [TABconf](), wrote payjoin.org, UX for `payjoin-cli`, and minor contributions to [BIP-77]()" ]
                , li [ class "list-disc" ] [ text "`bitcoin-qr`: A zero-dependency, zero-framework QR code web component for Bitcoin on-chain, Lightning, and unified BIP-21 payments." ]
                , li [ class "list-disc" ] [ text "Added [herecomesbitcoin]() animations to [bitcoin.org]()" ]
                , li [ class "list-disc" ] [ text "Setup [internationalization for Alby wallet]() to allow multiple languages" ]
                , li [ class "list-disc" ] [ text "Created [roc-overlay]() to help members of the Roc community" ]



                  -- INTERESTS
                , li [ class "list-disc" ] [ text "Free and Open Source Software (FOSS): Bitcoin, Lightning Network, Payjoin, Linux, GrapheneOS, VPNs, etc." ]
                , li [ class "list-disc" ] [ text "History: Ancient Greek, Roman, American Revolution, and more.)" ]
                , li [ class "list-disc" ] [ text "Biographies: Adams, Hamilton, Washington, Franklin, Oppenheimer, Ramanujan and more" ]
                , li [ class "list-disc" ] [ text "Philosophy, psychology, Christianity: Influenced by Cicero, Nietzsche, Karl Popper, Dostoevsky, Will Durant, Oliver Sacks, Jung, Seneca, and more. Attempting to read Kierkegaard, but finding it impenetrably difficult yet joyful.)" ]
                , li [ class "list-disc" ] [ text "Languages: I'm currently learning Ancient Greek and Latin." ]
                , li [ class "list-disc" ] [ text "Fun: Bass guitar" ]
                ]
            ]
        )


layout : String -> List (Html Never) -> List (Html Never)
layout _ contentItems =
    [ UI.header
    , h1 [ class "unifrakturmaguntia-regular text-6xl text-center w-full" ] [ text "Brandon Lucas" ]
    , div [ class "font-bold text-4xl italic text-center w-full" ] [ text "Βράνδων Λουκᾶς" ]
    , viewSubtitle
    , node "div"
        [ class "flex flex-col gap-4 w-full" ]
        [ viewAboutMe
        , viewInfoSectionGrid contentItems
        ]
    ]


viewInfoSectionGrid : List (Html Never) -> Html Never
viewInfoSectionGrid contentArr =
    contentArr |> List.map viewInfoSection |> div [ class "grid grid-cols-1 md:grid-cols-2 gap-4" ]


viewInfoSection : Html Never -> Html Never
viewInfoSection content =
    div
        [ class """flex flex-col gap-4 border border-gray-500
                        p-4 md:p-8 rounded-sm max-h-150 overflow-y-auto text-wrap break-words
                      """
        ]
        [ content ]


main : Elmstatic.Layout
main =
    let
        postItem : Post -> Html Never
        postItem post =
            div []
                [ Page.markdown post.content
                ]

        postListContent posts =
            if List.isEmpty posts then
                [ text "No posts yet!" ]

            else
                List.map postItem posts

        filterSnippets : List Post -> List Post
        filterSnippets posts =
            List.filter (\post -> String.contains "snippets" post.section) posts

        -- NOTE: We're sorting the home page markdown list
        -- in chronological order instead of reverse because
        -- we're using fake dates for the post snippets to order them
        sortPosts posts =
            List.sortBy .date posts
    in
    Elmstatic.layout Elmstatic.decodePostList <|
        \content ->
            Ok <| layout content.title <| postListContent <| sortPosts <| filterSnippets content.posts
