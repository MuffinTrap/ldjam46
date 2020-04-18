
GameStart = 1
GameEnd = 2

local titlescreen = {

  start_image = nil,
  end_image = nil,
  active_image = nil,
  active_state = 0,

}

function titlescreen.init(state)
  titlescreen.active_state = state

  if not start_image then
    titlescreen.start_image = love.graphics.newImage("data/images/start_screen.png")
  end
  if not end_image then
    titlescreen.end_image = love.graphics.newImage("data/images/end_screen.png")
  end

  if state == GameStart then
    titlescreen.active_image = titlescreen.start_image
  end
  if state == GameEnd then
    titlescreen.active_image = titlescreen.end_image
  end
end

function titlescreen.draw(data)
  love.graphics.draw(titlescreen.active_image, 0, 0)

  local credits = {"Made by:", "Muffintrap"}
  local scale = 0.5
  if titlescreen.active_state == GameEnd then
    local x = 6 * 8
    local y = 8
    for i, name in ipairs(credits) do
      love.graphics.print(name, x, y, 0, scale, scale)
      y = y + game_font_height * scale
    end
  end
end

function titlescreen.update(data, input)
  if buttonA_pressed(input) then
    return false
  end
  return true
end

function titlescreen.deinit(data)
  if titlescreen.active_state == GameEnd then
    love.event.quit()
  elseif titlescreen.active_state == GameStart then
    print("Title start deinit")
    local basicstate = walkstate
    basicstate.init(15 * 8, 10 * 8)
    push_state(data, basicstate)
  end
end

return titlescreen
