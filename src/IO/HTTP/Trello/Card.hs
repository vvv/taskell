{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module IO.HTTP.Trello.Card
    ( Card
    , idChecklists
    , cardToTask
    , setChecklists
    ) where

import ClassyPrelude

import Control.Lens (makeLenses, (&), (.~), (^.))

import           Data.Taskell.Date   (utcToLocalDay)
import qualified Data.Taskell.Task   as T (Task, due, new, setDescription, subtasks)
import           Data.Time.Format    (iso8601DateFormat, parseTimeM)
import           Data.Time.LocalTime (TimeZone)

import IO.HTTP.Aeson                (deriveFromJSON)
import IO.HTTP.Trello.ChecklistItem (ChecklistItem, checklistItemToSubTask)

data Card = Card
    { _name         :: Text
    , _desc         :: Text
    , _due          :: Maybe Text
    , _idChecklists :: [Text]
    , _checklists   :: Maybe [ChecklistItem]
    } deriving (Eq, Show)

-- strip underscores from field labels
$(deriveFromJSON ''Card)

-- create lenses
$(makeLenses ''Card)

-- operations
textToTime :: TimeZone -> Text -> Maybe Day
textToTime tz text = utcToLocalDay tz <$> utc
  where
    utc = parseTimeM False defaultTimeLocale (iso8601DateFormat (Just "%H:%M:%S%Q%Z")) $ unpack text

cardToTask :: TimeZone -> Card -> T.Task
cardToTask tz card =
    task & T.due .~ textToTime tz (fromMaybe "" (card ^. due)) & T.subtasks .~
    fromList (checklistItemToSubTask <$> fromMaybe [] (card ^. checklists))
  where
    task = T.setDescription (card ^. desc) $ T.new (card ^. name)

setChecklists :: Card -> [ChecklistItem] -> Card
setChecklists card cls = card & checklists .~ Just cls
