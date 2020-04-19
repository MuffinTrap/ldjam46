local luatable = require "LuaTable"

local listloader = {}

local function split_string(line, separator)
  local strings = {}
  local index = 1
  if string.len(line) > 0 then
    local begin = 1
    local sepFirst, sepLast = string.find(line, separator)
    while sepFirst do
      strings[index] = string.sub(line, begin, sepFirst -1)
      begin = sepLast + 1
      index = index + 1
      sepFirst, sepLast = string.find(line, separator, begin)
    end
    strings[index] = (string.sub(line, begin))
  end
  return strings
end

local function create_list_name(keyword)
  local filename = "data/" .. keyword .. "list.txt"
  return filename
end

function listloader.load_data(data)
  -- Load imagelist
  data.images = listloader.load_image_list()

  -- Load sprites
  data.sprites = listloader.load_sprite_list()

  -- Load Rooms
  data.rooms = listloader.load_room_list()

  -- Load worlds
  data.worlds = listloader.load_world_list()

end

function listloader.load_image_list()
  local images = {}
  local filename = create_list_name("image");
  local separator = " "
  if love.filesystem.getInfo(filename) then

    --># image.png # # # #
    local linenumber = 0
    for line in love.filesystem.lines(filename) do
      print ("Image list line: " .. linenumber)
      linenumber = linenumber + 1
        local parts = split_string(line, separator)
        if (#parts > 0) then
        local index = tonumber(parts[1])
        local imagename = parts[2]
        local image = nil
        local imagepath = "data/images/" .. imagename

        if (love.filesystem.getInfo(imagepath)) then
          image = love.graphics.newImage(imagepath)
        else
          print ("Did not find image:" .. imagename)
        end

        print ("Read image: " .. index .. " " .. imagename)
        images[index] = image
      end
    end

  else
    print ("Did not find imagelist.list")
  end

  return images
end

local function create_sprite()
  local sprite = {
    sprite_atlas = nil,
    frame_width = 8,
    frame_height = 8,
    active_animation = "",
    active_frame = 0,
    last_update = 0,
    animations = {},
  }
  return sprite
end

local function load_sprite_image(filename)
  local sprite = create_sprite()
  if love.filesystem.getInfo(filename) then
      sprite.sprite_atlas = love.graphics.newImage(filename)
      sprite.frame_width = sprite.sprite_atlas:getWidth()
      sprite.frame_height = sprite.sprite_atlas:getHeight()
      print("Frame size: " .. sprite.frame_width .. ", " .. sprite.frame_height)
  else
    print("Could not find sprite image:" .. filename)
  end
  return sprite
end

local function load_sprite(filename)
  --[[
    bunny.png 8 16
    idle 1 2 1000, ...
  ]]--

  local sprite = create_sprite()

  local spritefilename = nil

  print("Loading sprite from: " .. filename)
  local line_number = 1
  local separator = " "
  if love.filesystem.getInfo(filename) then
    for line in love.filesystem.lines(filename) do

      local parts = split_string(line, separator)

      if line_number == 1 then
        print("Sprite atlas:")
        -- Image name and frame size
        spritefilename = parts[1]
        local frame_w = parts[2]
        local frame_h = parts[3]
        local spritepath = "data/images/" .. spritefilename
        if (love.filesystem.getInfo(spritepath)) then
          sprite.sprite_atlas = love.graphics.newImage(spritepath)
        else
          print ("Did not find sprite:" .. spritefilename)
        end
        print ("Read sprite: " .. spritefilename)
        sprite.frame_width = frame_w
        sprite.frame_height = frame_h
      else
        -- Rest of the lines define animations if sprite has them
        local animation_name = parts[1]
        local first = tonumber(parts[2])
        local amount = tonumber(parts[3])
        local times = {}
        local fi = 1
        for ft = 4, #parts do
          times[fi] = tonumber(parts[ft])
          fi = fi + 1
        end

        local animation = {
          name = animation_name,
          first_frame = first,
          frame_amount = math.abs(amount),
          frame_times = times,
          mirror_x = false,
        }
        if (amount < 0) then
          animation.mirror_x = true
        end
        sprite.animations[#sprite.animations + 1] = animation
        -- First animation becomes the initial active animation
        if line_number == 2 then
          sprite.active_animation = animation_name
        end
      end
      line_number = line_number + 1
    end
  else
    print("Could not find sprite file:" .. filename)
  end

  print("Frame size: " .. sprite.frame_width .. ", " .. sprite.frame_height)
  for ai = 1, #sprite.animations do
    print("Has animation: " .. sprite.animations[ai].name)
  end

  return sprite
end

function listloader.load_sprite_list()
  local sprites = {}
  local filename = create_list_name("sprite");
  local separator = " "
  if love.filesystem.getInfo(filename) then

    local linenumber = 0
    for line in love.filesystem.lines(filename) do
      print ("Sprite list line: " .. linenumber)
      linenumber = linenumber + 1
      local parts = split_string(line, separator)
      if (#parts == 2) then
        local index = tonumber(parts[1])
        local spritefilename = parts[2]
        -- If filename is .png, then just load the image and no animations etc
        print ("Sprite filename" .. spritefilename)
        if spritefilename:find(".png", -5) then
          local spritepath = "data/images/" .. spritefilename
          sprites[index] = load_sprite_image(spritepath)
        else
          local spritepath = "data/sprites/" .. spritefilename
          sprites[index] = load_sprite(spritepath)
        end
      end
    end

  else
    print ("Did not find imagelist.list")
  end

  return sprites

end

local function print_table(item)
  local orig_type = type(item)
  if orig_type == 'table' then
    print("Table")
    for orig_key, orig_value in next, item, nil do
      print("key: " .. orig_key)
      if type(orig_value) == "table" then
        print_table(orig_value)
      else
        print("Value: " .. orig_value)
      end
    end
  else -- number, string, boolean, etc
    print("" .. item)
  end
end

local function load_list(keyword, default_creator_function)
  local items = {}
  local filename = create_list_name(keyword)
  local separator = " "
  if love.filesystem.getInfo(filename) then
    local linenumber = 0

    for line in love.filesystem.lines(filename) do
      print ("" .. keyword .. " list line: " .. linenumber)
      linenumber = linenumber + 1
      --># item.xxx
      local parts = split_string(line, separator)

      if (#parts > 0) then
        local index = tonumber(parts[1])
        local item_file_name = parts[2]
        local filepath = "data/".. keyword .. "s/" .. item_file_name

        if (love.filesystem.getInfo(filepath)) then
          local tablestring = love.filesystem.read(filepath)
          local itemtable = luatable.decode(tablestring, false)
          if itemtable then
            print ("Read " .. keyword ..": " .. index .. " " .. item_file_name)
            items[index] = itemtable
          else
            print ("Failed to decode file " .. filepath)
          end
        else
          print ("No such file " .. filepath)
        end

      end

    end

  else
    print ("Did not find " .. filename)
    items[1] = default_creator_function()
  end

  if #items == 0 then
    print("No items listed in " .. filename)
    items[1] = default_creator_function()
  end

  return items
end

function listloader.load_room_list()
  return load_list("room", create_room)
end

function listloader.load_world_list()
  return load_list("world", create_world)
end

local function create_room_filename(room, index)
  local name = room.name
  if name == "" then
    name = "room" .. index
  end
  return "" .. name .. ".map"
end

local function create_world_filename(world, index)
  local name = world.name
  if name == "" then
    name = "world" .. index
  end
  return "" .. name .. ".map"
end

local function create_room_path(room, index)
  return "data/rooms/" .. create_room_filename(room, index)
end

local function create_world_path(world, index)
  return "data/worlds/" .. create_world_filename(world, index)
end

local function write_room(data, room_index)
  local filename = create_room_path(data.rooms[room_index], room_index)
  local roomstring = luatable.encode(data.rooms[room_index], "skip")
  local file = love.filesystem.newFile(filename, "w")
  local writeResult, writeMsg = file:write(roomstring)
  if not writeResult then
    print ("Failed to write room file " .. filename .. " Error: " .. writeMsg)
  end
  file:close()
end

local function write_world(data, world_index)
  local filename = create_world_path(data.worlds[world_index], world_index)
  local tablestring = luatable.encode(data.worlds[world_index], "skip")
  local file = love.filesystem.newFile(filename, "w")
  local writeResult, writeMsg = file:write(tablestring)
  if not writeResult then
    print ("Failed to write world file " .. filename .. " Error: " .. writeMsg)
  end
  file:close()
end

function listloader.write_data(data)
  love.filesystem.createDirectory("data/worlds")
  love.filesystem.createDirectory("data/rooms")
  local rooms = {}
  local worlds = {}
  for r = 1, #data.rooms do
    rooms[r] = create_room_filename(data.rooms[r], r)
    write_room(data, r)
  end

  for w = 1, #data.worlds do
    worlds[w] = create_world_filename(data.worlds[w], w)
    write_world(data, w)
  end

  -- roomlist.txt
  local roomfile = "data/roomlist.txt"
  local file = love.filesystem.newFile(roomfile, "w")
  for r = 1, #rooms do
    local writeResult, writeMsg = file:write("" .. r .. " " .. rooms[r] .. "\r\n")
    if not writeResult then
      print ("Failed to write roomlist.txt file " .. roomfile .. " Error: " .. writeMsg)
      break
    end
  end
  file:close()


  -- worldlist.txt
  local worldfile = "data/worldlist.txt"
  file = love.filesystem.newFile(worldfile, "w")
  for r = 1, #worlds do
    writeResult, writeMsg = file:write("" .. r .. " " .. worlds[r] .. "\r\n")
    if not writeResult then
      print ("Failed to write roomlist.txt file " .. worldfile .. " Error: " .. writeMsg)
      break
    end
  end
  file:close()


end

return listloader
