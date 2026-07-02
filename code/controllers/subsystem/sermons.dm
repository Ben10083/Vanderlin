//THE BIG TODO LIST
// [] FRAMEWORK
//    [] Initial Subsystem Setup
//       [] Find and assign Brazier and Cross
//    [] Track Host, Audience, 'Active Audience'
//       [] If Sermon active, ability to join active audience. If leave area, leave audience and active audience
//    [] Sermon Datum
//    [] "God Profiles" for Sermons (A datum for the datum to cover variations for Gods)
//    [] Tiers for sermon
//    [] Win/Lose
//       [] Tiers for Win/Lose
//    [] COOLDOWNS
//       [] Timer (15 minutes)
//       [] Daily (resets on dae like spellbooks)
//       [] ONE TIME ONLY
//    [] Timer for each phase
//    [] Tiers make sermons more intense (music + sprites + Godspan for prayer)
// [] PRAYER
//    [] Host preaches (devotion drain)
//    [] Audience vs Active Audience
//    [] THOSE WITH DEVOTION AND THE BOOK CO-HOST
//    [] Global 'Prayer' Pool to track how FIRE the prayer is
// [] OFFERINGS
//    [] EVERY CHURCH IN MAPS NEEDS SPECIAL BRAZIER, DO LAST!!!
//    [] Offering Tiers
//    [] Proc to 'verify valid offering'
//    [] Way to signal to host where to give the offering
//    [] Offering Pool to allow for bulk offering? (make it option for certain sermons?)
// [] SACRIFICE
//    [] Verify person is on cross
//    [] Special fire
//       [] Does not ash EVER
//       [] Does not kill until we want it to (Timer and then kill/ash)
// [] STARTER SERMONS
//    [] General prayer (PRAYER DAE!!!!!)
//    [] Sacrifice the Heretic!
//       [] Heretics can convert or be ashed
//       [] Certain antags get ashed
//       [] Rest are just burnt to death (revivable)
//    [] Call Astrata to force it to be dae!
//       [] Tiered Rewards
//       [] Inspiration from Xyllix cruel trick on successful dae
//       [] Verewolves and Vamps get notified
//          [] Daewalker, vamps immune to sun get alternative messages
//    [] EORA MARRIAGE
//       [] Apple biten by the couple and offered to brazier
//       [] Alternative, Eoran buds offered by the Couple

//TODO CHANGE
SUBSYSTEM_DEF(death_arena)
	name = "Death Arena"
	wait = 2 SECONDS
	flags = SS_NO_INIT
	priority = 1

	var/turf/first_spawn
	var/turf/second_spawn
	var/list/waiting_fighters = list()
	///this is just so I can easily reference the head later
	var/list/fighters_heads = list()
	var/list/fighters = list()
	///we check if spirits here aswell
	var/list/tollless_clients = list()
	var/fighting = FALSE
	var/fight_force_end = null

/datum/controller/subsystem/death_arena/fire(resumed = 0)
