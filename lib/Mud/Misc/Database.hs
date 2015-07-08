{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
{-# LANGUAGE FlexibleContexts, GADTs, GeneralizedNewtypeDeriving, MultiParamTypeClasses, OverloadedStrings, QuasiQuotes, TemplateHaskell, TypeFamilies, ViewPatterns #-}

module Mud.Misc.Database ( BanHost(..)
                         , BanHostId
                         , BanPla(..)
                         , BanPlaId
                         , Bug(..)
                         , BugId
                         , dumpDbTbl
                         , insertDbTbl
                         , migrateDbTbls
                         , Prof(..)
                         , ProfId
                         , Typo(..)
                         , TypoId ) where

import Mud.TopLvlDefs.FilePaths

import Control.Monad (void)
import Data.Conduit (($$), (=$))
import Data.Monoid ((<>))
import Database.Persist.Class (fromPersistValues)
import Database.Persist.Sql (insert, rawQuery)
import Database.Persist.Sqlite (runMigrationSilent, runSqlite)
import Database.Persist.TH (mkMigrate, mkPersist, persistLowerCase, share, sqlSettings)
import qualified Data.Conduit.List as CL (consume, map)
import qualified Data.Text as T


--TODO: What about exceptions?


-- ==================================================


share [ mkPersist sqlSettings, mkMigrate "migrateAll" ] [persistLowerCase|
BanHost
  timestamp T.Text
  host      T.Text
  isBanned  Bool
  reason    T.Text
BanPla
  timestamp T.Text
  name      T.Text
  isBanned  Bool
  reason    T.Text
Bug
  timestamp T.Text
  name      T.Text
  loc       T.Text
  desc      T.Text
  isOpen    Bool
Prof
  timestamp T.Text
  host      T.Text
  profanity T.Text
Typo
  timestamp T.Text
  name      T.Text
  loc       T.Text
  desc      T.Text
  isOpen    Bool
|]


dbFile' :: T.Text
dbFile' = T.pack dbFile


migrateDbTbls :: IO ()
migrateDbTbls = runSqlite dbFile' . void . runMigrationSilent $ migrateAll


dumpDbTbl tblName = runSqlite dbFile' helper
  where
    helper = rawQuery ("select * from " <> tblName) [] $$ CL.map (fromPersistValues . tail) =$ CL.consume


insertDbTbl x = runSqlite dbFile' . void . insert $ x
