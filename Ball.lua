Ball = Class{}

function Ball:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    self.dx = 0
    self.dy = 0
end

function Ball:collides(player)
    if self.x > player.x + player.width or player.x > self.x + self.width then
        return false
    elseif self.y > player.y + player.height or player.y > self.y + self.height then
        return false
    else
        return true
    end
end

function Ball:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end

function Ball:reset()
    self.x = VIRTUAL_WIDTH/2 -2
    self.y = VIRTUAL_HEIGHT/2 - 2

    self.dx = math.random(2) == 1 and 100 or -100
    self.dy = math.random(2) == 1 and math.random(-80, -100) or math.random(80, 100)
end

function Ball:draw()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end