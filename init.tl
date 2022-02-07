print('hello. I scene from separated thread')

--local tl = require "tl"
require "love"
require "love_inc".require_pls_nographic()
require 'pipeline'

--require "love.timer"

love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/colored_text_transform_mt/?.lua")
local i18n = require "i18n"
--local colorize = require 'ansicolors2'.ansicolors
--local format = string.format

--require "external"
--require "common"

--package.path = package.path .. ";scenes/automato/?.lua"

--local cam = require "camera".new()
--local gr = love.graphics
--local imgui = require "imgui"
--local inspect = require "inspect"
--local keyconfig = require "keyconfig"
--local next = next
--local timer = require "Timer"

local event_channel = love.thread.getChannel("event_channel")
--local draw_ready_channel = love.thread.getChannel("draw_ready_channel")
--local graphic_command_channel = love.thread.getChannel("graphic_command_channel")
--local graphic_code_channel = love.thread.getChannel("graphic_code_channel")

local mx, my = 0, 0

local last_render: number

local pipeline = Pipeline.new()

-- Как часто перекомпилировать код рисовки?
-- Варианты - 
--  * по таймеру
--  * используя метод :peek() на каждой итерации цикла
-- Сейчас функция компилируется один раз при загрузке файла исходного текста
-- потока.

local function init()
    i18n.set('en.welcome', 'welcome to this program')
    i18n.load({
        en = {
            good_bye = "good-bye!",
            age_msg = "your age is %{age}.",
            phone_msg = {
                one = "you have one new message.",
                other = "you have %{count} new messages."
            }
        }
    })
    print("translated", i18n.translate('welcome'))
    print("translated", i18n('welcome'))

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

    pipeline:pushCode('transformed_text', [[

    --pcall(function()
        --local makeDescentColorText = require 'colored_text'.makeDescentColorText
    --end)

    local makeDescentColorText = require 'colored_text'.makeDescentColorText

    --local font = love.graphics.newFont(96)
    local font = love.graphics.newFont(300)
    local tobject = love.graphics.newText(font)

    local x, y = 0, 0
    makeDescentColorText(
        tobject, 
        'hippopotamus',
        {1, 0, 0, 1}, 
        {0.5, 0.7, 0, 1}, 
        x, y)

    --coroutine.yield()
    --makeDescentColorText(tobject, "hippopotamus", {1, 1, 1, 1}, {0.5, 0, 0, 1})

    local x, y = 256, 256
    local width, height = 256, 256

    while true do
        local angle = love.timer.getTime()
        local scale = math.sin(love.timer.getTime())
        
        love.graphics.push()

        love.graphics.translate(x, y)
        love.graphics.rotate(angle)
        love.graphics.translate(-width / 2, -height / 2)

        love.graphics.scale(scale, scale)

        love.graphics.setFont(font)
        love.graphics.setColor {1, 1, 1, 1}
        love.graphics.draw(tobject)

        love.graphics.pop()

        coroutine.yield()
    end
    ]])

    last_render = love.timer.getTime()
end

local function render()
    pipeline:openAndClose('clear')

    --pipeline:openAndClose('text')

    local x, y = love.mouse.getPosition()
    --print('mouse x, y', x, y)
    local rad = 50

    --pipeline:open('circle_under_mouse')
    --pipeline:push(y, x, rad)
    --pipeline:close()

    pipeline:openAndClose('transformed_text')

    pipeline:sync()
end

local function mainloop()
    while true do
        --print('mainloop iter')
        local events = event_channel:pop() as {any}
        if events then
            for _, e in ipairs(events) do
                local evtype: string = (e as {string})[1]
                if evtype == "mousemoved" then
                    mx = math.floor((e as {number})[2])
                    my = math.floor((e as {number})[3])
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
