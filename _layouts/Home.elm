module Home exposing (layout, main, markdown)

import Elmstatic exposing (..)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, href)
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
    h2 [ class "text-xl text-center flex flex-col" ]
        [ span [] [ text "Determinate Computing @ ", a [ href "https://kai.nix.fun" ] [ text "kai.nix.fun" ] ]
        , span [] [ text "Ancient Greek Library @ ", a [ href "https://lyceum.quest" ] [ text "lyceum.quest" ] ]
        , span [] [ text "Bitcoin Lightning Payments @ ", a [ href "https://voltage.cloud" ] [ text "voltage.cloud" ] ]
        , span [] [ text "Bitcoin Privacy & Scalability @ ", a [ href "https://payjoin.org" ] [ text "payjoin.org" ] ]
        , span [] [ a [ href "https://github.com/thebrandonlucas" ] [ text "GitHub" ] ]
        ]


viewAboutMe : Html Never
viewAboutMe =
    viewInfoSection
        (div [ class "flex flex-col gap-4" ]
            [ span [ class "text-center" ] [ text "Welcome!" ]
            , span [ class "text-center" ] [ text "An enthusiast about everything, but mostly great software." ]
            , span [ class "text-center" ] [ text "Highlights" ]
            , ul [ class "list-outside ml-8" ]
                (List.map (\item -> li [ class "list-disc" ] [ markdown item ])
                    [ "Currently building [Kai](https://github.com/thebrandonlucas/kai), a friendly frontend for determinate computing"
                    , "Built one of the world's most comprehensive web interfaces & open source databases for Ancient Greek"
                    , "Built [conllu.lyceum.quest](https://conllu.lyceum.quest): an open source, accountless, comprehensive PWA visualizer for [CoNLL-U](https://universaldependencies.org/format.html) files"
                    , "[First Place Team](https://x.com/satsie/status/1909081177765364080) and later mentor & volunteer @ [MIT Bitcoin Hackathon](https://mitbitcoin.devpost.com/)"
                    , "Payjoin contributor: Presented Async Payjoin @ [TABconf](https://www.youtube.com/watch?v=vPzvLxv0YfQ), wrote payjoin.org, UX for `payjoin-cli`, and minor contributions to [BIP-77](https://github.com/bitcoin/bips/blob/master/bip-0077.mediawiki)"
                    , "[`bitcoin-qr`](https://github.com/thebrandonlucas/bitcoin-qr): A zero-dependency, zero-framework QR code web component for Bitcoin on-chain, Lightning, and unified BIP-21 payments."
                    , "Set up [internationalization for Alby wallet](https://github.com/getAlby/lightning-browser-extension/pull/906) to allow multiple languages"
                    , "Created [roc-overlay](https://github.com/thebrandonlucas/roc-overlay) to help members of the Roc community install and pin nightly compiler builds reproducibly with Nix."
                    ]
                )
            ]
        )


viewInterests : Html Never
viewInterests =
    viewInfoSection
        (div [ class "flex flex-col gap-4" ]
            [ h2 [ class "text-center" ] [ text "Interests" ]
            , ul [ class "list-outside ml-8" ]
                [ li [ class "list-disc" ] [ text "Free and Open Source Software (FOSS): NixOS, Roc, Bitcoin, Lightning Network, Payjoin, Linux, GrapheneOS, VPNs, etc." ]
                , li [ class "list-disc" ] [ text "History: Ancient Greece, Rome, American Revolution, etc." ]
                , li [ class "list-disc" ] [ text "Biographies: Adams, Hamilton, Washington, Franklin, Oppenheimer, Ramanujan and more" ]
                , li [ class "list-disc" ] [ text "Philosophy, psychology, Christianity: Influenced by Cicero, Nietzsche, Karl Popper, Dostoevsky, Will Durant, Oliver Sacks, Jung, Seneca, and more. Attempting to read Kierkegaard, but finding it impenetrably difficult yet joyful." ]
                , li [ class "list-disc" ] [ text "Languages: I'm currently learning Ancient Greek." ]
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
        , viewInterests
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
