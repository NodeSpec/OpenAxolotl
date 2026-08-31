class_name SaveMigrations
extends RefCounted

## The upgrade path across save format versions (REQ-014 AC-5).
##
## Migrations are an ORDERED CHAIN of single-step upgrades, each tested against a
## fixture save of the prior version. A direct v1 -> v3 migration is untestable
## once v2 saves exist in the wild, so every step stands alone and they compose.

const CURRENT_VERSION := 1

## Saves written before the format carried a version field. Detected by the
## absence of "saveFormatVersion" rather than by guessing at content.
const LEGACY_UNVERSIONED := 0


## Reads the declared version, treating an absent field as the legacy
## pre-versioning format rather than as the current one — assuming "current"
## would silently skip the migration a genuinely old save needs.
static func version_of(profile: Dictionary) -> int:
	if not profile.has("saveFormatVersion"):
		return LEGACY_UNVERSIONED
	return int(profile["saveFormatVersion"])


## Upgrades a profile to [constant CURRENT_VERSION], applying each step in order.
## Returns null and populates [param out_errors] when no path exists — including
## a save from a FUTURE version, which this build cannot understand and must not
## guess at.
static func migrate_to_current(
	profile: Dictionary, out_errors: Array[SaveError] = []
) -> Dictionary:
	var version := version_of(profile)

	if version > CURRENT_VERSION:
		out_errors.append(SaveError.new(
			SaveError.UNKNOWN_FORMAT_VERSION,
			"saveFormatVersion",
			"save is version %d but this build understands at most %d"
			% [version, CURRENT_VERSION]))
		return {}

	var working := profile.duplicate(true)
	while version < CURRENT_VERSION:
		var next := version + 1
		var stepped := _apply_step(version, next, working)
		if stepped.is_empty():
			out_errors.append(SaveError.new(
				SaveError.NO_MIGRATION_PATH,
				"saveFormatVersion",
				"no migration from version %d to %d" % [version, next]))
			return {}
		working = stepped
		working["saveFormatVersion"] = next
		version = next

	return working


## Dispatches one single-step migration. An explicit match rather than dynamic
## dispatch by name: the compiler then checks every step exists, and an
## unregistered version pair is a missing-path error instead of a runtime
## "no such method".
static func _apply_step(
	from_version: int, to_version: int, profile: Dictionary
) -> Dictionary:
	if from_version == LEGACY_UNVERSIONED and to_version == 1:
		return _migrate_0_to_1(profile)
	return {}


## v0 -> v1: the pre-versioning format kept world progress in a flat top-level
## dictionary, which made a world's data indistinguishable from a profile field.
## v1 namespaces it under "worlds" so a module can never collide with a profile
## key, and stamps the version field the format had been missing.
static func _migrate_0_to_1(profile: Dictionary) -> Dictionary:
	var upgraded: Dictionary = {
		"worlds": {},
		"settings": profile.get("settings", {}),
		"unlockedGillMods": profile.get("unlockedGillMods", []),
	}

	var reserved: PackedStringArray = [
		"settings", "unlockedGillMods", "saveFormatVersion", "worlds"
	]
	for key: Variant in profile:
		var name := String(key)
		if reserved.has(name):
			continue
		if profile[key] is Dictionary:
			(upgraded["worlds"] as Dictionary)[name] = profile[key]

	return upgraded
