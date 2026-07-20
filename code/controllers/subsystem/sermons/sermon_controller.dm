//THE BIG TODO LIST
// [] FRAMEWORK
//    [] Initial Subsystem Setup
//       [] Assign to area
//       [] Find and assign Brazier and Cross
//    [] Maphelper that assigns vital variables to subsystem
//    [] Track Host, Audience, 'Active Audience'
//       [] If Sermon active, ability to join active audience. If leave area, leave audience and active audience
//    [] Sermon Datum
//    [] "God Profiles" for Sermons (A datum for the datum to cover variations for Gods) (WE DO IT FOR ALL TEN DESPITE ONLY ASTRATA AND EORA)
//       [X] Framework
//       [] Overlays for crosses
//       [] Messages for prayer and sacrifice (audience + host)
//       [] MUSIC
//    [] Tiers for sermon
//    [] Win/Lose
//       [] Tiers for Win/Lose
//    [] COOLDOWNS
//       [] Timer (15 minutes)
//       [] Daily (resets on dae like spellbooks)
//       [] ONE TIME ONLY
//    [] Timer for each phase
//    [] Tiers make sermons more intense (music + sprites + Godspan for prayer)
// [] UI for Active Sermons (Oh Gods)
//    [] Top Middle of screen for Host/Active Audience
//    [] Tracks 'Objective', Timer, 'Tier Points' (WE MUST BARS BC BARS ARE AWESOME!!!)
//    [] Le Epic Scroll Open and Close animation
// [] UI for selecting a Sermon with DA BOOK (OH GODS)
//    [] Sorted by God Type in categories(like recipe book)
//    [] General Page for Sermon Tutorial (prob under an 'all' tab that is still sorted by god)
//    [] Greyed out if unable to be done (Cooldown/Not your god)
//    [] Button in sermon page to start the sermon
// [] PRAYER
//    [] Host preaches (devotion drain)
//    [] Audience vs Active Audience
//    [] THOSE WITH DEVOTION AND THE BOOK CO-HOST
//    [] Global 'Prayer' Pool to track how FIRE the prayer is
// [] OFFERINGS
//    [] EVERY CHURCH IN MAPS NEEDS SPECIAL BRAZIER, DO LAST!!!
//    [] Offering Tiers
//    [] Add way to give reagents
//    [] Proc to 'verify valid offering'
//    [] Way to signal to host where to give the offering
//    [] Offering Pool to allow for bulk offering? (make it option for certain sermons?)
// [] SACRIFICE
//    [] Verify person is on cross
//    [] Special fire
//       [] Does not ash EVER
//       [] Does not kill until we want it to (Timer and then kill/ash)
//       [] Give pain and burn damage but not kill? (Maybe just pain + )
// [] STARTER SERMONS
//    [] Can't do during Schisms
//    [] Cool Epic Names for all Sermons
//    [] Stress relief for tennites attending sermon (better if active)
//    [] General prayer (PRAYER DAE!!!!!)
//       [] Devotion or Mammon generation
//    [] Sacrifice the Heretic!
//       [] Heretics can convert or be ashed
//       [] Certain antags get ashed
//       [] Rest are just burnt to death (revivable)
//    [] Call Astrata to force it to be dae!
//       [] Tiered Rewards
//       [] Inspiration from Xyllix cruel trick on successful dae
//       [] Verewolves and Vamps get notified
//          [] Daewalker, vamps immune to sun get alternative messages
//       [] Can't do if a ritual is blocking the Sun
//    [] EORA MARRIAGE
//       [] Apple biten by the couple and offered to brazier
//       [] Alternative, Eoran buds offered by the Couple

//TODO CHANGE
SUBSYSTEM_DEF(sermon_controller) //TODO learn enough about subsystems to know what the below variables should be
	name = "Sermon Controller"
	wait = 2 SECONDS
	flags = SS_NO_INIT
	priority = 1

	/// Area where the controller will be 'assigned' to, set by a maphelper
	var/area/assigned_area
	/// Firebowl used for sermons, set by a maphelper
	var/obj/machinery/light/fueled/firebowl/church/sermon/firebowl
	/// Cross used for sermons, set by a maphelper
	var/obj/structure/fluff/psycross/copper/cross

	/// Host of the sermon, if they leave `assigned_area`, FAIL
	var/mob/living/host
	/// List of mob/living active audience members. These people take a more active role in the sermon than simply watching
	var/list/active_audience
	/// List of all mob/living that are in the area (`assigned_area` should not be an area that is too large due to this)
	var/list/audience

	// TODO, make maphelper to assign area to subsystem, and learn more about subsystems

/datum/controller/subsystem/sermon_controller/fire(resumed = 0)
