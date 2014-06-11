import 'dart:convert' as convert;
import 'package:yaml/yaml.dart' as yaml;

class Meaning {
  String meaning;
  String example;
  List<String> synonyms;
}

class Kind {
  String kind;
  List<Meaning> meanings;
}

class Noun extends Kind {
  String plural;
}

class Word {
  String word;
  String pronunciation;
  List<Kind> kinds;
  String related;
}

main() {
  var result = yaml.loadYaml(essential);
  print(result);
}

var essential =
"""
abyss:
  pronunciation: "əˈbɪs"
  kinds:
    noun:
      plural: "abysses"
      translations: ["propast", "hlubina"]
      meanings:
        - meaning: "a deep or seemingly bottomless chasm."
          example: "a rope led down into the dark abyss"
          synonyms: "chasm, gorge, ravine, canyon, fissure, rift, crevasse, gap, hole, gulf, pit, depth, cavity, void, bottomless pit"
        - meaning: "a wide or profound difference between people; a gulf."
          example: "the abyss between the two nations"  
        - meaning: "the regions of hell conceived of as a bottomless pit."
          example: "Satan's dark abyss"
        - meaning: "a catastrophic situation seen as likely to occur."
          example: "teetering on the edge of the abyss of a total political wipeout"
  related: ["abysmal"]

dubious:
  pronunciation: "ˈdjuːbɪəs"
  kinds:
    adjective:
      translations: ["pochybný", "nejistý", "nevěrohodný", "problematický"]
      meanings:
        - meaning: "hesitating or doubting."
          example: "I was rather dubious about the whole idea"
          synonyms: "doubtful, uncertain, unsure, in doubt, hesitant; undecided, unsettled, unconfirmed, undetermined, indefinite, unresolved, up in the air; wavering, vacillating, irresolute, in a quandary, in a dilemma, on the horns of a dilemma; sceptical, suspicious; <informal> iffy"
          antonyms: certain, definite
        - meaning: "not to be relied upon."
          example: "extremely dubious assumptions"
        - meaning: "morally suspect."
          example: "timeshare has been brought into disrepute by dubious sales methods"
          synonyms: "suspicious, suspect, under suspicion, untrustworthy, unreliable, undependable, questionable; informalshady, fishy, funny, not kosher; (informal) dodgy"
          antonyms: "trustworthy"
        - meaning: of questionable value.
          example: "he holds the dubious distinction of being relegated with every club he has played for"
          synonyms: equivocal, ambiguous, indeterminate, indefinite, unclear, vague, imprecise, hazy, puzzling, enigmatic, cryptic; open to question, debatable, questionable"
          antonyms: "decisive, clear, definite"
  related: ["doubt"]

rigour:
  pronunciation: "ˈrɪgə"
  kinds:
    noun:
      plural: "rigours"
      translations: ["přísnost", "zimnice", "třasavka", "mrazení", "nemilosrdnost", "drsnost počasí", "ztuhnutí těla"]
      meanings:
        - meaning: "the quality of being extremely thorough and careful."
          example:
            - "his analysis is lacking in rigour"
            - "a speech noted for its intellectual rigour"
          synonyms: "meticulousness, thoroughness, carefulness, attention to detail, diligence, scrupulousness, exactness, exactitude, precision, accuracy, correctness, strictness, punctiliousness, conscientiousness; archaicnicety"
          antonyms: "carelessness"
        - meaning: "severity or strictness."
          example:
            - "the full rigour of the law"
            - "the mines were operated under conditions of some rigour"
          synonyms: "strictness, severity, sternness, stringency, austerity, toughness, hardness, harshness, rigidity, inflexibility; cruelty, savagery, relentlessness, unsparingness, authoritarianism, despotism, intransigence"
          antonyms: "laxness"
        - meaning: "harsh and demanding conditions."
          example:
            - "the rigours of a harsh winter"
            - "she could not face the rigours of the journey"
          synonyms: "hardship, harshness, severity, adversity, suffering, privation, ordeal, misery, distress, trial; discomfort, inconvenience"
          antonyms: "pleasures"
  related: ["rigorous"]
voluptuous:
  pronunciation: "vəˈlʌptjʊəs"
  kind:
    adjective:
      translations: ["smyslný", "kyprý", "rozkošnický", "vnadný"]
""";

var stuff =
"""
impediment
indigenous
intrepid
jeopardy
leash
elucidate
enchant
endeavor
exploit
estensive
flimsy
fraud
gaudy
ghastly
grumble
harass
heretic
extol
endorse
afflication
affluent
ambiguous
annex


acquiesce
affable

agitate

aqueous
arduous
aroma
atone
avarice
bellicose
calisthenics
captor
concoct
dangle
deprive
diligent
disrobe
docile
doleful
drought
dumbfound
efface

enthral



insatiate

irate

loafer
lucrative
lustrous
malign
meddle
mend
mirth
nausea
neglect
nocturnal
obese
obsolete
perch
pervade
petulant
pillage
presumptuous
quashed
quenching
refurbished
rejoicing
reticent
reverberate

rotundity

shunned

taciturn
tantalize
tentative
torpid
treacherous

tyro


salvage
scattered
shatter
sketchy
sporadic
stifled
strive
subsequent
succumb

tremor
uproar
vanity
vehemence
vigilance
vindicate

wan
wile
wrinkle
""";