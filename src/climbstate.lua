
--[[
  State for when player is climbing a ladder up or
  down. When feet touch ground or feet no longer touch ladder
  end the state
  ]]--

local movement = require "player_movement"

local climbstate = {
  player_speed = 0,
  player_acceleration = 0.1,
  player_slowing = 0.3,
  player_max_speed = 1,
  player_x = 0,
  player_y = 0,
}

function climbstate.init(player_start_x, player_start_y)
  climbstate.player_x = player_start_x
  climbstate.player_y = player_start_y
  climbstate.speed = 0
end

function climbstate.update(data, input)
  -- When hit floor or no longer hit ladder, end state
  local player = get_player_sprite(data)
  if not player then
    return
  end

  local speed = climbstate.player_speed
  local max = climbstate.player_max_speed
  local acc = climbstate.player_acceleration

  local test_x = 0
  local test_y = 0

  local step_x = 0
  local step_y = 0

  if direction_down(input) then
    climbstate.player_speed = movement.accelerate(speed, acc, max)

    if input.up then
      step_y = -climbstate.player_speed
      drawing.set_animation(player, "walk_up")
    elseif input.down then
      step_y = climbstate.player_speed
      drawing.set_animation(player, "walk_down")
    end

    if input.left then
      step_x = -climbstate.player_speed
      drawing.set_animation(player, "walk_left")
    elseif input.right then
      step_x = climbstate.player_speed
      drawing.set_animation(player, "walk_right")
    end

    test_x = climbstate.player_x + step_x
    test_y = climbstate.player_y + step_y
  else
    climbstate.player_speed = movement.deaccelerate(climbstate.player_speed, climbstate.player_slowing)
    drawing.set_animation(player, "idle")
  end

  local bounds = movement.get_bounds(test_x, test_y, player.frame_width, player.frame_height)

  -- If player climbs inside wall, push out
  local move_result = movement.test_collision_room_fg(data, bounds, firstFloorId)
  if move_result.hit_index >= firstFloorId then
    climbstate.player_x = move_result.x
    climbstate.player_y = move_result.y
  end

  test_x = climbstate.player_x + step_x
  test_y = climbstate.player_y + step_y
  local bounds = movement.get_bounds(test_x, test_y, player.frame_width, player.frame_height)

  -- Test if still touching ladder
  local move_result = movement.test_collision_room_fg(data, bounds, firstLadderId, lastLadderId)
  if move_result.hit_index >= firstLadderId and move_result.hit_index <= lastLadderId then
    -- Touching ladder, climbing continues

    -- Test if changing room
    local change_result = movement.update_room_change(data, bounds)
    climbstate.player_x = change_result.x
    climbstate.player_y = change_result.y

    -- move player towards the center of the ladder
    if input.up or input.down then
      local centering = movement.test_center_room_fg(data, bounds, firstLadderId, lastLadderId)
      if centering.hit_index > 0 then
        climbstate.player_x = centering.x
      end
    end

    return true
  else
    -- No longer touches ladder, pop state
    climbstate.player_x = move_result.x
    climbstate.player_y = move_result.y
    print ("Climb end")
    return false
  end
end

function climbstate.get_player_pos()
  return {x = math.floor(climbstate.player_x), y = math.floor(climbstate.player_y)}
end

function climbstate.draw(data)
end

function climbstate.deinit(data)
  -- Transmit changed player position down the stack
  data.state_stack[data.state_index - 1].set_player_pos(climbstate.player_x, climbstate.player_y)
  pop_state(data)
end

return climbstate
