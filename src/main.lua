
local listloader = require "listloader"
local editor = require "neseditor"
drawing = require "nesdraw"
walkstate = require "walkstate"
title = require "titlescreen"

g_debug = true
g_music_on = false
g_fullscreen_on = false
g_editor_on = true


local GameState = 0
local EditorState = 1
local state = GameState

local editor_font = nil
local font_height = 16
game_font_height = 32
local game_font = nil

-- All Images
-- All Rooms

local data = {
  worlds = {},
  rooms = {},
  images = {},
  sprites = {},

  active_world = 1,
  active_room = 1,

  state_index = 0,
  state_target = 1,
  state_stack = {},

  player_sprite = 1,

  get_player_sprite = nil,
}

function get_player_sprite(data)
  return data.sprites[data.player_sprite]
end

function push_state(data, state)
  data.state_index = data.state_index + 1
  data.state_stack[data.state_index] = state
end

function pop_state(data)
  data.state_stack[data.state_index] = nil
  data.state_index = data.state_index - 1
end

local input = {
  up = false,
  down = false,
  left = false,
  right = false,
  buttonA = false,
  buttonB = false,
  joystick = nil,
  mouse_relative = {0,0},
}

function direction_down(input)
  return input.up or input.down or input.left or input.right
end

function buttonA_pressed(input)
  if input.buttonA then
    input.buttonA = false
    return true
  end
  return false
end

-- Global constants
ROOM_SIZE = { w = 32, h = 30}
WORLD_SIZE = { w = 10, h = 10}
TILE_SIZE = 8

function get_world_pixel_size(scale)
  return {w = ROOM_SIZE.w * TILE_SIZE * WORLD_SIZE.w * scale, h = ROOM_SIZE.h * TILE_SIZE * WORLD_SIZE.h * scale}
end

function get_room_pixel_size(scale)
  return {w = ROOM_SIZE.w * TILE_SIZE * scale, h = ROOM_SIZE.h * TILE_SIZE * scale}
end

function get_world_tile_size(scale)
  local tileSize = { w = ROOM_SIZE.w * TILE_SIZE * scale, h = ROOM_SIZE.h * TILE_SIZE * scale}
  return tileSize
end

function create_room()
  local room = {
    name = "",
    bg = {},
    fg = {},
    triggers = {},
  }
  return room
end

function create_world()
  local world = {
    name = "",
    rooms = {},
  }
  return world
end

function create_grid_item(item_index, tile_x, tile_y)
  return {index = item_index, x = tile_x, y = tile_y}
end

function love.load()
  love.window.setTitle("LudumDare46-LodeClone");
  love.mouse.setVisible(true)

  -- Love can only write to User directory and not to the
  -- source/working directory folder.
  -- Need to copy the files from User directory when building the release
  -- Reading will look first from the User directory and then from source

  -- This sets the name of the folder in the user directory
  -- Windows 10: C:\Users\user\AppData\Roaming\LOVE
  -- Linux ~/.local/share/love
  love.filesystem.setIdentity("ludum46")

  -- Do not soften the pixels
  love.graphics.setDefaultFilter("nearest", "nearest", 0)
  love.graphics.setLineStyle("rough")

  -- NES resolution

  -- These are globals
  nes_width = 256
  nes_height = 240

  window_height = 0
  window_width = 0


  -- fullscreen
  local deskWidth, deskHeight = love.window.getDesktopDimensions()
  if g_fullscreen_on then
    love.window.setMode(deskWidth, deskHeight,
                      {fullscreen=true, fullscreen="desktop", vsync=true})
    window_width = deskWidth
    window_height = deskHeight

    else
      if g_editor_on then
        love.window.setMode(1280, 720,
                            {fullscreen=false, fullscreentype="desktop", vsync=true})
        window_width = 1280
        window_height = 720
      else
        local nes_scale = 4
        love.window.setMode(nes_width * nes_scale, nes_height * nes_scale,
                            {fullscreen=false, fullscreentype="desktop", vsync=true})
        window_width = nes_width * nes_scale
        window_height = nes_height * nes_scale

      end
  end

  -- when editor is not needed

  -- Draw game to canvas and then
  -- draw the canvas scaled to the screen


  game_canvas = love.graphics.newCanvas(nes_width, nes_height)
  game_canvas:setFilter("nearest", "nearest", 0)
  game_aspect = nes_width / nes_height

  -- Gui Scale is based on 1980x1080
  gui_scale = window_height / 1080

  game_max_scale = math.floor(window_height / nes_height)
  game_x = (window_width - nes_width * game_max_scale) / 2
  game_y = (window_height - nes_height * game_max_scale) / 2
  game_left_x = 0
  game_right_x = window_width - game_x;
  game_time = 0

  editor_x = 100 * gui_scale
  editor_y = 180 * gui_scale

  editor_scale = 2 * gui_scale
  font_scale = gui_scale


  listloader.load_data(data)


  -- Load font
  game_font = love.graphics.newFont("data/Seraphimb1.ttf", game_font_height)
  -- game_font:setFilter("nearest", "nearest", 0)

  editor_font = love.graphics.newFont("data/Born2bSportyV2.ttf", font_height)
  editor_font:setFilter("nearest", "nearest", 0)

  love.graphics.setFont(game_font)

  -- Music
  if g_music_on then
    game_music = love.audio.newSource("data/music/TastyCamping_MainMusicV2.ogg", "stream")
    game_music:setLooping(true)
    love.audio.play(game_music)
  end

  -- Joystick
  local joysticks = love.joystick.getJoysticks()
  for i, joystick in ipairs(joysticks) do
    print(joystick:getName())
    if joystick:isGamepad() then
      print("Joystick is gamepad")
    end
  end
  -- Building the state stack
  local titlestart = title
  titlestart.init(GameStart)
  push_state(data, titlestart)
end


function love.update(dt)
  game_time = game_time + dt

  if (state == EditorState) then
    editor.update(data)
  else
    local continue = data.state_stack[data.state_index].update(data, input)
    if not continue then
      data.state_stack[data.state_index].deinit(data)
    end
  end


end

function love.gamepadpressed(joystick, key)
-- Input
if key == "dpup" then
  input.up = true
end
if key == "dpdown" then
  input.down = true
end
if key == "dpleft" then
  input.left = true
end
if key == "dpright" then
  input.right = true
end
end


function love.gamepadreleased(joystick, button)
  if button == "a" or button ==  "b" or button ==  "x" or button ==  "y" then
    input.buttonA = true
  else
    input.buttonB = true
  end

  -- Input
  if button == "dpup" then
    input.up = false
  end
  if button == "dpdown" then
    input.down = false
  end
  if button == "dpleft" then
    input.left = false
  end
  if button == "dpright" then
    input.right = false
  end
end


function love.draw()
  love.graphics.clear(0.1, 0.1, 0.1)

  if state == GameState then
    draw_game()
  elseif state == EditorState then
    editor.draw(data, font_height, 16)
  end
end

function draw_game()
  love.graphics.setColor(1,1,1)

  love.graphics.setCanvas(game_canvas)
  love.graphics.clear(0, 0, 0)

  drawing.draw_room(data, data.active_room, 0, 0, 1)

  -- Draw player
  local sprite = get_player_sprite(data)
  if sprite then
    local scale = 1
    if data.state_stack[data.state_index].get_player_pos then
      local player_pos = data.state_stack[data.state_index].get_player_pos()
      drawing.draw_sprite(sprite, player_pos.x, player_pos.y, scale)
    end
  end

  assert(data.state_stack[data.state_index], "Nil at stack")
  data.state_stack[data.state_index].draw(data)

  -- Game bg color
  -- Draw canvas to screen scaled
  love.graphics.setCanvas()
  love.graphics.draw(game_canvas, game_x, game_y, 0, game_max_scale, game_max_scale)

end



function normalize(vector)
  x = vector[1]
  y = vector[2]
  dx = x - ox
  dy = y - oy
  length = math.sqrt(dx * dx + dy * dy)
  ux = dx / length
  uy = dy / length

  return {ux, uy}
end

function love.keypressed( key, scancode, isrepeat )
	if (key == "escape" ) then
		love.event.quit()
	end
  if (state == EditorState) then
    editor.keypressed(key)
  end

  -- Input
  if key == "up" then
    input.up = true
  end
  if key == "down" then
    input.down = true
  end
  if key == "left" then
    input.left = true
  end
  if key == "right" then
    input.right = true
  end

end


function love.keyreleased( key, scancode)
  if (key == "f1") then
    state = GameState
    love.graphics.setFont(game_font)
  elseif key == "f2" then
    state = EditorState
    love.graphics.setFont(editor_font)
  end

  if (state == EditorState) then
    editor.keyreleased(key)
  end

  if key == "up" then
    input.up = false
  end
  if key == "down" then
    input.down = false
  end
  if key == "left" then
    input.left = false
  end
  if key == "right" then
    input.right = false
  end

  if key == "return" then
    input.buttonA = true
  else
    input.buttonB = true
  end
end

function love.joystickadded(joystick)
  input.joystick = joystick
end

function love.textinput(text)
  if (state == EditorState) then
    editor.textinput(text)
  end
end

function love.mousepressed(x, y, button, istouch, presses)
  if (state == EditorState) then
    editor.mousepressed(x, y, button)
  end

end

function love.mousereleased(x, y, button, istouch, presses)
  if (state == EditorState) then
    editor.mousereleased(x, y, button)
  end

end

function love.wheelmoved(x, y)
  if (state == EditorState) then
    editor.mousewheelmoved(x, y)
  end
end

function love.quit()
  if g_music_on then
    game_music:stop()
  end
end
