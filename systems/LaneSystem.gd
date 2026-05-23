# res://systems/LaneSystem.gd
extends Node

const LANE_COUNT := 3

# Обычные массивы — это валидные константные выражения
const LANE_CENTERS := [-24.0, 0.0, 24.0]
const LANE_BOUNDS  := [-12.0, 12.0]

const DEPTH_MIN := -24.0
const DEPTH_MAX :=  24.0

# physics layers для полос (9..11)
const LAYER_LANE_0 := 1 << 8
const LAYER_LANE_1 := 1 << 9
const LAYER_LANE_2 := 1 << 10

static func clamp_lane(i: int) -> int:
	return clampi(i, 0, LANE_COUNT - 1)

static func clamp_depth(d: float) -> float:
	return clampf(d, DEPTH_MIN, DEPTH_MAX)

static func lane_from_depth(depth_y: float) -> int:
	# LANE_BOUNDS точно не null теперь
	if depth_y < float(LANE_BOUNDS[0]):
		return 0
	if depth_y > float(LANE_BOUNDS[1]):
		return 2
	return 1

static func center_from_lane(lane: int) -> float:
	return float(LANE_CENTERS[clamp_lane(lane)])

static func layer_from_lane(lane: int) -> int:
	match clamp_lane(lane):
		0: return LAYER_LANE_0
		1: return LAYER_LANE_1
		_: return LAYER_LANE_2
