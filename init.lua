local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; print('hello. I scene from separated thread')


require("love")
require("love_inc").require_pls_nographic()
require('pipeline')



love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/colored_text_transform_mt/?.lua")
local i18n = require("i18n")
















local event_channel = love.thread.getChannel("event_channel")




local mx, my = 0, 0

local last_render

local pipeline = Pipeline.new()








local function init()
   i18n.set('en.welcome', 'welcome to this program')
   i18n.load({
      en = {
         good_bye = "good-bye!",
         age_msg = "your age is %{age}.",
         phone_msg = {
            one = "you have one new message.",
            other = "you have %{count} new messages.",
         },
      },
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



   local x, y = love.mouse.getPosition()

   local rad = 50





   pipeline:openAndClose('transformed_text')

   pipeline:sync()
end

local function mainloop()
   while true do

      local events = event_channel:pop()
      if events then
         for _, e in ipairs(events) do
            local evtype = (e)[1]
            if evtype == "mousemoved" then
               mx = math.floor((e)[2])
               my = math.floor((e)[3])
            elseif evtype == "keypressed" then
               local key = (e)[2]
               local scancode = (e)[3]
               print('keypressed', key, scancode)
               if scancode == "escape" then
                  love.event.quit()
               end
            elseif evtype == "mousepressed" then





            end
         end
      end

      local nt = love.timer.getTime()

      local pause = 1. / 300.
      if nt - last_render >= pause then
         last_render = nt



         render()
      end









      love.timer.sleep(0.0001)
   end
end

init()
mainloop()

print('goodbye. I scene from separated thread')
