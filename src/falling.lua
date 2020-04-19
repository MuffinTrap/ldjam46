
local movement = require "player_movement"

--[[ State for falling player ]]--

local falling = {
      player_x = 0,
      player_y = 0,
      speed = 0,
      acceleration = 0.1,
      max_speed = 2,
      }

function falling.init(px, py)
  falling.player_x = px
  falling.player_y = py
  falling.speed = 0
end


function falling.update(data, input)
  -- When hit floor, end state
  local player = get_player_sprite(data)
  if not player then
    return
  end

  falling.speed = movement.accelerate(falling.speed, falling.acceleration, falling.max_speed)

  local test_x = falling.player_x
  local test_y = falling.player_y + falling.speed

  local bounds = movement.get_bounds(test_x, test_y, player.frame_width, player.frame_height)
  local fall_result = movement.test_collision_room_fg(data, bounds, firstLadderId)
  if  fall_result.hit_index >= firstLadderId then
    falling.player_x = fall_result.x
    falling.player_y = fall_result.y
    -- Falling is over
    return false
  else
    local change_result = movement.update_room_change(data, bounds)
    falling.player_x = change_result.x
    falling.player_y = change_result.y
    return true
  end
end

function falling.get_player_pos()
  return {x = math.floor(falling.player_x), y = math.floor(falling.player_y)}
end

function falling.draw()
end

function falling.deinit(data)
  -- Transmit changed player position down the stack
  data.state_stack[data.state_index - 1].set_player_pos(falling.player_x, falling.player_y)
  pop_state(data)
end

return falling
