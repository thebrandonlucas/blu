module Post exposing (main, metadataHtml)

import Elmstatic exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class, href)
import Iso8601
import Page
import Parser
import Time


parseIsoDate : String -> String
parseIsoDate isoString =
    case Iso8601.toTime isoString of
        Ok posix ->
            let
                year =
                    String.fromInt (Time.toYear Time.utc posix)

                month =
                    monthToString (Time.toMonth Time.utc posix)

                day =
                    String.fromInt (Time.toDay Time.utc posix)
            in
            year ++ " " ++ month ++ " " ++ day

        Err deadEnds ->
            "Invalid date: " ++ Parser.deadEndsToString deadEnds


monthToString : Time.Month -> String
monthToString month =
    case month of
        Time.Jan ->
            "Jan"

        Time.Feb ->
            "Feb"

        Time.Mar ->
            "Mar"

        Time.Apr ->
            "Apr"

        Time.May ->
            "May"

        Time.Jun ->
            "Jun"

        Time.Jul ->
            "Jul"

        Time.Aug ->
            "Aug"

        Time.Sep ->
            "Sep"

        Time.Oct ->
            "Oct"

        Time.Nov ->
            "Nov"

        Time.Dec ->
            "Dec"


tagsToHtml : List String -> List (Html Never)
tagsToHtml tags =
    let
        tagLink tag =
            "/tags/" ++ String.toLower tag

        tagged i tag =
            (if i > 0 then
                [ text ", " ]

             else
                []
            )
                ++ [ a [ href (tagLink tag) ] [ text tag ] ]
    in
    [ div [] (List.concat (List.indexedMap tagged tags)) ]


metadataHtml : Elmstatic.Post -> Html Never
metadataHtml post =
    div [ class "post-metadata border-b mb-8 pb-8 items-center flex flex-col " ]
        ([ span [] [ text (parseIsoDate post.date) ]
         , span [] [ text "-" ]
         ]
            ++ tagsToHtml post.tags
        )


main : Elmstatic.Layout
main =
    Elmstatic.layout Elmstatic.decodePost <|
        \content ->
            Ok <|
                Page.layout
                    content.title
                    [ div [ class "post-content flex flex-col gap-4 pb-12 border-b" ]
                        [ metadataHtml content, Page.markdown content.content ]
                    ]
