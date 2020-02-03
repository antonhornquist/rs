-- shared logic for paged user interface
-- this file pollutes the global namespace

HI_LEVEL = 15
LO_LEVEL = 4
FPS = 35

fine = false
prev_held = false
next_held = false

local Common = {}

local update_ui

function Common.start_ui()
  local update_ui_metro = metro.init()
  update_ui_metro.event = update_ui
  update_ui_metro.time = 1/FPS
  update_ui_metro:start()
end

function update_ui()
  if target_page then
    current_page = current_page + page_trans_div
    page_trans_frames = page_trans_frames - 1
    if page_trans_frames == 0 then
      current_page = target_page
      target_page = nil
    end
    UI.set_dirty()
  end
  UI.refresh()
end

function Common.redraw()
  local enc1_x = 0
  local enc1_y = 12

  local enc2_x = 10
  local enc2_y = 29 -- 31 -- 33

  local enc3_x = enc2_x+65
  local enc3_y = enc2_y

  local page_indicator_y = enc2_y + 16 + 3

  local key2_x = 0
  local key2_y = 63

  local key3_x = key2_x+65
  local key3_y = key2_y

  local function redraw_enc1_widget()
    screen.move(enc1_x, enc1_y)

    screen.level(LO_LEVEL)
    screen.text("LEVEL")
    screen.move(enc1_x+45, enc1_y)
    screen.level(HI_LEVEL)
    screen.text(util.round(mix:get_raw("output")*100, 1))
  end

  local function redraw_event_flash_widget()
    screen.level(LO_LEVEL)
    screen.rect(122, enc1_y-7, 5, 5)
    screen.fill()
  end

  local function bullet(x, y, level)
    screen.level(level)
    screen.rect(x, y, 2, 2)
    screen.fill()
  end

  local function translate_visual(value, indicator_width)
    return util.round(indicator_width * value)
  end

  local function draw_value(ind_x, ind_y, ind_x_delta, level)
    local x = ind_x + ind_x_delta
    bullet(x, ind_y, level)
  end

  local function strokedraw_value(ind_x, ind_y, min_value, max_value, level, width)
    local min_ind_x_delta = translate_visual(min_value, width-2)
    local max_ind_x_delta = translate_visual(max_value, width-2)
    for ind_x_delta=min_ind_x_delta, max_ind_x_delta do
      draw_value(ind_x, ind_y, ind_x_delta, level)
    end
  end

  local function draw_visual_values(ind_x, ind_y, width, ui_param)
    local visual_values = ui_param.visual_values

    if visual_values then
      local max_level = 2 -- LO_LEVEL
      local num_visual_values = #visual_values.content
      if num_visual_values > 1 then
        local prev_visual_value = visual_values.content[1]
        for idx=2, num_visual_values do
          local visual_value = visual_values.content[idx]

          local min_visual_value = math.min(prev_visual_value, visual_value)
          local max_visual_value = math.max(prev_visual_value, visual_value)

          local level = util.round(max_level/num_visual_values*idx)

          strokedraw_value(ind_x, ind_y, min_visual_value, max_visual_value, level, width)

          prev_visual_value = visual_value
        end
      end
      --[[
      if num_visual_values == 2 then
        local prev_visual_value = translate_visual(visual_values.content[1], width-2)
        local current_visual_value = translate_visual(visual_values.content[2], width-2)
        local min_visual_value = math.min(prev_visual_value, current_visual_value)
        local max_visual_value = math.max(prev_visual_value, current_visual_value)
        strokedraw_value(ind_x, ind_y, min_visual_value, max_visual_value, max_level, width)
      end
      ]]
    end
  end

  local function draw_ui_param(page, param_index, x, y)
    local ui_param = page_params[page][param_index]
    screen.move(x, y)
    screen.level(LO_LEVEL)
    screen.text(ui_param.label)
    screen.move(x, y+12)
    screen.level(HI_LEVEL)
    screen.text(ui_param.format(ui_param.id))

    local ind_x = x + 1
    local ind_y = y + 14

    -- TODO, see below local ind_width = ui_param.ind_width
    local label_width = _norns.screen_extents(ui_param.label) - 2 -- TODO, cache this in ind_width or similar instead

    draw_visual_values(ind_x, ind_y, label_width, ui_param)

    local ind_ref = ui_param.ind_ref

    if ind_ref then
      draw_value(ind_x, ind_y, translate_visual(ind_ref, label_width), HI_LEVEL)
    end
  end

  local function redraw_enc2_widget()
    local left = math.floor(current_page)
    local right = math.ceil(current_page)
    local offset = current_page - left
    local pixel_ofs = util.round(offset*128)

    draw_ui_param(left, 1, enc2_x-pixel_ofs, enc2_y)

    if left ~= right then
      draw_ui_param(right, 1, enc2_x+128-pixel_ofs, enc2_y)
    end

  end

  local function redraw_enc3_widget()
    local left = math.floor(current_page)
    local right = math.ceil(current_page)
    local offset = current_page - left
    local pixel_ofs = util.round(offset*128)

    draw_ui_param(left, 2, enc3_x-pixel_ofs, enc3_y)

    if left ~= right then
      draw_ui_param(right, 2, enc3_x+128-pixel_ofs, enc3_y)
    end
  end
    
  local function redraw_page_indicator()
    local div = 128/num_pages()

    screen.level(LO_LEVEL)

    screen.rect(util.round((current_page-1)*div), page_indicator_y, util.round(div), 2)
    screen.fill()
  end

  local function redraw_key2key3_widget()
    --screen.move(126, key2_y)
    screen.move(key2_x+42, key2_y)
    screen.level(HI_LEVEL)
    screen.text("FN")
  end

  local function redraw_key2_widget()
    screen.move(key2_x, key2_y)
    if prev_held and not fine then
      screen.level(HI_LEVEL)
    else
      screen.level(LO_LEVEL)
    end
    screen.text("PREV")
  end

  local function redraw_key3_widget()
    screen.move(key3_x, key3_y)
    if next_held and not fine then
      screen.level(HI_LEVEL)
    else
      screen.level(LO_LEVEL)
    end
    screen.text("NEXT")
  end

  screen.font_size(16)
  screen.clear()

  redraw_enc1_widget()

  if UI.show_event_indicator then
    redraw_event_flash_widget()
  end

  redraw_enc2_widget()
  redraw_enc3_widget()

  redraw_page_indicator()

  if fine then
    redraw_key2key3_widget()
  end

  redraw_key2_widget()
  redraw_key3_widget()

  screen.update()
end

function Common.enc(n, delta)
  local d
  if fine then
    d = delta/5
  else
    d = delta
  end
  if n == 1 then
    mix:delta("output", d)
    UI.screen_dirty = true
  else
    params:delta(get_param_id_for_current_page(n-1), d)
  end
end

function Common.key(n, z)
  local page

  if target_page then
    page = target_page
  else
    page = get_page()
  end

  if n == 2 then
    if z == 1 then
      page = page - 1
      if page < 1 then
        page = num_pages()
      end

      transition_to_page(page)

      prev_held = true
    else
      prev_held = false
    end
    UI.set_dirty()
  elseif n == 3 then
    if z == 1 then
      page = page + 1
      if page > num_pages() then
        page = 1
      end

      transition_to_page(page)

      next_held = true
    else
      next_held = false
    end
    UI.set_dirty()
  end

  fine = prev_held and next_held
end

function Common.arc_delta(n, delta)
  local d
  if fine then
    d = delta/5
  else
    d = delta
  end
  local id = get_param_id_for_current_page(n)
  local val = params:get_raw(id)
  params:set_raw(id, val+d/500)
end

function Common.draw_arc(my_arc, value1, visual_values1, value2, visual_values2)
  local range = 44

  local function translate(n)
    n = util.round(n*range)
    return n
  end

  local function ring_map(n)
    if n < range/2 then
      n = 64-range/2+n
    else
      n = n-range/2
    end
    return n
  end

  local function ring_map_stroke(ring, start_n, end_n, level)
    for n=start_n, end_n do
      my_arc:led(ring, ring_map(n), level)
    end
  end

  local function draw_visual_values(ring, visual_values)
    if visual_values then
      local max_level = 2
      local num_visual_values = #visual_values.content
      if num_visual_values > 1 then
        local prev_led_n = translate(visual_values.content[1])
        for idx=2, num_visual_values do
          local led_n = translate(visual_values.content[idx])
          local min_n = math.min(prev_led_n, led_n)
          local max_n = math.max(prev_led_n, led_n)

          local level = util.round(max_level/num_visual_values*idx)

          ring_map_stroke(ring, min_n, max_n, level)

          prev_led_n = led_n
        end
      end
      --[[
      TODO
      if num_visual_values == 2 then
        print(ring, translate(visual_values.content[1]), translate(visual_values.content[2]), max_level)
        ring_map_stroke(ring, translate(visual_values.content[1]), translate(visual_values.content[2]), max_level)
      end
      ]]
    end
  end

  local function draw_arc_ring_leds(ring, value, visual_values)
    for n=range/2, 64-range/2 do
      my_arc:led(ring, n, 1)
    end

    draw_visual_values(ring, visual_values)

    local led_n = ring_map(translate(value))

    my_arc:led(ring, led_n, 15)
  end

  my_arc:all(0)
  draw_arc_ring_leds(1, value1, visual_values1)
  draw_arc_ring_leds(2, value2, visual_values2)
end

function set_page(page)
  current_page = page
end

function get_page()
  return util.round(current_page)
end

Common.get_page = get_page

function get_param_id_for_current_page(n)
  local page = get_page()
  return page_params[page][n].id
end

function num_pages()
  return #page_params
end

function transition_to_page(page)
  target_page = page
  page_trans_frames = FPS/5
  page_trans_div = (target_page - current_page) / page_trans_frames
end

function Common.new_capped_list(capacity)
  return {
    capacity=capacity,
    content={}
  }
end

function Common.push_to_capped_list(list, value)
  if #list.content > list.capacity then
    table.remove(list.content, 1)
  end
  table.insert(list.content, value)
end

-- shared logic for loading / saving settings
-- this file pollutes the global namespace

function Common.load_settings()
  local fd=io.open(norns.state.data .. SETTINGS_FILE,"r")
  local page
  if fd then
    io.input(fd)
    local str = io.read()
    io.close(fd)
    if str ~= "" then
      page = tonumber(str)
    end
  end
  set_page(page or 1)
end

function Common.save_settings()
  local fd=io.open(norns.state.data .. SETTINGS_FILE,"w+")
  io.output(fd)
  io.write(get_page() .. "\n")
  io.close(fd)
end

return Common
