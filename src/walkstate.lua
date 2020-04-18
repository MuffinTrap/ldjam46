
--[[ State that handles player moving in rooms and changing rooms

]]--

local drawing = require "nesdraw"

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

local function accelerate(state)
  local new_speed = state.player_speed + state.player_acceleration
  if new_speed > state.player_max_speed then
    new_speed = state.player_max_speed
  end
  state.player_speed = new_speed
  return new_speed
end

local function deaccelerate(state)
  local new_speed = state.player_speed - state.player_slowing
  if new_speed < 0 then
    new_speed = 0
  end
  state.player_speed = new_speed
  return new_speed
end

local function get_room_at(data, x, y)
  local world = data.worlds[data.active_world]
  for i, roomitem in ipairs(world.rooms) do
    if roomitem.x == x and roomitem.y == y then
      return roomitem.index
    end
  end
  return nil
end

local function get_room_coordinates(data, room_index)
  local world = data.worlds[data.active_world]
  for i, roomitem in ipairs(world.rooms) do
    if roomitem.index == room_index then
      return {x = roomitem.x, y = roomitem.y}
    end
  end
  return {x = -1, y = -1}
end

local function room_contains_sprite(data, character)
  for i, sprite in ipairs(data.rooms[data.active_room].fg) do
    if sprite.index == character then
      return true
    end
  end

  return false
end

local function restrict(bounds, room_size)
  local px = bounds.x
  local py = bounds.y
  if bounds.r >= room_size.w then
    px = room_size.w - bounds.w
  elseif bounds.x <= 0 then
    px = 0
  end

  if bounds.b >= room_size.h then
    py = room_size.h - bounds.h
  elseif bounds.y <= 0 then
    py = 0
  end

  return px, py
end

local function travel(bounds, room_size)
  local px = bounds.x
  local py = bounds.y
  if bounds.x > room_size.w then
    px = bounds.x - room_size.w
  elseif bounds.r < 0 then
    px = room_size.w - bounds.w
  end

  if bounds.y > room_size.h then
    py = bounds.y - room_size.h
  elseif bounds.b < 0 then
    py = room_size.h - bounds.h
  end

  return px, py
end

local function get_player_bounds(player, x, y)
  local px = x
  local py = y
  local pw = player.frame_width
  local ph = player.frame_height
  local pr = px + pw
  local pb = py + ph

  local bounds = {x = px, y = py, w = pw, h = ph, r = pr, b = pb}
  return bounds
end

local function update_room_change(data, input, bounds)
  -- Check walking over room border
  local room_size = get_room_pixel_size(1)
  local current_coordinates = get_room_coordinates(data, data.active_room)
  local next_coordinates = {x = current_coordinates.x , y = current_coordinates.y}


  -- Start looking if should restrict or travel
  local change_x = 0
  local change_y = 0
  if bounds.r > room_size.w then
    change_x = 1
  elseif bounds.x < 0 then
    change_x = -1
  end

  if bounds.b > room_size.h then
    change_y = 1
  elseif bounds.y < 0 then
    change_y = -1
  end

  local result_x = bounds.x
  local result_y = bounds.y

  if change_x ~= 0 or change_y ~= 0 then
    -- Check if there is room in the direction
    local nextroom = get_room_at(data, current_coordinates.x + change_x, current_coordinates.y + change_y)

    if nextroom then
      local travel_x , travel_y = travel(bounds, room_size)
      -- travel function changed coordinates, can change room
      if travel_x ~= bounds.x
      or travel_y ~= bounds.y then
        result_x = travel_x
        result_y = travel_y
        data.active_room = nextroom
      end
    else
      -- There is no room, restrict movement
      result_x, result_y = restrict(bounds, room_size)
    end
  end

  return result_x, result_y
end

local function print_bounds(b)
  print("x " .. b.x .. ", " .. b.y ..", " .. b.r .. ", " .. b.b)

end

local function test_collision(bounds_a, bounds_b)
  local result = {collision = false, x = 0, y = 0}
  if bounds_a.x <= bounds_b.x then
    result.x = math.min(bounds_b.x - bounds_a.r, 0)
  else
    result.x = math.max(bounds_b.r - bounds_a.x, 0)
  end
  if bounds_a.y < bounds_b.y then
    result.y = math.min(bounds_b.y - bounds_a.b, 0)
  else
    result.y = math.max(bounds_b.b - bounds_a.y, 0)
  end
  result.collision = (result.x ~= 0 and result.y ~= 0)
  -- Return only the smaller correction
  if math.abs(result.x) < math.abs(result.y) then
    result.y = 0
  else
    result.x = 0
  end
  return result
end

local function update_collision_check(data, input, bounds)

  local firstFloorId = 9
  local firstLadderId = 4
  local lastLadderId = 6
  local goldId = 7

  local grid_size = 16

  local bounds_b = {x = 0, y = 0, r = 0, b = 0}

  local result_x = bounds.x
  local result_y = bounds.y

  for i, sprite in ipairs(data.rooms[data.active_room].fg) do
    if sprite.index >= firstFloorId then
      bounds_b.x = sprite.x * TILE_SIZE
      bounds_b.y = sprite.y * TILE_SIZE
      bounds_b.r = bounds_b.x + grid_size
      bounds_b.b = bounds_b.y + grid_size
      local collision_result = test_collision(bounds, bounds_b)
      if collision_result.collision == true then
        print_bounds(bounds)
        print_bounds(bounds_b)
        result_x = result_x + collision_result.x
        result_y = result_y + collision_result.y
      end
    end
  end
  -- Collision with floor?
  -- No floor underneath -> Change to falling state

  -- Collision with gold -> Change to gold pick state

  -- Collision with ladder -> Can move up and down?

  return result_x, result_y

end

local function update_walk(data, input)

  local player = get_player_sprite(data)
  if not player then
    return
  end


  local test_x = walkstate.player_x
  local test_y = walkstate.player_y

  if direction_down(input) then
    local step_x = 0
    local step_y = 0
    if input.up then
      step_y = -accelerate(walkstate)
      drawing.set_animation(player, "walk_up")
    elseif input.down then
      step_y = accelerate(walkstate)
      drawing.set_animation(player, "walk_down")
    elseif input.left then
      step_x = -accelerate(walkstate)
      drawing.set_animation(player, "walk_left")
    elseif input.right then
      step_x = accelerate(walkstate)
      drawing.set_animation(player, "walk_right")
    end

    test_x = walkstate.player_x + step_x
    test_y = walkstate.player_y + step_y
  else
    deaccelerate(walkstate)
    player.active_animation = "idle"
  end

  local bounds = get_player_bounds(player, test_x, test_y)
  local result_x, result_y = update_collision_check(data, input, bounds)
  walkstate.player_x = result_x
  walkstate.player_y = result_y
  -- walkstate.player_x, walkstate.player_y = update_room_change(data, input, bounds)
end

local debugWin = false

function walkstate.get_player_pos()
  return {x = math.floor(walkstate.player_x), y = math.floor(walkstate.player_y)}
end

function walkstate.update(data, input)
  update_walk(data, input)

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
