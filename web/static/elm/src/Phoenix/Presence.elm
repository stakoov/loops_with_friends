{-
  This file is borrowed from
  https://github.com/knewter/elm-phoenix-socket/blob/feature/add_presence_support_and_test/src/Phoenix/Presence.elm
  until if/when https://github.com/fbonetti/elm-phoenix-socket/pull/16
  is merged.
-}


module Phoenix.Presence
    exposing
        ( PresenceState
        , PresenceStateMetaWrapper
        , PresenceStateMetaValue
        , PresenceDiff
        , syncState
        , syncDiff
        , presenceStateDecoder
        , presenceDiffDecoder
        , listDefault
        , list
        )


import Dict exposing (Dict)
import Json.Decode as JD exposing ((:=))


-- TYPES


type alias PresenceState a =
    Dict String (PresenceStateMetaWrapper a)


type alias PresenceStateMetaWrapper a =
    { metas : List (PresenceStateMetaValue a) }


type alias PresenceStateMetaValue a =
    { phx_ref : String
    , payload : a
    }


type alias PresenceDiff a =
    { leaves : PresenceState a
    , joins : PresenceState a
    }


-- Json Decoders


presenceDiffDecoder : JD.Decoder a -> JD.Decoder (PresenceDiff a)
presenceDiffDecoder payloadDecoder =
    JD.object2 PresenceDiff
        ("leaves" := presenceStateDecoder payloadDecoder)
        ("joins" := presenceStateDecoder payloadDecoder)


presenceStateDecoder : JD.Decoder a -> JD.Decoder (PresenceState a)
presenceStateDecoder payloadDecoder =
    JD.dict (presenceStateMetaWrapperDecoder payloadDecoder)


presenceStateMetaWrapperDecoder : JD.Decoder a -> JD.Decoder (PresenceStateMetaWrapper a)
presenceStateMetaWrapperDecoder payloadDecoder =
    JD.object1 PresenceStateMetaWrapper
        ("metas" := JD.list (presenceStateMetaDecoder payloadDecoder))


presenceStateMetaDecoder : JD.Decoder a -> JD.Decoder (PresenceStateMetaValue a)
presenceStateMetaDecoder payloadDecoder =
    let
        createFinalRecord phxRef payload =
            JD.succeed (PresenceStateMetaValue phxRef payload)

        decodeWithPhxRef phxRef =
            payloadDecoder `JD.andThen` (createFinalRecord phxRef)
    in
        ("phx_ref" := JD.string) `JD.andThen` decodeWithPhxRef


-- API


listDefault : PresenceState a -> List (PresenceStateMetaWrapper a)
listDefault =
    Dict.values


list : (String -> PresenceStateMetaWrapper a -> Maybe b) -> PresenceState a -> List (Maybe b)
list mapper =
    Dict.map mapper >> Dict.values


syncState : PresenceState a -> PresenceState a -> PresenceState a
syncState newState state =
    newState


syncDiff : PresenceDiff a -> PresenceState a -> PresenceState a
syncDiff diff state =
    let
        mergeLeaves : PresenceState a -> String -> PresenceStateMetaWrapper a -> PresenceStateMetaWrapper a
        mergeLeaves leaves key currentMetaWrapper =
            case Dict.get key leaves of
                Nothing ->
                    currentMetaWrapper

                Just leaveValues ->
                    let
                        leftRefs =
                            List.map .phx_ref leaveValues.metas
                    in
                        currentMetaWrapper.metas
                            |> List.filter
                                (\metaValue ->
                                    not (List.any (\phx_ref -> metaValue.phx_ref == phx_ref) leftRefs)
                                )
                            |> PresenceStateMetaWrapper

        mergeJoins : PresenceState a -> PresenceState a -> PresenceState a
        mergeJoins left right =
            let
                inBoth : comparable -> PresenceStateMetaWrapper a -> PresenceStateMetaWrapper a -> PresenceState a -> PresenceState a
                inBoth key leftValue rightValue acc =
                    acc |> Dict.insert key (PresenceStateMetaWrapper (leftValue.metas ++ rightValue.metas))
            in
                merge Dict.insert
                    inBoth
                    Dict.insert
                    left
                    right
                    Dict.empty
    in
        state
            |> mergeJoins diff.joins
            |> Dict.map (mergeLeaves diff.leaves)
            |> Dict.filter (\_ metaWrapper -> metaWrapper.metas /= [])


merge :
    (comparable -> a -> result -> result)
    -> (comparable -> a -> b -> result -> result)
    -> (comparable -> b -> result -> result)
    -> Dict comparable a
    -> Dict comparable b
    -> result
    -> result
merge leftStep bothStep rightStep leftDict rightDict initialResult =
    let
        stepState rKey rValue ( list, result ) =
            case list of
                [] ->
                    ( list, rightStep rKey rValue result )

                ( lKey, lValue ) :: rest ->
                    if lKey < rKey then
                        stepState rKey rValue ( rest, leftStep lKey lValue result )
                    else if lKey > rKey then
                        ( list, rightStep rKey rValue result )
                    else
                        ( rest, bothStep lKey lValue rValue result )

        ( leftovers, intermediateResult ) =
            Dict.foldl stepState ( Dict.toList leftDict, initialResult ) rightDict
    in
        List.foldl (\( k, v ) result -> leftStep k v result) intermediateResult leftovers
