module Elmstatic exposing
    ( Content
    , Format(..)
    , Layout
    , Page
    , Post
    , PostList
    , decodePage
    , decodePost
    , decodePostList
    , htmlTemplate
    , inlineScript
    , layout
    , script
    , stylesheet
    )

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Json


type Format
    = Markdown
    | ElmMarkup


type alias Post =
    { content : String
    , date : String
    , format : Format
    , link : String
    , section : String
    , siteTitle : String
    , tags : List String
    , title : String
    }


type alias Page =
    { content : String
    , format : Format
    , siteTitle : String
    , title : String
    }


type alias PostList =
    { posts : List Post
    , section : String
    , siteTitle : String
    , title : String
    }


type alias Content a =
    { a | siteTitle : String, title : String }


type alias Layout =
    Program Json.Value Json.Value Never


{-| For backward compatibility, look for the content either in `markdown` or `content` fields
-}
decodeContent : Json.Decoder String
decodeContent =
    Json.oneOf [ Json.field "markdown" Json.string, Json.field "content" Json.string ]


decodeFormat : Json.Decoder Format
decodeFormat =
    Json.oneOf
        [ Json.map
            (\format ->
                if format == "emu" then
                    ElmMarkup

                else
                    Markdown
            )
          <|
            Json.field "format" Json.string
        , Json.succeed Markdown
        ]


decodePage : Json.Decoder Page
decodePage =
    Json.map4 Page
        decodeContent
        decodeFormat
        (Json.field "siteTitle" Json.string)
        (Json.field "title" Json.string)


decodePost : Json.Decoder Post
decodePost =
    Json.map8 Post
        decodeContent
        (Json.field "date" Json.string)
        decodeFormat
        (Json.field "link" Json.string)
        (Json.field "section" Json.string)
        (Json.field "siteTitle" Json.string)
        (Json.field "tags" <| Json.list Json.string)
        (Json.field "title" Json.string)


decodePostList : Json.Decoder PostList
decodePostList =
    Json.map4 PostList
        (Json.field "posts" <| Json.list decodePost)
        (Json.field "section" Json.string)
        (Json.field "siteTitle" Json.string)
        (Json.field "title" Json.string)


script : String -> Html Never
script src =
    node "citatsmle-script" [ attribute "src" src ] []


deferredScript : String -> Html Never
deferredScript src =
    node "citatsmle-script" [ attribute "src" src, attribute "defer" "" ] []


inlineScript : String -> Html Never
inlineScript js =
    node "citatsmle-script" [] [ text js ]


jsonLdScript : String -> Html Never
jsonLdScript jsonLd =
    node "citatsmle-script" [ attribute "type" "application/ld+json" ] [ text jsonLd ]


structuredData : String
structuredData =
    """{"@context":"https://schema.org","@graph":[{"@type":"WebSite","@id":"https://blu.cx/#website","url":"https://blu.cx","name":"Brandon Lucas","description":"Personal website of Brandon Lucas. Bitcoin Lightning developer at Voltage, privacy advocate at Payjoin.","publisher":{"@id":"https://blu.cx/#person"}},{"@type":"Person","@id":"https://blu.cx/#person","name":"Brandon Lucas","url":"https://blu.cx","sameAs":["https://github.com/thebrandonlucas","https://x.com/brandonstlucas"],"jobTitle":"Software Engineer","worksFor":[{"@type":"Organization","name":"Voltage","url":"https://voltage.cloud"},{"@type":"Organization","name":"Payjoin","url":"https://payjoin.org"}]}]}"""


stylesheet : String -> Html Never
stylesheet href =
    node "link" [ attribute "href" href, attribute "rel" "stylesheet", attribute "type" "text/css" ] []


asyncStylesheet : String -> Html Never
asyncStylesheet href =
    node "link"
        [ attribute "href" href
        , attribute "rel" "stylesheet"
        , attribute "media" "print"
        , attribute "onload" "this.media='all'"
        ]
        []


preloadFont : String -> Html Never
preloadFont href =
    node "link"
        [ attribute "rel" "preload"
        , attribute "href" href
        , attribute "as" "font"
        , attribute "type" "font/woff2"
        , attribute "crossorigin" ""
        ]
        []


htmlTemplate : String -> List (Html Never) -> Html Never
htmlTemplate title contentNodes =
    node "html"
        [ attribute "lang" "en" ]
        [ node "head"
            []
            [ node "title" [] [ text title ]
            , node "meta" [ attribute "charset" "utf-8" ] []
            , node "meta" [ attribute "name" "viewport", attribute "content" "width=device-width, initial-scale=1" ] []
            , node "meta" [ attribute "name" "description", attribute "content" "Personal website of Brandon Lucas. Bitcoin Lightning developer at Voltage, privacy advocate at Payjoin. Writing about software, history, and philosophy." ] []
            , node "meta" [ attribute "property" "og:title", attribute "content" title ] []
            , node "meta" [ attribute "property" "og:description", attribute "content" "Personal website of Brandon Lucas. Bitcoin Lightning developer at Voltage, privacy advocate at Payjoin. Writing about software, history, and philosophy." ] []
            , node "meta" [ attribute "property" "og:type", attribute "content" "website" ] []
            , node "meta" [ attribute "property" "og:url", attribute "content" "https://blu.cx" ] []
            , node "meta" [ attribute "property" "og:image", attribute "content" "https://blu.cx/images/social-card.png" ] []
            , node "meta" [ attribute "property" "og:site_name", attribute "content" "Brandon Lucas" ] []
            , node "meta" [ attribute "name" "twitter:card", attribute "content" "summary_large_image" ] []
            , node "meta" [ attribute "name" "twitter:site", attribute "content" "@brandonstlucas" ] []
            , node "meta" [ attribute "name" "twitter:title", attribute "content" title ] []
            , node "meta" [ attribute "name" "twitter:description", attribute "content" "Personal website of Brandon Lucas. Bitcoin Lightning developer at Voltage, privacy advocate at Payjoin. Writing about software, history, and philosophy." ] []
            , node "meta" [ attribute "name" "twitter:image", attribute "content" "https://blu.cx/images/social-card.png" ] []
            , node "link" [ attribute "rel" "canonical", attribute "href" "https://blu.cx" ] []
            , preloadFont "/fonts/EBGaramond-Regular.woff2"
            , preloadFont "/fonts/UnifrakturMaguntia-Regular.woff2"
            , stylesheet "/styles.css"
            , stylesheet "/highlight/tokyo-night-dark.min.css"
            , jsonLdScript structuredData
            , deferredScript "/highlight/highlight.min.js"
            , inlineScript "document.addEventListener('DOMContentLoaded', function() { hljs.highlightAll(); document.querySelectorAll('.markdown img').forEach(function(img) { img.loading = 'lazy'; img.decoding = 'async'; }); });"
            ]
        , node "body"
            []
            [ node "main" [ class "flex flex-col gap-8 w-[80%] items-center mx-auto my-20" ] contentNodes ]
        ]


layout : Json.Decoder (Content content) -> (Content content -> Result String (List (Html Never))) -> Layout
layout decoder view =
    Browser.document
        { init = \contentJson -> ( contentJson, Cmd.none )
        , view =
            \contentJson ->
                case Json.decodeValue decoder contentJson of
                    Err error ->
                        { title = "error"
                        , body = [ div [ attribute "error" <| Json.errorToString error ] [] ]
                        }

                    Ok content ->
                        case view content of
                            Err viewError ->
                                { title = "error"
                                , body = [ div [ attribute "error" viewError ] [] ]
                                }

                            Ok viewHtml ->
                                { title = ""
                                , body = [ htmlTemplate content.siteTitle <| viewHtml ]
                                }
        , update = \_ contentJson -> ( contentJson, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }
