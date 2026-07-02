//THE BIG TODO LIST
// [] FRAMEWORK
//    [] Initial Subsystem Setup
//    []
//    [] Win/Lose
// [] PRAYER
//    []
// [] OFFERINGS
//    []
// [] SACRIFICE
//    [] Verify person is on cross
//    [] Special fire
//       [] Does not ash EVER
//       [] Does not kill until we want it to?

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
