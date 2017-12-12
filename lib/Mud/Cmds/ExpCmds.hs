{-# LANGUAGE NamedFieldPuns, OverloadedStrings, ViewPatterns #-}

module Mud.Cmds.ExpCmds ( expCmdNames
                        , expCmdSet
                        , expCmds
                        , getExpCmdByName
                        , mkExpAction ) where

import           Mud.Cmds.Msgs.Advice
import           Mud.Cmds.Msgs.Sorry
import           Mud.Cmds.Util.Misc
import           Mud.Cmds.Util.Pla
import           Mud.Data.Misc
import           Mud.Data.State.ActionParams.ActionParams
import           Mud.Data.State.MudData
import           Mud.Data.State.Util.Get
import           Mud.Data.State.Util.Misc
import           Mud.Data.State.Util.Output
import           Mud.Misc.LocPref
import qualified Mud.Misc.Logging as L (logPlaOut)
import qualified Mud.Util.Misc as U (pmf)
import           Mud.Util.Misc hiding (pmf)
import           Mud.Util.Operators
import           Mud.Util.Text

import           Control.Arrow (first)
import           Control.Lens.Operators ((?~), (.~))
import           Data.Bool
import           Data.List (delete)
import qualified Data.Set as S (Set, filter, foldr, fromList, map, toList)
import           Data.Text (Text)
import qualified Data.Text as T
import           GHC.Stack (HasCallStack)

pmf :: PatternMatchFail
pmf = U.pmf "Mud.Cmds.ExpCmds"

-----

logPlaOut :: Text -> Id -> [Text] -> MudStack ()
logPlaOut = L.logPlaOut "Mud.Cmds.ExpCmds"

-- ==================================================

expCmdSet :: HasCallStack => S.Set ExpCmd
expCmdSet = S.fromList
    [ ExpCmd "admire"       (HasTarget "You admire @."
                                       "% admires you."
                                       "% admires @.")
                            False
                            Nothing
    , ExpCmd "applaud"      (Versatile "You applaud enthusiastically."
                                       "% applauds enthusiastically."
                                       "You applaud enthusiastically for @."
                                       "% applauds enthusiastically for you."
                                       "% applauds enthusiastically for @.")
                            True
                            Nothing
    , ExpCmd "astonished"   (Versatile "You are absolutely astonished."
                                       "% is absolutely astonished."
                                       "You stare at @ with an astonished expression on your face."
                                       "% stares at you with an astonished expression on & face."
                                       "% stares at @ with an astonished expression on & face.")
                            False
                            Nothing
    , ExpCmd "astounded"    (Versatile "You are altogether astounded."
                                       "% is altogether astounded."
                                       "You are altogether astounded at @."
                                       "% is altogether astounded at you."
                                       "% is altogether astounded at @.")
                            False
                            Nothing
    , ExpCmd "avert"        (Versatile "You avert your eyes."
                                       "% averts & eyes."
                                       "You avert your eyes from @."
                                       "% averts & eyes from you."
                                       "% averts & eyes from @.")
                            False
                            Nothing
    , ExpCmd "bawl"         (NoTarget  "You bawl like a baby."
                                       "% bawls like a baby.")
                            True
                            Nothing
    , ExpCmd "beam"         (Versatile "You beam cheerfully."
                                       "% beams cheerfully."
                                       "You beam cheerfully at @."
                                       "% beams cheerfully at you."
                                       "% beams cheerfully at @.")
                            False
                            Nothing
    , ExpCmd "belch"        (Versatile "You let out a deep belch."
                                       "% lets out a deep belch."
                                       "You belch purposefully at @."
                                       "% belches purposefully at you."
                                       "% belches purposefully at @.")
                            True
                            Nothing
    , ExpCmd "bewildered"   (Versatile "You are hopelessly bewildered."
                                       "% is hopelessly bewildered."
                                       "You are hopelessly bewildered by @'s behavior."
                                       "% is hopelessly bewildered by your behavior."
                                       "% is hopelessly bewildered by @'s behavior.")
                            False
                            Nothing
    , ExpCmd "blank"        (Versatile "You have a blank expression on your face."
                                       "% has a blank expression on & face."
                                       "You look blankly at @."
                                       "% looks blankly at you."
                                       "% looks blankly at @.")
                            False
                            Nothing
    , ExpCmd "blink"        (Versatile "You blink."
                                       "% blinks."
                                       "You blink at @."
                                       "% blinks at you."
                                       "% blinks at @.")
                            False
                            Nothing
    , ExpCmd "blush"        (NoTarget  "You blush."
                                       "% blushes.")
                            False
                            Nothing
    , ExpCmd "boggle"       (NoTarget  "You boggle at the concept."
                                       "% boggles at the concept.")
                            False
                            Nothing
    , ExpCmd "bow"          (Versatile "You bow."
                                       "% bows."
                                       "You bow before @."
                                       "% bows before you."
                                       "% bows before @.")
                            True
                            Nothing
    , ExpCmd "burp"         (Versatile "You burp."
                                       "% burps."
                                       "You burp rudely at @."
                                       "% burps rudely at you."
                                       "% burps rudely at @.")
                            True
                            Nothing
    , ExpCmd "burstlaugh"   (Versatile "You abruptly burst into laughter."
                                       "% abruptly bursts into laughter."
                                       "You abruptly burst into laughter in reaction to @."
                                       "% abruptly bursts into laughter in reaction to you."
                                       "% abruptly bursts into laughter in reaction to @.")
                            True
                            Nothing
    , ExpCmd "calm"         (NoTarget  "You appear calm and collected."
                                       "% appears calm and collected.")
                            False
                            Nothing
    , ExpCmd "caresscheek"  (HasTarget "You caress @'s cheek."
                                       "% caresses your cheek."
                                       "% caresses @'s cheek.")
                            True
                            Nothing
    , ExpCmd "cheer"        (Versatile "You cheer eagerly."
                                       "% cheers eagerly."
                                       "You cheer eagerly for @."
                                       "% cheers eagerly for you."
                                       "% cheers eagerly for @.")
                            True
                            Nothing
    , ExpCmd "chortle"      (Versatile "You chortle gleefully."
                                       "% chortles gleefully."
                                       "You chortle gleefully at @."
                                       "% chortles gleefully at you."
                                       "% chortles gleefully at @.")
                            True
                            Nothing
    , ExpCmd "chuckle"      (Versatile "You chuckle."
                                       "% chuckles."
                                       "You chuckle at @."
                                       "% chuckles at you."
                                       "% chuckles at @.")
                            True
                            Nothing
    , ExpCmd "clap"         (Versatile "You clap."
                                       "% claps."
                                       "You clap for @."
                                       "% claps for you."
                                       "% claps for @.")
                            True
                            Nothing
    , ExpCmd "closeeyes"    (NoTarget  "You close your eyes."
                                       "% closes & eyes.")
                            False
                            Nothing
    , ExpCmd "coldsweat"    (NoTarget  "You break out in a cold sweat."
                                       "% breaks out in a cold sweat.")
                            False
                            Nothing
    , ExpCmd "comfort"      (HasTarget "You comfort @."
                                       "% comforts you."
                                       "% comforts @.")
                            True
                            Nothing
    , ExpCmd "confused"     (Versatile "You look utterly confused."
                                       "% looks utterly confused."
                                       "Utterly confused, you look fixedly at @."
                                       "Utterly confused, % looks fixedly at you."
                                       "Utterly confused, % looks fixedly at @.")
                            False
                            Nothing
    , ExpCmd "cough"        (Versatile "You cough."
                                       "% coughs."
                                       "You cough loudly at @."
                                       "% coughs loudly at you."
                                       "% coughs loudly at @.")
                            True
                            Nothing
    , ExpCmd "coverears"    (NoTarget  "You cover your ears."
                                       "% covers & ears.")
                            False
                            Nothing
    , ExpCmd "covereyes"    (NoTarget  "You cover your eyes."
                                       "% covers & eyes.")
                            False
                            Nothing
    , ExpCmd "covermouth"   (NoTarget  "You cover your mouth."
                                       "% covers & mouth.")
                            False
                            Nothing
    , ExpCmd "cower"        (Versatile "You cower in fear."
                                       "% cowers in fear."
                                       "You cower in fear before @."
                                       "% cowers in fear before you."
                                       "% cowers in fear before @.")
                            False
                            Nothing
    , ExpCmd "cringe"       (Versatile "You cringe."
                                       "% cringes."
                                       "You cringe at @."
                                       "% cringes at you."
                                       "% cringes at @.")
                            False
                            Nothing
    , ExpCmd "crossarms"    (NoTarget  "You cross your arms."
                                       "% crosses & arms.")
                            False
                            Nothing
    , ExpCmd "crossfingers" (NoTarget  "You cross your fingers."
                                       "% crosses & fingers.")
                            False
                            Nothing
    , ExpCmd "cry"          (NoTarget  "You cry."
                                       "% cries.")
                            True
                            Nothing
    , ExpCmd "cryanger"     (Versatile "You cry out in anger."
                                       "% cries out in anger."
                                       "You cry out in anger at @."
                                       "% cries out in anger at you."
                                       "% cries out in anger at @.")
                            True
                            Nothing
    , ExpCmd "cuddle"       (HasTarget "You cuddle with @."
                                       "% cuddles with you."
                                       "% cuddles with @.")
                            True
                            Nothing
    , ExpCmd "curious"      (Versatile "You have a curious expression on your face."
                                       "% has a curious expression on & face."
                                       "You flash a curious expression at @."
                                       "% flashes a curious expression at you."
                                       "% flashes a curious expression at @.")
                            False
                            Nothing
    , ExpCmd "curse"        (Versatile "You curse."
                                       "% curses."
                                       "You curse at @."
                                       "% curses at you."
                                       "% curses at @.")
                            True
                            Nothing
    , ExpCmd "curtsey"      (Versatile "You curtsey."
                                       "% curtseys."
                                       "You curtsey to @."
                                       "% curtseys to you."
                                       "% curtseys to @.")
                            False
                            Nothing
    , ExpCmd "curtsy"       (Versatile "You curtsy."
                                       "% curtsies."
                                       "You curtsy to @."
                                       "% curtsies to you."
                                       "% curtsies to @.")
                            False
                            Nothing
    , ExpCmd "dance"        (Versatile "You dance around."
                                       "% dances around."
                                       "You dance with @."
                                       "% dances with you."
                                       "% dances with @.")
                            True
                            (Just "")
    , ExpCmd "daydream"     (NoTarget  "Staring off into the distance, you indulge in a daydream."
                                       "Staring off into the distance, % indulges in a daydream.")
                            False
                            Nothing
    , ExpCmd "deepbreath"   (NoTarget  "You take a deep breath."
                                       "% takes a deep breath.")
                            True
                            Nothing
    , ExpCmd "disappoint"   (Versatile "You are clearly disappointed."
                                       "% is clearly disappointed."
                                       "You are clearly disappointed in @."
                                       "% is clearly disappointed in you."
                                       "% is clearly disappointed in @.")
                            False
                            Nothing
    , ExpCmd "dizzy"        (NoTarget  "Dizzy and reeling, you look as though you might pass out."
                                       "Dizzy and reeling, % looks as though ^ might pass out.")
                            False
                            Nothing
    , ExpCmd "doublelaugh"  (Versatile "You double over with laughter."
                                       "% doubles over with laughter."
                                       "You double over with laughter in reaction to @."
                                       "% doubles over with laughter in reaction to you."
                                       "% doubles over with laughter in reaction to @.")
                            True
                            Nothing
    , ExpCmd "drool"        (NoTarget  "You drool."
                                       "% drools.")
                            False
                            Nothing
    , ExpCmd "droop"        (NoTarget  "Your eyes droop."
                                       "%'s eyes droop.")
                            False
                            Nothing
    , ExpCmd "duck"         (Versatile "You duck."
                                       "% ducks."
                                       "You duck away from @."
                                       "% ducks away from you."
                                       "% ducks away from @.")
                            True
                            Nothing
    , ExpCmd "embrace"      (HasTarget "You warmly embrace @."
                                       "% embraces you warmly."
                                       "% embraces @ warmly.")
                            True
                            Nothing
    , ExpCmd "exhausted"    (NoTarget  "Exhausted, your face displays a weary expression."
                                       "Exhausted, %'s face displays a weary expression.")
                            False
                            Nothing
    , ExpCmd "facepalm"     (NoTarget  "You facepalm."
                                       "% facepalms.")
                            False
                            Nothing
    , ExpCmd "faint"        (NoTarget  "You faint."
                                       "% faints.")
                            True
                            (Just "fainted")
    , ExpCmd "fistpump"     (NoTarget  "You pump your fist in the air triumphantly."
                                       "% pumps & fist in the air triumphantly.")
                            False
                            Nothing
    , ExpCmd "flex"         (Versatile "You flex your muscles."
                                       "%'s flexes & muscles."
                                       "You flex your muscles at @."
                                       "% flexes & muscles at you."
                                       "% flexes & muscles at @.")
                            False
                            Nothing
    , ExpCmd "flinch"       (NoTarget  "You flinch."
                                       "% flinches.")
                            False
                            Nothing
    , ExpCmd "flop"         (NoTarget  "You flop down on the ground."
                                       "% flops down on the ground.")
                            True
                            (Just "on the ground")
    , ExpCmd "flustered"    (NoTarget  "You look entirely flustered."
                                       "% looks entirely flustered.")
                            False
                            Nothing
    , ExpCmd "frown"        (Versatile "You frown."
                                       "% frowns."
                                       "You frown at @."
                                       "% frowns at you."
                                       "% frowns at @.")
                            False
                            Nothing
    , ExpCmd "funnyface"    (Versatile "You make a funny face."
                                       "% makes a funny face."
                                       "You make a funny face at @."
                                       "% makes a funny face at you."
                                       "% makes a funny face at @.")
                            False
                            Nothing
    , ExpCmd "gape"         (Versatile "You gape."
                                       "% gapes."
                                       "You gape at @."
                                       "% gapes at you."
                                       "% gapes at @.")
                            False
                            Nothing
    , ExpCmd "gasp"         (Versatile "You gasp."
                                       "% gasps."
                                       "You gasp at @."
                                       "% gasps at you."
                                       "% gasps at @.")
                            True
                            Nothing
    , ExpCmd "gawk"         (HasTarget "You gawk at @."
                                       "% gawks at you."
                                       "% gawks at @.")
                            False
                            Nothing
    , ExpCmd "gaze"         (HasTarget "You gaze longingly at @."
                                       "% gazes longingly at you."
                                       "% gazes longingly at @.")
                            False
                            Nothing
    , ExpCmd "giggle"       (Versatile "You giggle."
                                       "% giggles."
                                       "You giggle at @."
                                       "% giggles at you."
                                       "% giggles at @.")
                            True
                            Nothing
    , ExpCmd "glance"       (Versatile "You glance around."
                                       "% glances around."
                                       "You glance at @."
                                       "% glances at you."
                                       "% glances at @.")
                            False
                            Nothing
    , ExpCmd "glare"        (HasTarget "You glare at @."
                                       "% glares at you."
                                       "% glares at @.")
                            False
                            Nothing
    , ExpCmd "greet"        (HasTarget "You greet @."
                                       "% greets you."
                                       "% greets @.")
                            True
                            Nothing
    , ExpCmd "grimace"      (Versatile "You grimace disapprovingly."
                                       "% grimaces disapprovingly."
                                       "You grimace disapprovingly at @."
                                       "% grimaces disapprovingly at you."
                                       "% grimaces disapprovingly at @.")
                            False
                            Nothing
    , ExpCmd "grin"         (Versatile "You grin."
                                       "% grins."
                                       "You grin at @."
                                       "% grins at you."
                                       "% grins at @.")
                            False
                            Nothing
    , ExpCmd "groan"        (Versatile "You groan."
                                       "% groans."
                                       "You groan at @."
                                       "% groans at you."
                                       "% groans at @.")
                            True
                            Nothing
    , ExpCmd "grovel"       (HasTarget "You grovel before @."
                                       "% grovels before you."
                                       "% grovels before @.")
                            True
                            Nothing
    , ExpCmd "growl"        (Versatile "You growl menacingly."
                                       "% growls menacingly."
                                       "You growl menacingly at @."
                                       "% growls menacingly at you."
                                       "% growls menacingly at @.")
                            True
                            Nothing
    , ExpCmd "grumble"      (NoTarget  "You grumble to yourself."
                                       "% grumbles to *.")
                            True
                            Nothing
    , ExpCmd "guffaw"       (Versatile "You guffaw boisterously."
                                       "% guffaws boisterously."
                                       "You guffaw boisterously at @."
                                       "% guffaws boisterously at you."
                                       "% guffaws boisterously at @.")
                            True
                            Nothing
    , ExpCmd "gulp"         (NoTarget  "You gulp."
                                       "% gulps.")
                            True
                            Nothing
    , ExpCmd "handhips"     (NoTarget  "You put your hands on your hips."
                                       "% puts & hands on & hips.")
                            False
                            Nothing
    , ExpCmd "hesitate"     (NoTarget  "You hesitate."
                                       "% hesitates.")
                            False
                            Nothing
    , ExpCmd "hiccup"       (NoTarget  "You hiccup involuntarily."
                                       "% hiccups involuntarily.")
                            True
                            Nothing
    , ExpCmd "highfive"     (HasTarget "You give @ a high five."
                                       "% gives you a high five."
                                       "% gives @ a high five.")
                            True
                            Nothing
    , ExpCmd "hmm"          (NoTarget  "You say, \"Hmm...\" and think about it."
                                       "% says, \"Hmm...\" and thinks about it.")
                            True
                            Nothing
    , ExpCmd "holdhand"     (HasTarget "You hold @'s hand."
                                       "% holds your hand."
                                       "% holds @'s hand.")
                            True
                            Nothing
    , ExpCmd "hop"          (NoTarget  "You hop up and down excitedly."
                                       "% hops up and down excitedly.")
                            True
                            Nothing
    , ExpCmd "howllaugh"    (Versatile "You howl with laughter."
                                       "% howls with laughter."
                                       "You howl with laughter at @."
                                       "% howls with laughter at you."
                                       "% howls with laughter at @.")
                            True
                            Nothing
    , ExpCmd "hug"          (HasTarget "You hug @."
                                       "% hugs you."
                                       "% hugs @.")
                            True
                            Nothing
    , ExpCmd "hum"          (NoTarget  "You hum a merry tune."
                                       "% hums a merry tune.")
                            True
                            Nothing
    , ExpCmd "innocent"     (NoTarget  "You try to look innocent."
                                       "% tries to look innocent.")
                            False
                            Nothing
    , ExpCmd "inquisitive"  (Versatile "You have an inquisitive expression on your face."
                                       "% has an inquisitive expression on & face."
                                       "You flash an inquisitive expression at @."
                                       "% flashes an inquisitive expression at you."
                                       "% flashes an inquisitive expression at @.")
                            False
                            Nothing
    , ExpCmd "jig"          (Versatile "You dance a lively jig."
                                       "% dances a lively jig."
                                       "You dance a lively jig with @."
                                       "% dances a lively jig with you."
                                       "% dances a lively jig with @.")
                            True
                            (Just "")
    , ExpCmd "joytears"     (NoTarget  "You are overcome with tears of joy."
                                       "% is overcome with tears of joy.")
                            False
                            Nothing
    , ExpCmd "jump"         (NoTarget  "You jump up and down excitedly."
                                       "% jumps up and down excitedly.")
                            True
                            Nothing
    , ExpCmd "kiss"         (HasTarget "You kiss @."
                                       "% kisses you."
                                       "% kisses @.")
                            True
                            Nothing
    , ExpCmd "kisscheek"    (HasTarget "You kiss @ on the cheek."
                                       "% kisses you on the cheek."
                                       "% kisses @ on the cheek.")
                            True
                            Nothing
    , ExpCmd "kisspassion"  (HasTarget "You kiss @ passionately."
                                       "% kisses you passionately."
                                       "% kisses @ passionately.")
                            True
                            Nothing
    , ExpCmd "kneel"        (Versatile "You kneel down."
                                       "% kneels down."
                                       "You kneel down before @."
                                       "% kneels down before you."
                                       "% kneels down before @.")
                            True
                            (Just "kneeling down")
    , ExpCmd "laugh"        (Versatile "You laugh."
                                       "% laughs."
                                       "You laugh at @."
                                       "% laughs at you."
                                       "% laughs at @.")
                            True
                            Nothing
    , ExpCmd "laughheart"   (Versatile "You laugh heartily."
                                       "% laughs heartily."
                                       "You laugh heartily at @."
                                       "% laughs heartily at you."
                                       "% laughs heartily at @.")
                            True
                            Nothing
    , ExpCmd "laydown"      (Versatile "You lay down."
                                       "% lays down."
                                       "You lay down next to @."
                                       "% lays down next to you."
                                       "% lays down next to @.")
                            True
                            (Just "laying down")
    , ExpCmd "leap"         (NoTarget  "You leap into the air."
                                       "% leaps into the air.")
                            True
                            Nothing
    , ExpCmd "leer"         (HasTarget "You leer at @."
                                       "% leers at you."
                                       "% leers at @.")
                            False
                            Nothing
    , ExpCmd "licklips"     (NoTarget  "You lick your lips."
                                       "% licks & lips.")
                            False
                            Nothing
    , ExpCmd "livid"        (NoTarget  "You are positively livid."
                                       "% is positively livid.")
                            False
                            Nothing
    , ExpCmd "longingly"    (HasTarget "You gaze longingly at @."
                                       "% gazes longingly at you."
                                       "% gazes longingly at @.")
                            False
                            Nothing
    , ExpCmd "losswords"    (NoTarget  "You appear to be at a loss for words."
                                       "% appears to be at a loss for words.")
                            False
                            Nothing
    , ExpCmd "massage"      (HasTarget "You massage @."
                                       "% massages you."
                                       "% massages @.")
                            True
                            Nothing
    , ExpCmd "moan"         (NoTarget  "You moan."
                                       "% moans.")
                            True
                            Nothing
    , ExpCmd "mumble"       (Versatile "You mumble to yourself."
                                       "% mumbles to *."
                                       "You mumble something to @."
                                       "% mumbles something to you."
                                       "% mumbles something to @.")
                            True
                            Nothing
    , ExpCmd "muscles"      (Versatile "You flex your muscles."
                                       "%'s flexes & muscles."
                                       "You flex your muscles at @."
                                       "% flexes & muscles at you."
                                       "% flexes & muscles at @.")
                            False
                            Nothing
    , ExpCmd "mutter"       (Versatile "You mutter to yourself."
                                       "% mutters to *."
                                       "You mutter something to @."
                                       "% mutters something to you."
                                       "% mutters something to @.")
                            True
                            Nothing
    , ExpCmd "nod"          (Versatile "You nod."
                                       "% nods."
                                       "You nod to @."
                                       "% nods to you."
                                       "% nods to @.")
                            False
                            Nothing
    , ExpCmd "nodagree"     (Versatile "You nod in agreement."
                                       "% nods in agreement."
                                       "You nod to @ in agreement."
                                       "% nods to you in agreement."
                                       "% nods to @ in agreement.")
                            False
                            Nothing
    , ExpCmd "noexpress"    (NoTarget  "Your face is entirely expressionless."
                                       "%'s face is entirely expressionless.")
                            False
                            Nothing
    , ExpCmd "nudge"        (HasTarget "You nudge @."
                                       "% nudges you."
                                       "% nudges @.")
                            True
                            Nothing
    , ExpCmd "nuzzle"       (HasTarget "You nuzzle @ lovingly."
                                       "% nuzzles you lovingly."
                                       "% nuzzles @ lovingly.")
                            True
                            Nothing
    , ExpCmd "openeyes"     (NoTarget  "You open your eyes."
                                       "% opens & eyes.")
                            False
                            Nothing
    , ExpCmd "openmouth"    (Versatile "Your mouth hangs open."
                                       "%'s mouth hangs open."
                                       "Your mouth hangs open in response to @."
                                       "%'s mouth hangs open in response to you."
                                       "%'s mouth hangs open in response to @.")
                            False
                            Nothing
    , ExpCmd "pace"         (NoTarget  "You pace around nervously."
                                       "% paces around nervously.")
                            True
                            (Just "")
    , ExpCmd "pant"         (NoTarget  "You pant."
                                       "% pants.")
                            True
                            Nothing
    , ExpCmd "patback"      (HasTarget "You pat @ on the back."
                                       "% pats you on the back."
                                       "% pats @ on the back.")
                            True
                            Nothing
    , ExpCmd "pathead"      (HasTarget "You pat @ on the head."
                                       "% pats you on the head."
                                       "% pats @ on the head.")
                            True
                            Nothing
    , ExpCmd "peer"         (HasTarget "You peer at @."
                                       "% peers at you."
                                       "% peers at @.")
                            False
                            Nothing
    , ExpCmd "pensive"      (Versatile "Your wistful expression suggests a pensive mood."
                                       "%'s wistful expression suggests a pensive mood."
                                       "You gaze pensively at @."
                                       "% gazes pensively at you."
                                       "% gazes pensively at @.")
                            False
                            Nothing
    , ExpCmd "perplexed"    (NoTarget  "You are truly perplexed by the situation."
                                       "% is truly perplexed by the situation.")
                            False
                            Nothing
    , ExpCmd "pet"          (HasTarget "You pet @."
                                       "% pets you."
                                       "% pets @.")
                            True
                            Nothing
    , ExpCmd "picknose"     (NoTarget  "You pick your nose."
                                       "% picks & nose.")
                            False
                            Nothing
    , ExpCmd "pinch"        (HasTarget "You pinch @."
                                       "% pinches you."
                                       "% pinches @.")
                            True
                            Nothing
    , ExpCmd "point"        (HasTarget "You point to @."
                                       "% points to you."
                                       "% points to @.")
                            False
                            Nothing
    , ExpCmd "poke"         (HasTarget "You poke @."
                                       "% pokes you."
                                       "% pokes @.")
                            True
                            Nothing
    , ExpCmd "ponder"       (NoTarget  "You ponder the situation."
                                       "% ponders the situation.")
                            False
                            Nothing
    , ExpCmd "pose"         (Versatile "You strike a pose."
                                       "% strikes a pose."
                                       "You strike a pose before @."
                                       "% strikes a pose before you."
                                       "% strikes a pose before @.")
                            False
                            Nothing
    , ExpCmd "pounce"       (HasTarget "You pounce on @."
                                       "% pounces on you."
                                       "% pounces on @.")
                            True
                            (Just "")
    , ExpCmd "pout"         (Versatile "You pout."
                                       "% pouts."
                                       "You pout at @."
                                       "% pouts at you."
                                       "% pout at @.")
                            False
                            Nothing
    , ExpCmd "prance"       (Versatile "You prance around."
                                       "% prances around."
                                       "You prance around @."
                                       "% prances around you."
                                       "% prances around @.")
                            True
                            Nothing
    , ExpCmd "purr"         (NoTarget  "You purr."
                                       "% purrs.")
                            True
                            Nothing
    , ExpCmd "questioning"  (Versatile "You have a questioning expression on your face."
                                       "% has a questioning expression on & face."
                                       "You flash a questioning expression at @."
                                       "% flashes a questioning expression at you."
                                       "% flashes a questioning expression at @.")
                            False
                            Nothing
    , ExpCmd "raisebrow"    (Versatile "You raise an eyebrow."
                                       "% raises an eyebrow."
                                       "You raise an eyebrow at @."
                                       "% raises an eyebrow at you."
                                       "% raises an eyebrow at @.")
                            False
                            Nothing
    , ExpCmd "raisehand"    (NoTarget  "You raise your hand."
                                       "% raises & hand.")
                            False
                            Nothing
    , ExpCmd "reeling"      (NoTarget  "Dizzy and reeling, you look as though you might pass out."
                                       "Dizzy and reeling, % looks as though ^ might pass out.")
                            False
                            Nothing
    , ExpCmd "relieved"     (NoTarget  "You look relieved."
                                       "% looks relieved.")
                            False
                            Nothing
    , ExpCmd "rock"         (NoTarget  "You rock back and forth."
                                       "% rocks back and forth.")
                            False
                            Nothing
    , ExpCmd "rolleyes"     (Versatile "You roll your eyes."
                                       "% rolls & eyes."
                                       "You roll your eyes at @."
                                       "% rolls & eyes at you."
                                       "% rolls & eyes at @.")
                            False
                            Nothing
    , ExpCmd "rubeyes"      (NoTarget  "You rub your eyes."
                                       "% rubs & eyes.")
                            False
                            Nothing
    , ExpCmd "ruffle"       (HasTarget "You ruffle @'s hair."
                                       "% ruffles your hair."
                                       "% ruffles @'s hair.")
                            True
                            Nothing
    , ExpCmd "salute"       (HasTarget "You salute @."
                                       "% salutes you."
                                       "% salutes @.")
                            False
                            Nothing
    , ExpCmd "satisfied"    (NoTarget  "You look satisfied."
                                       "% looks satisfied.")
                            False
                            Nothing
    , ExpCmd "scowl"        (Versatile "You scowl with contempt."
                                       "% scowls with contempt."
                                       "You scowl with contempt at @."
                                       "% scowls with contempt at you."
                                       "% scowls with contempt at @.")
                            False
                            Nothing
    , ExpCmd "scratchchin"  (NoTarget  "You scratch your chin."
                                       "% scratches & chin.")
                            False
                            Nothing
    , ExpCmd "scratchhead"  (NoTarget  "You scratch your head."
                                       "% scratches & head.")
                            False
                            Nothing
    , ExpCmd "scream"       (Versatile "You unleash a high-pitched scream."
                                       "% unleashes high-pitched scream."
                                       "You scream at @."
                                       "% screams at you."
                                       "% screams at @.")
                            True
                            Nothing
    , ExpCmd "shake"        (Versatile "You shake your head."
                                       "% shakes & head."
                                       "You shake your head at @."
                                       "% shakes & head at you."
                                       "% shakes & head at @.")
                            False
                            Nothing
    , ExpCmd "shiver"       (NoTarget  "You shiver."
                                       "% shivers.")
                            False
                            Nothing
    , ExpCmd "shriek"       (NoTarget  "You let out a shriek."
                                       "% lets out a shriek.")
                            True
                            Nothing
    , ExpCmd "shrieklaugh"  (Versatile "You shriek with laughter."
                                       "% shrieks with laughter."
                                       "You shriek with laughter at @."
                                       "% shrieks with laughter at you."
                                       "% shrieks with laughter at @.")
                            True
                            Nothing
    , ExpCmd "shrug"        (NoTarget  "You shrug your shoulders."
                                       "% shrugs & shoulders.")
                            False
                            Nothing
    , ExpCmd "shudder"      (NoTarget  "You shudder."
                                       "% shudders.")
                            False
                            Nothing
    , ExpCmd "shush"        (HasTarget "You shush @."
                                       "% shushes you."
                                       "% shushed @.")
                            True
                            Nothing
    , ExpCmd "sigh"         (NoTarget  "You sigh."
                                       "% sighs.")
                            True
                            Nothing
    , ExpCmd "sighrelief"   (NoTarget  "You sigh in relief."
                                       "% sighs in relief.")
                            True
                            Nothing
    , ExpCmd "sighsadly"    (NoTarget  "You sigh sadly."
                                       "% sighs sadly.")
                            True
                            Nothing
    , ExpCmd "sighwearily"  (NoTarget  "You sigh wearily."
                                       "% sighs wearily.")
                            True
                            Nothing
    , ExpCmd "sit"          (Versatile "You sit down."
                                       "% sits down."
                                       "You sit down next to @."
                                       "% sits down next to you."
                                       "% sit down next to @.")
                            True
                            (Just "sitting down")
    , ExpCmd "sleepy"       (NoTarget  "You look sleepy."
                                       "% looks sleepy.")
                            False
                            Nothing
    , ExpCmd "slowclap"     (Versatile "You clap slowly with a mocking lack of enthusiasm."
                                       "% claps slowly with a mocking lack of enthusiasm."
                                       "With a mocking lack of enthusiasm, you clap slowly for @."
                                       "With a mocking lack of enthusiasm, % claps slowly for you."
                                       "With a mocking lack of enthusiasm, % claps slowly for @.")
                            True
                            Nothing
    , ExpCmd "smacklips"    (NoTarget  "You smack your lips."
                                       "% smacks & lips.")
                            True
                            Nothing
    , ExpCmd "smile"        (Versatile "You smile."
                                       "% smiles."
                                       "You smile at @."
                                       "% smiles at you."
                                       "% smiles at @.")
                            False
                            Nothing
    , ExpCmd "smirk"        (Versatile "You smirk."
                                       "% smirks."
                                       "You smirk at @."
                                       "% smirks at you."
                                       "% smirks at @.")
                            False
                            Nothing
    , ExpCmd "snap"         (Versatile "You snap your fingers."
                                       "% snaps & fingers."
                                       "You snap your fingers at @."
                                       "% snaps & fingers at you."
                                       "% snaps & fingers at @.")
                            True
                            Nothing
    , ExpCmd "snarl"        (Versatile "You snarl."
                                       "% snarls."
                                       "You snarl at @."
                                       "% snarls at you."
                                       "% snarls at @.")
                            True
                            Nothing
    , ExpCmd "sneeze"       (NoTarget  "You sneeze."
                                       "% sneezes.")
                            True
                            Nothing
    , ExpCmd "snicker"      (Versatile "You snicker derisively."
                                       "% snickers derisively."
                                       "You snicker derisively at @."
                                       "% snickers derisively at you."
                                       "% snickers derisively at @.")
                            True
                            Nothing
    , ExpCmd "sniff"        (NoTarget  "You sniff the air."
                                       "% sniffs the air.")
                            True
                            Nothing
    , ExpCmd "sniffle"      (NoTarget  "You sniffle."
                                       "% sniffles.")
                            True
                            Nothing
    , ExpCmd "snore"        (NoTarget  "You snore loudly."
                                       "% snores loudly.")
                            True
                            Nothing
    , ExpCmd "snort"        (Versatile "You snort."
                                       "% snorts."
                                       "You snort at @."
                                       "% snorts at you."
                                       "% snorts at @.")
                            True
                            Nothing
    , ExpCmd "sob"          (NoTarget  "You sob."
                                       "% sobs.")
                            True
                            Nothing
    , ExpCmd "spit"         (Versatile "You spit."
                                       "% spits."
                                       "You spit on @."
                                       "% spits on you."
                                       "% spits on @.")
                            True
                            Nothing
    , ExpCmd "stagger"      (NoTarget  "You stagger around."
                                       "% staggers around.")
                            True
                            Nothing
    , ExpCmd "stamp"        (NoTarget  "Your stamp your feet."
                                       "% stamps & feet.")
                            True
                            Nothing
    , ExpCmd "stand"        (NoTarget  "You stand up."
                                       "% stands up.")
                            True
                            (Just "")
    , ExpCmd "stare"        (HasTarget "You stare at @."
                                       "% stares at you."
                                       "% stares at @.")
                            False
                            Nothing
    , ExpCmd "stiflelaugh"  (NoTarget  "You try hard to stifle a laugh."
                                       "% tries hard to stifle a laugh.")
                            True
                            Nothing
    , ExpCmd "stifletears"  (NoTarget  "You try hard to stifle your tears."
                                       "% tries hard to stifle & tears.")
                            False
                            Nothing
    , ExpCmd "stomach"      (NoTarget  "Your stomach growls."
                                       "%'s stomach growls.")
                            True
                            Nothing
    , ExpCmd "stomp"        (NoTarget  "Your stomp your feet."
                                       "% stomps & feet.")
                            True
                            Nothing
    , ExpCmd "stretch"      (NoTarget  "You stretch your muscles."
                                       "% stretches & muscles.")
                            False
                            Nothing
    , ExpCmd "strokehair"   (HasTarget "You stroke @'s hair."
                                       "% strokes your hair."
                                       "% strokes @'s hair.")
                            True
                            Nothing
    , ExpCmd "strut"        (NoTarget  "Your strut your stuff."
                                       "% struts & stuff.")
                            True
                            Nothing
    , ExpCmd "stumble"      (NoTarget  "You stumble and almost fall over."
                                       "% stumbles and almost falls over.")
                            True
                            Nothing
    , ExpCmd "suckthumb"    (NoTarget  "You suck your thumb."
                                       "% sucks & thumb.")
                            False
                            Nothing
    , ExpCmd "sulk"         (NoTarget  "You sulk."
                                       "% sulks.")
                            False
                            Nothing
    , ExpCmd "sweat"        (NoTarget  "You break out in a sweat."
                                       "% breaks out in a sweat.")
                            False
                            Nothing
    , ExpCmd "tap"          (HasTarget "You tap @ on the shoulder."
                                       "% taps you on the shoulder."
                                       "% taps @ on the shoulder.")
                            True
                            Nothing
    , ExpCmd "taunt"        (HasTarget "You taunt @."
                                       "% taunts you."
                                       "% taunts @.")
                            False
                            Nothing
    , ExpCmd "think"        (NoTarget  "You say, \"Hmm...\" and think about it."
                                       "% says, \"Hmm...\" and thinks about it.")
                            True
                            Nothing
    , ExpCmd "throat"       (NoTarget  "You clear your throat."
                                       "% clears & throat.")
                            True
                            Nothing
    , ExpCmd "thumbsdown"   (Versatile "You give a thumbs down."
                                       "% gives a thumbs down."
                                       "You give a thumbs down to @."
                                       "% gives a thumbs down to you."
                                       "% gives a thumbs down to @.")
                            False
                            Nothing
    , ExpCmd "thumbsup"     (Versatile "You give a thumbs up."
                                       "% gives a thumbs up."
                                       "You give a thumbs up to @."
                                       "% gives a thumbs up to you."
                                       "% gives a thumbs up to @.")
                            False
                            Nothing
    , ExpCmd "tickle"       (HasTarget "You tickle @."
                                       "% tickles you."
                                       "% tickles @.")
                            True
                            Nothing
    , ExpCmd "tongue"       (Versatile "You stick your tongue out."
                                       "% sticks & tongue out."
                                       "You stick your tongue out at @."
                                       "% sticks & tongue out at you."
                                       "% sticks & tongue out at @.")
                            False
                            Nothing
    , ExpCmd "tremble"      (Versatile "You tremble in fear."
                                       "% trembles in fear."
                                       "You tremble in fear of @."
                                       "% trembles in fear of you."
                                       "% trembles in fear of @.")
                            False
                            Nothing
    , ExpCmd "turnhead"     (HasTarget "You turn your head to look at @."
                                       "% turns & head to look at you."
                                       "% turns & head to look at @.")
                            False
                            Nothing
    , ExpCmd "twiddle"      (NoTarget  "You twiddle your thumbs."
                                       "% twiddles & thumbs.")
                            False
                            Nothing
    , ExpCmd "twirl"        (NoTarget  "You twirl around."
                                       "% twirls around.")
                            True
                            Nothing
    , ExpCmd "twitch"       (NoTarget  "You twitch nervously."
                                       "% twitches nervously.")
                            False
                            Nothing
    , ExpCmd "unamused"     (Versatile "You are plainly unamused."
                                       "% is plainly unamused."
                                       "You are plainly unamused by @'s antics."
                                       "% is plainly unamused by your antics."
                                       "% is plainly unamused by @'s antics.")
                            False
                            Nothing
    , ExpCmd "watch"        (HasTarget "You watch @ with interest."
                                       "% watches you with interest."
                                       "% watches @ with interest.")
                            False
                            Nothing
    , ExpCmd "wave"         (Versatile "You wave."
                                       "% waves."
                                       "You wave at @."
                                       "% waves at you."
                                       "% waves at @.")
                            False
                            Nothing
    , ExpCmd "weary"        (Versatile "Exhausted, your face displays a weary expression."
                                       "Exhausted, %'s face displays a weary expression."
                                       "You cast @ a weary glance."
                                       "% casts you a weary glance."
                                       "% casts @ a weary glance.")
                            False
                            Nothing
    , ExpCmd "whimper"      (Versatile "You whimper."
                                       "% whimpers."
                                       "You whimper at @."
                                       "% whimpers at you."
                                       "% whimpers at @.")
                            True
                            Nothing
    , ExpCmd "whistle"      (NoTarget  "You whistle."
                                       "% whistles.")
                            True
                            Nothing
    , ExpCmd "wiggle"       (NoTarget  "You wiggle around."
                                       "% wiggles around.")
                            False
                            Nothing
    , ExpCmd "wince"        (NoTarget  "You wince in pain."
                                       "% winces in pain.")
                            False
                            Nothing
    , ExpCmd "wink"         (Versatile "You wink."
                                       "% winks."
                                       "You wink at @."
                                       "% winks at you."
                                       "% winks at @.")
                            False
                            Nothing
    , ExpCmd "wipeface"     (NoTarget  "You wipe your face."
                                       "% wipes & face.")
                            False
                            Nothing
    , ExpCmd "wistful"      (Versatile "Your wistful expression suggests a pensive mood."
                                       "%'s wistful expression suggests a pensive mood."
                                       "You gaze wistfully at @."
                                       "% gazes wistfully at you."
                                       "% gazes wistfully at @.")
                            False
                            Nothing
    , ExpCmd "worried"      (Versatile "You look genuinely worried."
                                       "% looks genuinely worried."
                                       "You look genuinely worried for @."
                                       "% looks genuinely worried for you."
                                       "% looks genuinely worried for @.")
                            False
                            Nothing
    , ExpCmd "yawn"         (NoTarget  "You yawn."
                                       "% yawns.")
                            True
                            Nothing ]

expCmds :: HasCallStack => [Cmd]
expCmds = S.foldr helper [] expCmdSet
  where
    helper ec@(ExpCmd expCmdName _ _ _) = (Cmd { cmdName           = expCmdName
                                               , cmdPriorityAbbrev = Nothing
                                               , cmdFullName       = expCmdName
                                               , cmdAction         = Action (expCmd ec) True
                                               , cmdDesc           = "" } :)

expCmdNames :: HasCallStack => [Text]
expCmdNames = S.toList . S.map (\(ExpCmd n _ _ _) -> n) $ expCmdSet

getExpCmdByName :: HasCallStack => ExpCmdName -> ExpCmd
getExpCmdByName cn = head . S.toList . S.filter (\(ExpCmd cn' _ _ _) -> cn' == cn) $ expCmdSet

-----

expCmd :: HasCallStack => ExpCmd -> ActionFun
expCmd (ExpCmd ecn HasTarget {} _ _   ) p@NoArgs {}        = advise p [] . sorryExpCmdRequiresTarget $ ecn
expCmd (ExpCmd ecn ect          _ desc) (NoArgs i mq cols) = getState >>= \ms -> case ect of
  (NoTarget  toSelf toOthers      ) | isPla i ms
                                    , r <- getRace i ms
                                    , r `elem` furRaces
                                    , ecn == "blush" -> wrapSend mq cols . sorryExpCmdBlush . pp $ r
                                    | otherwise      -> helper ms toSelf toOthers
  (Versatile toSelf toOthers _ _ _)                  -> helper ms toSelf toOthers
  _                                                  -> pmf "expCmd" ect
  where
    furRaces                  = [ Felinoid, Lagomorph, Vulpenoid ]
    helper ms toSelf toOthers =
        let d                           = mkStdDesig i ms DoCap
            serialized                  = serializeDesigHelper d toOthers
            (heShe, hisHer, himHerself) = mkPros . getSex i $ ms
            substitutions               = [ ("%", serialized), ("^", heShe), ("&", hisHer), ("*", himHerself) ]
            toOthersBcast               = pure (nlnl . replace substitutions $ toOthers, desigOtherIds d)
            tuple                       = (toSelf, toOthersBcast, desc, toSelf)
        in expCmdHelper i mq cols ecn tuple
expCmd (ExpCmd ecn NoTarget {} _ _   ) p@(WithArgs     _ _  _    (_:_) ) = advise p [] . sorryExpCmdIllegalTarget $ ecn
expCmd (ExpCmd ecn ect         _ desc)   (OneArgNubbed i mq cols target) = case ect of
  (HasTarget     toSelf toTarget toOthers) -> helper toSelf toTarget toOthers
  (Versatile _ _ toSelf toTarget toOthers) -> helper toSelf toTarget toOthers
  _                                        -> pmf "expCmd" ect
  where
    helper toSelf toTarget toOthers = getState >>= \ms -> case singleArgInvEqRm InRm target of
      (InRm, target') ->
          let d                                = mkStdDesig i ms DoCap
              (first (i `delete`) -> invCoins) = getMobRmInvCoins i ms
          in if ()!# invCoins
            then case uncurry (resolveRmInvCoins i ms . pure $ target') invCoins of
              (_,                    [Left [sorryMsg]]) -> wrapSend mq cols sorryMsg
              (_,                    Right _:_        ) -> wrapSend mq cols sorryExpCmdCoins
              ([Left sorryMsg   ], _                  ) -> wrapSend mq cols sorryMsg
              ([Right (_:_:_)   ], _                  ) -> wrapSend mq cols adviceExpCmdExcessArgs
              ([Right [targetId]], _                  ) ->
                let ioHelper targetDesigTxt =
                        let (toSelf', toOthers', logMsg, substitutions) = mkBindings targetDesigTxt
                            toTarget'     = replace substitutions toTarget
                            toTargetBcast = (nlnl toTarget', pure targetId)
                            toOthersBcast = (nlnl toOthers', targetId `delete` desigOtherIds d)
                            tuple         = (toSelf', [ toTargetBcast, toOthersBcast ], desc, logMsg)
                        in expCmdHelper i mq cols ecn tuple
                    mkBindings targetTxt = let msg                         = replace (pure ("@", targetTxt)) toSelf
                                               toSelf'                     = parseDesig Nothing i ms msg
                                               logMsg                      = parseDesigSuffix   i ms msg
                                               serialized                  = serializeDesigHelper d toOthers
                                               (heShe, hisHer, himHerself) = mkPros . getSex i $ ms
                                               toOthers'                   = replace substitutions toOthers
                                               substitutions               = [ ("@", targetTxt)
                                                                             , ("%", serialized)
                                                                             , ("^", heShe)
                                                                             , ("&", hisHer)
                                                                             , ("*", himHerself) ]
                                           in (toSelf', toOthers', logMsg, substitutions)
                in if getType targetId ms `elem` [ PlaType, NpcType ]
                  then ioHelper . serialize . mkStdDesig targetId ms $ Don'tCap
                  else wrapSend mq cols sorryExpCmdTargetType
              x -> pmf "expCmd helper" x
            else wrapSend mq cols sorryNoOneHere
      (x, _) -> wrapSend mq cols . sorryExpCmdInInvEq $ x
expCmd _ p = advise p [] adviceExpCmdExcessArgs

expCmdHelper :: HasCallStack => ExpCmdFun
expCmdHelper i mq cols ecn (toSelf, bs, desc, logMsg) = do logPlaOut ecn i . pure $ logMsg
                                                           wrapSend mq cols toSelf
                                                           bcastIfNotIncog i bs
                                                           mobRmDescHelper i desc

mobRmDescHelper :: HasCallStack => Id -> MobRmDesc -> MudStack ()
mobRmDescHelper _ Nothing    = unit
mobRmDescHelper i (Just "" ) = tweak $ mobTbl.ind i.mobRmDesc .~ Nothing
mobRmDescHelper i (Just txt) = tweak $ mobTbl.ind i.mobRmDesc ?~ txt

serializeDesigHelper :: HasCallStack => Desig -> Text -> Text
serializeDesigHelper d toOthers = serialize . bool d { desigCap = Don'tCap } d $ T.head toOthers == '%'

-----

mkExpAction :: HasCallStack => Text -> ActionFun
mkExpAction name = expCmd . head . S.toList . S.filter helper $ expCmdSet
  where
    helper (ExpCmd ecn _ _ _) = ecn == name
