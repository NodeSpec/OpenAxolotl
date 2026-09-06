class_name PortalTier
extends RefCounted

## Portal tiering: Official, Community, Experimental (REQ-009 AC-5, REQ-020 AC-6).
##
## The tier comes from the manifest's optional `tier` field, and its ABSENT
## DEFAULT IS OFFICIAL — at MVP everything installed ships in this repository
## past the maintainer gate, so an undeclared tier is an official world, and the
## reference template (which by design declares nothing optional) lands where it
## belongs. Tier is not a security boundary and must never become one: every
## community world reaches `worlds/` only through mandatory human review, and
## the reviewer confirming the declared tier is part of that review. The
## machine-checked boundary is the static gate; the tier is presentation.
##
## Each tier is distinguished by THREE channels — a pedestal shape, a text
## label, and a colour — because REQ-019 forbids colour-only encoding
## project-wide. A colour-blind player tells an Experimental portal from an
## Official one by its silhouette and its label before colour ever enters
## into it.

enum Tier {
	OFFICIAL,
	COMMUNITY,
	EXPERIMENTAL,
}

const ALL: Array[Tier] = [Tier.OFFICIAL, Tier.COMMUNITY, Tier.EXPERIMENTAL]

const MANIFEST_FIELD := "tier"

## shape id, label, colour — three channels per tier, deliberately all distinct.
const _DISCRIMINATORS: Dictionary = {
	Tier.OFFICIAL: ["pedestal_arch", "Official Lagoon", Color(0.25, 0.55, 0.85)],
	Tier.COMMUNITY: ["pedestal_ring", "Community Lagoon", Color(0.3, 0.7, 0.45)],
	Tier.EXPERIMENTAL: ["pedestal_spire", "Experimental Lagoon", Color(0.8, 0.6, 0.25)],
}


static func id(tier: Tier) -> String:
	return String(Tier.keys()[tier]).to_lower()


static func is_known_id(text: String) -> bool:
	var wanted := text.strip_edges().to_lower()
	for tier: Tier in ALL:
		if id(tier) == wanted:
			return true
	return false


static func from_id(text: String) -> Tier:
	var wanted := text.strip_edges().to_lower()
	for tier: Tier in ALL:
		if id(tier) == wanted:
			return tier
	return Tier.OFFICIAL


## Reads the tier from a manifest dictionary. Absent means OFFICIAL; a value
## outside the closed set is a named error rather than a silent default,
## because "expermental" quietly becoming an official portal is exactly the
## kind of drift a closed set exists to stop.
static func from_manifest(manifest: Dictionary,
		out_errors: Array[HubError] = []) -> Tier:
	if not manifest.has(MANIFEST_FIELD):
		return Tier.OFFICIAL
	var raw := String(manifest[MANIFEST_FIELD])
	if not is_known_id(raw):
		out_errors.append(HubError.new(
			HubError.UNKNOWN_TIER, raw,
			"'%s' is not one of official, community, experimental" % raw))
		return Tier.OFFICIAL
	return from_id(raw)


static func shape_id(tier: Tier) -> String:
	return String((_DISCRIMINATORS[tier] as Array)[0])


static func label(tier: Tier) -> String:
	return String((_DISCRIMINATORS[tier] as Array)[1])


static func color(tier: Tier) -> Color:
	return (_DISCRIMINATORS[tier] as Array)[2] as Color
