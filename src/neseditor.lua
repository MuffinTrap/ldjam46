--[[ Editor ]]--

local drawing = require "nesdraw"
local utf8 = require "utf8"
local luatable = require "LuaTable"
local listloader = require "listloader"

local EditRoomState = 1
local EditWorldState = 2

local textInputText = ""

local NamingActive = 1
local NamingCompeleted = 2
local NamingInactive = 3

local LayerBg = 1
local LayerFg = 2
local LayerTrigger = 3

local neseditor = {
  selected_image = 1,
  selected_sprite = 1,
  selected_room = 1,
  selected_world = 1,
  selected_layer = LayerBg,
  m1_released = false,
  m2_released = false,
  m1_dragging = false,
  mouse_scroll = 0,
  state = EditRoomState,
  write_pending = false,
  load_pending = false,
  naming_state = NamingInactive,

}

function neseditor.load()
end

function neseditor.mb1click()
  local released = neseditor.m1_released
  neseditor.m1_released = false
  return released
end

function neseditor.mb2click()
  local released = neseditor.m2_released
  neseditor.m2_released = false
  return released
end

function neseditor.mousepressed(x, y, button)
  if button == 1 then
    neseditor.m1_dragging = true
  end

end

function neseditor.mousereleased(x, y, button)
  if button == 1 then
    neseditor.m1_released = true
    neseditor.m1_dragging = false
  end

  if button == 2 then
    neseditor.m2_released = true
  end
end

function neseditor.mousewheelmoved(x, y)
  neseditor.mouse_scroll = neseditor.mouse_scroll + 10.0 * y
end


local function reload_images_and_rooms(data)
  data.images = listloader.load_image_list()
  data.rooms = listloader.load_room_list()
end

function neseditor.keypressed(key)
  if key == "backspace" then
    local byteoffset = utf8.offset(textInputText, -1)
    if byteoffset then
      textInputText = string.sub(textInputText, 1, byteoffset - 1)
    end
  end
end

function neseditor.textinput(text)
  textInputText = textInputText .. text
end

function neseditor.keyreleased(key)
  if neseditor.naming_state == NamingActive then
    if key == "return" then
      print("Enter released")
      neseditor.naming_state = NamingCompleted
      love.keyboard.setKeyRepeat(false)
    end

    return
  end

  if key == "f3" then
    neseditor.state = EditWorldState
  elseif key == "f4" then
    neseditor.state = EditRoomState
  elseif key == "f5" then
    -- Save
    neseditor.write_pending = true
  elseif key == "f6" then
    -- Load images and rooms
    neseditor.load_pending = true
  elseif key == "f7" and neseditor.naming_state == NamingInactive then
    neseditor.naming_state = NamingActive
    love.keyboard.setKeyRepeat(true) -- Allow keeping backspace down
  elseif key == "n" then
    if neseditor.state == EditRoomState then
      local nextRoom = neseditor.selected_room + 1;
      if nextRoom < 255 then
      neseditor.selected_room = nextRoom;
      end
    elseif neseditor.state == EditWorldState then
      local nextWorld = neseditor.selected_world + 1;
      if nextWorld < 255 then
        neseditor.selected_world = nextWorld;
      end
    end
  elseif key == "p" then
    if neseditor.state == EditRoomState then
      local nextRoom = neseditor.selected_room - 1;
      if nextRoom > 0 then
        neseditor.selected_room = nextRoom;
      end
    elseif neseditor.state == EditWorldState then
      local nextWorld = neseditor.selected_world - 1;
      if nextWorld > 0 then
        neseditor.selected_world = nextWorld;
      end
    end
  elseif key == "f" then
    neseditor.selected_layer = LayerFg
  elseif key == "b" then
    neseditor.selected_layer = LayerBg
  elseif key == "t" then
    neseditor.selected_layer = LayerTrigger
  end
end

local function draw_sprites(data, x, y, scroll, editor_scale, font_height, mx, my)
  -- Draw all sprites
  local listX = x
  local imageX = x + 20
  local imageY = y
  love.graphics.print("Sprites!", imageX, imageY - font_height)
  imageY = imageY + scroll
  for i, sprite in pairs(data.sprites) do

    local imageWidth = sprite.frame_width
    local imageHeight = sprite.frame_height
    imageWidth = imageWidth * editor_scale
    imageHeight = imageHeight * editor_scale

    -- Selecting an image
    if  mx > imageX and mx < imageX + imageWidth
    and my > imageY and my < imageY + imageHeight then

      drawing.setColor(4)
      love.graphics.rectangle("fill", imageX-1, imageY-1, imageWidth+2, imageHeight+2)

      if neseditor.mb1click() then
        neseditor.selected_sprite = i
      end

    else
      drawing.setColor(3)
    end

    love.graphics.print("" .. i .. ":", listX, imageY)

    love.graphics.setColor(1,1,1)
    drawing.draw_sprite(data.sprites[i], imageX, imageY, editor_scale)
    imageY = imageY + imageHeight
  end
end

local function draw_images(data, x, y, scroll, editor_scale, font_height, mx, my)
    -- Draw all images
  local listX = x
    local imageX = x + 20
    local imageY = y
    love.graphics.print("Images!", imageX, imageY - font_height)
    imageY = imageY + scroll
    for i, image in pairs(data.images) do

      local imageWidth, imageHeight = image:getPixelDimensions()
      imageWidth = imageWidth * editor_scale
      imageHeight = imageHeight * editor_scale

      -- Selecting an image
      if  mx > imageX and mx < imageX + imageWidth
      and my > imageY and my < imageY + imageHeight then

        drawing.setColor(4)
        love.graphics.rectangle("fill", imageX-1, imageY-1, imageWidth+2, imageHeight+2)

        if neseditor.mb1click() then
          neseditor.selected_image = i
        end

      else
        drawing.setColor(3)
      end

      love.graphics.print("" .. i .. ":", listX, imageY)

      love.graphics.setColor(1,1,1)
      love.graphics.draw(image, imageX, imageY, 0, editor_scale, editor_scale)
      imageY = imageY + imageHeight
    end
end

local function draw_rooms(data, x, y, scroll, scale, font_height, mx, my)
  local listX = x
  local roomX = x + 20
  local roomY = y
  love.graphics.print("Rooms!", roomX, roomY - font_height)
  roomY = roomY + scroll
  for i, room in pairs(data.rooms) do

    roomWidth = ROOM_SIZE.w * TILE_SIZE * scale
    roomHeight = ROOM_SIZE.h * TILE_SIZE * scale

    -- Selecting an room
    if  mx > roomX and mx < roomX + roomWidth
    and my > roomY and my < roomY + roomHeight then

      drawing.setColor(4)
      love.graphics.rectangle("fill", roomX-1, roomY-1, roomWidth+2, roomHeight+2)

      if neseditor.mb1click() then
        neseditor.selected_room = i
      end

    else
      drawing.setColor(3)
    end

    love.graphics.print("" .. i .. ":", listX, roomY)

    love.graphics.setColor(1,1,1)
    drawing.draw_room(data, i, roomX, roomY, scale)
    roomY = roomY + roomHeight
  end

end

local function get_selected_tile(mx, my, gridX, gridY, gridWidth, gridHeight
                                 , tile_size
                                 , tile_dimensions
                                 , dimAdjust)
  if (mx > gridX and mx < gridX + gridWidth and
      my > gridY and my < gridY + gridHeight) then

    local mtx = ((mx - gridX) / gridWidth) * tile_dimensions.w / dimAdjust
    local mty = ((my  - gridY ) / gridHeight) * tile_dimensions.h / dimAdjust
    mtx = math.floor(mtx)
    mty = math.floor(mty)

    return {gridX + mtx * tile_size.w, gridY + mty * tile_size.h}, {mtx * dimAdjust, mty * dimAdjust}
  else
    return nil
  end
end

local function modify_grid(grid, item_index, mt)
  local layer = grid
  local last = #layer
  if neseditor.mb1click() then
    -- Prevent duplicates
    local add = true
    for i, item in pairs(layer) do
      if item.x == mt[1] and item.y == mt[2] then
        if item.index == item_index then
          -- This item is already here
          add = false
        else
          -- Replace
          layer[i] = create_grid_item(item_index, mt[1], mt[2])
          add = false
        end
      end
    end
    if add then
      layer[last + 1] = create_grid_item(item_index, mt[1], mt[2])
    end
  end

  if neseditor.mb2click() then
    -- Remove by replacing the item with last item
    for i, item in ipairs(layer) do
      if item.x == mt[1] and item.y == mt[2] then
        if last > 1 then
          layer[i] = layer[last]
          layer[last] = nil
        else
          -- If only one item, remove it
          layer[i] = nil
        end
      end
    end
  end
end

function neseditor.update(data)
  if neseditor.write_pending then
    listloader.write_data(data)
    neseditor.write_pending = false
  end
  if neseditor.load_pending then
    reload_images_and_rooms(data)
    neseditor.load_pending = false
  end

  if not data.rooms[neseditor.selected_room] then
    data.rooms[neseditor.selected_room] = create_room()
  end

  if not data.worlds[neseditor.selected_world] then
    data.worlds[neseditor.selected_world] = create_world()
  end

  -- We have text input but naming is no longer active
  if string.len(textInputText) > 0 and neseditor.naming_state == NamingCompleted then
    print("Naming over: " .. textInputText)
    if neseditor.state == EditWorldState then
      data.worlds[neseditor.selected_world].name = textInputText
    elseif neseditor.state == EditRoomState then
      data.rooms[neseditor.selected_room].name = textInputText
    end
    textInputText = ""
    neseditor.naming_state = NamingInactive
  end

end

function neseditor.draw(data, font_height, grid_snap_size)
  love.graphics.setColor(1,1,1)
  local guide_x = 10 * gui_scale
  love.graphics.print("Editor!", guide_x, 0)
  love.graphics.print("F3 World - F4 Room - F5 Save - F6 Load", guide_x, font_height)

  local editTarget = "World"
  if neseditor.state == EditRoomState then
    editTarget = "Room"
  end
  love.graphics.print("F7 Rename " .. editTarget .. " - N/P Next/Prev " .. editTarget, guide_x, font_height * 2)
  love.graphics.print("(B)ackground, (F)oreground, (T)rigger" , guide_x, font_height * 3)

  love.graphics.print("Left mouse: Insert - Right mouse: Remove", guide_x, font_height * 4)


  local room_scale = editor_scale
  local world_scale = editor_scale / 10

  local mx, my = love.mouse.getPosition()

  local room_size = get_room_pixel_size(room_scale)
  local world_size = get_world_pixel_size(world_scale)

  local room_tile_size = {w = grid_snap_size * room_scale, h = grid_snap_size * room_scale}
  local world_tile_size = get_world_tile_size(world_scale)

  local world_pos = {x = editor_x, y = editor_y}
  local room_pos = {x = editor_x + room_size.w * 1.5, y = editor_y}
  local imageListX = room_pos.x + room_size.w
  local roomListX = world_pos.x + world_size.w

  -- Careful not to edit rooms and worlds that do not exist yet
  if data.worlds[neseditor.selected_world] and data.rooms[neseditor.selected_room] then

    drawing.setColor(3);
    if neseditor.state == EditWorldState then
      drawing.setColor(4)
      if neseditor.naming_state == NamingActive then
        drawing.setColor(4)
        love.graphics.print("> " .. textInputText, world_pos.x, world_pos.y - font_height * 2)
      end
    end


    -- Draw world

    love.graphics.print("World " .. neseditor.selected_world .. " : " .. data.worlds[neseditor.selected_world].name
                        , world_pos.x, world_pos.y - font_height)

    drawing.draw_world(data, neseditor.selected_world, world_pos.x, world_pos.y, world_scale)

    drawing.setColor(3);
    if neseditor.state == EditRoomState then
      drawing.setColor(4)
      if neseditor.naming_state == NamingActive then
        drawing.setColor(4)
        love.graphics.print("> " .. textInputText, room_pos.x, room_pos.y - font_height * 2)
      end
    end

    -- Rooms list
    draw_rooms(data, roomListX, world_pos.y,  neseditor.mouse_scroll, editor_scale / 4, font_height, mx, my)


    -- Draw Room

    love.graphics.print("Room " .. neseditor.selected_room .. " : " .. data.rooms[neseditor.selected_room].name
                        , room_pos.x, room_pos.y - font_height)


    drawing.draw_room(data, neseditor.selected_room, room_pos.x, room_pos.y, editor_scale)

    -- Layer selection

    local layer = "Background"
    if neseditor.selected_layer == LayerFg then
      layer = "Foregound"
    elseif neseditor.selected_layer == LayerTrigger then
      layer = "Triggers"
    end
    love.graphics.print("Layer :" .. layer, room_pos.x, room_pos.y + room_size.h)


    -- Images or sprites

    if neseditor.selected_layer == LayerBg then
      draw_images(data, imageListX, room_pos.y, neseditor.mouse_scroll, editor_scale, font_height, mx, my)
    elseif neseditor.selected_layer == LayerFg then
      draw_sprites(data, imageListX, room_pos.y, neseditor.mouse_scroll, editor_scale, font_height, mx, my)
    end

    -- Edit Room

    local dimAdjust = grid_snap_size / TILE_SIZE
    local st, mt = get_selected_tile(mx, my, room_pos.x, room_pos.y,
                                     room_size.w, room_size.h, room_tile_size,
                                     ROOM_SIZE, dimAdjust)
    if st then
      local room = data.rooms[neseditor.selected_room]
      local grid = room.bg
      local selected_item = neseditor.selected_image

      local valid_image = data.images[neseditor.selected_image] ~= nil
      local valid_sprite = data.sprites[neseditor.selected_sprite] ~= nil

      if neseditor.selected_layer == LayerBg and valid_image then
        -- Draw selected image
      love.graphics.draw(data.images[neseditor.selected_image], st[1], st[2], 0, room_scale, room_scale)
      elseif neseditor.selected_layer == LayerFg and valid_sprite then
        grid = room.fg
        selected_item = neseditor.selected_sprite
        -- Draw selected sprite
        drawing.draw_sprite(data.sprites[neseditor.selected_sprite], st[1], st[2], room_scale)
      elseif neseditor.selected_layer == LayerTrigger then
        grid = room.triggers
      end

      -- Draw borders around held tile
      love.graphics.rectangle("line", st[1]-1, st[2]-1, room_tile_size.w + 2, room_tile_size.h + 2)

      -- Draw guides for 16x16 tiles
      drawing.setColor(7)
      local guide_size = 16 * room_scale
      local guides_x = room_size.w / guide_size
      local guides_y = room_size.h / guide_size
      for guide_x = 0, guides_x do
        love.graphics.line(room_pos.x + guide_x * guide_size, room_pos.y
                           , room_pos.x + guide_x * guide_size, room_pos.y + room_size.h)
      end

      for guide_y = 0, guides_y do
        love.graphics.line(room_pos.x, room_pos.y + guide_y * guide_size
                           , room_pos.x + room_size.w, room_pos.y + guide_y * guide_size)
      end

      -- Draw guides for selected image or sprite
      drawing.setColor(6)
      local imagew = 0
      local imageh = 0
      if valid_image then
        imagew = data.images[neseditor.selected_image]:getWidth() * room_scale
        imageh = data.images[neseditor.selected_image]:getHeight() * room_scale
      elseif valid_sprite then
        imagew = data.sprites[neseditor.selected_sprite].frame_width * room_scale
        imageh = data.sprites[neseditor.selected_sprite].frame_height * room_scale
      end

      if valid_sprite or valid_image then
        love.graphics.line(room_pos.x, st[2],
                           room_pos.x + room_size.w, st[2])
        love.graphics.line(room_pos.x, st[2] + imageh,
                           room_pos.x + room_size.w, st[2] + imageh)

        love.graphics.line(st[1], room_pos.y
                           , st[1], room_pos.y + room_size.h)

        love.graphics.line(st[1] + imagew, room_pos.y
                           , st[1] + imagew, room_pos.y + room_size.h)
      end

      -- Finally modify the room
      modify_grid(grid, selected_item, mt)
    end


    -- Edit World

    st, mt = get_selected_tile(mx, my
                               , world_pos.x, world_pos.y
                               , world_size.w, world_size.h
                               , world_tile_size, WORLD_SIZE, 1)

    if st then
      -- Draw selected room
      drawing.draw_room(data, neseditor.selected_room, st[1], st[2], world_scale)
      love.graphics.rectangle("line"
                              , st[1]-1, st[2]-1
                              , world_tile_size.w + 2, world_tile_size.h + 2)

      modify_grid(data.worlds[neseditor.selected_world].rooms
                  , neseditor.selected_room
                  , mt)
    end

  end


  -- Draw mouse cursor
  drawing.setColor(2)
  love.graphics.rectangle("fill", mx - 4, my - 1, 8, 2)
  love.graphics.rectangle("fill", mx - 1, my - 4, 2, 8)
end

return neseditor
