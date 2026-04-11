// Defines for wanted poster
/// Can't request or declare outlaws
#define NO_OUTLAW_POWER 0
/// Can request someone to be outlawed
#define LIMITED_OUTLAW_POWER 1
/// Can declare someone outlawed and approve requests
#define FULL_OUTLAW_POWER 2

/// Wanted Poster, displays players that have been declared an Outlaw
/// Can be used by some Garrison roles to declare/request declaring new Outlaws
/obj/structure/fluff/walldeco/wantedposter
	name = "wanted poster"
	desc = "A list of the worst scoundrels this realm has to offer along with their face sketches."
	icon_state = "wanted1"
	layer = BELOW_MOB_LAYER
	SET_BASE_PIXEL(0, 32)

/obj/structure/fluff/walldeco/wantedposter/r
	SET_BASE_PIXEL(32, 0)

/obj/structure/fluff/walldeco/wantedposter/l
	SET_BASE_PIXEL(-32, 0)

/obj/structure/fluff/walldeco/wantedposter/Initialize()
	. = ..()
	icon_state = "wanted[rand(1,3)]"
	dir = pick(GLOB.cardinals)

/obj/structure/fluff/walldeco/wantedposter/examine(mob/user)
	. = ..()
	if(ishuman(user))
		if(user.Adjacent(src))
			var/mob/living/carbon/human/human_user = user
			show_outlaw_headshot(human_user)
		else
			to_chat(user, span_warning("I need to get closer to see the scoundrels' faces!"))

/obj/structure/fluff/walldeco/wantedposter/attackby(obj/item/P, mob/user, list/modifiers)
	if(istype(P, /obj/item/paper) && ishuman(user))
		return declare_outlaw(P, user)
	else if((istype(P, /obj/item/natural/feather) || istype(P, /obj/item/natural/thorn)) && ishuman(user))
		// see if they have paper
		for(var/obj/item/paper/paper in user.held_items)
			return declare_outlaw(paper, user)
		to_chat(user, span_warning("How are you going to sketch an outlaw without something to write on?"))
		return

	else
		return ..()

/// Handles declaring or requesting a declaration of Outlaw status. Called by `attackby` when given an object with the path of `/obj/item/paper`
/// Calls additional procs to determine if people is 'worthy' of declaring someone and Outlaw, and whether the person is a valid target
/// If valid, either becomes a requested Outlaw (handled in UI on `examine`) or declares them an Outlaw outright
/obj/structure/fluff/walldeco/wantedposter/proc/declare_outlaw(obj/item/paper/paper, mob/living/carbon/human/human)
	// Determine power they have
	var/outlaw_power = determine_outlaw_power(human)

	if(!outlaw_power)
		to_chat(human, span_warning("You have no authority in [SSmapping.config.map_name], they would never consider this seriously..."))
		return
	if(paper.info)
		to_chat(human, span_warning("How are you going to sketch an outlaw on something that has already been written on?"))
		return

	//check if we have something to write on
	var/has_writer = FALSE
	for(var/obj/item in human.held_items) // tried to have this done differently, but didnt work so doing it this way
		if(istype(item, /obj/item/natural/feather) || istype(item, /obj/item/natural/thorn))
			has_writer = TRUE
	if(!has_writer)
		to_chat(human, span_warning("How are you going to sketch an outlaw without having something to write with?"))
		return

	var/possible_outlaw_name = SANITIZE_HEAR_MESSAGE(tgui_input_text(human, "Who do you want to be an Outlaw?", "The Accused", max_length = 50, encode = FALSE))
	var/mob/living/carbon/human/possible_outlaw

	for(var/mob/living/carbon/human/to_be_outlawed in GLOB.human_list)
		if(to_be_outlawed.real_name == possible_outlaw_name)
			possible_outlaw = to_be_outlawed

		if(to_be_outlawed.job == "Faceless One")
			to_chat(human, span_warning("That person doesn't exist!"))
			return

	if(!possible_outlaw)
		to_chat(human, span_warning("That person doesn't exist!"))
		return

	if(!can_be_outlawed(human, possible_outlaw))
		return

	// Person found, now get reason
	var/crimes = tgui_input_text(human, "Leave blank for 'General Crimes'", "Reason (Optional)", max_length = 75)
	if(!crimes)
		crimes = "General Crimes"

	if(!human.Adjacent(src)) // Not actually working???
		to_chat(human, span_warning("You need to stand near \the [src]!"))
		return

	human.visible_message("[human] starts to sketch out someone's mugshot on \the [paper]", "You start to sketch out a mugshot of [possible_outlaw.real_name] on \the [paper]")
	if(!do_after(human, 15 SECONDS, src, progress = TRUE, display_over_user = TRUE))
		to_chat(human, span_warning("You need to stand still to make an accurate sketch!"))
		return
	else
		human.visible_message("[human] finishes drawing on \the [paper] and attaches it to \the [src]", "You finish your sketch and attach the mugshot of [possible_outlaw.real_name] to \the [src]")
		qdel(paper)

		if(outlaw_power == FULL_OUTLAW_POWER) // Declare them outlaw
			GLOB.outlawed_players[possible_outlaw.real_name] = crimes

			if(crimes != "General Crimes")
				priority_announce("For [crimes], [possible_outlaw.real_name] has been declared an outlaw and must be captured or slain.", "[human.real_name], The [human.get_role_title()] Decrees", 'sound/misc/alert.ogg', "Captain")
			else
				priority_announce("[possible_outlaw.real_name] has been declared an outlaw and must be captured or slain.", "[human.real_name], The [human.get_role_title()] Decrees", 'sound/misc/alert.ogg', "Captain")
		else
			GLOB.outlaw_requested_players[possible_outlaw.real_name] = list(crimes, human.real_name)
			to_chat(human, span_info("With that done, now you need to speak with someone with authority to approve your request..."))

			// Notify captain and apply the status_effect
			for(var/mob/living/carbon/human/captain in GLOB.human_list)
				if(!captain.mind)
					continue
				if(istype(captain.mind.assigned_role,/datum/job/captain)) // Not working
					send_ooc_note("You sense that there is a new Outlaw request on the Wanted Posters", name = captain.real_name)
					playsound(captain, 'sound/misc/mail.ogg', 100, FALSE, -1)
					captain.apply_status_effect(/datum/status_effect/has_outlaw_requests)

/// Checks if person has the trait `TRAIT_CAN_DECLARE_OUTLAW` or if they are other special roles, returns a define at `wanted_poster.dm` based on result
/obj/structure/fluff/walldeco/wantedposter/proc/determine_outlaw_power(mob/living/carbon/human/human)
	// Outlaws do not have power over themselves.
	if(GLOB.outlawed_players?[human.real_name])
		return NO_OUTLAW_POWER
	if(HAS_TRAIT(human, TRAIT_CAN_DECLARE_OUTLAW))
		return FULL_OUTLAW_POWER

	if((human.job == "City Watch Lieutenant") || (human.job == "Serjeant-at-Arms"))
		return LIMITED_OUTLAW_POWER

	if(human.honorary == "Serjeant")
		return LIMITED_OUTLAW_POWER

	// At this stage, person is a NOBODY
	return NO_OUTLAW_POWER

/// This proc checks if person is already an outlaw, or if the `potential_outlaw` is restricted from being an Outlaw unless declared by the Monarch
/obj/structure/fluff/walldeco/wantedposter/proc/can_be_outlawed(mob/living/carbon/human/human, mob/living/carbon/human/potential_outlaw)
	if(GLOB.outlawed_players?[potential_outlaw.real_name])
		to_chat(human, span_warning("That person is already an outlaw!"))
		return FALSE

	if(GLOB.outlaw_requested_players?[potential_outlaw.real_name])
		to_chat(human, span_warning("You realize that someone has already placed a sketch of them on \the [src] for them to be declared an Outlaw."))
		return FALSE

	//TODO COMMENT THIS BACK IN AT END
	//if(human.job_type == /datum/job/lord) // The Monarch is never wrong.
		//return TRUE

	if(potential_outlaw.job_type == /datum/job/lord)
		to_chat(human, span_warning("You accuse \the [potential_outlaw.honorary][potential_outlaw.real_name]?! You fool!!"))
		return FALSE

	if(SSticker.regent_mob == potential_outlaw)
		to_chat(human, span_warning("You can't accuse the Regent of being an Outlaw, they may become your Lord soon!"))
		return FALSE

	if((potential_outlaw.job_type == /datum/job/royalknight) || (ispath(potential_outlaw.job_type, /datum/job/advclass/royalknight)))
		to_chat(human, span_warning("You would need to be the Monarch to declare one of their own knights an Outlaw..."))
		return FALSE

	if(potential_outlaw.job_type == /datum/job/captain)
		to_chat(human, span_warning("You would need to be the Monarch to declare their own Captain an Outlaw..."))
		return FALSE

	if((potential_outlaw.job_type == /datum/job/consort) || (ispath(potential_outlaw.job_type, /datum/job/advclass/consort)))
		to_chat(human, span_warning("[potential_outlaw.real_name]... the Monarch's own Consort?! You wouldn't dare."))
		return FALSE

	if((potential_outlaw.job_type == /datum/job/hand) || (ispath(potential_outlaw.job_type, /datum/job/advclass/hand)))
		to_chat(human, span_warning("[potential_outlaw.real_name] is (officially at least) the Monarch's most trusted advisor, you cannot declare them an Outlaw!"))
		return FALSE

	if(potential_outlaw.is_noble())
		to_chat(human, span_warning("Only the Monarch can declare someone of noble blood an Outlaw!"))
		return FALSE

	if(potential_outlaw.job_type == /datum/job/priest)
		to_chat(human, span_warning("You accuse their Eminence themselves?! Remove that thought before Astrata smites you where you stand!"))
		return FALSE

	if(potential_outlaw.job_type == /datum/job/monk || potential_outlaw.job_type == /datum/job/templar || potential_outlaw.job_type == /datum/job/gmtemplar || potential_outlaw.job_type == /datum/job/undertaker)
		to_chat(human, span_warning("Only the Monarch can declare one of the Clergy an outlaw..."))
		return FALSE

	return TRUE

/// Takes key of entry in `GLOB.outlawed_players` and `person` to send feedback to, and sends `person` a chat message giving reason they are outlawed
/obj/structure/fluff/walldeco/wantedposter/proc/display_reason(key, mob/living/person)
	var/mob/living/carbon/human/outlaw = null
	for(var/mob/living/carbon/human/human in GLOB.human_list)
		if(human.real_name == key)
			outlaw = human
	if(GLOB.outlawed_players?[key] && person && outlaw)
		to_chat(person, span_info("You read the wanted notice, which has a sketch of \a [outlaw.gender == FEMALE ? "feminine" : "masculine"] [outlaw.dna.species.name] with the message: <span class='bold'>[uppertext(key)]</span>, WANTED DEAD OR ALIVE FOR <span class='bold'>[uppertext(GLOB.outlawed_players?[key])]</span>."))

/// Takes key of entry in `GLOB.outlaw_requested_players` and has them declared an outlaw, with entry removed at end
/obj/structure/fluff/walldeco/wantedposter/proc/approve_request(key, mob/living/carbon/human/approver)
	var/list/outlaw_entry = GLOB.outlaw_requested_players[key]
	var/crimes = outlaw_entry[1]
	GLOB.outlawed_players[key] = crimes

	if(crimes != "General Crimes")
		priority_announce("For [crimes], [key] has been declared an outlaw and must be captured or slain.", "[approver.real_name], The [approver.get_role_title()] Decrees", 'sound/misc/alert.ogg', "Captain")
	else
		priority_announce("[key] has been declared an outlaw and must be captured or slain.", "[approver.real_name], The [approver.get_role_title()] Decrees", 'sound/misc/alert.ogg', "Captain")


	GLOB.outlaw_requested_players -= key

	if(!length(GLOB.outlaw_requested_players))
		// Remove status for each Captain
		for(var/mob/living/carbon/human/captain in GLOB.human_list)
			if(!captain.mind)
				continue
			if(istype(captain.mind.assigned_role,/datum/job/captain)) // Not working
				captain.remove_status_effect(/datum/status_effect/has_outlaw_requests)

/// Takes key of entry in `GLOB.outlaw_requested_players` and removes it
/obj/structure/fluff/walldeco/wantedposter/proc/deny_request(key)
	GLOB.outlaw_requested_players -= key

	if(!length(GLOB.outlaw_requested_players))
		// Remove status for each Captain
		for(var/mob/living/carbon/human/captain in GLOB.human_list)
			if(!captain.mind)
				continue
			if(istype(captain.mind.assigned_role,/datum/job/captain)) // Not working
				captain.remove_status_effect(/datum/status_effect/has_outlaw_requests)

/obj/structure/fluff/walldeco/wantedposter/proc/show_outlaw_headshot(mob/living/carbon/human/user)
	var/list/outlaws = list()

	for(var/mob/living/carbon/human/outlaw in GLOB.human_list)
		if(GLOB.outlawed_players?[outlaw.real_name])
			var/icon/credit_icon = SScrediticons.get_credit_icon(outlaw, TRUE)
			if(credit_icon)
				outlaws += list(list(
					"name" = outlaw.real_name,
					"icon" = credit_icon
				))

	if(!length(outlaws))
		to_chat(user, span_warning("There are no wanted criminals at the moment..."))
		return

	if(GLOB.outlawed_players?[user.real_name])
		var/list/funny = list("Yup. My face is on there.", "Wait a minute... That's me!", "Look at that handsome devil...", "At least I am wanted by someone...", "My chin can't be that big... right?")
		to_chat(user, span_notice("[pick(funny)]"))
		if(!HAS_MIND_TRAIT(user, TRAIT_KNOWBANDITS))
			ADD_TRAIT(user.mind, TRAIT_KNOWBANDITS, TRAIT_GENERIC)
			user.playsound_local(user, 'sound/misc/notice (2).ogg', 100, FALSE)
			to_chat(user, span_notice("I can recognize these fine people anywhere now."))
	else if(!HAS_MIND_TRAIT(user, TRAIT_KNOWBANDITS))
		ADD_TRAIT(user.mind, TRAIT_KNOWBANDITS, TRAIT_GENERIC)
		user.playsound_local(user, 'sound/misc/notice (2).ogg', 100, FALSE)
		to_chat(user, span_notice("I can recognize these faces as wanted criminals now."))

	var/dat = {"
	<style>
		.wanted-container {
			display: grid;
			grid-template-columns: repeat(3, 1fr);
			gap: 20px;
			padding: 15px;
		}
		.wanted-poster {
			width: 175px;
			height: 228px;
			border: 3px double #5c2c0f;
			background-color: #f5e7d0;
			padding: 8px;
			box-shadow: 3px 3px 5px rgba(0,0,0,0.3);
			font-family: 'Times New Roman', serif;
			display: flex;
			flex-direction: column;
		}
		.wanted-header {
			color: #c70404;
			font-size: 28px;
			font-weight: bold;
			text-align: center;
			margin-bottom: 5px;
			text-transform: uppercase;
		}
		.wanted-divider {
			border-bottom: 2px solid #8B0000;
			margin: 5px 0;
		}
		.wanted-footer {
			color: #8B0000;
			font-size: 16px;
			font-weight: bold;
			text-align: center;
			margin-bottom: 8px;
			text-transform: uppercase;
		}
		.wanted-icon-container {
			width: 120px;
			height: 85px;
			margin: 0 auto;
			border: 2px solid #5c2c0f;
			background-color: #ccac74;
			padding: 3px;
		}
		.wanted-icon {
			width: 100%;
			height: 90%;
			object-fit: cover;
			image-rendering: pixelated;
		}
		.wanted-name-container {
			flex-grow: 1;
			display: flex;
			flex-direction: column;
			justify-content: center;
			min-height: 65px;
			margin-top: 5px;
		}
		.wanted-name {
			color: #000000;
			font-size: 18px;
			font-weight: bold;
			text-align: center;
			padding: 0 5px;
			text-transform: uppercase;
			word-break: break-word;
			overflow: hidden;
			display: -webkit-box;
			-webkit-line-clamp: 3;
			-webkit-box-orient: vertical;
		}
	</style>
	<div class='wanted-container'>
	"}

	for(var/list/outlaw_data in outlaws)
		var/icon_html = ""
		if(outlaw_data["icon"])
			icon_html = "<img class='wanted-icon' src='data:image/png;base64,[icon2base64(outlaw_data["icon"])]'>"
		else
			icon_html = "<div class='wanted-icon' style='background:#8B4513;'></div>"

		dat += {"
		<div class='wanted-poster'>
			<div class='wanted-header'>WANTED</div>
			<div class='wanted-divider'></div>
			<div class='wanted-footer'>DEAD OR ALIVE</div>
			<div class='wanted-icon-container'>
				[icon_html]
			</div>
			<div class='wanted-name-container'>
				<div class='wanted-name'>[outlaw_data["name"]]</div>
			</div>
		</div>
		"}

	dat += "</div>"

	var/datum/browser/popup = new(user, "wanted_posters", "<center>Wanted Posters</center>", 688, 570)
	popup.set_content(dat)
	popup.open()

#undef NO_OUTLAW_POWER
#undef LIMITED_OUTLAW_POWER
#undef FULL_OUTLAW_POWER
