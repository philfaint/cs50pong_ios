local screenWidth, screenHeight = love.window.getDesktopDimensions()

VIRTUAL_WIDTH = 522
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

push = require 'push'
Class = require 'class'
require 'Paddle'
require 'Ball'

function love.load()
    currentOS = love.system.getOS()

    love.window.setTitle("Pong")

    love.graphics.setDefaultFilter('nearest', 'nearest')

    --set various params with the push library
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, screenWidth, screenHeight,{
        fullscreen = true,
        vsync = true,
        resizable = false
    })

    math.randomseed(os.time())

    fonts = {
        ['smallFont'] = love.graphics.newFont('fonts/font.ttf', 7),
        ['scoreFont'] = love.graphics.newFont('fonts/font.ttf', 30),
        ['textFont'] = love.graphics.newFont('fonts/font.ttf', 8)
    }

    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['point_scored'] = love.audio.newSource('sounds/point_scored.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    -- create instances of players from Paddle class
    -- ios has bigger paddles
    if currentOS == 'iOS' then
        player1 = Paddle(50, 10, 8, 30)
        player2 = Paddle(VIRTUAL_WIDTH - 55, VIRTUAL_HEIGHT - 30, 8, 30)
    else
        player1 = Paddle(50, 10, 5, 20)
        player2 = Paddle(VIRTUAL_WIDTH - 55, VIRTUAL_HEIGHT - 30, 5, 20)
    end

    -- create an instance of a Ball
    ball = Ball(VIRTUAL_WIDTH/2 - 2, VIRTUAL_HEIGHT/2 - 2, 4, 4)

    player1score = 0
    player2score = 0

    servingPlayer = math.random(2)

    winner = 0

    -- table of states in the game
    states = {
        ['start'] = 'start',
        ['serve'] = 'serve',
        ['play'] = 'play',
        ['victory'] = 'victory'
    }

    currentState = states['start']
end

-- resize the window with a push library to fit nicely on different ios screens
function love.resize(w, h)
    push:resize(w, h)
end

-- callback function to switch states when the button is pressed
function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if currentState == states['start'] then
            currentState = states['serve']
        elseif currentState == states['serve'] then
            currentState = states['play']
        elseif currentState == states['victory'] then
            currentState = states['start']

            ball:reset()

            player1score = 0
            player2score = 0

            if winner == 1 then
                servingPlayer = 2
            elseif winner == 2 then
                servingPlayer = 1
            end
        end
    end
end

local touches ={}

function parseID(id)
    return tostring(id)
end

-- same if the screen is touched
function love.touchpressed(id, x, y, dx, dy)
    touches[parseID(id)] = {id, x, y, dx, dy}

    if currentState == states['start'] then
        currentState = states['serve']
    elseif currentState == states['serve'] then
        currentState = states['play']
    elseif currentState == states['victory'] then
        currentState = states['start']

        ball:reset()

        player1score = 0
        player2score = 0

        if winner == 1 then
            servingPlayer = 2
        elseif winner == 2 then
            servingPlayer = 1
        end
    end

end

-- callback function if the finger is moved on touch screen
function love.touchmoved(id, x, y, dx, dy)
    touches[parseID(id)] = {id, x, y, dx, dy}
end
  
-- empty table of touches once the finger is released from the screen
function love.touchreleased(id, x, y, dx, dy)
    touches[parseID(id)] = nil
end


function love.update(dt)
    -- movement for keyboard
        if love.keyboard.isDown('w') then
            player1.dy = -PADDLE_SPEED
        elseif love.keyboard.isDown('s') then
            player1.dy = PADDLE_SPEED
        else 
            player1.dy = 0
        end
 
        if love.keyboard.isDown('up') then
            player2.dy = -PADDLE_SPEED
        elseif love.keyboard.isDown('down') then
            player2.dy = PADDLE_SPEED
        else
            player2.dy = 0
        end
    
    if currentState == 'serve' then
        -- set the initial dy for ball dependong on who erves the ball
        ball.dy = math.random(2) == 1 and math.random(-40, -80) or math.random(40, 80)
        if servingPlayer == 1 then
            ball.dx = math.random(140,200)
        elseif servingPlayer == 2 then 
            ball.dx = -math.random(140, 200)
        end
    elseif currentState == 'play' then
        -- checking collision of ball against bottom and up and reflect it
        if ball.y < 1 then
            ball.y = 1
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        elseif ball.y > VIRTUAL_HEIGHT-2 then
            ball.y = VIRTUAL_HEIGHT-2
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- checking collision against the first player
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + player1.width
            sounds['paddle_hit']:play()

            if ball.dy < 0 then
                ball.dy = math.random(10,150)
            else
                ball.dy = -math.random(10,150)
            end
        end
        -- checking collision against the second player
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - player2.width
            sounds['paddle_hit']:play()

            if ball.dy < 0 then
                ball.dy = math.random(10,150)
            else
                ball.dy = -math.random(10,150)
            end
        end

        -- give a score if ball crossed the line and switch states. 
        -- Victory condition is checked here as well
        if ball.x > VIRTUAL_WIDTH then
            player1score = player1score + 1
            servingPlayer = 2
            sounds['point_scored']:play()

            if player1score == 3 then
                winner = 1
                currentState = 'victory'
            else
                currentState = 'serve'
                ball:reset()
            end
        elseif ball.x < -10 then
            player2score = player2score + 1
            servingPlayer = 1
            sounds['point_scored']:play()

            if player2score == 3 then
                winner = 2
                currentState = 'victory'
            else
                currentState = 'serve'
                ball:reset()
            end

        end
    end
    -- update players' position
    player1:update(dt)
    player2:update(dt)

    -- update the ball if the game is played
    if currentState == 'play' then
        ball:update(dt)
    end                        
end

function love.draw()
    push:apply('start')

    love.graphics.clear(40/255, 50/255, 60/255, 255/255)

    -- get touches table and apply movement + position for players1 and 2
    if currentOS == 'iOS' then
        local x, y, dx, dy

        for _, data in pairs(touches) do
                if data then
                    id, x, y, dx, dy = unpack(data)

                    if x < 100 then
                        player1.y = math.min(y / 1.6, VIRTUAL_HEIGHT - player1.height)
                        player1.dy = dy 
                    elseif x > VIRTUAL_WIDTH - 100 then
                        player2.y = math.min(y / 1.6, VIRTUAL_HEIGHT - player2.height)
                        player2.dy = dy
                    end
                end
            
        end
    end

    player1:draw()
    player2:draw()
    ball:draw()

    drawScore()
    renderTexts()
    displayFPS()

    push:apply("end")
end

-- display any debug info we need here
function displayFPS()
    love.graphics.setColor(0, 255/255, 0, 255/255)
    love.graphics.setFont(fonts['smallFont'])
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), VIRTUAL_WIDTH - 60, 0)
    love.graphics.setColor(1,1,1,1)
end

-- draw score
function drawScore()
    love.graphics.setFont(fonts['scoreFont'])
    love.graphics.print(player1score, VIRTUAL_WIDTH/ 2 - 50, 30)
    love.graphics.print(player2score, VIRTUAL_WIDTH/2 + 40, 30)
end

-- draw texts
function renderTexts()
    love.graphics.setFont(fonts['textFont'])
    if currentState == 'start' then
        love.graphics.printf('Welcome to Pong!',0,10,VIRTUAL_WIDTH,'center')
        love.graphics.printf('Press Enter to Continue!',0,20,VIRTUAL_WIDTH,'center')
    elseif currentState == 'serve' then
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. ' serves!',0,10,VIRTUAL_WIDTH,'center')
        love.graphics.printf('Press Enter to start',0,20,VIRTUAL_WIDTH,'center')
    elseif currentState == 'victory' then
        love.graphics.printf('Player ' .. tostring(winner) .. ' won!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to re-start',0,20,VIRTUAL_WIDTH,'center')
    end
end