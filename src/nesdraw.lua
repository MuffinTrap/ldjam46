--[[
  All drawing functions etc
]]--

local function create_color(r, g, b)
  return {r/255, g/255, b/255}
end

local c1 = create_color(248, 200, 104)
local c2 = create_color(141, 219, 52)
local c3 = create_color(105, 207, 239)
local c4 = create_color(209, 179, 255)
local c5 = create_color(255, 142, 101)
local c6 = {255/255, 241/255, 232/255}
local c7 = create_color(100, 100, 100)

local bg1 = create_color(87, 67, 104)
local bg2 = create_color(132, 136, 211)
local bg3 = create_color(204, 86, 174)

local colors = {c1, c2, c3, c4, c5, c6, c7}

local nesdraw = {

}

function nesdraw.setColor(index)
    love.graphics.setColor(colors[index])
end

function nesdraw.draw_room(data, room_index, x, y, scale)
  local room = data.rooms[room_index]

  assert(room, "No room found with index: " .. room_index)
  assert(room.name, "No name for room : " .. room_index)
  assert(room.bg, "No bg layer in room : " .. room.name)


  local tileSize = TILE_SIZE * scale
  -- Room bg
  if room.bg_color then
  love.graphics.setColor(room.bg_color)
  love.graphics.rectangle("fill", x, y, ROOM_SIZE.w * tileSize, ROOM_SIZE.h * tileSize)
  end

  -- Draw bg
  love.graphics.setColor(1,1,1)

  for i, item in ipairs(room.bg) do
    local draw_x = x + item.x * tileSize
    local draw_y = y + item.y * tileSize
    assert(data.images[item.index], "No image with index" .. item.index)
    love.graphics.draw(data.images[item.index], draw_x, draw_y, 0, scale, scale)
   end

  for s, item in ipairs(room.fg) do
    local draw_x = x + item.x * tileSize
    local draw_y = y + item.y * tileSize
    nesdraw.draw_sprite(data.sprites[item.index], draw_x, draw_y, scale)
  end
end

function nesdraw.draw_world(data, world_index, x, y, scale)
  local world = data.worlds[world_index]
  local world_size_scaled = get_world_pixel_size(scale)
  local world_size = get_world_pixel_size(1)
  local world_tile_size = get_world_tile_size(scale)
  local world_tile_size_pixel = get_world_tile_size(1)
  -- World bg
  love.graphics.setColor(0,0,0)
  love.graphics.rectangle("fill", x, y, world_size_scaled.w, world_size_scaled.h)

  -- Calculating the room scale.
  -- The roomscale tells how much to scale a 8x8 tile
  local room_pixel_size = get_room_pixel_size(1)
  local height_in_tiles = world_size.h / TILE_SIZE
  local scaled_tile_height = world_size_scaled.h / height_in_tiles
  local roomscale = scaled_tile_height * scale

  love.graphics.setColor(1,1,1)

  local bracket = 0.25

  for i, item in ipairs(world.rooms) do
    local room_x = x + item.x * world_tile_size.w
    local room_y = y + item.y * world_tile_size.h
    nesdraw.draw_room(data, item.index, room_x, room_y, roomscale)
    love.graphics.line(room_x, room_y, room_x + world_tile_size.w * bracket, room_y)
    love.graphics.line(room_x, room_y, room_x, room_y + world_tile_size.h * bracket)
    love.graphics.print("" .. item.index, room_x + world_tile_size.w * 0.5, room_y)
  end
end


function nesdraw.set_animation(sprite, animation)
  for a, anim in ipairs(sprite.animations) do
    if anim.name == animation and sprite.active_animation ~= animation then
      sprite.active_animation = animation
      sprite.active_frame = 0
      break
    end
  end
end

local function draw_sprite_frame(sprite, x, y, u, v, scale, mirror_x)
  local frame = love.graphics.newQuad(u, v
                                      , sprite.frame_width, sprite.frame_height
                                      , sprite.sprite_atlas:getWidth()
                                      , sprite.sprite_atlas:getHeight())

  local scale_x = scale
  if mirror_x then
    scale_x = -scale
    x = x + sprite.frame_width
  end
  local transform = love.math.newTransform(x, y, 0, scale_x, scale)
  love.graphics.draw(sprite.sprite_atlas, frame, transform)

end

function nesdraw.draw_sprite(sprite, x, y, scale)

  local active_animation = nil
  if sprite.active_animation == "" then
    -- This sprite does not have animations
    draw_sprite_frame(sprite, x, y, 0, 0, scale)
  else
    for a, anim in ipairs(sprite.animations) do
      if anim.name == sprite.active_animation then
          active_animation = anim
          break
      end
    end

    assert(active_animation, "Sprite does not have animation " .. sprite.active_animation)

    -- Game time is in seconds
    if game_time - sprite.last_update >= active_animation.frame_times[1] then
      sprite.last_update = game_time
      sprite.active_frame = sprite.active_frame + 1
      sprite.active_frame = sprite.active_frame % active_animation.frame_amount
    end

    local frame_number = active_animation.first_frame + sprite.active_frame

    local frame_u = 0 + (frame_number) * sprite.frame_width
    local frame_v = 0

    assert(sprite.sprite_atlas, "Sprite has no atlas");

    draw_sprite_frame(sprite, x, y, frame_u, frame_v, scale, active_animation.mirror_x)
    -- Debugging frame
    -- love.graphics.print("" .. frame_number, x + 8, y)
  end
end

return nesdraw


