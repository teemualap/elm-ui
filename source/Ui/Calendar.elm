module Ui.Calendar
  ( Model, Action, init, update, view, setValue, nextDay
  , previousDay ) where

{-| This is a calendar component where the user can:
  - Select a date by clicking on it
  - Change the month with arrows

# Model
@docs Model, Action, init, update

# View
@docs view

# Functions
@docs setValue, nextDay, previousDay
-}
import Html.Attributes exposing (classList)
import Html.Events exposing (onMouseDown)
import Html exposing (node, text, span)
import Html.Lazy

import Date.Format exposing (format)
import Time exposing (Time)
import Ext.Signal
import Ext.Date
import Effects
import Signal
import List
import Date

import Ui.Container
import Ui

{-| Representation of a calendar component:
  - **selectable** - Whether or not the user can select a date by clicking
  - **date** - The month in which this date is will be displayed
  - **readonly** - Whether or not the calendar is interactive
  - **disabled** - Whether or not the calendar is disabled
  - **mailbox** - The mailbox of the calendar
  - **valueSignal** - A signal for the value
  - **value** - The current selected date
-}
type alias Model =
  { mailbox : Signal.Mailbox Time
  , valueSignal : Signal Time
  , selectable : Bool
  , value : Date.Date
  , date : Date.Date
  , disabled : Bool
  , readonly : Bool
  }

{-| Actions that a calendar can make. -}
type Action
  = Select Date.Date
  | PreviousMonth
  | NextMonth
  | Tasks ()

{-| Initializes a calendar with the given values.

    Calendar.init date
-}
init : Date.Date -> Model
init date =
  let
    mailbox = Signal.mailbox 0
  in
    { valueSignal = Signal.dropRepeats mailbox.signal
    , mailbox = mailbox
    , selectable = True
    , disabled = False
    , readonly = False
    , value = date
    , date = date
    }

{-| Updates a calendar. -}
update : Action -> Model -> (Model, Effects.Effects Action)
update action model =
  case action of
    NextMonth ->
      ({ model | date = Ext.Date.nextMonth model.date }, Effects.none)

    PreviousMonth ->
      ({ model | date = Ext.Date.previousMonth model.date }, Effects.none)

    Select date ->
      ({ model | value = date }
       , Ext.Signal.sendAsEffect model.mailbox.address (Date.toTime date) Tasks)

    Tasks _ ->
      (model, Effects.none)

{-| Renders a calendar. -}
view : Signal.Address Action -> Model -> Html.Html
view address model =
  Html.Lazy.lazy2 render address model

-- Render internal
render : Signal.Address Action -> Model -> Html.Html
render address model =
  let
    -- The date of the month
    month =
      Ext.Date.begginingOfMonth model.date

    -- List of dates in the month
    dates =
      Ext.Date.datesInMonth month

    -- The left padding in the table
    leftPadding =
      paddingLeft month

    -- The cells before the month
    paddingLeftItems =
      Ext.Date.datesInMonth (Ext.Date.previousMonth month)
      |> List.reverse
      |> List.take (paddingLeft month)
      |> List.reverse

    -- The cells after the month -
    paddingRightItems =
      Ext.Date.datesInMonth (Ext.Date.nextMonth month)
      |> List.take (42 - leftPadding - (List.length dates))

    -- All of the 42 cells combined --
    cells =
      paddingLeftItems ++ dates ++ paddingRightItems
      |> List.map (\item -> renderCell address item model)

    nextAction =
      Ui.enabledActions model [ onMouseDown address NextMonth ]

    previousAction =
      Ui.enabledActions model [ onMouseDown address PreviousMonth ]

    {- Header container -}
    container =
      Ui.Container.row []
        [ Ui.icon "chevron-left" (not model.readonly) previousAction
        , node "div" [] [text (format "%Y - %B" month)]
        , Ui.icon "chevron-right" (not model.readonly) nextAction
        ]
  in
    node "ui-calendar" [classList [ ("disabled", model.disabled)
                                  , ("readonly", model.readonly)
                                  ]
                       ]
      [ container
      , node "ui-calendar-header" []
        (List.map (\item -> span [] [text item]) dayNames)
      , node "ui-calendar-table" [] cells
      ]

{-| Sets the value of a calendar. -}
setValue : Date.Date -> Model -> Model
setValue date model =
  { model | value = date }
    |> fixDate

{-| Steps the selected value to the next day -}
nextDay : Model -> Model
nextDay model =
  { model | value = Ext.Date.nextDay model.value }
    |> fixDate

{-| Steps the selected value to the preivous day -}
previousDay : Model -> Model
previousDay model =
  { model | value = Ext.Date.previousDay model.value }
    |> fixDate

-- Fixes the date in order to make sure the selected date is visible
fixDate : Model -> Model
fixDate model =
  if Ext.Date.isSameMonth model.date model.value then
    model
  else
    { model | date = model.value }

-- Returns the padding based on the day of the week
paddingLeft : Date.Date -> Int
paddingLeft date =
  case Date.dayOfWeek date of
    Date.Mon -> 0
    Date.Tue -> 1
    Date.Wed -> 2
    Date.Thu -> 3
    Date.Fri -> 4
    Date.Sat -> 5
    Date.Sun -> 6

-- Short names of days
dayNames : List String
dayNames =
  ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

-- Renders a single cell
renderCell : Signal.Address Action -> Date.Date -> Model -> Html.Html
renderCell address date model =
  let
    sameMonth =
      Ext.Date.isSameMonth date model.date

    value =
      Ext.Date.isSameDate date model.value

    click =
      if model.selectable && sameMonth &&
         not model.disabled && not model.readonly then
        [onMouseDown address (Select date)]
      else
        []

    classes =
      classList [ ("selected", value )
                , ("inactive", not sameMonth)
                ]
  in
    node "ui-calendar-cell"
         ([classes] ++ click)
         [text (toString (Date.day date))]
