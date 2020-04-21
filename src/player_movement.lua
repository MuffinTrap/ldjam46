--[[
  Functions for player movement
  ]]--


local player_movement = {}

-- Globals to help with collisions
firstFloorId = 9
firstLadderId = 4
lastLadderId = 6
goldEmptyId = 8
goldId = 7

function player_movement.accelerate(speed, acc, max)
  local new_speed = speed + acc
  if new_speed > max then
    new_speed = max
  end
  return new_speed
end

function player_movement.deaccelerate(speed, slowing)
  local new_speed = speed - slowing
  if new_speed < 0 then
    new_speed = 0
  end
  return new_speed
end

function player_movement.get_bounds(x, y, w, h)
  local r = x + w
  local b = y + h

  local bounds = {x = x, y = y, w = w, h = h, r = r, b = b}
  return bounds
end

local function print_bounds(b)
  print("x " .. b.x .. ", " .. b.y ..", " .. b.r .. ", " .. b.b)
end


function player_movement.test_collision(bounds_a, bounds_b)
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

-- Returns how much center must be moved to match center of bounds B
function player_movement.test_center_inside(bounds_a, bounds_b)
  local result = {collision = false, x = 0, y = 0}
  local cx = bounds_a.x + bounds_a.w * 0.5
  local cy = bounds_a.x + bounds_a.h * 0.5

  local bcx = bounds_b.x + bounds_b.w * 0.5
  local bcy = bounds_b.x + bounds_b.h * 0.5

  if (cx > bounds_b.x and cx < bounds_b.r) then
    result.x = bcx - cx
  end
  if (cy > bounds_b.y and cy < bounds_b.b) then
    result.y = bcy - cy
  end
  result.collision = (result.x ~= 0 or result.y ~= 0)
  return result
end

function player_movement.test_center_room_fg(data, bounds, start_index, end_index)
  if end_index == nil then
    end_index = 9999
  end

  local grid_size = 16
  local bounds_b = {x = 0, y = 0, w = 0, h = 0, r = 0, b = 0}
  local update_result = {
    x = bounds.x,
    y = bounds.y,
    hit_index = 0,
    hit_sprite = nil,
    collision = false,
  }

  local grid_size = 16 -- Should really be sprite's frame width and height

  for i, sprite in ipairs(data.rooms[data.active_room].fg) do
    if sprite.index >= start_index and sprite.index <= end_index then
      bounds_b.x = sprite.x * TILE_SIZE
      bounds_b.y = sprite.y * TILE_SIZE
      bounds_b.w = grid_size
      bounds_b.w = grid_size
      bounds_b.r = bounds_b.x + grid_size
      bounds_b.b = bounds_b.y + grid_size
      local center_result = player_movement.test_center_inside(bounds, bounds_b)

      if center_result.collision == true then
          update_result.x = update_result.x + center_result.x
          update_result.y = update_result.y + center_result.y
          update_result.hit_index = sprite.index
          update_result.hit_sprite = sprite
          update_result.collision = true
          return update_result
      end
    end
  end
  return update_result
end

function player_movement.test_collision_room_fg(data, bounds, start_index, end_index)
  if end_index == nil then
    end_index = 9999
  end

  local grid_size = 16

  local bounds_b = {x = 0, y = 0, r = 0, b = 0}

  local update_result = {
    x = bounds.x,
    y = bounds.y,
    hit_index = 0,
  }

  for i, sprite in ipairs(data.rooms[data.active_room].fg) do
    if sprite.index >= start_index and sprite.index <= end_index then
      bounds_b.x = sprite.x * TILE_SIZE
      bounds_b.y = sprite.y * TILE_SIZE
      bounds_b.r = bounds_b.x + grid_size
      bounds_b.b = bounds_b.y + grid_size
      local collision_result = player_movement.test_collision(bounds, bounds_b)
      if collision_result.collision == true then
        if sprite.index >= firstFloorId then
          update_result.x = update_result.x + collision_result.x
          update_result.y = update_result.y + collision_result.y
          update_result.hit_index = sprite.index
        end
        if sprite.index >= firstLadderId and sprite.index <= lastLadderId then
          update_result.hit_index = sprite.index
        end
      end
    end
  end
  return update_result
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
  for i, roomeitem in ipairs(world.rooms) do
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

function player_movement.update_room_change(data, bounds)
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

  local result = {
    x = bounds.x,
    y = bounds.y,
    restrict = false,
  }

  if change_x ~= 0 or change_y ~= 0 then
    -- Check if there is room in the direction
    local nextroom = get_room_at(data, current_coordinates.x + change_x, current_coordinates.y + change_y)

    if nextroom then
      local travel_x , travel_y = travel(bounds, room_size)
      -- travel function changed coordinates, can change room
      if travel_x ~= bounds.x
      or travel_y ~= bounds.y then
        result.x = travel_x
        result.y = travel_y
        data.active_room = nextroom
      end
    else
      -- There is no room, restrict movement
      result.x, result.y = restrict(bounds, room_size)
      result.restrict = true
    end
  end

  return result
end

return player_movement
