
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

local function restrict(px, py, w, h, room_size)
  if px + w > room_size.w then
    px = room_size.w - w
  elseif px < 0 then
    px = 0
  elseif py + h > room_size.h then
    py = room_size.h - h
  elseif py  < 0 then
    py = 0
  end
  return px, py
end

local function travel(px, py, w, h, room_size)
  if px > room_size.w then
    px = px - room_size.w
  elseif px + w < 0 then
    px = room_size.w - w
  elseif py > room_size.h then
    py = py - room_size.h
  elseif py + h < 0 then
    py = room_size.h - h
  end
  return px, py
end

local function update_walk(data, input)

  local player = get_player_sprite(data)
  if not player then
    return
  end

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

    walkstate.player_x = walkstate.player_x + step_x
    walkstate.player_y = walkstate.player_y + step_y
  else
    deaccelerate(walkstate)
    player.active_animation = "idle"
  end

  -- Check walking over room border
  local room_size = get_room_pixel_size(1)
  local current_coordinates = get_room_coordinates(data, data.active_room)
  local next_coordinates = {x = current_coordinates.x , y = current_coordinates.y}

  local x = walkstate.player_x
  local y = walkstate.player_y
  local w = player.frame_width
  local h = player.frame_height

  -- Start looking if should restrict or travel
  if x + w > room_size.w then
    next_coordinates.x = current_coordinates.x + 1
    next_coordinates.y = current_coordinates.y
  elseif x < 0 then
    next_coordinates.x = current_coordinates.x - 1
    next_coordinates.y = current_coordinates.y
  elseif y + h > room_size.h then
    next_coordinates.x = current_coordinates.x
    next_coordinates.y = current_coordinates.y + 1
  elseif y < 0 then
    next_coordinates.x = current_coordinates.x
    next_coordinates.y = current_coordinates.y - 1
  end

  if next_coordinates.x ~= current_coordinates.x
  or next_coordinates.y ~= current_coordinates.y then

    -- Check if there is room in the direction

    local nextroom = get_room_at(data, next_coordinates.x, next_coordinates.y)

    if nextroom then
      local travel_x , travel_y = travel(x,y, w, h, room_size)
      -- travel function changed coordinates, can change room
      if travel_x ~= x
      or travel_y ~= y then
        walkstate.player_x = travel_x
        walkstate.player_y = travel_y
        data.active_room = nextroom
      end
    else
      -- There is no room, restrict movement
      walkstate.player_x, walkstate.player_y = restrict(x, y, w, h, room_size)
    end
  end
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
