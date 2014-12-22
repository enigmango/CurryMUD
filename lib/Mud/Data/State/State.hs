{-# OPTIONS_GHC -funbox-strict-fields -Wall -Werror -fno-warn-unused-do-bind #-}
{-# LANGUAGE OverloadedStrings, PatternSynonyms, RebindableSyntax, RecordWildCards, TemplateHaskell, ViewPatterns #-}

module Mud.Data.State.State where

import Mud.Data.State.StateInIORefT
import Mud.Util

import Control.Concurrent (ThreadId)
import Control.Concurrent.Async (Async)
import Control.Concurrent.STM.TMVar (TMVar)
import Control.Concurrent.STM.TQueue (TQueue)
import Control.Lens (makeLenses)
import Data.List (nub)
import Data.Monoid (Monoid, mappend, mempty)
import Data.String (fromString)
import Data.Time.Clock (UTCTime)
import Formatting ((%), sformat)
import Formatting.Formatters (string)
import Network (HostName)
import Prelude hiding ((>>))
import qualified Data.IntMap.Lazy as IM (IntMap)
import qualified Data.Map.Lazy as M (Map)
import qualified Data.Text as T


ifThenElse :: Bool -> a -> a -> a
ifThenElse True  x _ = x
ifThenElse False _ y = y


-- ==================================================
-- The monad transformer stack:


type MudStack = StateInIORefT MudState IO


-- ==================================================
-- MUD state:


data MudState = MudState { _worldStateTMVar :: TMVar WorldState
                         , _nonWorldState   :: NonWorldState }


-- ==================================================
-- World state:


data WorldState = WorldState { _entTbl   :: IM.IntMap Ent
                             , _objTbl   :: IM.IntMap Obj
                             , _clothTbl :: IM.IntMap Cloth
                             , _invTbl   :: IM.IntMap Inv
                             , _coinsTbl :: IM.IntMap Coins
                             , _conTbl   :: IM.IntMap Con
                             , _wpnTbl   :: IM.IntMap Wpn
                             , _armTbl   :: IM.IntMap Arm
                             , _eqTbl    :: IM.IntMap EqMap
                             , _mobTbl   :: IM.IntMap Mob
                             , _pcTbl    :: IM.IntMap PC
                             , _rmTbl    :: IM.IntMap Rm
                             , _typeTbl  :: IM.IntMap Type }


-- ==================================================
-- Entity:


type Id   = Int
type Sing = T.Text
type Plur = T.Text


data Ent = Ent { _entId    :: !Id
               , _entName  :: !(Maybe T.Text)
               , _sing     :: !Sing
               , _plur     :: !Plur
               , _entDesc  :: !T.Text
               , _entFlags :: !Int } deriving (Eq, Show)


-- ==================================================
-- Object:
-- Has an entity.


data Obj = Obj { _weight :: !Int
               , _vol    :: !Int } deriving (Eq, Show)


-- ==================================================
-- Clothing:
-- Has an object (and an entity).


data Cloth = EarC
           | NoseC
           | NeckC
           | WristC
           | FingerC
           | UpBodyC
           | LowBodyC
           | FullBodyC
           | BackC
           | FeetC deriving (Eq, Show)


-- ==================================================
-- Inventory:


type Inv = [Id]


-- ==================================================
-- Coins:


type Cop = Int
type Sil = Int
type Gol = Int


newtype Coins = Coins (Cop, Sil, Gol) deriving (Eq, Show)


instance Monoid Coins where
  mempty = Coins (0, 0, 0)
  Coins (cop, sil, gol) `mappend` Coins (cop', sil', gol') = Coins (cop + cop', sil + sil', gol + gol')


-- ============================================================
-- Container:
-- Has an object (and an entity) and an inventory and coins.


type Cap = Int


newtype Con = Con Cap deriving (Eq, Show)


type ConName = T.Text


-- ==================================================
-- Weapon:
-- Has an object (and an entity).


data Wpn = Wpn { _wpnSub :: !WpnSub
               , _minDmg :: !Int
               , _maxDmg :: !Int } deriving (Eq, Show)


data WpnSub = OneHanded
            | TwoHanded deriving (Eq, Show)


-- ==================================================
-- Armor:
-- Has an object (and an entity).


type AC = Int


data Arm = Arm { _armSub :: !ArmSub
               , _ac     :: !AC } deriving (Eq, Show)


data ArmSub = HeadA
            | UpBodyA
            | LowBodyA
            | FullBodyA deriving (Eq, Show)


-- ==================================================
-- Equipment:


type EqMap = M.Map Slot Id


data Slot = HeadS
          | REar1S | REar2S
          | LEar1S | LEar2S
          | Nose1S | Nose2S
          | Neck1S | Neck2S | Neck3S
          | RWrist1S | RWrist2S | RWrist3S
          | LWrist1S | LWrist2S | LWrist3S
          | RIndexFS | RMidFS | RRingFS | RPinkyFS
          | LIndexFS | LMidFS | LRingFS | LPinkyFS
          | RHandS
          | LHandS
          | BothHandsS
          | UpBodyCS
          | LowBodyCS
          | FullBodyCS
          | UpBodyAS
          | LowBodyAS
          | FullBodyAS
          | BackS
          | FeetS deriving (Enum, Eq, Ord)


-- ==================================================
-- Mobile:
-- Has an entity and an inventory and coins and equipment.


data Mob = Mob { _sex               :: !Sex
               , _st, _dx, _iq, _ht :: !Int
               , _hp, _fp           :: !Int
               , _xp                :: !Int
               , _hand              :: !Hand } deriving (Eq, Show)


data Sex = Male
         | Female
         | NoSex deriving (Eq, Show)


data Hand = RHand
          | LHand
          | NoHand deriving (Eq, Show)


-- ======================================================================
-- Player character:
-- Has a mob (and an entity and an inventory and coins and equipment).


data PC = PC { _rmId       :: !Id
             , _race       :: !Race
             , _introduced :: ![Sing]
             , _linked     :: ![Sing] } deriving (Eq, Show)


data Race = Dwarf
          | Elf
          | Felinoid
          | Halfling
          | Human
          | Lagomorph
          | Nymph
          | Vulpenoid deriving (Enum, Eq, Show)


-- ==================================================
-- Room:
-- Has an inventory and coins.


data Rm = Rm { _rmName  :: !T.Text
             , _rmDesc  :: !T.Text
             , _rmFlags :: !Int
             , _rmLinks :: ![RmLink] } deriving Eq


type LinkName = T.Text


data RmLink = StdLink    { _linkDir      :: !LinkDir
                         , _stdDestId    :: !Id }
            | NonStdLink { _linkName     :: !LinkName
                         , _nonStdDestId :: !Id
                         , _originMsg    :: !(T.Text -> T.Text)
                         , _destMsg      :: !(T.Text -> T.Text) }


instance Eq RmLink where
  (StdLink    dir i      ) == (StdLink    dir' i'        ) | dir   == dir'
                                                           , i     == i'     = True
  (NonStdLink ln  i om dm) == (NonStdLink ln'  i' om' dm') | ln    == ln'
                                                           , i     == i'
                                                           , om "" == om' ""
                                                           , dm "" == dm' "" = True
  _                        == _                            = False


data LinkDir = North
             | Northeast
             | East
             | Southeast
             | South
             | Southwest
             | West
             | Northwest
             | Up
             | Down deriving (Eq, Show)


-- ==================================================
-- Types of world elements:


data Type = ObjType
          | ClothType
          | ConType
          | WpnType
          | ArmType
          | MobType
          | PCType
          | RmType deriving (Eq, Show)


-- ==================================================
-- Non-world state:


data NonWorldState = NonWorldState { _startTime         :: !UTCTime
                                   , _noticeLog         :: !(Maybe LogService)
                                   , _errorLog          :: !(Maybe LogService)
                                   , _plaLogTblTMVar    :: !(TMVar (IM.IntMap LogService))
                                   , _threadTblTMVar    :: !(TMVar ThreadTbl)
                                   , _talkAsyncTblTMVar :: !(TMVar TalkAsyncTbl)
                                   , _msgQueueTblTMVar  :: !(TMVar (IM.IntMap MsgQueue))
                                   , _plaTblTMVar       :: !(TMVar (IM.IntMap Pla)) }


-- ==================================================
-- Log services:


data LogCmd = StopLog | LogMsg T.Text


type LogAsync   = Async ()
type LogQueue   = TQueue LogCmd
type LogService = (LogAsync, LogQueue)


-- ==================================================
-- Thread table:


type ThreadTbl = M.Map ThreadId ThreadType


data ThreadType = Error
                | InacTimer Id
                | Listen
                | Notice
                | PlaLog    Id
                | Receive   Id
                | Server    Id
                | Talk      Id
                | ThreadTblPurger deriving (Eq, Ord, Show)


-- ==================================================
-- Talk async table:


type TalkAsyncTbl = M.Map ThreadId (Async ())


-- ==================================================
-- Message queue:


type MsgQueue = TQueue Msg


data Msg = Dropped
         | FromClient T.Text
         | FromServer T.Text
         | InacBoot
         | MsgBoot    T.Text
         | Prompt     T.Text
         | Quit
         | Shutdown
         | SilentBoot


-- ==================================================
-- Player:


type CmdName = T.Text
type Interp  = (CmdName -> ActionParams -> MudStack ())


data Pla = Pla { _isWiz    :: !Bool
               , _hostName :: !HostName
               , _columns  :: !Int
               , _interp   :: !Interp }


-- ==================================================
-- Action parameters:


type Cols = Int
type Args = [T.Text]


data ActionParams = ActionParams { plaId       :: !Id
                                 , plaMsgQueue :: !MsgQueue
                                 , plaCols     :: !Cols
                                 , args        :: !Args }


instance Show ActionParams where
  show ActionParams { .. } = showIt (show plaId) (show plaCols) (show args)
    where
      showIt i cols = T.unpack . sformat m i cols
      m = do
          "ActionParams {plaId = "
          ", plaMsgQueue = elided, plaCols = "
          ", args = "
          "}"
      a >> b = a % string % b


-- ==================================================
-- Patterns matching type "ActionParams":


pattern WithArgs i mq cols as = ActionParams { plaId       = i
                                             , plaMsgQueue = mq
                                             , plaCols     = cols
                                             , args        = as }


pattern NoArgs i mq cols = WithArgs i mq cols []


pattern NoArgs' i mq <- NoArgs i mq _


pattern NoArgs'' i <- NoArgs' i _


pattern Lower i mq cols as <- WithArgs i mq cols (map T.toLower -> as)


pattern Lower' i as <- Lower i _ _ as


pattern LowerNub i mq cols as <- WithArgs i mq cols (nub . map T.toLower -> as)


pattern LowerNub' i as <- LowerNub i _ _ as


pattern Ignoring mq cols as <- WithArgs _ mq cols (dblQuote . T.unwords -> as)


pattern AdviseNoArgs <- NoArgs' _ _


pattern AdviseOneArg a <- WithArgs _ _ _ [a]


pattern Advising mq cols <- WithArgs _ mq cols _


-- ==================================================
-- Template Haskell for creating lenses:


makeLenses ''MudState

makeLenses ''WorldState
makeLenses ''Ent
makeLenses ''Obj
makeLenses ''Wpn
makeLenses ''Arm
makeLenses ''Mob
makeLenses ''PC
makeLenses ''Rm
makeLenses ''RmLink

makeLenses ''NonWorldState
makeLenses ''Pla
