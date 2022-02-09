print('hello. I scene from separated thread')

local inspect = require 'inspect'
require "love"
require "love_inc".require_pls_nographic()
require 'pipeline'

love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/textured_quad/?.lua")

local event_channel = love.thread.getChannel("event_channel")

local last_render: number

local SCENE_PREFIX = 'scenes/textured_quad'
local pipeline = Pipeline.new(SCENE_PREFIX)

-- Как часто перекомпилировать код рисовки?
-- Варианты - 
--  * по таймеру
--  * используя метод :peek() на каждой итерации цикла
-- Сейчас функция компилируется один раз при загрузке файла исходного текста
-- потока.

local function init()

    pipeline:pushCode('text', [[
    while true do
        local w, h = love.graphics.getDimensions()
        local x, y = math.random() * w, math.random() * h
        love.graphics.setColor{0, 0, 0}
        love.graphics.print("TestTest", x, y)

        coroutine.yield()
    end
    ]])

    pipeline:pushCode('circle_under_mouse', [[
    while true do
        local y = graphic_command_channel:demand()
        local x = graphic_command_channel:demand()
        local rad = graphic_command_channel:demand()
        love.graphics.setColor{0, 0, 1}
        love.graphics.circle('fill', x, y, rad)

        coroutine.yield()
    end
    ]])

    -- Допустимо-ли переопределение функций? Или добавить специальный флаг?
    -- Нормально-ли использовать константы?
    pipeline:pushCode('clear', [[
    while true do
        love.graphics.clear{0.5, 0.5, 0.5}

        coroutine.yield()
    end
    ]])

    pipeline:pushCode('textured_quad', [[

    local path = SCENE_PREFIX .. '/tex.png'
    print('path', path)
    local tex = love.graphics.newImage(path)

    local x, y = 100, 100
    local width, height = tex:getDimensions()
    local scale = 1
    print('width, height', width, height)
    local quad = love.graphics.newQuad(0, 0, 100, 100, width, height)

    while true do
        --local angle = love.timer.getTime()
        --local scale = math.sin(love.timer.getTime())
        
        love.graphics.push()

        --love.graphics.translate(x, y)
        --love.graphics.rotate(angle)
        --love.graphics.translate(-width / 2, -height / 2)
        --love.graphics.scale(scale, scale)

        love.graphics.setColor {1, 1, 1, 1}
        love.graphics.draw(tex, quad, 0, 0)

        love.graphics.pop()

        coroutine.yield()
    end
    ]])

    pipeline:pushCode('border', [[
    local yield = coroutine.yield
    local gr = love.graphics
    local newlwidth = 5
    local inspect = require 'inspect'
    --local color = {0.5, 0.5, 0.5, 1}
    local color = {0, 0, 0, 1}

    while true do
        local lwidth = gr.getLineWidth()

        --local x, y, w, h = 0, 0, 100, 100
        local x = graphic_command_channel:demand()
        local y = graphic_command_channel:demand()
        local w = graphic_command_channel:demand()
        local h = graphic_command_channel:demand()

        print('x, y, w, h', 
            inspect(x),
            inspect(y),
            inspect(w),
            inspect(h)
        )

        gr.setColor(color)
        gr.setLineWidth(newlwidth)
        gr.rectangle('line', x, y, w, h)
        gr.setLineWidth(lwidth)
        yield()
    end
    ]])

    last_render = love.timer.getTime()
end

local enum SelectionState
    'pressed'
    'unpressed'
end

local record BorderStart
    x: number
    y: number
end

local record BorderEnd
    w: number
    h: number
end

local state: SelectionState = 'unpressed'
local border_start: BorderStart = {}
local border_end: BorderEnd = {
    w = 0,
    h = 0
}

local function render()
    pipeline:openAndClose('clear')

    pipeline:open('textured_quad')
    pipeline:close()
    --[[
    Сделать "резиновую рамку" для выделения мышью
    --]]

    --local x, y, w, h = 0, 0, 100, 100
    --pipeline:push(x, y, w, h)

    if state == 'pressed' then
        --local x, y, w, h = 400, 400, 128, 128

        pipeline:open('border')
        pipeline:push(
            border_start.x, 
            border_start.y, 
            border_end.w, 
            border_end.h
        )
        pipeline:close()

        print('render border', 
            border_start.x, 
            border_start.y, 
            border_end.w, 
            border_end.h
        )
    end

    pipeline:sync()
end

local function process_border()
    if state == 'pressed' then
        local mx, my = love.mouse.getPosition()
        local abs = math.abs
        print('border_end', border_end.w, border_end.h)
        border_end.w, border_end.h = abs(mx - border_start.x), abs(my -border_start.y)
    elseif state == 'unpressed' then
        state = 'pressed'
        print('border_start', inspect(border_start))
        border_start.x, border_start.y = love.mouse.getPosition()
    end
end

local function mainloop()
    while true do
        --print('mainloop iter')
        local events = event_channel:pop() as {any}
        if events then
            for _, e in ipairs(events) do
                local evtype: string = (e as {string})[1]
                if evtype == "mousemoved" then
                    --local mx = math.floor((e as {number})[2])
                    --local my = math.floor((e as {number})[3])
                elseif evtype == "keypressed" then
                    local key = (e as {string})[2]
                    local scancode = (e as {string})[3]
                    print('keypressed', key, scancode)
                    if scancode == "escape" then
                        love.event.quit()
                    end
                elseif evtype == "mousepressed" then
                    --local x: number = (e as {number})[2]
                    --local y: number = (e as {number})[3]
                    --local button: number = (e as {number})[4]

                    process_border()

                    --local istouch: boolean = (e as {boolean})[5]
                    --local presses: number = (e as {number})[6]
                end
            end
        end
        
        local nt = love.timer.getTime()
        --local pause = 1. / 10.
        local pause = 1. / 300.
        if nt - last_render >= pause then
            last_render = nt
            --local msg = 'love.timer.getTime() = %f'
            --print(colorize('%{blue}' .. format(msg, love.timer.getTime())))

            render()
        end
        --]]

        --render()

        --[[
        Ограничение кадров в секунду до 60
        --]]

        --love.timer.sleep(0.0008)
        love.timer.sleep(0.0001)
    end
end

init()
mainloop()

print('goodbye. I scene from separated thread')
