
--[[ State that handles player moving in rooms and changing rooms

]]--

local drawing = require "nesdraw"
local movement = require "player_movement"
local falling_state = require "falling"
local climbing_state = require "climbstate"
local gold = require "goldstatus"

local walkstate = {
  player_max_speed = 1,
  player_acceleration = 0.1,
  player_slowing = 0.3,
  player_speed = 0,
  player_x = 0,
  player_y = 0,
}

function walkstate.init(player_start_x, player_start_y)
  walkstate.player_x = player_start_x
  walkstate.player_y = player_start_y
  walkstate.player_speed = 0
end

local start_fall = 1
local start_climb = 2
local continue_walk = 3

local function update_walk(data, input)
  local player = get_player_sprite(data)
  if not player then
    return
  end

  -- Test if player is fa-fa-fa-falling!
  local test_x = walkstate.player_x
  local test_y = walkstate.player_y + 1

  local bounds = movement.get_bounds(test_x, test_y, player.frame_width, player.frame_height)
  local fall_result = movement.test_collision_room_fg(data, bounds, firstLadderId)
  if fall_result.hit_index == 0 then
    -- No floor or ladder under player, start falling
    return start_fall
  end
  if fall_result.hit_index == firstLadderId and input.down then
    -- Ladder under feet, start climbing
    return start_climb
  end

  local test_x = walkstate.player_x
  local test_y = walkstate.player_y

  local speed = walkstate.player_speed
  local max = walkstate.player_max_speed
  local acc = walkstate.player_acceleration

  if direction_down(input) then
    local step_x = 0
    local step_y = 0
    walkstate.player_speed = movement.accelerate(speed, acc, max)
    --[[
    if input.up then
      step_y = -walkstate.player_speed
      drawing.set_animation(player, "walk_up")
    elseif input.down then
      step_y = walkstate.player_speed
      drawing.set_animation(player, "walk_down")
    ]]--
    if input.left then
      step_x = -walkstate.player_speed
      drawing.set_animation(player, "walk_left")
    elseif input.right then
      step_x = walkstate.player_speed
      drawing.set_animation(player, "walk_right")
    end

    test_x = walkstate.player_x + step_x
    test_y = walkstate.player_y + step_y
  else
    walkstate.player_speed = movement.deaccelerate(walkstate.player_speed, walkstate.player_slowing)
    drawing.set_animation(player, "idle")
  end

  local bounds = movement.get_bounds(test_x, test_y, player.frame_width, player.frame_height)
  local update_result = movement.test_collision_room_fg(data, bounds, firstLadderId)

  if (input.up or input.down)
  and (update_result.hit_index >= firstLadderId and update_result.hit_index <= lastLadderId) then
    walkstate.player_x = update_result.x
    return start_climb
  end

  if update_result.hit_index > firstFloorId then
    walkstate.player_x = update_result.x
    walkstate.player_y = update_result.y
  else
    local change_result = movement.update_room_change(data, bounds)
    walkstate.player_x = change_result.x
    walkstate.player_y = change_result.y
  end

  -- Check if center collides with gold
  local gold_status = movement.test_center_room_fg(data, bounds, goldId, goldId)
  if gold_status.collision then
    print("hit gold")
    gold.collect(gold_status.hit_sprite)
  end

  return continue_walk
end

function walkstate.set_player_pos(x, y)
  walkstate.player_x = x
  walkstate.player_y = y
  walkstate.speed = 0
end

function walkstate.get_player_pos()
  return {x = math.floor(walkstate.player_x), y = math.floor(walkstate.player_y)}
end

function walkstate.update(data, input)
  local walk_result = update_walk(data, input)

  local player = get_player_sprite(data)
  if not player then
    return false
  end

  if walk_result == start_fall then
    print ("Walk -> Fall")
    drawing.set_animation(player, "fall")
    local fall = falling_state
    fall.init(walkstate.player_x, walkstate.player_y)
    push_state(data, fall)
    return true
  end

  if walk_result == start_climb then
    print ("Walk -> Climb")
    drawing.set_animation(player, "climb")
    local climb = climbing_state
    climb.init(walkstate.player_x, walkstate.player_y)
    push_state(data, climb)
    return true
  end

  if buttonA_pressed(input) then
    -- Drop food
  end

  return true
end

function walkstate.draw(data)
end

function walkstate.deinit(data)
end

return walkstate
