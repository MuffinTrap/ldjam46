
--[[ Keeping track of gold collected in rooms ]]--

local movement = require "player_movement"

local goldstatus = {
      collected = 0,
      remaining = 0,
}

function goldstatus.record_room(data, room_index)

end

function goldstatus.collect(sprite)
  if sprite ~= nil and sprite.index == goldId then
    sprite.index = goldEmptyId
    goldstatus.collected = goldstatus.collected + 1
    goldstatus.remaining = goldstatus.remaining - 1
  end
end

function goldstatus.is_ready()
  return (goldstatus.remaining == 0)
end

return goldstatus
