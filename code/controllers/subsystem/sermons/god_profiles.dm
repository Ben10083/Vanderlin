// Datums for sermon god 'personalities' (How you would pray, variations in spriting, etc etc)
// Default is Astrata

/// Default god profile, technically centrist but will be mostly Astrata outside of lines
/datum/god_profile
	/// Which god, use defines in `code\__DEFINES\storytellers.dm`
	var/god = ASTRATA
	/// the span code for god speech, we grab the value of the defines in `code\__DEFINES\chat\span.dm` instead of the DEFINE itself to make it usable.
	var/god_speech_span = "god_astrata"

	// TODO SET THESE
	/// Overlay for the pantheon cross that increases based on tier of sermon
	var/cross_overlay
	///.dmi file for `cross_overlay` DO NOT MODIFY
	var/cross_overlays

	// TODO SET THESE
	/// Music that plays during tier 1 of sermons
	var/music_tier1
	/// Music that plays during tier 2 of sermons
	var/music_tier2
	/// Music that plays during tier 3 of sermons
	var/music_tier3

	/// Lines the host of the sermon will say during prayer phases
	var/list/prayer_lines
	/// Lines active audience members will say during prayer phases
	var/list/prayer_lines_audience

	/// Lines the host of the sermon will say during sacrifice phases (Burn the Heretic!)
	var/list/sacrifice_lines
	/// Lines active audience members will say during prayer phases
	var/list/sacrifice_lines_audience

/// Abyssor's god profile
/datum/god_profile/abyssor
	god = ABYSSOR
	god_speech_span = "god_abyssor"

/datum/god_profile/astrata
	god = ASTRATA
	god_speech_span = "god_astrata"

/// Dendor's god profile
/datum/god_profile/dendor
	god = DENDOR
	god_speech_span = "god_dendor"

/// Eora's god profile
/datum/god_profile/eora
	god = EORA
	god_speech_span = "god_eora"

/// Malum's god profile
/datum/god_profile/malum
	god = MALUM
	god_speech_span = "god_malum"

/// Necra's god profile
/datum/god_profile/necra
	god = NECRA
	god_speech_span = "god_necra"

/// Noc's god profile
/datum/god_profile/noc
	god = NOC
	god_speech_span = "god_noc"

/// Pestra's god profile
/datum/god_profile/pestra
	god = PESTRA
	god_speech_span = "god_pestra"

/// Ravox's god profile
/datum/god_profile/ravox
	god = RAVOX
	god_speech_span = "god_ravox"

/// Xylix's god profile
/datum/god_profile/xylix
	god = XYLIX
	god_speech_span = "god_xylix"
