{-# OPTIONS_GHC -funbox-strict-fields -Wall -Werror #-}
{-# LANGUAGE OverloadedStrings, RebindableSyntax, RecordWildCards, ViewPatterns #-}

module Mud.Data.Misc ( AOrThe(..)
                     , Action
                     , Amount
                     , Args
                     , Broadcast
                     , ClassifiedBroadcast(..)
                     , Cmd(..)
                     , CmdName
                     , Cols
                     , EmptyNoneSome(..)
                     , GetEntsCoinsRes(..)
                     , GetOrDrop(..)
                     , Help(..)
                     , HelpName
                     , Index
                     , InvType(..)
                     , PCDesig(..)
                     , PutOrRem(..)
                     , RightOrLeft(..)
                     , Serializable
                     , ShouldBracketQuote(..)
                     , ToOrFromThePeeped(..)
                     , Verb(..)
                     , deserialize
                     , fromRol
                     , getEntFlag
                     , getPlaFlag
                     , getRmFlag
                     , pp
                     , serialize
                     , setEntFlag
                     , setPlaFlag
                     , setRmFlag ) where

import Mud.Data.State.ActionParams.ActionParams
import Mud.Data.State.ActionParams.Util
import Mud.Data.State.State
import Mud.TopLvlDefs.Chars
import Mud.Util.Misc hiding (patternMatchFail)
import Mud.Util.Quoting
import qualified Mud.Util.Misc as U (patternMatchFail)

import Control.Lens (both, over)
import Control.Lens.Getter (Getting)
import Control.Lens.Operators ((^.))
import Control.Lens.Setter (Setting)
import Data.Bits (clearBit, setBit, testBit)
import Data.Monoid ((<>))
import Data.String (fromString)
import Prelude hiding ((>>), pi)
import qualified Data.Text as T


{-# ANN module ("HLint: ignore Use camelCase" :: String) #-}


-----


patternMatchFail :: T.Text -> [T.Text] -> a
patternMatchFail = U.patternMatchFail "Mud.Data.Misc"


-- ==================================================
-- Original typeclasses and instances:


class FromRol a where
  fromRol :: RightOrLeft -> a


instance FromRol Slot where
  fromRol RI = RIndexFS
  fromRol RM = RMidFS
  fromRol RR = RRingFS
  fromRol RP = RPinkyFS
  fromRol LI = LIndexFS
  fromRol LM = LMidFS
  fromRol LR = LRingFS
  fromRol LP = LPinkyFS
  fromRol s  = patternMatchFail "fromRol" [ showText s ]


-----


class HasFlags a where
  flagGetter :: Getting Int a Int

  flagSetter :: Setting (->) a a Int Int

  getFlag :: (Enum e) => e -> a -> Bool
  getFlag (fromEnum -> flagBitNum) a = (a^.flagGetter) `testBit` flagBitNum

  setFlag :: (Enum e) => e -> Bool -> a -> a
  setFlag (fromEnum -> flagBitNum) b = over flagSetter (`f` flagBitNum)
    where
      f = if b then setBit else clearBit


instance HasFlags Ent where
  flagGetter = entFlags
  flagSetter = entFlags


getEntFlag :: EntFlags -> Ent -> Bool
getEntFlag = getFlag


setEntFlag :: EntFlags -> Bool -> Ent -> Ent
setEntFlag = setFlag


instance HasFlags Rm where
  flagGetter = rmFlags
  flagSetter = rmFlags


getRmFlag :: RmFlags -> Rm -> Bool
getRmFlag = getFlag


setRmFlag :: RmFlags -> Bool -> Rm -> Rm
setRmFlag = setFlag


instance HasFlags Pla where
  flagGetter = plaFlags
  flagSetter = plaFlags


getPlaFlag :: PlaFlags -> Pla -> Bool
getPlaFlag = getFlag


setPlaFlag :: PlaFlags -> Bool -> Pla -> Pla
setPlaFlag = setFlag


-----


class Pretty a where
  pp :: a -> T.Text


instance Pretty AOrThe where
  pp A   = "a"
  pp The = "the"


instance Pretty Race where
  pp Dwarf     = "dwarf"
  pp Elf       = "elf"
  pp Felinoid  = "felinoid"
  pp Halfling  = "halfling"
  pp Human     = "human"
  pp Lagomorph = "lagomorph"
  pp Nymph     = "nymph"
  pp Vulpenoid = "vulpenoid"


instance Pretty RightOrLeft where
  pp R   = "right"
  pp L   = "left"
  pp rol = pp (fromRol rol :: Slot)


instance Pretty Sex where
  pp Male   = "male"
  pp Female = "female"
  pp NoSex  = undefined


instance Pretty Slot where
  pp HeadS      = "head"
  pp REar1S     = "right ear"
  pp REar2S     = "right ear"
  pp LEar1S     = "left ear"
  pp LEar2S     = "left ear"
  pp Nose1S     = "nose"
  pp Nose2S     = "nose"
  pp Neck1S     = "neck"
  pp Neck2S     = "neck"
  pp Neck3S     = "neck"
  pp RWrist1S   = "right wrist"
  pp RWrist2S   = "right wrist"
  pp RWrist3S   = "right wrist"
  pp LWrist1S   = "left wrist"
  pp LWrist2S   = "left wrist"
  pp LWrist3S   = "left wrist"
  pp RIndexFS   = "right index finger"
  pp RMidFS     = "right middle finger"
  pp RRingFS    = "right ring finger"
  pp RPinkyFS   = "right pinky finger"
  pp LIndexFS   = "left index finger"
  pp LMidFS     = "left middle finger"
  pp LRingFS    = "left ring finger"
  pp LPinkyFS   = "left pinky finger"
  pp RHandS     = "right hand"
  pp LHandS     = "left hand"
  pp BothHandsS = "both hands"
  pp UpBodyCS   = "upper body"
  pp LowBodyCS  = "lower body"
  pp FullBodyCS = "full body"
  pp UpBodyAS   = "upper body"
  pp LowBodyAS  = "lower body"
  pp BackS      = "back"
  pp FeetS      = "feet"


-----


class Serializable a where
  serialize   :: a -> T.Text
  deserialize :: T.Text -> a


instance Serializable PCDesig where
  serialize StdDesig { .. }
    | fields <- [ serMaybeText stdPCEntSing, showText isCap, pcEntName, showText pcId, showText pcIds ]
    = quoteWith d . T.intercalate d' $ fields
    where
      serMaybeText Nothing    = ""
      serMaybeText (Just txt) = txt
      (d, d')                 = over both T.singleton (stdDesigDelimiter, desigDelimiter)
  serialize NonStdDesig { .. } = quoteWith d $ do
      nonStdPCEntSing
      d'
      nonStdDesc
    where
      (>>)    = (<>)
      (d, d') = over both T.singleton (nonStdDesigDelimiter, desigDelimiter)
  deserialize a@(headTail' -> (c, T.init -> t))
    | c == stdDesigDelimiter, [ pes, ic, pen, pi, pis ] <- T.splitOn d t =
        StdDesig { stdPCEntSing = deserMaybeText pes
                 , isCap        = read . T.unpack $ ic
                 , pcEntName    = pen
                 , pcId         = read . T.unpack $ pi
                 , pcIds        = read . T.unpack $ pis }
    | [ pes, nsd ] <- T.splitOn d t = NonStdDesig { nonStdPCEntSing = pes
                                                  , nonStdDesc      = nsd }
    | otherwise = patternMatchFail "deserialize" [ showText a ]
    where
      deserMaybeText ""  = Nothing
      deserMaybeText txt = Just txt
      d                  = T.singleton desigDelimiter


-- ==================================================
-- Data types:


data AOrThe = A | The


-----


type Broadcast = (T.Text, Inv)


data ClassifiedBroadcast = TargetBroadcast    Broadcast
                         | NonTargetBroadcast Broadcast deriving Eq


instance Ord ClassifiedBroadcast where
  TargetBroadcast    _ `compare` NonTargetBroadcast _ = LT
  NonTargetBroadcast _ `compare` TargetBroadcast    _ = GT
  _                    `compare` _                    = EQ


-----


type Action = ActionParams -> MudStack ()


data Cmd = Cmd { cmdName :: !CmdName
               , action  :: !Action
               , cmdDesc :: !T.Text }


-----


type Amount = Int
type Index  = Int


data GetEntsCoinsRes = Mult    { amount          :: !Amount
                               , nameSearchedFor :: !T.Text
                               , entsRes         :: !(Maybe [Ent])
                               , coinsRes        :: !(Maybe (EmptyNoneSome Coins)) }
                     | Indexed { index           :: !Index
                               , nameSearchedFor :: !T.Text
                               , entRes          :: !(Either Plur Ent) }
                     | Sorry   { nameSearchedFor :: !T.Text }
                     | SorryIndexedCoins deriving Show


data EmptyNoneSome a = Empty
                     | NoneOf a
                     | SomeOf a deriving (Eq, Show)


-----


data GetOrDrop = Get | Drop


-----


type HelpName = T.Text


data Help = Help { helpName     :: HelpName
                 , helpFilePath :: FilePath
                 , isCmdHelp    :: Bool
                 , isAdminHelp  :: Bool }


-----

data InvType = PCInv | PCEq | RmInv deriving Eq


-----


data PCDesig = StdDesig    { stdPCEntSing    :: !(Maybe T.Text)
                           , isCap           :: !Bool
                           , pcEntName       :: !T.Text
                           , pcId            :: !Id
                           , pcIds           :: !Inv }
             | NonStdDesig { nonStdPCEntSing :: !T.Text
                           , nonStdDesc      :: !T.Text } deriving (Eq, Show)


-----


data PutOrRem = Put | Rem deriving (Eq, Show)


-----


data RightOrLeft = R
                 | L
                 | RI | RM | RR | RP
                 | LI | LM | LR | LP deriving (Read, Show)


-----


data ShouldBracketQuote = DoBracket | Don'tBracket


-----


data ToOrFromThePeeped = ToThePeeped | FromThePeeped


-----


data Verb = SndPer | ThrPer deriving Eq
