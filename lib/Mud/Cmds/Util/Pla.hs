{-# LANGUAGE FlexibleContexts, LambdaCase, MultiWayIf, NamedFieldPuns, OverloadedStrings, RankNTypes, RecordWildCards, TupleSections, ViewPatterns #-}

-- This module contains helper functions used by multiple functions in "Mud.Cmds.Pla", as well as helper functions used
-- by both "Mud.Cmds.Pla" and "Mud.Cmds.ExpCmds".

module Mud.Cmds.Util.Pla ( InvWithCon
                         , IsConInRm
                         , adminTagTxt
                         , alertMsgHelper
                         , armSubToSlot
                         , bugTypoLogger
                         , checkActing
                         , checkDark
                         , checkMutuallyTuned
                         , checkSlotSmellTaste
                         , clothToSlot
                         , connectHelper
                         , descSlotForId
                         , disconnectHelper
                         , donMsgs
                         , execIfPossessed
                         , expandLinkName
                         , expandOppLinkName
                         , extractMobIdsFromEiss
                         , fillHelper
                         , fillerToSpcs
                         , findAvailSlot
                         , genericAction
                         , genericActionWithFuns
                         , genericCheckActing
                         , genericSorry
                         , genericSorryWithFuns
                         , getActs
                         , getDblLinkedSings
                         , getMatchingChanWithName
                         , getRelativePCName
                         , hasFp
                         , hasHp
                         , hasMp
                         , hasPp
                         , helperDropEitherInv
                         , helperExtinguishEitherInv
                         , helperGetDropEitherCoins
                         , helperGetEitherInv
                         , helperLinkUnlink
                         , helperSettings
                         , helperTune
                         , helperUnready
                         , inOutOnOffs
                         , isNonStdLink
                         , isRingRol
                         , isRndmName
                         , isSlotAvail
                         , maybeSingleSlot
                         , mkChanBindings
                         , mkChanNamesTunings
                         , mkCoinsDesc
                         , mkCoinsSummary
                         , mkCorpseSmellLvl
                         , mkEffDxDesc
                         , mkEffHtDesc
                         , mkEffMaDesc
                         , mkEffPsDesc
                         , mkEffStDesc
                         , mkEntDesc
                         , mkEntDescs
                         , mkEqDesc
                         , mkExitsSummary
                         , mkFpDesc
                         , mkFullDesc
                         , mkHpDesc
                         , mkInvCoinsDesc
                         , mkLastArgIsTargetBindings
                         , mkLastArgWithNubbedOthers
                         , mkMaybeCorpseSmellMsg
                         , mkMaybeHumMsg
                         , mkMaybeNthOfM
                         , mkMpDesc
                         , mkPpDesc
                         , mkReadyMsgs
                         , mkRmInvCoinsDesc
                         , mkSettingPairs
                         , moveReadiedItem
                         , notFoundSuggestAsleeps
                         , onOffs
                         , otherHand
                         , putOnMsgs
                         , readHelper
                         , resolveMobInvCoins
                         , resolveRmInvCoins
                         , sacrificeHelper
                         , shuffleGive
                         , shufflePut
                         , shuffleRem
                         , sorryConHelper
                         , spiritHelper
                         , stopAttacking
                         , stopDrinking
                         , stopEating
                         , stopSacrificing ) where

import           Mud.Cmds.Msgs.Advice
import           Mud.Cmds.Msgs.Dude
import           Mud.Cmds.Msgs.Hint
import           Mud.Cmds.Msgs.Misc
import           Mud.Cmds.Msgs.Sorry
import           Mud.Cmds.Util.Abbrev
import           Mud.Cmds.Util.Misc
import           Mud.Data.Misc
import           Mud.Data.State.ActionParams.ActionParams
import           Mud.Data.State.MsgQueue
import           Mud.Data.State.MudData
import           Mud.Data.State.Util.Calc
import           Mud.Data.State.Util.Coins
import           Mud.Data.State.Util.Get
import           Mud.Data.State.Util.Hierarchy
import           Mud.Data.State.Util.Misc
import           Mud.Data.State.Util.Noun
import           Mud.Data.State.Util.Output
import           Mud.Misc.ANSI
import           Mud.Misc.Database
import           Mud.Misc.LocPref
import qualified Mud.Misc.Logging as L (logNotice, logPla, logPlaOut)
import           Mud.Misc.Misc
import           Mud.Misc.NameResolution
import           Mud.Threads.Act
import           Mud.Threads.Misc
import           Mud.TopLvlDefs.Misc
import           Mud.TopLvlDefs.Padding
import           Mud.TopLvlDefs.Vols
import           Mud.TopLvlDefs.Weights
import           Mud.Util.List
import qualified Mud.Util.Misc as U (blowUp, pmf)
import           Mud.Util.Misc hiding (blowUp, pmf)
import           Mud.Util.Operators
import           Mud.Util.Padding
import           Mud.Util.Quoting
import           Mud.Util.Text
import           Mud.Util.Wrapping

import           Control.Arrow ((***), (&&&), first, second)
import           Control.Lens (Getter, _1, _2, _3, _4, _5, at, both, each, to, view, views)
import           Control.Lens.Operators ((-~), (?~), (.~), (&), (%~), (^.), (<>~))
import           Control.Monad ((>=>), forM_, guard)
import           Control.Monad.IO.Class (liftIO)
import           Data.Bool (bool)
import           Data.Char (isLower)
import           Data.Function (on)
import qualified Data.IntMap.Strict as IM (IntMap, (!), keys)
import           Data.Ix (inRange)
import           Data.List ((\\), delete, elemIndex, find, foldl', group, intercalate, nub, nubBy, partition, sortBy, zip4)
import qualified Data.Map.Strict as M ((!), filter, keys, map, member, notMember, toList)
import           Data.Maybe (isNothing)
import           Data.Monoid ((<>), Sum(..))
import           Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Vector.Unboxed as V (Vector)
import           GHC.Stack (HasCallStack)
import           Prelude hiding (pi)

blowUp :: BlowUp a
blowUp = U.blowUp "Mud.Cmds.Util.Pla"

pmf :: PatternMatchFail
pmf = U.pmf "Mud.Cmds.Util.Pla"

-----

logNotice :: Text -> Text -> MudStack ()
logNotice = L.logNotice "Mud.Cmds.Util.Pla"

logPla :: Text -> Id -> Text -> MudStack ()
logPla = L.logPla "Mud.Cmds.Util.Pla"

logPlaOut :: Text -> Id -> [Text] -> MudStack ()
logPlaOut = L.logPlaOut "Mud.Cmds.Util.Pla"

-- ==================================================

alertMsgHelper :: HasCallStack => Id -> CmdName -> Text -> MudStack ()
alertMsgHelper i cn txt = getState >>= \ms -> if isAdminId i ms
  then unit
  else let matches = filter (`T.isInfixOf` T.toLower txt) alertMsgTriggers
       in if ()!# matches
         then liftIO mkTimestamp >>= \ts ->
             let match  = head matches
                 s      = getSing i ms
                 msg    = T.concat [ s, " issued a message via the ", dblQuote cn, " command containing the word "
                                   , dblQuote match, ": ", txt ]
                 outIds = (getIdForRoot ms `delete`) $ getAdminIds ms \\ getLoggedInAdminIds ms
                 rec    = AlertMsgRec Nothing ts s cn match txt
             in do logNotice fn   msg
                   logPla    fn i msg
                   bcastAdmins msg
                   forM_ outIds (\adminId -> retainedMsg adminId ms . mkRetainedMsgFromPerson s $ msg)
                   withDbExHandler_ fn . insertDbTblAlertMsg $ rec
         else unit
  where
    fn = "alertMsgHelper"

-----

armSubToSlot :: HasCallStack => ArmSub -> Slot
armSubToSlot = \case Head      -> HeadS
                     Torso     -> TorsoS
                     Arms      -> ArmsS
                     Hands     -> HandsS
                     LowerBody -> LowerBodyS
                     Feet      -> FeetS
                     Shield    -> undefined

-----

bugTypoLogger :: HasCallStack => ActionParams -> WhichLog -> MudStack ()
bugTypoLogger (Msg' i mq msg) wl = getState >>= \ms ->
    let s     = getSing i  ms
        ri    = getRmId i  ms
        mkLoc = parensQuote (showTxt ri) |<>| view rmName (getRm ri ms)
    in liftIO mkTimestamp >>= \ts -> do
        logPla "bugTypoLogger" i . T.concat $ [ "logging a ", showTxt wl, ": ", msg ]
        sequence_ $ case wl of BugLog  -> let b = BugRec ts s mkLoc msg
                                          in [ withDbExHandler_ "bugTypoLogger" . insertDbTblBug $ b
                                             , bcastOtherAdmins i $ s <> " has logged a bug: "  <> pp b ]
                               TypoLog -> let t = TypoRec ts s mkLoc msg
                                          in [ withDbExHandler_ "bugTypoLogger" . insertDbTblTypo $ t
                                             , bcastOtherAdmins i $ s <> " has logged a typo: " <> pp t ]
        send mq . nlnl $ "Thank you."
bugTypoLogger p _ = pmf "bugTypoLogger" p

-----

checkActing :: ActionParams -> MudState -> Either ActType Text -> [ActType] -> Fun -> MudStack ()
checkActing (ActionParams i mq cols _) ms attempting ngActs f =
    maybe f (wrapSend mq cols) . checkActingHelper i ms attempting $ ngActs

checkActingHelper :: HasCallStack => Id -> MudState -> Either ActType Text -> [ActType] -> Maybe Text
checkActingHelper i ms attempting ngActs = case filter (`M.member` getActMap i ms) ngActs of
  []                -> Nothing
  matches@(match:_) ->
      let f attemptingAct | attemptingAct `elem` matches = prd $ "You're already " <> pp attemptingAct
                          | otherwise = let t = case attemptingAct of Attacking   -> "attack"
                                                                      Drinking    -> "drink"
                                                                      Eating      -> "eat"
                                                                      Sacrificing -> "sacrifice a corpse"
                                        in sorryActing t match
      in Just . either f (`sorryActing` match) $ attempting

genericCheckActing :: HasCallStack => Id -> MudState -> Either ActType Text -> [ActType] -> GenericRes -> GenericRes
genericCheckActing i ms attempting ngActs a = maybe a (genericSorry ms) . checkActingHelper i ms attempting $ ngActs

-----

checkDark :: HasCallStack => ActionParams -> Fun -> MudStack ()
checkDark (ActionParams i mq cols _) f = getStateTime >>= \(ms, ct) ->
  ((||) <$> uncurry isSpiritId <*> uncurry (isMobRmLit ct)) (i, ms) ? f :? wrapSend mq cols darkMsg

-----

checkMutuallyTuned :: HasCallStack => Id -> MudState -> Sing -> Either Text Id
checkMutuallyTuned i ms targetSing = case areMutuallyTuned of
  (False, _,     _       ) -> Left . sorryTunedOutPCSelf $ targetSing
  (True,  False, _       ) -> Left . (effortsBlockedMsg <>) . sorryTunedOutPCTarget $ targetSing
  (True,  True,  targetId) -> Right targetId
  where
    areMutuallyTuned | targetId <- getIdForPCSing targetSing ms
                     , a <- (M.! targetSing) . getTeleLinkTbl i        $ ms
                     , b <- (M.! s         ) . getTeleLinkTbl targetId $ ms
                     = (a, b, targetId)
    s = getSing i ms

-----

checkSlotSmellTaste :: HasCallStack => Sing -> Slot -> Maybe Text
checkSlotSmellTaste s slot | slot `elem` ngSlots = Just . sorrySmellTasteSlot $ s
                           | otherwise           = Nothing
  where
    ngSlots = [ EarringR1S .. NoseRing2S ] ++ [ HeadS, TorsoS, TrousersS, LowerBodyS, FeetS, BackpackS ]

-----

clothToSlot :: HasCallStack => Cloth -> Slot
clothToSlot = \case Shirt    -> ShirtS
                    Smock    -> SmockS
                    Coat     -> CoatS
                    Trousers -> TrousersS
                    Skirt    -> SkirtS
                    Dress    -> DressS
                    FullBody -> FullBodyS
                    Backpack -> BackpackS
                    Cloak    -> CloakS
                    _        -> undefined

-----

connectHelper :: HasCallStack => Id -> (Text, Args) -> MudState -> (MudState, (MudState, ([Either Text Sing], Maybe Id)))
connectHelper i (target, as) ms =
    let (f, guessWhat) | any hasLocPref as = (stripLocPref, sorryConnectIgnore)
                       | otherwise         = (id,           ""                )
        as'         = map (capitalize . T.toLower . f) as
        notFound    = sorry . sorryChanName $ target
        found match = let (cn, c) = getMatchingChanWithName match cns cs in if views chanConnTbl (M.! s) c
          then let procTarget pair@(ms', _) a =
                       let notFoundSing         = sorryProcTarget . notFoundSuggestAsleeps a asleepSings $ ms'
                           foundSing targetSing = case c^.chanConnTbl.at targetSing of
                             Just _  -> sorryProcTarget . sorryConnectAlready targetSing $ cn
                             Nothing ->
                                 let checkChanName targetId = if hasChanOfSameName targetId
                                       then blocked . sorryConnectChanName targetSing $ cn
                                       else checkPp
                                     checkPp | not . hasPp i ms' $ 3 = let msg = sorryPp $ "connect " <> targetSing
                                                                       in sorryProcTarget msg
                                             | otherwise = pair & _1.chanTbl.ind ci.chanConnTbl.at targetSing ?~ True
                                                                & _1.mobTbl.ind i.curPp -~ 3
                                                                & _2 <>+ Right targetSing
                                 in either sorryProcTarget checkChanName . checkMutuallyTuned i ms' $ targetSing
                           sorryProcTarget msg = pair & _2 <>+ Left msg
                           blocked             = sorryProcTarget . (effortsBlockedMsg <>)
                       in findFullNameForAbbrev a targetSings |&| maybe notFoundSing foundSing
                   ci                         = c^.chanId
                   dblLinkeds                 = views pcTbl (filter (isDblLinked ms . (i, )) . IM.keys) ms
                   dblLinkedsPair             = partition (`isAwake` ms) dblLinkeds
                   (targetSings, asleepSings) = dblLinkedsPair & both %~ map (`getSing` ms)
                   hasChanOfSameName targetId | targetCs  <- getPCChans targetId ms
                                              , targetCns <- selects chanName T.toLower targetCs
                                              = T.toLower cn `elem` targetCns
                   (ms'', res)                = foldl' procTarget (ms, []) as'
               in (ms'', (ms'', (onFalse (()# guessWhat) (Left guessWhat :) res, Just ci)))
          else sorry . sorryTunedOutICChan $ cn
        (cs, cns, s) = mkChanBindings i ms
        sorry        = (ms, ) . (ms, ) . (, Nothing) . pure . Left
    in findFullNameForAbbrev target (map T.toLower cns) |&| maybe notFound found

-----

descSlotForId :: HasCallStack => Id -> MudState -> Id -> EqMap -> Text
descSlotForId i ms itemId = maybeEmp (parensQuote . mkSlotDesc i ms) . lookupMapValue itemId

mkSlotDesc :: HasCallStack => Id -> MudState -> Slot -> Text
mkSlotDesc i ms s = case s of
  -- Clothing slots:
  EarringR1S  -> wornOn -- "right ear"
  EarringR2S  -> wornOn -- "right ear"
  EarringL1S  -> wornOn -- "left ear"
  EarringL2S  -> wornOn -- "left ear"
  NoseRing1S  -> wornOn -- "nose"
  NoseRing2S  -> wornOn -- "nose"
  Necklace1S  -> wornOn -- "neck"
  Necklace2S  -> wornOn -- "neck"
  Necklace3S  -> wornOn -- "neck"
  BraceletR1S -> wornOn -- "right wrist"
  BraceletR2S -> wornOn -- "right wrist"
  BraceletR3S -> wornOn -- "right wrist"
  BraceletL1S -> wornOn -- "left wrist"
  BraceletL2S -> wornOn -- "left wrist"
  BraceletL3S -> wornOn -- "left wrist"
  RingRIS     -> wornOn -- "right index finger"
  RingRMS     -> wornOn -- "right middle finger"
  RingRRS     -> wornOn -- "right ring finger"
  RingRPS     -> wornOn -- "right pinky finger"
  RingLIS     -> wornOn -- "left index finger"
  RingLMS     -> wornOn -- "left middle finger"
  RingLRS     -> wornOn -- "left ring finger"
  RingLPS     -> wornOn -- "left pinky finger"
  ShirtS      -> wornAs -- "shirt"
  SmockS      -> wornAs -- "smock"
  CoatS       -> wornAs -- "coat"
  TrousersS   -> "worn as trousers" -- "trousers"
  SkirtS      -> wornAs -- "skirt"
  DressS      -> wornAs -- "dress"
  FullBodyS   -> "worn about " <> hisHer <> " body" -- "about body"
  BackpackS   -> "worn on "    <> hisHer <> " back" -- "backpack"
  CloakS      -> wornAs -- "cloak"
  -- Armor slots:
  HeadS       -> wornOn -- "head"
  TorsoS      -> wornOn -- "torso"
  ArmsS       -> wornOn -- "arms"
  HandsS      -> wornOn -- "hands"
  LowerBodyS  -> wornOn -- "lower body"
  FeetS       -> wornOn -- "feet"
  -- Weapon/shield slots:
  RHandS      -> heldIn -- "right hand"
  LHandS      -> heldIn -- "left hand"
  BothHandsS  -> "wielding with both hands" -- "both hands"
  where
    hisHer = mkPossPro . getSex i $ ms
    wornOn = T.concat [ "worn on ", hisHer, " ", pp s ]
    wornAs = "worn as " <> aOrAn (pp s)
    heldIn = "held in " <> hisHer |<>| pp s

-----

disconnectHelper :: HasCallStack => Id
                                 -> (Text, Args)
                                 -> IM.IntMap [(Id, Text)]
                                 -> MudState
                                 -> (MudState, ([Either Text (Id, Sing, Text)], Maybe Id))
disconnectHelper i (target, as) idNamesTbl ms =
    let (f, guessWhat) | any hasLocPref as = (stripLocPref, sorryDisconnectIgnore)
                       | otherwise         = (id,           ""                   )
        as'         = map (T.toLower . f) as
        notFound    = sorry . sorryChanName $ target
        found match = let (cn, c) = getMatchingChanWithName match cns cs in if views chanConnTbl (M.! s) c
          then let procTarget (pair@(ms', _), b) a = case filter ((== a) . T.toLower . snd) $ idNamesTbl IM.! ci of
                     [] -> (pair & _2 <>+ (Left . hint . sorryChanTargetName (dblQuote cn) $ a), True)
                     [(targetId, targetName)]
                       | not . hasPp i ms' $ 3 ->
                           let targetName' = isRndmName targetName ? underline targetName :? targetName
                               msg         = sorryPp $ "disconnect " <> targetName'
                           in (pair & _2 <>+ Left msg, b)
                       | otherwise -> let targetSing = getSing targetId ms'
                                      in ( pair & _1.chanTbl.ind ci.chanConnTbl.at targetSing .~ Nothing
                                                & _1.mobTbl.ind i.curPp -~ 3
                                                & _2 <>+ Right (targetId, targetSing, targetName)
                                         , b )
                     xs -> pmf "disconnectHelper found" xs
                     where
                       hint = onFalse b ((<> hintDisconnect) . spcR)
                   ci               = c^.chanId
                   ((ms'', res), _) = foldl' procTarget ((ms, []), False) as'
               in (ms'', (onFalse (()# guessWhat) (Left guessWhat :) res, Just ci))
          else sorry . sorryTunedOutICChan $ cn
        (cs, cns, s) = mkChanBindings i ms
        sorry        = (ms, ) . (, Nothing) . pure . Left
    in findFullNameForAbbrev target (map T.toLower cns) |&| maybe notFound found

-----

donMsgs :: HasCallStack => Desig -> Sing -> (Text, Broadcast)
donMsgs = mkReadyMsgs "don" "dons"

type SndPerVerb = Text
type ThrPerVerb = Text

mkReadyMsgs :: HasCallStack => SndPerVerb -> ThrPerVerb -> Desig -> Sing -> (Text, Broadcast)
mkReadyMsgs spv tpv d s = (  T.concat [ "You ", spv, " the ", s, "." ]
                          , (T.concat [ serialize d, spaced tpv, mkSerVerbObj . aOrAn $ s, "." ], desigOtherIds d) )

-----

execIfPossessed :: HasCallStack => ActionParams -> CmdName -> (Id -> ActionFun) -> MudStack ()
execIfPossessed p@(WithArgs i mq cols _) cn f = getState >>= \ms -> let s = getSing i ms in case getPossessor i ms of
      Nothing -> wrapSend mq cols (sorryNotPossessed s cn)
      Just i' -> f i' p
execIfPossessed p _ _ = pmf "execIfPossessed" p

-----

expandLinkName :: HasCallStack => Text -> Text
expandLinkName "n"  = "north"
expandLinkName "ne" = "northeast"
expandLinkName "e"  = "east"
expandLinkName "se" = "southeast"
expandLinkName "s"  = "south"
expandLinkName "sw" = "southwest"
expandLinkName "w"  = "west"
expandLinkName "nw" = "northwest"
expandLinkName "u"  = "up"
expandLinkName "d"  = "down"
expandLinkName x    = pmf "expandLinkName" x

expandOppLinkName :: HasCallStack => Text -> Text
expandOppLinkName "n"  = "the south"
expandOppLinkName "ne" = "the southwest"
expandOppLinkName "e"  = "the west"
expandOppLinkName "se" = "the northwest"
expandOppLinkName "s"  = "the north"
expandOppLinkName "sw" = "the northeast"
expandOppLinkName "w"  = "the east"
expandOppLinkName "nw" = "the southeast"
expandOppLinkName "u"  = "below"
expandOppLinkName "d"  = "above"
expandOppLinkName x    = pmf "expandOppLinkName" x

-----

extractMobIdsFromEiss :: HasCallStack => MudState -> [Either Text Inv] -> Inv
extractMobIdsFromEiss ms = foldl' helper []
  where
    helper acc Left   {}  = acc
    helper acc (Right is) = acc ++ findMobIds ms is

-----

fillHelper :: HasCallStack => Id -> MudState -> LastArgIsTargetBindings -> Id -> GenericResWithFuns
fillHelper i ms LastArgIsTargetBindings { .. } targetId =
    let (inInvs, inEqs, inRms)      = sortArgsInvEqRm InInv otherArgs
        sorryInEq                   = inEqs |!| sorryFillInEq
        sorryInRm                   = inRms |!| sorryFillInRm
        (eiss, ecs)                 = uncurry (resolveMobInvCoins i ms inInvs) srcInvCoins
        sorryCoins                  = ecs |!| sorryFillCoins
        (ms', toSelfs, bs, logMsgs) = helperFillEitherInv i srcDesig targetId eiss (ms, [], [], [])
    in (ms', (dropBlanks $ [ sorryInEq, sorryInRm, sorryCoins ] ++ toSelfs, bs, logMsgs, []))

helperFillEitherInv :: HasCallStack => Id
                                    -> Desig
                                    -> Id
                                    -> [Either Text Inv]
                                    -> GenericIntermediateRes
                                    -> GenericIntermediateRes
helperFillEitherInv _ _        _        []         a               = a
helperFillEitherInv i srcDesig targetId (eis:eiss) a@(ms, _, _, _) = case getVesselCont targetId ms of
  Nothing   -> sorry . sorryFillEmptySource $ targetSing
  Just cont -> next $ case eis of Left msg -> sorry msg
                                  Right is -> helper cont is a
  where
    targetSing = getSing targetId ms
    next       = helperFillEitherInv i srcDesig targetId eiss
    sorry msg  = a & _2 <>+ msg
    helper _                              []       a'                = a'
    helper cont@(targetLiq, targetMouths) (vi:vis) a'@(ms', _, _, _)
      | isNothing . getVesselCont targetId $ ms' = a'
      | vi == targetId                           = helper cont vis . sorry' . sorryFillSelf $ vs
      | getType vi ms' /= VesselType             = helper cont vis . sorry' . sorryFillType $ vs
      | otherwise                                = helper cont vis . (_3 <>~ bs) $ case getVesselCont vi ms' of
          Nothing | vmm <  targetMouths -> a' & _1.vesselTbl.ind targetId.vesselCont ?~ (targetLiq, targetMouths - vmm)
                                              & _1.vesselTbl.ind vi      .vesselCont ?~ (targetLiq, vmm)
                                              & _2 <>+ mkFillUpMsg
                                              & _4 <>+ mkFillUpMsg
                  | vmm == targetMouths -> a' & _1.vesselTbl.ind targetId.vesselCont .~ Nothing
                                              & _1.vesselTbl.ind vi      .vesselCont ?~ (targetLiq, vmm)
                                              & _2 <>+ mkFillUpEmptyMsg
                                              & _4 <>+ mkFillUpEmptyMsg
                  | otherwise           -> a' & _1.vesselTbl.ind targetId.vesselCont .~ Nothing
                                              & _1.vesselTbl.ind vi      .vesselCont ?~ (targetLiq, targetMouths)
                                              & _2 <>+ mkXferEmptyMsg
                                              & _4 <>+ mkXferEmptyMsg
          Just (vl, vm)
            | vl 🍰 targetLiq    -> sorry' . uncurry sorryFillLiqTypes $ (targetId, vi) & both %~ flip getBothGramNos ms'
            | vm >= vmm          -> sorry' . sorryFillAlready $ vs
            | vAvail <- vmm - vm -> if | vAvail <  targetMouths ->
                                           a' & _1.vesselTbl.ind targetId.vesselCont ?~ (targetLiq, targetMouths - vAvail)
                                              & _1.vesselTbl.ind vi      .vesselCont ?~ (targetLiq, vmm)
                                              & _2 <>+ mkFillUpMsg
                                              & _4 <>+ mkFillUpMsg
                                       | vAvail == targetMouths ->
                                           a' & _1.vesselTbl.ind targetId.vesselCont .~ Nothing
                                              & _1.vesselTbl.ind vi      .vesselCont ?~ (targetLiq, vmm)
                                              & _2 <>+ mkFillUpEmptyMsg
                                              & _4 <>+ mkFillUpEmptyMsg
                                       | otherwise ->
                                           a' & _1.vesselTbl.ind targetId.vesselCont .~ Nothing
                                              & _1.vesselTbl.ind vi      .vesselCont ?~ (targetLiq, vm + targetMouths)
                                              & _2 <>+ mkXferEmptyMsg
                                              & _4 <>+ mkXferEmptyMsg
      where
        (🍰) = (/=) `on` view liqId
        sorry' msg       = a' & _2 <>+ msg
        (vs, vmm)        = (getSing `fanUncurry` getMaxMouthfuls) (vi, ms')
        n                = renderLiqNoun targetLiq id
        mkFillUpMsg      = T.concat [ "You fill up the ", vs, " with ", n, " from the ", targetSing, "." ]
        mkFillUpEmptyMsg = T.concat [ "You fill up the ", vs, " with ", n, " from the ", targetSing, ", emptying it." ]
        mkXferEmptyMsg   = T.concat [ "You transfer ", n, " to the ", vs,  " from the ", targetSing, ", emptying it." ]
        bs               | (vo1, vo2) <- (targetSing, vs) & both %~ mkSerVerbObj . aOrAn
                         = pure ( T.concat [ serialize srcDesig, " transfers liquid from ", vo1, " to ", vo2, "." ]
                                , desigOtherIds srcDesig )

-----

genericAction :: HasCallStack => ActionParams
                              -> (MudState -> GenericRes)
                              -> Text
                              -> MudStack ()
genericAction p helper fn = helper |&| modifyState >=> \(toSelfs, bs, logMsgs) ->
    genericActionHelper p fn toSelfs bs logMsgs

genericActionHelper :: HasCallStack => ActionParams -> Text -> [Text] -> [Broadcast] -> [Text] -> MudStack ()
genericActionHelper ActionParams { .. } fn toSelfs bs logMsgs = getState >>= \ms -> do
    logMsgs |#| logPlaOut fn myId . map (parseDesigSuffix myId ms)
    multiWrapSend plaMsgQueue plaCols [ parseDesig Nothing myId ms msg | msg <- toSelfs ]
    bcastIfNotIncogNl myId bs

genericActionWithFuns :: HasCallStack => ActionParams
                                      -> (V.Vector Int -> MudState -> GenericResWithFuns)
                                      -> Text
                                      -> MudStack ()
genericActionWithFuns p helper fn = mkRndmVector >>= \v ->
    helper v |&| modifyState >=> \(toSelfs, bs, logMsgs, fs) -> do genericActionHelper p fn toSelfs bs logMsgs
                                                                   sequence_ fs

-----

genericSorry :: HasCallStack => MudState -> Text -> GenericRes
genericSorry ms = (ms, ) . (, [], []) . pure

genericSorryWithFuns :: HasCallStack => MudState -> Text -> GenericResWithFuns
genericSorryWithFuns ms = (ms, ) . (, [], [], []) . pure

-----

getActs :: HasCallStack => Id -> MudState -> [ActType]
getActs i = M.keys . getActMap i

-----

getDblLinkedSings :: HasCallStack => Id -> MudState -> ([Sing], [Sing])
getDblLinkedSings i ms = foldr helper mempties . getLinked i $ ms
  where
    helper targetSing pair = let targetId = getIdForPCSing targetSing ms
                                 lens     = isAwake targetId ms ? _1 :? _2
                             in (pair |&|) $ if s `elem` getLinked targetId ms then lens %~ (targetSing :) else id
    s = getSing i ms

-----

getMatchingChanWithName :: HasCallStack => Text -> [ChanName] -> [Chan] -> (ChanName, Chan)
getMatchingChanWithName match cns cs = let cn  = head . filter ((== match) . T.toLower) $ cns
                                           c   = head . filter (views chanName (== cn)) $ cs
                                       in (cn, c)

-----

getRelativePCName :: HasCallStack => MudState -> (Id, Id) -> MudStack Text
getRelativePCName ms pair@(_, y)
  | isLinked ms pair = return . getSing y $ ms
  | otherwise        = underline <$> uncurry updateRndmName pair

-----

hasHp :: HasCallStack => Id -> MudState -> Int -> Bool
hasHp = hasPoints curHp

hasMp :: HasCallStack => Id -> MudState -> Int -> Bool
hasMp = hasPoints curMp

hasPp :: HasCallStack => Id -> MudState -> Int -> Bool
hasPp = hasPoints curPp

hasFp :: HasCallStack => Id -> MudState -> Int -> Bool
hasFp = hasPoints curFp

hasPoints :: HasCallStack => Getter Mob Int -> Id -> MudState -> Int -> Bool
hasPoints lens i ms amt = views (mobTbl.ind i.lens) (>= amt) ms

-----

type FromId   = Id
type FromSing = Sing
type ToId     = Id
type ToSing   = Sing

helperDropEitherInv :: HasCallStack => Id
                                    -> Desig
                                    -> FromId
                                    -> ToId
                                    -> GenericIntermediateRes
                                    -> Either Text Inv
                                    -> GenericIntermediateRes
helperDropEitherInv i d fromId toId a@(ms, _, _, _) = \case
  Left  msg -> a & _2 <>+ msg
  Right is  -> let (is',     sorrys) = checkNowEating i ms "drop" "" is
                   (toSelfs, bs    ) = mkGetDropInvDescs i ms d Drop is'
               in a & _1.invTbl.ind fromId %~  (\\ is')
                    & _1.invTbl.ind toId   %~  addToInv ms is'
                    & _2                   <>~ sorrys ++ toSelfs
                    & _3                   <>~ bs
                    & _4                   <>~ toSelfs

checkNowEating :: HasCallStack => Id -> MudState -> Text -> Text -> Inv -> (Inv, [Text])
checkNowEating i ms a b is = let pair = (is, []) in case getNowEating i ms of
  Nothing                                 -> pair
  Just (eatId, eatSing) | eatId `elem` is -> (eatId `delete` is, pure . sorryEating a b $ eatSing)
                        | otherwise       -> pair

mkGetDropInvDescs :: HasCallStack => Id -> MudState -> Desig -> GetOrDrop -> Inv -> ([Text], [Broadcast])
mkGetDropInvDescs i ms d god (mkName_maybeCorpseId_count_bothList i ms -> tuple) = unzip . map helper $ tuple
  where
    helper (_, mci, c, (s, _)) | c == 1 =
        ( T.concat  [ "You ",               mkGodVerb god SndPer,   " the ", s,          "." ]
        , (T.concat [ serialize d, spaced . mkGodVerb god $ ThrPer, renderMaybeCorpseId, "." ], desigOtherIds d) )
      where
        renderMaybeCorpseId = mkSerVerbObj $ case mci of (Just ci) -> the . serialize . CorpseDesig $ ci
                                                         Nothing   -> aOrAn s
    helper (_, _, c, b) =
        ( T.concat  [ "You ",           mkGodVerb god SndPer, " ",              objTxt, "." ]
        , (T.concat [ serialize d, " ", mkGodVerb god ThrPer, " ", mkSerVerbObj objTxt, "." ], desigOtherIds d) )
      where
        objTxt = showTxt c |<>| mkPlurFromBoth b

mkName_maybeCorpseId_count_bothList :: HasCallStack => Id -> MudState -> Inv -> [(Text, Maybe Id, Int, BothGramNos)]
mkName_maybeCorpseId_count_bothList i ms targetIds =
    let names                         = [ getEffName i ms targetId        | targetId <- targetIds ]
        corpseIds                     = [ mkMaybeCorpseId targetId ms     | targetId <- targetIds ]
        boths@(mkCountList -> counts) = [ getEffBothGramNos i ms targetId | targetId <- targetIds ]
    in nubBy ((==) `on` dropSndOfQuad) . zip4 names corpseIds counts $ boths

mkMaybeCorpseId :: HasCallStack => Id -> MudState -> Maybe Id
mkMaybeCorpseId i ms | getType i ms == CorpseType = case getCorpse i ms of PCCorpse  {} -> Just i
                                                                           NpcCorpse {} -> Nothing
                     | otherwise                  = Nothing

mkGodVerb :: HasCallStack => GetOrDrop -> Verb -> Text
mkGodVerb Get  SndPer = "pick up"
mkGodVerb Get  ThrPer = "picks up"
mkGodVerb Drop SndPer = "drop"
mkGodVerb Drop ThrPer = "drops"

-----

helperExtinguishEitherInv :: HasCallStack => Id
                                          -> Desig
                                          -> GenericResWithFuns
                                          -> (Either Text Inv, InvOrEq)
                                          -> GenericResWithFuns
helperExtinguishEitherInv i d a@(ms, (_, _, _, _)) = \case
  (Left  msg, _) -> a & _2._1 <>+ msg
  (Right is,  x) -> let (is', toSelfs, bs) = mkExtinguishDescs i ms d (is, x)
                    in a & _1.lightTbl %~  flip (foldr $ \i' -> ind i'.lightIsLit .~ False) is'
                         & _2._1       <>~ toSelfs
                         & _2._2       <>~ bs
                         & _2._3       <>~ toSelfs
                         & _2._4       <>+ forM_ is' (\i' -> views (lightAsyncTbl.at i') maybeThrowDeath ms)

mkExtinguishDescs :: HasCallStack => Id -> MudState -> Desig -> (Inv, InvOrEq) -> (Inv, [Text], [Broadcast])
mkExtinguishDescs i ms d (is, x) = foldr f mempty is
  where
    f targetId tuple =
        let s        = getSing targetId ms
            inInvMsg | vo <- mkSerVerbObj . aOrAn $ s = T.concat [ serialize d, " extinguishes ", vo, " (carried)." ]
            inEqMsg  | d' <- serialize d { desigDoMaskInDark = False }
                     = T.concat [ d', " extinguishes ", mkPossPro . getSex i $ ms, " ", s, "." ]
            sorry g  = tuple & _2 %~ (g s :)
        in if | getType targetId ms /= LightType              -> sorry sorryExtinguishType
              | views lightIsLit not . getLight targetId $ ms -> sorry sorryExtinguishNotLit
              | otherwise -> tuple & _1 %~ (targetId :)
                                   & _2 %~ ((prd $ "You extinguish the " <> s) :)
                                   & _3 %~ ((x == TheInv ? inInvMsg :? inEqMsg, desigOtherIds d) :)

-----

helperGetDropEitherCoins :: HasCallStack => Id
                                         -> Desig
                                         -> GetOrDrop
                                         -> FromId
                                         -> ToId
                                         -> GenericIntermediateRes
                                         -> [Either [Text] Coins]
                                         -> GenericIntermediateRes
helperGetDropEitherCoins i d god fromId toId (ms, toSelfs, bs, logMsgs) ecs =
    let (ms', toSelfs', logMsgs', canCoins) = foldl' helper (ms, toSelfs, logMsgs, mempty) ecs
    in (ms', toSelfs', bs ++ mkGetDropCoinsDescOthers d god canCoins, logMsgs')
  where
    helper a@(ms', _, _, _) = \case
      Left  msgs -> a & _2 <>~ msgs
      Right c    -> let (can, can't) = case god of Get  -> partitionCoinsByEnc i ms' c
                                                   Drop -> (c, mempty)
                        toSelfs'     = mkGetDropCoinsDescsSelf god can
                    in a & _1.coinsTbl.ind fromId %~  (<> negateCoins can)
                         & _1.coinsTbl.ind toId   %~  (<>             can)
                         & _2                     <>~ toSelfs' ++ mkCan'tGetCoinsDesc can't
                         & _3                     <>~ toSelfs'
                         & _4                     <>~ can

partitionCoinsByEnc :: HasCallStack => Id -> MudState -> Coins -> (Coins, Coins)
partitionCoinsByEnc = partitionCoinsHelper calcMaxEnc calcWeight coinWeight

partitionCoinsHelper :: HasCallStack => (Id -> MudState -> Int)
                                     -> (Id -> MudState -> Int)
                                     -> Int
                                     -> Id
                                     -> MudState
                                     -> Coins
                                     -> (Coins, Coins)
partitionCoinsHelper calcMax calcCurr factor i ms coins = let maxAmt    = calcMax  i ms
                                                              currAmt   = calcCurr i ms
                                                              noOfCoins = sum . coinsToList $ coins
                                                              coinsAmt  = noOfCoins * factor
                                                          in if currAmt + coinsAmt <= maxAmt
                                                            then (coins, mempty)
                                                            else let availAmt     = maxAmt - currAmt
                                                                     canNoOfCoins = availAmt `quot` factor
                                                                 in mkCanCan'tCoins coins canNoOfCoins

mkCanCan'tCoins :: HasCallStack => Coins -> Int -> (Coins, Coins)
mkCanCan'tCoins (Coins (c, 0, 0)) n = (Coins (n, 0, 0), Coins (c - n, 0,     0    ))
mkCanCan'tCoins (Coins (0, s, 0)) n = (Coins (0, n, 0), Coins (0,     s - n, 0    ))
mkCanCan'tCoins (Coins (0, 0, g)) n = (Coins (0, 0, n), Coins (0,     0,     g - n))
mkCanCan'tCoins c                 _ = pmf "mkCanCan'tCoins" c

mkGetDropCoinsDescOthers :: HasCallStack => Desig -> GetOrDrop -> Coins -> [Broadcast]
mkGetDropCoinsDescOthers d god c =
  c |!| [ ( T.concat [ serialize d, spaced . mkGodVerb god $ ThrPer, mkSerVerbObj . aCoinSomeCoins $ c, "." ]
          , desigOtherIds d ) ]

mkGetDropCoinsDescsSelf :: HasCallStack => GetOrDrop -> Coins -> [Text]
mkGetDropCoinsDescsSelf god = mkCoinsMsgs helper
  where
    helper 1 cn = T.concat [ "You ", mkGodVerb god SndPer, " ",            aOrAn cn, "."  ]
    helper a cn = T.concat [ "You ", mkGodVerb god SndPer, spaced . showTxt $ a, cn, "s." ]

mkCan'tGetCoinsDesc :: HasCallStack => Coins -> [Text]
mkCan'tGetCoinsDesc = mkCoinsMsgs (can'tCoinsDescHelper sorryGetEnc)

can'tCoinsDescHelper :: HasCallStack => Text -> Int -> Text -> Text
can'tCoinsDescHelper t a cn = t <> bool (T.concat [ showTxt a, " ", cn, "s." ]) (prd . the $ cn) (a == 1)

-----

helperGetEitherInv :: HasCallStack => Id
                                   -> Desig
                                   -> FromId
                                   -> GenericIntermediateRes
                                   -> Either Text Inv
                                   -> GenericIntermediateRes
helperGetEitherInv i d fromId a@(ms, _, _, _) = \case
  Left  msg                              -> a & _2 <>+ msg
  Right (sortByType -> (npcPCs, others)) ->
    let maxEnc            = calcMaxEnc i ms
        (_, cans, can'ts) = foldl' (partitionInvByEnc ms maxEnc)
                                   (calcWeight i ms, [], [])
                                   others
        (toSelfs, bs    ) = mkGetDropInvDescs i ms d Get cans
    in a & _1.invTbl.ind fromId %~  (\\ cans)
         & _1.invTbl.ind i      %~  addToInv ms cans
         & _2                   <>~ concat [ map sorryType npcPCs
                                           , toSelfs
                                           , mkCan'tGetInvDescs i ms maxEnc can'ts ]
         & _3                   <>~ bs
         & _4                   <>~ toSelfs
  where
    sortByType             = foldr helper mempties
    helper targetId sorted = let lens = case getType targetId ms of PlaType -> _1
                                                                    NpcType -> _1
                                                                    _       -> _2
                             in sorted & lens %~ (targetId :)
    sorryType targetId     = sorryGetType . serialize . mkStdDesig targetId ms $ Don'tCap

partitionInvByEnc :: HasCallStack => MudState -> Weight -> (Weight, Inv, Inv) -> Id -> (Weight, Inv, Inv)
partitionInvByEnc = partitionInvHelper calcWeight

partitionInvHelper :: HasCallStack => (Id -> MudState -> Int) -> MudState -> Int -> (Int, Inv, Inv) -> Id -> (Int, Inv, Inv)
partitionInvHelper f ms maxAmt acc@(x, _, _) targetId = let x' = x + f targetId ms
                                                            a  = acc & _1 .~ x' & _2 <>+ targetId
                                                            b  = acc & _3 <>+ targetId
                                                        in bool b a $ x' <= maxAmt

mkCan'tGetInvDescs :: HasCallStack => Id -> MudState -> Weight -> Inv -> [Text]
mkCan'tGetInvDescs i ms maxEnc = concatMap helper
  where
    helper targetId | calcWeight targetId ms > maxEnc = pure . sorryGetWeight . getSing targetId $ ms
                    | otherwise                       = can'tInvDescsHelper sorryGetEnc i ms . pure $ targetId

can'tInvDescsHelper :: HasCallStack => Text -> Id -> MudState -> Inv -> [Text]
can'tInvDescsHelper t i ms = map helper . mkNameCountBothList i ms
  where
    helper (_, c, b@(s, _)) = t <> bool (T.concat [ showTxt c, " ", mkPlurFromBoth b, "." ]) (prd . the $ s) (c == 1)

-----

helperLinkUnlink :: HasCallStack => MudState -> Id -> MsgQueue -> Cols -> MudStack (Maybe ([Text], [Text], [Text]))
helperLinkUnlink ms i mq cols =
    let s                = getSing   i ms
        othersLinkedToMe = getLinked i ms
        meLinkedToOthers = foldr buildSingList [] $ views pcTbl ((i `delete`) . IM.keys) ms
        buildSingList pi acc | s `elem` getLinked pi ms = getSing pi ms : acc
                             | otherwise                = acc
        twoWays              = map fst . filter ((== 2) . snd) . countOccs $ othersLinkedToMe ++ meLinkedToOthers
    in if uncurry (&&) . ((()#) *** (()#)) $ (othersLinkedToMe, meLinkedToOthers)
      then emptied $ do logPlaOut "helperLinkUnlink" i . pure $ sorryNoLinks
                        wrapSend mq cols (isSpiritId i ms ? sorryNoLinksSpirit :? sorryNoLinks)
      else unadulterated (meLinkedToOthers, othersLinkedToMe, twoWays)

-----

helperSettings :: HasCallStack => Id -> MudState -> (Pla, [Text], [Text]) -> Text -> (Pla, [Text], [Text])
helperSettings _ _ a@(_, msgs, _) arg@(length . filter (== '=') . T.unpack -> noOfEqs)
  | or [ noOfEqs /= 1, T.head arg == '=', T.last arg == '=' ] =
      let msg    = sorryParseArg arg
          f      = any (adviceSettingsInvalid `T.isInfixOf`) msgs ?  (++ pure msg)
                                                                  :? (++ [ msg <> adviceSettingsInvalid ])
      in a & _2 %~ f
helperSettings i ms a (T.breakOn "=" -> (name, T.tail -> value)) =
    findFullNameForAbbrev name (map fst . mkSettingPairs i $ ms) |&| maybe notFound found
  where
    notFound    = appendMsg . sorrySetName $ name
    appendMsg m = a & _2 <>+ m
    found       = \case "admin"    -> alterTuning "admin" IsTunedAdmin
                        "columns"  -> procEither . alterNumeric minCols      maxCols      "columns" $ columns
                        "lines"    -> procEither . alterNumeric minPageLines maxPageLines "lines"   $ pageLines
                        "question" -> alterTuning "question" IsTunedQuestion
                        "hp"       -> alterPts "hp" IsShowingHp
                        "mp"       -> alterPts "mp" IsShowingMp
                        "pp"       -> alterPts "pp" IsShowingPp
                        "fp"       -> alterPts "fp" IsShowingFp
                        t          -> pmf "helperSettings found" t
      where
        procEither f = parseInt |&| either appendMsg f
        parseInt     = case reads . T.unpack $ value of [(x, "")] -> Right x
                                                        _         -> sorryParse
        sorryParse   = Left . sorryParseSetting value $ name
    alterNumeric minVal maxVal settingName lens x
      | not . inRange (minVal, maxVal) $ x = appendMsg . sorrySetRange settingName minVal $ maxVal
      | otherwise = let msg = T.concat [ "Set ", settingName, " to ", showTxt x, "." ]
                    in appendMsg msg & _1.lens .~ x & _3 <>+ msg
    alterTuning n flag = case lookup value inOutOnOffs of
      Nothing      -> appendMsg . sorryParseInOut value $ n
      Just newBool -> let msg = T.concat [ "Tuned ", inOut newBool, " the ", n, " channel." ]
                      in appendMsg msg & _1 %~ setPlaFlag flag newBool & _3 <>+ msg
    alterPts n flag = case lookup value onOffs of
      Nothing      -> appendMsg . sorryParseOnOff value $ n
      Just newBool -> let msg = T.concat [ "Turned ", onOff newBool, " ", T.toUpper n, " in prompt." ]
                      in appendMsg msg & _1 %~ setPlaFlag flag newBool & _3 <>+ msg

mkSettingPairs :: HasCallStack => Id -> MudState -> [(Text, Text)]
mkSettingPairs i ms = let p = getPla i ms
                      in onTrue (isAdmin p) (adminPair p :) . pairs $ p
  where
    pairs p   = [ ("columns",  showTxt . getColumns   i  $ ms)
                , ("lines",    showTxt . getPageLines i  $ ms)
                , ("question", inOut   . isTunedQuestion $ p )
                , ("hp",       onOff   . isShowingHp     $ p )
                , ("mp",       onOff   . isShowingMp     $ p )
                , ("pp",       onOff   . isShowingPp     $ p )
                , ("fp",       onOff   . isShowingFp     $ p ) ]
    adminPair = ("admin", ) . inOut . isTunedAdmin

-----

helperTune :: HasCallStack => Sing -> (TeleLinkTbl, [Chan], [Text], [Text]) -> Text -> (TeleLinkTbl, [Chan], [Text], [Text])
helperTune _ a arg@(length . filter (== '=') . T.unpack -> noOfEqs)
  | or [ noOfEqs /= 1, T.head arg == '=', T.last arg == '=' ] = a & _3 %~ tuneInvalidArg arg
helperTune s a@(linkTbl, chans, _, _) arg@(T.breakOn "=" -> (name, T.tail -> value)) = case lookup value inOutOnOffs of
  Nothing  -> a & _3 %~ tuneInvalidArg arg
  Just val -> let connNames = "all" : linkNames ++ chanNames
              in findFullNameForAbbrev name connNames |&| maybe notFound (found val)
  where
    linkNames   = map uncapitalize . M.keys $ linkTbl
    chanNames   = selects chanName T.toLower chans
    notFound    = a & _3 <>+ sorryTuneName name
    found val n = if n == "all"
                    then appendMsg "all telepathic connections" & _1 %~ M.map (const val)
                                                                & _2 %~ map (chanConnTbl.at s ?~ val)
                    else foundHelper
      where
        appendMsg connName = let msg = T.concat [ "You tune ", connName, " ", inOut val, "." ]
                             in a & _3 <>+ msg & _4 <>+ msg
        foundHelper
          | n `elem` linkNames = let n' = capitalize n in appendMsg n' & _1.at n' ?~ val
          | otherwise          = case partition (views chanName ((== n) . T.toLower)) chans of
            (match:_, others) -> appendMsg (views chanName dblQuote match) & _2 .~ (match & chanConnTbl.at s ?~ val) : others
            _                 -> blowUp "helperTune found foundHelper" "connection name not found" n

tuneInvalidArg :: HasCallStack => Text -> [Text] -> [Text]
tuneInvalidArg arg msgs = let msg = sorryParseArg arg in
    msgs |&| (any (adviceTuneInvalid `T.isInfixOf`) msgs ? (++ pure msg) :? (++ [ msg <> adviceTuneInvalid ]))

-----

helperUnready :: HasCallStack => Id
                              -> MudState
                              -> Desig
                              -> (EqTbl, InvTbl, [Text], [Broadcast], [Text])
                              -> Either Text Inv
                              -> (EqTbl, InvTbl, [Text], [Broadcast], [Text])
helperUnready i ms d a = \case
  Left  msg       -> a & _3 <>+ msg
  Right targetIds -> let (bs, msgs) = mkUnreadyDescs i ms d targetIds
                     in a & _1.ind i %~ M.filter (`notElem` targetIds)
                          & _2.ind i %~ addToInv ms targetIds
                          & _3 <>~ msgs
                          & _4 <>~ bs
                          & _5 <>~ msgs

mkUnreadyDescs :: HasCallStack => Id
                               -> MudState
                               -> Desig
                               -> Inv
                               -> ([Broadcast], [Text])
mkUnreadyDescs i ms d = unzipAndSort . map helper . mkId_count_both_isLitLightList i ms
  where
    helper (targetId, count, b@(targetSing, _), isLit) = if count == 1
      then let toSelfMsg   = T.concat [ "You ", mkVerb targetId SndPer, " the ", targetSing, "." ]
               toOthersMsg = prd $ d' |<>| mkVerb targetId ThrPer |<>| f (aOrAn targetSing)
           in (((toOthersMsg, desigOtherIds d), isLit), toSelfMsg)
      else let toSelfMsg   = T.concat [ "You ", mkVerb targetId SndPer, spaced . showTxt $ count, mkPlurFromBoth b, "." ]
               toOthersMsg = prd $ d' |<>| mkVerb targetId ThrPer |<>| f (showTxt count |<>| mkPlurFromBoth b)
           in (((toOthersMsg, desigOtherIds d), isLit), toSelfMsg)
      where
        d' = serialize (isLit ? d { desigDoMaskInDark = False } :? d)
        f  = onFalse isLit mkSerVerbObj
    mkVerb targetId person = case getType targetId ms of
      ArmType   -> case getArmSub targetId ms of Head     -> mkVerbTakeOff person
                                                 Hands    -> mkVerbTakeOff person
                                                 Feet     -> mkVerbTakeOff person
                                                 Shield   -> mkVerbUnready person
                                                 _        -> mkVerbDoff    person
      ClothType -> case getCloth targetId ms of  Earring  -> mkVerbRemove  person
                                                 NoseRing -> mkVerbRemove  person
                                                 Necklace -> mkVerbTakeOff person
                                                 Bracelet -> mkVerbTakeOff person
                                                 Ring     -> mkVerbTakeOff person
                                                 Backpack -> mkVerbTakeOff person
                                                 _        -> mkVerbDoff    person
      ConType                    -> mkVerbTakeOff person
      WpnType | person == SndPer -> "stop wielding"
              | otherwise        -> "stops wielding"
      _                          -> mkVerbUnready person
    mkVerbRemove  = \case SndPer -> "remove"
                          ThrPer -> "removes"
    mkVerbTakeOff = \case SndPer -> "take off"
                          ThrPer -> "takes off"
    mkVerbDoff    = \case SndPer -> "doff"
                          ThrPer -> "doffs"
    mkVerbUnready = \case SndPer -> "unready"
                          ThrPer -> "unreadies"
    -- Sort the broadcasts such that lit light sources will appear to be unreadied first (this is important in the case
    -- that the unreadying of a lit light source plunges the room into darkness).
    unzipAndSort = first (map fst) . first (sortBy (flip compare `on` snd)) . unzip

mkId_count_both_isLitLightList :: HasCallStack => Id -> MudState -> Inv -> [(Id, Int, BothGramNos, Bool)]
mkId_count_both_isLitLightList i ms targetIds =
    let boths@(mkCountList -> counts) = [ getEffBothGramNos i ms targetId | targetId <- targetIds ]
        isLitLights                   = [ isLitLight targetId ms          | targetId <- targetIds ]
    in filterThem . nubBy ((==) `on` dropFstOfQuad) . zip4 targetIds counts boths $ isLitLights
  where
    -- In the case that the player is unreadying two light sources of the same name, and one of them is lit while the
    -- other is not, there will exist one tuple for the lit light source and another tuple for the unlit light source
    -- (the tuples will have the same "count" and "both grammar numbers"). We only want to keep the tuple for which the
    -- "is lit light" boolean is "True".
    filterThem xs = let f xs' []                     = xs'
                        f xs' ((_, c, b, True):rest) = f (filter ((/= (c, b, False)) . dropFstOfQuad) xs') rest
                        f xs' (_              :rest) = f xs' rest
                    in f xs xs

-----

inOutOnOffs :: HasCallStack => [(Text, Bool)]
inOutOnOffs = [ ("i",   True )
              , ("in",  True )
              , ("o",   False)
              , ("of",  False)
              , ("off", False)
              , ("on",  True )
              , ("ou",  False)
              , ("out", False) ]

-----

isRingRol :: HasCallStack => RightOrLeft -> Bool
isRingRol = \case R -> False
                  L -> False
                  _ -> True

-----

isRndmName :: HasCallStack => Text -> Bool
isRndmName = isLower . T.head . dropANSI

-----

isSlotAvail :: HasCallStack => EqMap -> Slot -> Bool
isSlotAvail = flip M.notMember

findAvailSlot :: HasCallStack => EqMap -> [Slot] -> Maybe Slot
findAvailSlot em = find (isSlotAvail em)

-----

maybeSingleSlot :: HasCallStack => EqMap -> Slot -> Maybe Slot
maybeSingleSlot em s = boolToMaybe (isSlotAvail em s) s

-----

mkChanBindings :: HasCallStack => Id -> MudState -> ([Chan], [ChanName], Sing)
mkChanBindings i ms = let { cs = getPCChans i ms; cns = select chanName cs } in (cs, cns, getSing i ms)

-----

mkChanNamesTunings :: HasCallStack => Id -> MudState -> ([Text], [Bool])
mkChanNamesTunings i ms = unzip . sortBy (compare `on` fst) . map helper . getPCChans i $ ms
  where
    helper = view chanName &&& views chanConnTbl (M.! getSing i ms)

-----

mkCoinsDesc :: HasCallStack => Cols -> Coins -> Text
mkCoinsDesc cols (Coins (each %~ Sum -> (cop, sil, gol))) =
    T.unlines . intercalate mMempty . map (wrap cols) . dropEmpties $ [ cop |!| copDesc
                                                                      , sil |!| silDesc
                                                                      , gol |!| golDesc ]
  where
    copDesc = "The copper piece is round and shiny."
    silDesc = "The silver piece is round and shiny."
    golDesc = "The gold piece is round and shiny."

-----

mkCorpseSmellLvl :: HasCallStack => Text -> Int
mkCorpseSmellLvl t = if | t == corpseSmellLvl1Msg -> 1
                        | t == corpseSmellLvl2Msg -> 2
                        | t == corpseSmellLvl3Msg -> 3
                        | t == corpseSmellLvl4Msg -> 4
                        | otherwise               -> blowUp "mkCorpseSmellLvl" "unexpected ent smell" . showTxt $ t

-----

mkEffStDesc :: HasCallStack => Id -> MudState -> Text
mkEffStDesc = mkEffDesc getBaseSt calcEffSt "weaker" "stronger"

mkEffDesc :: HasCallStack => (Id -> MudState -> Int) -> (Id -> MudState -> Int) -> Text -> Text -> Id -> MudState -> Text
mkEffDesc f g lessAdj moreAdj i ms =
    let x    = f i ms
        y    = g i ms - x
        p    = y `percent` x
        over = let (q, r) = y `quotRem` x
                   t      = mkDescForPercent (r `percent` x) [ (19,  "00")
                                                             , (39,  "20")
                                                             , (59,  "40")
                                                             , (79,  "60")
                                                             , (99,  "80") ]
               in colorWith magenta . T.concat $ [ "You feel ", showTxt q, t, "% ", moreAdj, " than usual." ]
    in mkDescForPercent p [ (-84, colorWith magenta $ "You feel immensely "    <> lessAdj <> " than usual.")
                          , (-70, colorWith red     $ "You feel exceedingly "  <> lessAdj <> " than usual.")
                          , (-56,                     "You feel quite a bit "  <> lessAdj <> " than usual.")
                          , (-42,                     "You feel considerably " <> lessAdj <> " than usual.")
                          , (-28,                     "You feel moderately "   <> lessAdj <> " than usual.")
                          , (-14,                     "You feel a little "     <> lessAdj <> " than usual.")
                          , (0,                       ""                                                   )
                          , (14,                      "You feel a little "     <> moreAdj <> " than usual.")
                          , (28,                      "You feel moderately "   <> moreAdj <> " than usual.")
                          , (42,                      "You feel considerably " <> moreAdj <> " than usual.")
                          , (56,                      "You feel quite a bit "  <> moreAdj <> " than usual.")
                          , (70,  colorWith red     $ "You feel strikingly "   <> moreAdj <> " than usual.")
                          , (84,  colorWith magenta $ "You feel exceedingly "  <> moreAdj <> " than usual.")
                          , (99,  colorWith magenta $ "You feel immensely "    <> moreAdj <> " than usual.")
                          , (100, over                                                                     ) ]

mkEffDxDesc :: HasCallStack => Id -> MudState -> Text
mkEffDxDesc = mkEffDesc getBaseDx calcEffDx "less agile" "more agile"

mkEffHtDesc :: HasCallStack => Id -> MudState -> Text
mkEffHtDesc = mkEffDesc getBaseHt calcEffHt "less vigorous" "more vigorous"

mkEffMaDesc :: HasCallStack => Id -> MudState -> Text
mkEffMaDesc = mkEffDesc getBaseMa calcEffMa "less proficient in magic" "more proficient in magic"

mkEffPsDesc :: HasCallStack => Id -> MudState -> Text
mkEffPsDesc = mkEffDesc getBasePs calcEffPs "less proficient in psionics" "more proficient in psionics"

-----

mkEntDescs :: HasCallStack => Id -> Cols -> MudState -> Inv -> Text
mkEntDescs i cols ms eis = nls [ mkEntDesc i cols ms (ei, e) | ei <- eis, let e = getEnt ei ms ]

mkEntDesc :: HasCallStack => Id -> Cols -> MudState -> (Id, Ent) -> Text
mkEntDesc i cols ms (ei, e) =
    case t of ConType      ->                  (ed <>) . mkInvCoinsDesc i cols ms ei $ s
              CorpseType   -> (corpseTxt <>)           . mkInvCoinsDesc i cols ms ei $ s
              NpcType      ->                  (ed <>) . (tempDescHelper <>) . mkEqDesc i cols ms ei s $ t
              PlaType      -> (pcHeader  <>) . (ed <>) . (tempDescHelper <>) . mkEqDesc i cols ms ei s $ t
              VesselType   ->                  (ed <>) . mkVesselContDesc  cols ms $ ei
              WritableType ->                  (ed <>) . mkWritableMsgDesc cols ms $ ei
              _            -> ed
  where
    ed                  = let foodTxt  = t == FoodType  |?| spcL (mkFoodRemTxt         ei ms)
                              lightTxt = t == LightType |?| spcL (mkLight_rem_isLitTxt ei ms)
                              desc     = T.concat [ e^.entDesc, foodTxt, lightTxt ]
                          in wrapUnlines cols desc <> mkAuxDesc i cols ms ei
    (s, t)              = (getSing `fanUncurry` getType) (ei, ms)
    corpseTxt           = let txt = expandCorpseTxt (mkCorpseAppellation i ms ei) . getCorpseDesc ei $ ms
                          in wrapUnlines cols txt <> mkAuxDesc i cols ms ei
    pcHeader            = wrapUnlines cols mkPCDescHeader
    mkPCDescHeader      = let sexRace = uncurry (|<>|) . mkPrettySexRace ei $ ms
                          in T.concat [ "You see a ", sexRace, rmDescHelper, adminTagHelper, "." ]
    rmDescHelper        = case mkMobRmDesc ei ms of "" -> ""
                                                    d  -> spcL d
    adminTagHelper      | isAdminId ei ms = spcL adminTagTxt
                        | otherwise       = ""
    tempDescHelper      = maybeEmp (wrapUnlines cols . coloredBracketQuote) . getTempDesc ei $ ms
    coloredBracketQuote = quoteWith' (("[ ", " ]") & both %~ colorWith tempDescColor)

mkAuxDesc :: HasCallStack => Id -> Cols -> MudState -> Id -> Text
mkAuxDesc i cols ms i' = maybeEmp (wrapUnlines cols) . mkMaybeHumMsg i ms i' $ id

mkMaybeHumMsg :: HasCallStack => Id -> MudState -> Id -> (Text -> Text) -> Maybe Text
mkMaybeHumMsg i ms i' f | t <- getType i' ms, hasObj t, isHummingId i' ms = Just . humMsg . f $ if t == CorpseType
                          then mkCorpseAppellation i ms i'
                          else getSing i' ms
                        | otherwise = Nothing

mkInvCoinsDesc :: HasCallStack => Id -> Cols -> MudState -> Id -> Sing -> Text
mkInvCoinsDesc i cols ms i' s =
    let pair@(is, c)           = (getInv `fanUncurry` getCoins) (i', ms)
        msg | i' == i          = dudeYourHandsAreEmpty
            | t  == CorpseType = "There is nothing on the corpse."
            | otherwise        = the' $ s <> " is empty."
    in case ((()#) *** (()#)) pair of
      (True,  True ) -> wrapUnlines cols msg
      (False, True ) -> header <> mkEntsInInvDesc i cols ms is                          <> footer
      (True,  False) -> header                                 <> mkCoinsSummary cols c <> footer
      (False, False) -> header <> mkEntsInInvDesc i cols ms is <> mkCoinsSummary cols c <> footer
  where
    t      = getType i' ms
    header = i' == i ? nl "You are carrying:" :? let n = t == CorpseType ? mkCorpseAppellation i ms i' :? s
                                                 in wrapUnlines cols . the' $ n <> " contains:"
    footer | i' == i   = nl $ showTxt (calcEncPer     i  ms) <> "% encumbered."
           | otherwise = nl $ showTxt (calcConPerFull i' ms) <> "% full."

mkEntsInInvDesc :: HasCallStack => Id -> Cols -> MudState -> Inv -> Text
mkEntsInInvDesc i cols ms =
    T.unlines . concatMap (wrapIndent bracketedEntNamePadding cols . helper) . mkStyledName_count_bothList i ms
  where
    helper (padBracketedEntName -> en, c, (s, _)) | c == 1 = en <> "1 " <> s
    helper (padBracketedEntName -> en, c, b     )          = T.concat [ en, commaShow c, " ", mkPlurFromBoth b ]

mkStyledName_count_bothList :: HasCallStack => Id -> MudState -> Inv -> [(Text, Int, BothGramNos)]
mkStyledName_count_bothList i ms is =
    let f                             = styleAbbrevs DoCoins DoQuote
        styleds                       = f [ getEffName        i ms targetId | targetId <- is ]
        boths@(mkCountList -> counts) =   [ getEffBothGramNos i ms targetId | targetId <- is ]
    in nub . zip3 styleds counts $ boths

mkCoinsSummary :: HasCallStack => Cols -> Coins -> Text
mkCoinsSummary cols = helper . zipWith mkNameAmt coinNames . coinsToList
  where
    helper         = T.unlines . wrapIndent 2 cols . commas . dropEmpties
    mkNameAmt cn a = Sum a |!| commaShow a |<>| bracketQuote (colorWith abbrevColor cn)

mkFoodRemTxt :: HasCallStack => Id -> MudState -> Text
mkFoodRemTxt i ms = perRemHelper (calcFoodPerRem i ms) Nothing

perRemHelper :: HasCallStack => Int -> Maybe Text -> Text
perRemHelper x = helper . fromMaybeEmp
  where
    helper t = parensQuote $ showTxt x <> "% remaining" <> t

mkLight_rem_isLitTxt :: HasCallStack => Id -> MudState -> Text
mkLight_rem_isLitTxt i ms = perRemHelper (calcLightPerRem i ms) $ if getLightIsLit i ms
  then Just $ ", " <> colorWith emphasisColor "lit"
  else Nothing

mkEqDesc :: HasCallStack => Id -> Cols -> MudState -> Id -> Sing -> Type -> Text
mkEqDesc i cols ms descId descSing descType = let descs = bool mkDescsOther mkDescsSelf $ descId == i in
    ()# descs ? noDescs :? ((header <>) . T.unlines . concatMap (wrapIndent 15 cols) $ descs)
  where
    mkDescsSelf =
        let (is, slotNames, es) = unzip3 [ (ei, pp slot, getEnt ei ms) | (slot, ei) <- M.toList . getEqMap i $ ms ]
            (sings, ens)        = unzip  [ view sing &&& mkEntName $ e | e          <- es                         ]
        in map helper . zip4 is slotNames sings . styleAbbrevs DoCoins DoQuote $ ens
      where
        helper (ei, T.breakOn (spcL "finger") -> (slotName, _), s, styled) =
            T.concat [ parensPad 15 slotName, s, mkAux ei, " ", styled ]
    mkDescsOther = map helper [ (pp slot, getSing ei ms, mkAux ei) | (slot, ei) <- M.toList . getEqMap descId $ ms ]
      where
        helper (T.breakOn (spcL "finger") -> (slotName, _), s, aux) = parensPad 15 slotName <> s <> aux
    mkAux ei = isLitLight ei ms |?| (spcL . parensQuote . colorWith emphasisColor $ "lit")
    noDescs  = wrapUnlines cols $ if
      | descId   == i       -> dudeYou'reNaked
      | descType == PlaType -> parseDesig Nothing i ms $ d <> " doesn't have anything readied."
      | otherwise           -> theOnLowerCap descSing      <> " doesn't have anything readied."
    header = wrapUnlines cols $ if
      | descId   == i       -> "You have readied the following equipment:"
      | descType == PlaType -> parseDesig Nothing i ms $ d <> " has readied the following equipment:"
      | otherwise           -> theOnLowerCap descSing      <> " has readied the following equipment:"
    d = serialize . mkStdDesig descId ms $ DoCap

mkVesselContDesc :: HasCallStack => Cols -> MudState -> Id -> Text
mkVesselContDesc cols ms targetId =
    let s = getSing   targetId ms
        v = getVessel targetId ms
        emptyDesc         = wrapUnlines cols . the' $ s <> " is empty."
        mkContDesc (l, m) = wrapUnlines cols . T.concat $ [ "The ", s, " contains ", renderLiqNoun l aOrAn, " "
                                                          , parensQuote $ showTxt (calcVesselPerFull v m) <> "% full", "." ]
    in views vesselCont (maybe emptyDesc mkContDesc) v

mkWritableMsgDesc :: HasCallStack => Cols -> MudState -> Id -> Text
mkWritableMsgDesc cols ms targetId = case getWritable targetId ms of
  (Writable Nothing          _       ) -> ""
  (Writable (Just _        ) (Just _)) -> helper "a language you don't recognize"
  (Writable (Just (_, lang)) Nothing ) -> helper . pp $ lang
  where
    helper txt = wrapUnlines cols . prd $ "There is something written on it in " <> txt

adminTagTxt :: HasCallStack => Text
adminTagTxt = parensQuote . colorWith adminTagColor $ "admin"

-----

mkExitsSummary :: HasCallStack => Cols -> Rm -> Text
mkExitsSummary cols (view rmLinks -> rls) =
    let stdNames    = [ rl^.slDir  .to (colorWith exitsColor . linkDirToCmdName) | rl <- rls, not . isNonStdLink $ rl ]
        customNames = [ rl^.nslName.to (colorWith exitsColor                   ) | rl <- rls,       isNonStdLink   rl ]
    in T.unlines . wrapIndent 2 cols . ("Obvious exits: " <>) . summarize stdNames $ customNames
  where
    summarize []  []  = "None!"
    summarize std cus = commas . (std ++) $ cus

isNonStdLink :: HasCallStack => RmLink -> Bool
isNonStdLink NonStdLink {} = True
isNonStdLink _             = False

-----

mkFpDesc :: HasCallStack => Id -> MudState -> Text
mkFpDesc i ms = let (c, m) = getFps i ms
                in mkDescForPercent9 (c `percent` m) [ colorWith magenta exhaustedMsg
                                                     , colorWith magenta "You are seriously tired."
                                                     , colorWith red     "You are extremely tired."
                                                     , "You are very tired."
                                                     , "You are quite tired."
                                                     , "You are considerably tired."
                                                     , "You are moderately tired."
                                                     , "You are slightly tired."
                                                     , "" ]

mkDescForPercent9 :: HasCallStack => Int -> [Text] -> Text
mkDescForPercent9 x = mkDescForPercent x . zip [ 0, 14, 28, 42, 56, 70, 84, 99, 100 ]

mkDescForPercent :: HasCallStack => Int -> [(Int, Text)] -> Text
mkDescForPercent _ []                          = blowUp "mkDescForPercent" "empty list" ""
mkDescForPercent _ [(_, txt)]                  = txt
mkDescForPercent x ((y, txt):rest) | x <= y    = txt
                                   | otherwise = mkDescForPercent x rest

-----

mkFullDesc :: HasCallStack => Id -> MudState -> Text
mkFullDesc i ms = mkDescForPercent9 (calcStomachPerFull i ms)
    [ "You are famished."
    , "You are extremely hungry."
    , "You are quite hungry."
    , "You feel a little hungry."
    , ""
    , "You feel satisfied."
    , "You are quite full."
    , "You are extremely full."
    , "You are profoundly satiated. You don't feel so good..." ]

-----

mkHpDesc :: HasCallStack => Id -> MudState -> Text
mkHpDesc i ms =
    let (c, m) = getHps i ms
    in mkDescForPercent (c `percent` m) [ (-15, colorWith magenta "You are dead."                            )
                                        , (0,   colorWith magenta "You are unconscious and mortally wounded.")
                                        , (14,  colorWith magenta "You are critically wounded."              )
                                        , (28,  colorWith red     "You are extremely wounded."               )
                                        , (42,                    "You are badly wounded."                   )
                                        , (56,                    "You are quite wounded."                   )
                                        , (70,                    "You are considerably wounded."            )
                                        , (84,                    "You are moderately wounded."              )
                                        , (99,                    "You are lightly wounded."                 )
                                        , (100,                   ""                                         ) ]

-----

mkLastArgIsTargetBindings :: HasCallStack => Id -> MudState -> Args -> LastArgIsTargetBindings
mkLastArgIsTargetBindings i ms as | (lastArg, others) <- mkLastArgWithNubbedOthers as =
    LastArgIsTargetBindings { srcDesig    = mkStdDesig  i ms DoCap
                            , srcInvCoins = getInvCoins i ms
                            , rmInvCoins  = first (i `delete`) . getMobRmVisibleInvCoins i $ ms
                            , targetArg   = lastArg
                            , otherArgs   = others }

mkLastArgWithNubbedOthers :: HasCallStack => Args -> (Text, Args)
mkLastArgWithNubbedOthers as = let lastArg = last as
                                   otherArgs = init $ case as of [_, _] -> as
                                                                 _      -> (++ pure lastArg) . nub . init $ as
                               in (lastArg, otherArgs)

-----

mkMaybeCorpseSmellMsg :: HasCallStack => Id -> MudState -> Id -> (Text -> Text) -> Maybe Text
mkMaybeCorpseSmellMsg i ms i' f | getType i' ms == CorpseType, n <- mkCorpseAppellation i ms i' = Just . helper . f $ n
                                | otherwise = Nothing
  where
    helper n = case mkCorpseSmellLvl . getEntSmell i' $ ms of
      1 -> "Thankfully, the " <> n <> " hasn't begun to give off an odor yet..."
      2 -> prd $ "There is a distinct odor emanating from the " <> n
      3 -> the' $ n <> " is exuding a most repulsive aroma."
      4 -> "There's no denying that the foul smell of death is in the air."
      x -> blowUp "mkMaybeCorpseSmellMsg helper" "unexpected corpse smell level" . showTxt $ x

-----

type IsConInRm  = Bool
type InvWithCon = Inv

mkMaybeNthOfM :: HasCallStack => MudState -> IsConInRm -> Id -> Sing -> InvWithCon -> Maybe NthOfM
mkMaybeNthOfM ms icir conId conSing invWithCon = guard icir >> res
  where
    res = case filter ((== conSing) . flip getSing ms) invWithCon of
      []      -> Nothing
      matches -> case elemIndex conId &&& length $ matches of (Nothing, _) -> Nothing
                                                              (Just n,  m) -> Just (succ n, m)

-----

mkMpDesc :: HasCallStack => Id -> MudState -> Text
mkMpDesc i ms = let (c, m) = getMps i ms
                in mkDescForPercent9 (c `percent` m) [ colorWith magenta "Your mana is entirely depleted."
                                                     , colorWith magenta "Your mana is severely depleted."
                                                     , colorWith red     "Your mana is extremely depleted."
                                                     , "Your mana is very depleted."
                                                     , "Your mana is quite depleted."
                                                     , "Your mana is considerably depleted."
                                                     , "Your mana is moderately depleted."
                                                     , "Your mana is slightly depleted."
                                                     , "" ]

-----

mkPpDesc :: HasCallStack => Id -> MudState -> Text
mkPpDesc i ms = let (c, m) = getPps i ms
                in mkDescForPercent9 (c `percent` m) [ colorWith magenta "Your psionic energy is entirely depleted."
                                                     , colorWith magenta "Your psionic energy is severely depleted."
                                                     , colorWith red     "Your psionic energy is extremely depleted."
                                                     , "Your psionic energy is very depleted."
                                                     , "Your psionic energy is quite depleted."
                                                     , "Your psionic energy is considerably depleted."
                                                     , "Your psionic energy is moderately depleted."
                                                     , "Your psionic energy is slightly depleted."
                                                     , "" ]

-----

mkRmInvCoinsDesc :: HasCallStack => Id -> Cols -> MudState -> Id -> Text
mkRmInvCoinsDesc i cols ms ri =
    let (ris, c)                = first (i `delete`) . getVisibleInvCoins ri $ ms
        (pcTuples, otherTuples) = splitPCsOthers . mkRmInvCoinsDescTuples i ms $ ris
        pcDescs                 = T.unlines . concatMap (wrapIndent 2 cols . mkPCDesc   ) $ pcTuples
        otherDescs              = T.unlines . concatMap (wrapIndent 2 cols . mkOtherDesc) $ otherTuples
    in (pcTuples |!| pcDescs) <> (otherTuples |!| otherDescs) <> (c |!| mkCoinsSummary cols c)
  where
    splitPCsOthers = first (map $ \((_, ia), rest) -> (ia, rest)) . second (map snd) . span (fst . fst)
    mkPCDesc (ia, (en, (s, _), d, c)) | c == 1 = T.concat [ (s |&|) $ if isKnownPCSing s
                                                              then colorWith knownNameColor
                                                              else colorWith unknownNameColor . aOrAn
                                                          , rmDescHepler d, adminTagHelper ia, " ", en ]
    mkPCDesc (ia, (en, b,      d, c))          = T.concat [ colorWith unknownNameColor $ commaShow c |<>| mkPlurFromBoth b
                                                          , rmDescHepler d, adminTagHelper ia, " ", en ]
    mkOtherDesc (en, (s, _), _, c) | c == 1 = aOrAnOnLower s |<>| en
    mkOtherDesc (en, b,      _, c)          = T.concat [ commaShow c, spaced . mkPlurFromBoth $ b, en ]
    adminTagHelper False = ""
    adminTagHelper True  = spcL adminTagTxt
    rmDescHepler   ""    = ""
    rmDescHepler   d     = spcL d

mkRmInvCoinsDescTuples :: HasCallStack => Id -> MudState -> Inv -> [((Bool, Bool), (Text, BothGramNos, Text, Int))]
mkRmInvCoinsDescTuples i ms targetIds =
  let isPlaAdmins =   [ mkIsPlaAdmin           targetId | targetId <- targetIds ]
      styleds     = f [ getEffName        i ms targetId | targetId <- targetIds ]
      boths       =   [ getEffBothGramNos i ms targetId | targetId <- targetIds ]
      rmDescs     =   [ mkMobRmDesc targetId ms         | targetId <- targetIds ]
      groups      = group . zip4 isPlaAdmins styleds boths $ rmDescs
  in [ (ipa, (s, b, d, c)) | ((ipa, s, b, d), c) <- [ (head &&& length) g | g <- groups ] ]
  where
    mkIsPlaAdmin targetId | isPla targetId ms = (True, isAdminId targetId ms)
                          | otherwise         = dup False
    f = styleAbbrevs DoCoins DoQuote

isKnownPCSing :: HasCallStack => Sing -> Bool
isKnownPCSing s = case T.words s of [ "male",   _ ] -> False
                                    [ "female", _ ] -> False
                                    _               -> True

-----

moveReadiedItem :: HasCallStack => Id
                                -> (EqTbl, InvTbl, [Text], [Broadcast], [Text])
                                -> Slot
                                -> Id
                                -> (Text, Broadcast)
                                -> (EqTbl, InvTbl, [Text], [Broadcast], [Text])
moveReadiedItem i a s targetId (msg, b) = a & _1.ind i.at s ?~ targetId
                                            & _2.ind i %~ (targetId `delete`)
                                            & _3 <>+ msg
                                            & _4 <>+ b
                                            & _5 <>+ msg

-----

notFoundSuggestAsleeps :: HasCallStack => Text -> [Sing] -> MudState -> Text
notFoundSuggestAsleeps a@(capitalize . T.toLower -> a') asleepSings ms =
    case findFullNameForAbbrev a' asleepSings of
      Just asleepTarget ->
          let heShe = mkThrPerPro . getSex (getIdForPCSing asleepTarget ms) $ ms
              guess = a' /= asleepTarget |?| ("Perhaps you mean " <> asleepTarget <> "? ")
          in T.concat [ guess, "Unfortunately, ", bool heShe asleepTarget $ ()# guess, " is sleeping at the moment..." ]
      Nothing -> sorryTwoWayLink a

-----

onOffs :: HasCallStack => [(Text, Bool)]
onOffs = [ ("o",   False)
         , ("of",  False)
         , ("off", False)
         , ("on",  True ) ]

-----

otherHand :: HasCallStack => Hand -> Hand
otherHand RHand  = LHand
otherHand LHand  = RHand
otherHand NoHand = LHand

-----

putOnMsgs :: HasCallStack => Desig -> Sing -> (Text, Broadcast)
putOnMsgs = mkReadyMsgs "put on" "puts on"

-----

readHelper :: HasCallStack => Id
                           -> Cols
                           -> MudState
                           -> Desig
                           -> (Text, [Broadcast], [Text])
                           -> Inv
                           -> (Text, [Broadcast], [Text])
readHelper i cols ms d = foldl' helper
  where
    helper acc targetId =
        let s                 = getSing targetId ms
            readIt txt header = acc & _1 <>~ (multiWrapNl cols . T.lines $ header <> txt)
                                    & _2 <>+ (T.concat [ serialize d, " reads ", aOrAn s, "." ], desigOtherIds d)
                                    & _3 <>+ s |<>| parensQuote (showTxt targetId)
        in case getType targetId ms of
          WritableType ->
              let (Writable msg r) = getWritable targetId ms in case msg of
                Nothing          -> f . blankWritableMsg $ s
                Just (txt, lang) -> case r of
                  Nothing -> if isKnownLang i ms lang
                    then readIt txt . T.concat $ [ "The following is written on the ", s, " in ", pp lang, nl ":" ]
                    else f . sorryReadLang s $ lang
                  Just recipSing | isPla   i ms
                                 , uncurry (||) . first (== recipSing) . (getSing `fanUncurry` isAdminId) $ (i, ms)
                                 , b    <- isKnownLang i ms lang
                                 , txt' <- onFalse b (const . sorryReadOrigLang $ lang) txt
                                 -> readIt txt' . mkMagicMsgHeader s b $ lang
                                 | otherwise -> f . sorryReadUnknownLang $ s
          HolySymbolType -> -- TODO: Can any holy vessels be read?
              let langs         = getKnownLangs i ms
                  holyHelper ts = acc & _1 <>~ multiWrapNl cols ts
                                      & _2 <>+ ( T.concat [ serialize d, " reads the writing on ", aOrAn s, "." ]
                                               , desigOtherIds d )
                                      & _3 <>+ s |<>| parensQuote (showTxt targetId)
              in either f holyHelper $ case getHolySymbolGodName targetId ms of
                Caila     | uncurry (&&) . second (== Human) . (isPla `fanUncurry` getRace) $ (i, ms)
                                                   -> Right . pure $ cailaOK
                          | otherwise              -> Left  cailaNG
                Itulvatar                          -> Right itulvatarOKs
                Rumialys  | NymphLang `elem` langs -> Right . pure $ rumialysOK
                          | otherwise              -> Left  rumialysNG
                _                                  -> Left  sorryReadHolySymbol
          _ -> f . sorryReadType $ s
      where
        f msg        = acc & _1 <>~ wrapUnlinesNl cols msg
        cailaOK      = "You recognize that the runes are of an antiquated human writing system predating the modern \
                       \hominal alphabet. Unfortunately, you don't know how to read them."
        cailaNG      = "You can't make heads or tails of the ancient runes embroidered upon the holy symbol."
        itulvatarOKs = [ "The following is engraved upon the back of the disc in common:"
                       , "Beloved Itulvatar,"
                       , "Architect of Stars,"
                       , "(may your Light bathe all existence):"
                       , "I humbly offer myself to You,"
                       , "that your Light may guide me"
                       , "through all darkness and calamity." ]
        rumialysOK   = "The following is etched upon the surface of the metal ring in " <> pp NymphLang <>
                       ": \"Mother of Life, Architect of All.\""
        rumialysNG   = "You recognize that the language etched on upon the metal ring is " <> pp NymphLang <>
                       ", but you can't read the words."
    mkMagicMsgHeader s b lang =
        T.concat [ "At first glance, the writing on the "
                 , s
                 , " appears to be in a language you don't recognize. Then suddenly the unfamiliar glyphs come alive, \
                   \squirming and melting into new forms. In a matter of seconds, the text transforms into "
                 , nl $ if b
                     then "the following message, written in " <> pp lang <> ":"
                     else prd $ "a message written in " <> pp lang ]

-----

resolveMobInvCoins :: HasCallStack => Id -> MudState -> Args -> Inv -> Coins -> ([Either Text Inv], [Either [Text] Coins])
resolveMobInvCoins i ms = resolveHelper i ms procGecrMisMobInv procReconciledCoinsMobInv

resolveHelper :: HasCallStack => Id
                              -> MudState
                              -> ((GetEntsCoinsRes, Maybe Inv) -> Either Text Inv)
                              -> (ReconciledCoins -> Either [Text] Coins)
                              -> Args
                              -> Inv
                              -> Coins
                              -> ([Either Text Inv], [Either [Text] Coins])
resolveHelper i ms f g as is c | (gecrs, miss, rcs) <- resolveEntCoinNames i ms as is c
                               , eiss               <- zipWith (curry f) gecrs miss
                               , ecs                <- map g rcs = (eiss, ecs)

resolveRmInvCoins :: HasCallStack => Id -> MudState -> Args -> Inv -> Coins -> ([Either Text Inv], [Either [Text] Coins])
resolveRmInvCoins i ms = resolveHelper i ms procGecrMisRm procReconciledCoinsRm

-----

sacrificeHelper :: HasCallStack => ActionParams -> Id -> GodName -> MudStack ()
sacrificeHelper p@(ActionParams i mq cols _) ci gn = getState >>= \ms ->
    let toSelf = T.concat [ "You kneel before the ", mkCorpseAppellation i ms ci, ", laying upon it the holy symbol of "
                          , pp gn, gn == Murgorhd |?| murgorhdMsg, ". You say a prayer..." ]
        d      = mkStdDesig i ms DoCap
        helper targetId | vo <- mkSerVerbObj . the . mkCorpseAppellation targetId ms $ ci
                        , ts <- [ serialize d, " kneels before ", vo, " and says a prayer to ", pp gn, "." ]
                        = (T.concat ts, pure targetId)
    in checkActing p ms (Left Sacrificing) allValues $ do logHelper ms
                                                          wrapSend1Nl mq cols toSelf
                                                          bcastIfNotIncogNl i . map helper . desigOtherIds $ d
                                                          startAct i Sacrificing . sacrificeAct i mq ci $ gn
  where
    logHelper ms = let msg = T.concat [ "sacrificing a ", descSingId ci ms, t, " using a holy symbol of ", pp gn, "." ]
                       t   = case getCorpse ci ms of PCCorpse s _ _ _ -> spcL . parensQuote $ s
                                                     _                -> ""
                   in logPla "sacrificeHelper" i msg
    murgorhdMsg  = " (you are careful to point the apex of the triangle westward)"

-----

shuffleGive :: HasCallStack => Id -> MudState -> LastArgIsTargetBindings -> GenericRes
shuffleGive i ms LastArgIsTargetBindings { .. } =
    let (targetGecrs, targetMiss, targetRcs) = uncurry (resolveEntCoinNames i ms . pure $ targetArg) rmInvCoins
    in if ()# targetMiss && ()!# targetRcs
      then genericSorry ms sorryGiveToCoin
      else case procGecrMisRm . head . zip targetGecrs $ targetMiss of
        Left  msg        -> genericSorry ms msg
        Right [targetId] -> if isNpcPla targetId ms
          then let (inInvs, inEqs, inRms) = sortArgsInvEqRm InInv otherArgs
                   sorryInEq              = inEqs |!| sorryGiveInEq
                   sorryInRm              = inRms |!| sorryGiveInRm
                   (eiss, ecs)            = uncurry (resolveMobInvCoins i ms inInvs) srcInvCoins
                   (ms',  toSelfs,  bs,  logMsgs ) = foldl' (helperGiveEitherInv  i srcDesig targetId)
                                                            (ms, [], [], [])
                                                            eiss
                   (ms'', toSelfs', bs', logMsgs') =        helperGiveEitherCoins i srcDesig targetId
                                                            (ms', toSelfs, bs, logMsgs)
                                                            ecs
               in (ms'', ( dropBlanks $ [ sorryInEq, sorryInRm ] ++ toSelfs'
                         , bs'
                         , map (parseDesigSuffix i ms) logMsgs' ))
          else genericSorry ms . sorryGiveType . getSing targetId $ ms
        Right {} -> genericSorry ms sorryGiveExcessTargets

helperGiveEitherInv :: HasCallStack => Id
                                    -> Desig
                                    -> ToId
                                    -> GenericIntermediateRes
                                    -> Either Text Inv
                                    -> GenericIntermediateRes
helperGiveEitherInv i d toId a@(ms, _, _, _) = \case
  Left  msg -> a & _2 <>+ msg
  Right is  ->
    let (is', sorrys)     = checkNowEating i ms "give" "to someone" is
        (_, cans, can'ts) = foldl' (partitionInvByEnc ms . calcMaxEnc toId $ ms) (calcWeight toId ms, [], []) is'
        (toSelfs, bs    ) = mkGiveInvDescs i ms d toId (serialize toDesig) cans
        toDesig           = mkStdDesig toId ms Don'tCap
    in a & _1.invTbl.ind i    %~  (\\ cans)
         & _1.invTbl.ind toId %~  addToInv ms cans
         & _2                 <>~ concat [ sorrys
                                         , toSelfs
                                         , can'tInvDescsHelper (serialize toDesig { desigCap = DoCap }) i ms can'ts ]
         & _3                 <>~ bs
         & _4                 <>~ toSelfs

mkGiveInvDescs :: HasCallStack => Id -> MudState -> Desig -> ToId -> Text -> Inv -> ([Text], [Broadcast])
mkGiveInvDescs i ms d toId toDesig = second concat . unzip . map helper . mkNameCountBothList i ms
  where
    helper (_, c, (s, _)) | c == 1 =
        ( T.concat [ "You give the ", s, " to ", toDesig, "." ]
        , [ (T.concat [ serialize d, " gives ", mkSerVerbObj . aOrAn $ s, " to ", toDesig, "." ], otherIds )
          , (T.concat [ serialize d, " gives you ", aOrAn s, "." ]                              , pure toId) ] )
    helper (_, c, b) = let stuff = showTxt c |<>| mkPlurFromBoth b in
        ( T.concat [ "You give ", stuff, " to ", toDesig, "." ]
        , [ (T.concat [ serialize d, " gives ", mkSerVerbObj stuff, " to ", toDesig, "." ], otherIds )
          , (T.concat [ serialize d, " gives you ", stuff, "." ]                          , pure toId) ] )
    otherIds = toId `delete` desigOtherIds d

helperGiveEitherCoins :: HasCallStack => Id
                                      -> Desig
                                      -> ToId
                                      -> GenericIntermediateRes
                                      -> [Either [Text] Coins]
                                      -> GenericIntermediateRes
helperGiveEitherCoins i d toId (ms, toSelfs, bs, logMsgs) ecs =
    let toDesig                             = serialize . mkStdDesig toId ms $ Don'tCap
        (ms', toSelfs', logMsgs', canCoins) = foldl' (helper toDesig) (ms, toSelfs, logMsgs, mempty) ecs
    in (ms', toSelfs', bs ++ mkGiveCoinsDescOthers d toId toDesig canCoins, logMsgs')
  where
    helper toDesig a@(ms', _, _, _) = \case
      Left  msgs -> a & _2 <>~ msgs
      Right c    -> let (can, can't) = partitionCoinsByEnc toId ms' c
                        toSelfs'     = mkGiveCoinsDescsSelf toDesig can
                    in a & _1.coinsTbl.ind i    %~  (<> negateCoins can)
                         & _1.coinsTbl.ind toId %~  (<>             can)
                         & _2                   <>~ toSelfs' ++ mkCan'tGiveCoinsDesc toDesig can't
                         & _3                   <>~ toSelfs'
                         & _4                   <>~ can

mkGiveCoinsDescOthers :: HasCallStack => Desig -> ToId -> Text -> Coins -> [Broadcast]
mkGiveCoinsDescOthers d toId toDesig c = c |!| toOthersBcast : [ (msg, pure toId) | msg <- toTargetMsgs ]
  where
    toOthersBcast = ( T.concat [ serialize d, " gives ", mkSerVerbObj . aCoinSomeCoins $ c, " to ", toDesig, "." ]
                    , toId `delete` desigOtherIds d )
    toTargetMsgs  = mkCoinsMsgs helper c
    helper 1 cn   = T.concat [ serialize d, " gives you ", aOrAn cn,                 "."  ]
    helper a cn   = T.concat [ serialize d, " gives you",  spaced . showTxt $ a, cn, "s." ]

mkGiveCoinsDescsSelf :: HasCallStack => Text -> Coins -> [Text]
mkGiveCoinsDescsSelf targetDesig = mkCoinsMsgs helper
  where
    helper 1 cn = T.concat [ "You give ", aOrAn cn,                 " to ",  targetDesig, "." ]
    helper a cn = T.concat [ "You give",  spaced . showTxt $ a, cn, "s to ", targetDesig, "." ]

mkCan'tGiveCoinsDesc :: HasCallStack => Text -> Coins -> [Text]
mkCan'tGiveCoinsDesc targetDesig = mkCoinsMsgs (can'tCoinsDescHelper . sorryGiveEnc $ targetDesig)

-----

type CoinsWithCon = Coins
type PCInv        = Inv
type PCCoins      = Coins

shufflePut :: HasCallStack => Id
                           -> MudState
                           -> Desig
                           -> ConName
                           -> IsConInRm
                           -> Args
                           -> (InvWithCon, CoinsWithCon)
                           -> (PCInv, PCCoins)
                           -> ((GetEntsCoinsRes, Maybe Inv) -> Either Text Inv)
                           -> GenericRes
shufflePut i ms d conName icir as invCoinsWithCon@(invWithCon, _) mobInvCoins f =
    let (conGecrs, conMiss, conRcs) = uncurry (resolveEntCoinNames i ms . pure $ conName) invCoinsWithCon
    in if ()# conMiss && ()!# conRcs
      then genericSorry ms sorryPutInCoin
      else case f . head . zip conGecrs $ conMiss of
        Left  msg     -> genericSorry ms msg
        Right [conId] | (conSing, conType) <- (getSing `fanUncurry` getType) (conId, ms) ->
            if not . hasCon $ conType
              then genericSorry ms . sorryConHelper i ms conId $ conSing
              else let (inInvs, inEqs, inRms) = sortArgsInvEqRm InInv as
                       sorryInEq              = inEqs |!| sorryPutInEq
                       sorryInRm              = inRms |!| sorryPutInRm
                       (eiss, ecs)            = uncurry (resolveMobInvCoins i ms inInvs) mobInvCoins
                       mnom                   = mkMaybeNthOfM ms icir conId conSing invWithCon
                       (ms',  toSelfs,  bs,  logMsgs ) = foldl' (helperPutEitherInv  i d mnom conId conSing)
                                                                (ms, [], [], [])
                                                                eiss
                       (ms'', toSelfs', bs', logMsgs') =        helperPutEitherCoins i d mnom conId conSing
                                                                (ms', toSelfs, bs, logMsgs)
                                                                ecs
                   in (ms'', (dropBlanks $ [ sorryInEq, sorryInRm ] ++ toSelfs', bs', logMsgs'))
        Right {} -> genericSorry ms sorryPutExcessCon

helperPutEitherInv :: HasCallStack => Id
                                   -> Desig
                                   -> Maybe NthOfM
                                   -> ToId
                                   -> ToSing
                                   -> GenericIntermediateRes
                                   -> Either Text Inv
                                   -> GenericIntermediateRes
helperPutEitherInv i d mnom toId toSing a@(ms, origToSelfs, _, _) = \case
  Left  msg -> a & _2 <>+ msg
  Right is  ->
    let (is', toSelfs)    | pair   <- checkNowEating i ms "put" "in a container" is
                          , (x, y) <- checkIsLitLight pair
                          = second (++ y) . onTrue (toId `elem` x) f $ (x, origToSelfs)
        f                 = filter (/= toId) *** (<> pure (sorryPutInsideSelf toSing))
        (_, cans, can'ts) = foldl' (partitionInvByVol ms . getConCapacity toId $ ms)
                                   (calcInvCoinsVol toId ms, [], [])
                                   is'
        (toSelfs', bs)    = mkPutRemInvDescs i ms d Put mnom (mkIsOrIsn'tCorpse toId ms) toSing cans
    in a & _1.invTbl.ind i    %~  (\\ cans)
         & _1.invTbl.ind toId %~  addToInv ms cans
         & _2                 .~  concat [ toSelfs, toSelfs', mkCan'tPutInvDescs toSing i ms can'ts ]
         & _3                 <>~ bs
         & _4                 <>~ toSelfs'
  where
    checkIsLitLight pair = let f pair' i' | getType i' ms == LightType, getLightIsLit i' ms
                                          , msg <- sorryPutLitLight (getSing i' ms) toSing
                                          = ((i' `delete`) *** (++ pure msg)) pair'
                                          | otherwise = pair'
                           in foldl' f pair . fst $ pair

partitionInvByVol :: HasCallStack => MudState -> Vol -> (Vol, Inv, Inv) -> Id -> (Vol, Inv, Inv)
partitionInvByVol = partitionInvHelper calcVol

mkIsOrIsn'tCorpse :: HasCallStack => Id -> MudState -> IsOrIsn'tCorpse
mkIsOrIsn'tCorpse i ms | getType i ms == CorpseType = IsCorpse $ case getCorpse i ms of PCCorpse  {} -> Just i
                                                                                        NpcCorpse {} -> Nothing
                       | otherwise                  = Isn'tCorpse

mkPutRemInvDescs :: HasCallStack => Id
                                 -> MudState
                                 -> Desig
                                 -> PutOrRem
                                 -> Maybe NthOfM
                                 -> IsOrIsn'tCorpse
                                 -> Sing
                                 -> Inv
                                 -> ([Text], [Broadcast])
mkPutRemInvDescs i ms d por mnom ioic conSing = unzip . map helper . mkNameCountBothList i ms
  where
    helper (_, c, (s, _)) | c == 1 =
        (  T.concat [ "You ", mkPorVerb por SndPer, spaced (s |&| bool aOrAn the (por == Put))
                    , mkPorPrep por SndPer mnom ioic conSing, rest ]
        , (T.concat [ serialize d, spaced . mkPorVerb por $ ThrPer, mkSerVerbObj . aOrAn $ s, " "
                    , mkPorPrep por ThrPer mnom ioic conSing, rest ], desigOtherIds d) )
    helper (_, c, b) =
        (  T.concat [ "You ", mkPorVerb por SndPer, spaced . showTxt $ c, mkPlurFromBoth b, " "
                    , mkPorPrep por SndPer mnom ioic conSing, rest ]
        , (T.concat [ serialize d, spaced . mkPorVerb por $ ThrPer, mkSerVerbObj $ showTxt c |<>| mkPlurFromBoth b, " "
                    , mkPorPrep por ThrPer mnom ioic conSing, rest ], desigOtherIds d) )
    rest = prd . onTheGround $ mnom

mkCan'tPutInvDescs :: HasCallStack => ToSing -> Id -> MudState -> Inv -> [Text]
mkCan'tPutInvDescs = can'tInvDescsHelper . sorryPutVol

type NthOfM = (Int, Int)

helperPutEitherCoins :: HasCallStack => Id
                                     -> Desig
                                     -> Maybe NthOfM
                                     -> ToId
                                     -> ToSing
                                     -> GenericIntermediateRes
                                     -> [Either [Text] Coins]
                                     -> GenericIntermediateRes
helperPutEitherCoins i d mnom toId toSing (ms, toSelfs, bs, logMsgs) ecs =
    let (ms', toSelfs', logMsgs', canCoins) = foldl' helper (ms, toSelfs, logMsgs, mempty) ecs
    in (ms', toSelfs', bs ++ mkPutRemCoinsDescOthers d Put mnom ioic toSing canCoins, logMsgs')
  where
    ioic                    = mkIsOrIsn'tCorpse toId ms
    helper a@(ms', _, _, _) = \case
      Left  msgs -> a & _2 <>~ msgs
      Right c    -> let (can, can't) = partitionCoinsByVol toId ms' c
                        toSelfs'     = mkPutRemCoinsDescsSelf Put mnom ioic toSing can
                    in a & _1.coinsTbl.ind i    %~  (<> negateCoins can)
                         & _1.coinsTbl.ind toId %~  (<>             can)
                         & _2                   <>~ toSelfs' ++ mkCan'tPutCoinsDesc toSing can't
                         & _3                   <>~ toSelfs'
                         & _4                   <>~ can

partitionCoinsByVol :: HasCallStack => Id -> MudState -> Coins -> (Coins, Coins)
partitionCoinsByVol = partitionCoinsHelper getConCapacity calcInvCoinsVol coinVol

mkPutRemCoinsDescOthers :: HasCallStack => Desig -> PutOrRem -> Maybe NthOfM -> IsOrIsn'tCorpse -> Sing -> Coins -> [Broadcast]
mkPutRemCoinsDescOthers d por mnom ioic conSing c
  | ts <- [ serialize d, spaced . mkPorVerb por $ ThrPer, mkSerVerbObj . aCoinSomeCoins $ c, " "
          , mkPorPrep por ThrPer mnom ioic conSing, prd . onTheGround $ mnom ]
  = c |!| pure (T.concat ts, desigOtherIds d)

mkPutRemCoinsDescsSelf :: HasCallStack => PutOrRem -> Maybe NthOfM -> IsOrIsn'tCorpse -> Sing -> Coins -> [Text]
mkPutRemCoinsDescsSelf por mnom ioic conSing = mkCoinsMsgs helper
  where
    helper a cn | a == 1 = T.concat [ partA, aOrAn cn,  " ",           partB ]
    helper a cn          = T.concat [ partA, showTxt a, " ", cn, "s ", partB ]
    partA                = spcR $ "You " <> mkPorVerb por SndPer
    partB                = prd $ mkPorPrep por SndPer mnom ioic conSing <> onTheGround mnom

mkPorVerb :: HasCallStack => PutOrRem -> Verb -> Text
mkPorVerb Put SndPer = "put"
mkPorVerb Put ThrPer = "puts"
mkPorVerb Rem SndPer = "remove"
mkPorVerb Rem ThrPer = "removes"

data IsOrIsn'tCorpse = IsCorpse (Maybe Id)
                     | Isn'tCorpse deriving (Eq, Show)

mkPorPrep :: HasCallStack => PutOrRem -> Verb -> Maybe NthOfM -> IsOrIsn'tCorpse -> Sing -> Text
mkPorPrep Put SndPer Nothing       Isn'tCorpse s = ("in "   <>) . the $ s
mkPorPrep Rem SndPer Nothing       Isn'tCorpse s = ("from " <>) . the $ s
mkPorPrep Put ThrPer Nothing       Isn'tCorpse s = ("in "   <>) . mkSerVerbObj . aOrAn $ s
mkPorPrep Rem ThrPer Nothing       Isn'tCorpse s = ("from " <>) . mkSerVerbObj . aOrAn $ s
mkPorPrep Put SndPer Nothing       x           s = ("on "   <>) . the . mkCD x $ s
mkPorPrep Rem SndPer Nothing       x           s = ("from " <>) . the . mkCD x $ s
mkPorPrep Put ThrPer Nothing       x           s = ("on "   <>) . mkSerVerbObj . the . mkCD x $ s
mkPorPrep Rem ThrPer Nothing       x           s = ("from " <>) . mkSerVerbObj . the . mkCD x $ s
mkPorPrep Put SndPer (Just (n, m)) Isn'tCorpse s = ("in "   <>) . the . (descNthOfM n m <>) $ s
mkPorPrep Rem SndPer (Just (n, m)) Isn'tCorpse s = ("from " <>) . the . (descNthOfM n m <>) $ s
mkPorPrep Put ThrPer (Just (n, m)) Isn'tCorpse s = ("in "   <>) . mkSerVerbObj . the . (descNthOfM n m <>) $ s
mkPorPrep Rem ThrPer (Just (n, m)) Isn'tCorpse s = ("from " <>) . mkSerVerbObj . the . (descNthOfM n m <>) $ s
mkPorPrep Put SndPer (Just (n, m)) x           s = ("on "   <>) . the . (descNthOfM n m <>) . mkCD x $ s
mkPorPrep Rem SndPer (Just (n, m)) x           s = ("from " <>) . the . (descNthOfM n m <>) . mkCD x $ s
mkPorPrep Put ThrPer (Just (n, m)) x           s = ("on "   <>) . mkSerVerbObj . the . (descNthOfM n m <>) . mkCD x $ s
mkPorPrep Rem ThrPer (Just (n, m)) x           s = ("from " <>) . mkSerVerbObj . the . (descNthOfM n m <>) . mkCD x $ s

mkCD :: HasCallStack => IsOrIsn'tCorpse -> Sing -> Text
mkCD (IsCorpse (Just i)) _ = serialize . CorpseDesig $ i
mkCD (IsCorpse Nothing ) s = s
mkCD x                   _ = pmf "mkCD" x

descNthOfM :: HasCallStack => Int -> Int -> Text
descNthOfM 1 1 = ""
descNthOfM n _ = spcR . mkOrdinal $ n

onTheGround :: HasCallStack => Maybe NthOfM -> Text
onTheGround = (|!| " on the ground") . ((both %~ Sum) <$>)

mkCan'tPutCoinsDesc :: HasCallStack => Sing -> Coins -> [Text]
mkCan'tPutCoinsDesc conSing = mkCoinsMsgs (can'tCoinsDescHelper . sorryPutVol $ conSing)

-----

shuffleRem :: HasCallStack => Id
                           -> MudState
                           -> Desig
                           -> ConName
                           -> IsConInRm
                           -> Args
                           -> (InvWithCon, CoinsWithCon)
                           -> ((GetEntsCoinsRes, Maybe Inv) -> Either Text Inv)
                           -> GenericRes
shuffleRem i ms d conName icir as invCoinsWithCon@(invWithCon, _) f =
    let (conGecrs, conMiss, conRcs) = uncurry (resolveEntCoinNames i ms . pure $ conName) invCoinsWithCon
    in if ()# conMiss && ()!# conRcs
      then genericSorry ms sorryRemCoin
      else case f . head . zip conGecrs $ conMiss of
        Left  msg     -> genericSorry ms msg
        Right [conId] | (conSing, conType) <- (getSing `fanUncurry` getType) (conId, ms) ->
            if not . hasCon $ conType
              then genericSorry ms . sorryConHelper i ms conId $ conSing
              else let (as', guessWhat)   = stripLocPrefs
                       invCoinsInCon      = getInvCoins conId ms
                       (gecrs, miss, rcs) = uncurry (resolveEntCoinNames i ms as') invCoinsInCon
                       eiss               = zipWith (curry . procGecrMisCon $ conSing) gecrs miss
                       ecs                = map (procReconciledCoinsCon conSing) rcs
                       mnom               = mkMaybeNthOfM ms icir conId conSing invWithCon
                       (ms',  toSelfs,  bs,  logMsgs ) = foldl' (helperRemEitherInv  i d mnom conId conSing icir)
                                                                (ms, [], [], [])
                                                                eiss
                       (ms'', toSelfs', bs', logMsgs') =        helperRemEitherCoins i d mnom conId conSing icir
                                                                (ms', toSelfs, bs, logMsgs)
                                                                ecs
                   in if ()!# invCoinsInCon
                     then (ms'', (guessWhat ++ toSelfs', bs', logMsgs'))
                     else genericSorry ms . sorryRemEmpty $ conSing
        Right {} -> genericSorry ms sorryRemExcessCon
  where
    stripLocPrefs = onTrue (any hasLocPref as) g (as, [])
    g pair        = pair & _1 %~ map stripLocPref
                         & _2 .~ pure sorryRemIgnore

helperRemEitherInv :: HasCallStack => Id
                                   -> Desig
                                   -> Maybe NthOfM
                                   -> FromId
                                   -> FromSing
                                   -> IsConInRm
                                   -> GenericIntermediateRes
                                   -> Either Text Inv
                                   -> GenericIntermediateRes
helperRemEitherInv i d mnom fromId fromSing icir a@(ms, _, _, _) = \case
  Left  msg -> a & _2 <>+ msg
  Right is  -> let (_, cans, can'ts) = f is
                   f | icir          = foldl' (partitionInvByEnc ms . calcMaxEnc i $ ms) (calcWeight i ms, [], [])
                     | otherwise     = (0, , [])
                   (toSelfs, bs)     = mkPutRemInvDescs i ms d Rem mnom (mkIsOrIsn'tCorpse fromId ms) fromSing cans
               in a & _1.invTbl.ind fromId %~  (\\ cans)
                    & _1.invTbl.ind i      %~  addToInv ms cans
                    & _2                   <>~ toSelfs ++ mkCan'tRemInvDescs i ms can'ts
                    & _3                   <>~ bs
                    & _4                   <>~ toSelfs

mkCan'tRemInvDescs :: HasCallStack => Id -> MudState -> Inv -> [Text]
mkCan'tRemInvDescs = can'tInvDescsHelper sorryRemEnc

helperRemEitherCoins :: HasCallStack => Id
                                     -> Desig
                                     -> Maybe NthOfM
                                     -> FromId
                                     -> FromSing
                                     -> IsConInRm
                                     -> GenericIntermediateRes
                                     -> [Either [Text] Coins]
                                     -> GenericIntermediateRes
helperRemEitherCoins i d mnom fromId fromSing icir (ms, toSelfs, bs, logMsgs) ecs =
    let (ms', toSelfs', logMsgs', canCoins) = foldl' helper (ms, toSelfs, logMsgs, mempty) ecs
    in (ms', toSelfs', bs ++ mkPutRemCoinsDescOthers d Rem mnom ioic fromSing canCoins, logMsgs')
  where
    ioic                    = mkIsOrIsn'tCorpse fromId ms
    helper a@(ms', _, _, _) = \case
      Left  msgs -> a & _2 <>~ msgs
      Right c    -> let (can, can't)  = f c
                        f | icir      = partitionCoinsByEnc i ms'
                          | otherwise = (, mempty)
                        toSelfs'      = mkPutRemCoinsDescsSelf Rem mnom ioic fromSing can
                    in a & _1.coinsTbl.ind fromId %~ (<> negateCoins can)
                         & _1.coinsTbl.ind i      %~ (<>             can)
                         & _2 <>~ toSelfs' ++ mkCan'tRemCoinsDesc can't
                         & _3 <>~ toSelfs'
                         & _4 <>~ c

mkCan'tRemCoinsDesc :: HasCallStack => Coins -> [Text]
mkCan'tRemCoinsDesc = mkCoinsMsgs (can'tCoinsDescHelper sorryRemEnc)

-----

sorryConHelper :: HasCallStack => Id -> MudState -> Id -> Sing -> Text
sorryConHelper i ms conId conSing
  | isNpcPla conId ms = sorryCon . parseDesig Nothing i ms . serialize . mkStdDesig conId ms $ Don'tCap
  | otherwise         = sorryCon conSing

-----

spiritHelper :: HasCallStack => Id -> (MudState -> MudStack ()) -> (MudState -> MudStack ()) -> MudStack ()
spiritHelper i a b = getState >>= \ms -> ms |&| bool a b (isSpiritId i ms)

-----

stopAttacking :: HasCallStack => ActionParams -> MudState -> MudStack ()
stopAttacking (WithArgs i mq cols _) ms =
  let toSelf = "You stop attacking."
      d      = mkStdDesig i ms DoCap
      msg    = serialize d <> " stops attacking."
  in sequence_ [ stopAct i Attacking, wrapSend mq cols toSelf, bcast . pure $ (msg, desigOtherIds d) ]
stopAttacking p _ = pmf "stopAttacking" p

stopDrinking :: HasCallStack => ActionParams -> MudState -> MudStack ()
stopDrinking (WithArgs i mq cols _) ms = maybeVoid helper . getNowDrinking i $ ms
  where
    helper (l, s) = let toSelf      = T.concat [ "You stop drinking ", renderLiqNoun l the, " from the ", s, "." ]
                        d           = mkStdDesig i ms DoCap
                        msg         = T.concat [ serialize d, " stops drinking from ", mkSerVerbObj . aOrAn $ s, "." ]
                        bcastHelper = bcastIfNotIncogNl i . pure $ (msg, desigOtherIds d)
                    in stopAct i Drinking >> wrapSend mq cols toSelf >> bcastHelper
stopDrinking p _ = pmf "stopDrinking" p

stopEating :: HasCallStack => ActionParams -> MudState -> MudStack ()
stopEating (WithArgs i mq cols _) ms = maybeVoid helper . getNowEating i $ ms
  where
    helper (_, s) = let toSelf      = prd $ "You stop eating " <> theOnLower s
                        d           = mkStdDesig i ms DoCap
                        msg         = T.concat [ serialize d, " stops eating ", mkSerVerbObj . aOrAn $ s, "." ]
                        bcastHelper = bcastIfNotIncogNl i . pure $ (msg, desigOtherIds d)
                    in stopAct i Eating >> wrapSend mq cols toSelf >> bcastHelper
stopEating p _ = pmf "stopEating" p

stopSacrificing :: HasCallStack => ActionParams -> MudState -> MudStack ()
stopSacrificing (WithArgs i mq cols _) ms = let toSelf      = "You stop sacrificing the corpse."
                                                d           = mkStdDesig i ms DoCap
                                                msg         | vo <- mkSerVerbObj "a corpse"
                                                            = prd $ serialize d <> " stops sacrificing " <> vo
                                                bcastHelper = bcastIfNotIncogNl i . pure $ (msg, desigOtherIds d)
                                            in stopAct i Sacrificing >> wrapSend mq cols toSelf >> bcastHelper
stopSacrificing p                      _  = pmf "stopSacrificing" p
