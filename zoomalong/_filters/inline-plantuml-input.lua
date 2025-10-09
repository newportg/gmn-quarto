-- inline-plantuml-input.lua
-- Inline external PlantUML files into plantuml code blocks.
-- Behavior:
--  - If a code block has a `filename` attribute and the block is empty, load that file and replace the block text.
--  - Expand `!include <path>` lines by inlining the referenced file content (recursively up to a depth limit).

local max_depth = 8

-- Emit a short startup message so we can confirm the filter file was loaded.
-- Emit a short startup message so we can confirm the filter file was loaded. Avoid calling project_root here
-- because project_root itself uses io.popen; defer that until inside CodeBlock where needed.
-- Small helper to write debug messages only when INLINE_PLANTUML_DEBUG is set.
local function dbg(msg)
  if (os.getenv('INLINE_PLANTUML_DEBUG') or '') == '' then return end
  pcall(function()
    if io.stdout and io.stdout.write then io.stdout:write(tostring(msg) .. '\n') end
  end)
end

-- Announce load only in debug mode
dbg('INLINE-PLANTUML-LOADED')
dbg('INLINE-PLANTUML-DEBUG=' .. tostring(os.getenv('INLINE_PLANTUML_DEBUG')))

local function is_absolute(p)
  if not p then return false end
  -- On Windows, a path is absolute if it starts with a drive letter (C:\) or a file:// URL.
  -- Leading-slash paths like '/images/...' should be treated as project-relative, not filesystem absolute.
  if p:match('^%a:[/\\]') or p:match('^file://') then
    return true
  end
  return false
end

local function normalize_path(p)
  if not p then return p end
  return p:gsub('\\', '/')
end

local function read_file(path)
  local fh, err = io.open(path, 'rb')
  if not fh then return nil, err end
  local content = fh:read('*a')
  fh:close()
  return content
end

local function try_paths(base_paths, rel)
  rel = normalize_path(rel)
  for _, base in ipairs(base_paths) do
    local candidate = base
    if not candidate:match('/$') then candidate = candidate .. '/' end
    candidate = normalize_path(candidate .. rel)
    -- Debug: announce candidate path when debug is enabled
    dbg('INLINE-PLANTUML-TRY: ' .. tostring(candidate))
    local content = read_file(candidate)
    if content then return content, candidate end
  end
  return nil
end

local function resolve_include_path(inc)
  if not inc then return nil end
  -- Treat leading slash as project-relative (e.g. /images/...) instead of filesystem absolute
  if inc:match('^/') then
    inc = inc:gsub('^/', '')
  end

  if is_absolute(inc) then
    local p = inc
    p = p:gsub('^file:///', '')
    p = p:gsub('^file://', '')
    p = normalize_path(p)
    local c = read_file(p)
    if c then return c, p end
    return nil
  end

  local candidates = {}
  local proj = os.getenv('QUARTO_PROJECT_DIR')
  if proj and proj ~= '' then table.insert(candidates, proj) end
  -- fallback to cwd
  local ok, cwd = pcall(function()
    local f = io.popen('cd')
    if not f then return '.' end
    local r = f:read('*l')
    f:close()
    return r or '.'
  end)
  if ok and cwd and cwd ~= '' then table.insert(candidates, cwd) end
  table.insert(candidates, '.')

  return try_paths(candidates, inc)
end

local function inline_includes(text, depth, seen)
  depth = depth or 0
  if depth > max_depth then return text end
  seen = seen or {}
  local out = {}
  for line in text:gmatch('([^\n]*)\n?') do
    local inc = line:match('^%s*!include%s+(.+)$')
    if inc then
      inc = inc:gsub('^%s*"', ''):gsub('"%s*$', ''):gsub("^%s*'", ''):gsub("'%s*$", '')
      if seen[inc] then
        table.insert(out, '-- !include cycle detected: ' .. inc)
      else
        seen[inc] = true
        local content, path = resolve_include_path(inc)
        if content then
          content = inline_includes(content, depth + 1, seen)
          table.insert(out, content)
        else
          table.insert(out, '-- !include not found: ' .. inc)
        end
      end
    else
      table.insert(out, line)
    end
  end
  return table.concat(out, '\n')
end

-- Helper: sanitize a filename to safe characters
local function sanitize_name(n)
  n = n or 'inline'
  n = tostring(n)
  n = n:gsub('^%s+', ''):gsub('%s+$', '')
  n = n:gsub('[^%w._-]', '_')
  return n
end

local function strip_directive_lines(s)
  if not s then return s end
  local out = {}
  for line in s:gmatch('([^\n]*)\n?') do
    local is_directive = false
    if line:match('^%s*%%+%s*|?%s*filename%s*:') then is_directive = true end
    if line:match('^%s*filename%s*:') then is_directive = true end
    if not is_directive then table.insert(out, line) end
  end
  return table.concat(out, '\n')
end

-- Ensure that the content contains @startuml/@enduml. If missing, wrap it.
local function ensure_uml_bounds(s)
  if not s then return s end
  local has_start = s:match('@startuml')
  local has_end = s:match('@enduml')
  if has_start and has_end then return s end
  -- Trim leading/trailing whitespace
  s = s:gsub('^%s+', ''):gsub('%s+$', '')
  return '@startuml\n' .. s .. '\n@enduml'
end

local function project_root()
  local proj = os.getenv('QUARTO_PROJECT_DIR')
  if proj and proj ~= '' then return proj end
  local ok, cwd = pcall(function()
    local f = io.popen('cd')
    if not f then return '.' end
    local r = f:read('*l')
    f:close()
    return r or '.'
  end)
  if ok and cwd and cwd ~= '' then return cwd end
  return '.'
end

function CodeBlock (cb)
  if not cb.classes then return nil end
  if cb.classes[1] ~= 'plantuml' then return nil end

  local filename = cb.attributes['filename'] or cb.attributes['file']
  -- If the block text contains a single-line filename directive (e.g. "%%| filename: /path/file.puml"),
  -- and the block is otherwise empty of plantuml source, treat it as an input filename.
  if (not filename) and cb.text then
    local fm = cb.text:match('%s*%%+%s*|?%s*filename%s*:%s*(.+)') or cb.text:match('filename%s*:%s*(.+)')
    if fm and not cb.text:match('@startuml') then
      -- Strip surrounding quotes and whitespace
      fm = fm:gsub('^%s*"', ''):gsub('"%s*$', ''):gsub("^%s*'", ''):gsub("'%s*$", ''):gsub('%s*$', ''):gsub('^%s*', '')
      -- If the directive contains a Markdown link like [path](url), prefer the link text
      local link_text = fm:match('%[([^%]]+)%]')
      if link_text and link_text ~= '' then fm = link_text end
      -- If it's wrapped in parentheses or angle brackets, trim them
      fm = fm:gsub('^%(', ''):gsub('%)$', ''):gsub('^<', ''):gsub('>$', '')
      -- Final trim
      fm = fm:gsub('^%s+', ''):gsub('%s+$', '')
      filename = fm
    end
  end

  local is_directive_only = false
  if cb.text then
    if cb.text:match('^%s*$') then
      is_directive_only = true
    elseif cb.text:match('^%s*filename%s*:') then
      is_directive_only = true
    elseif cb.text:match('^%s*%%+%s*|?%s*filename%s*:') then
      is_directive_only = true
    end
  end

  if filename and (not cb.text or is_directive_only) then
    filename = filename:gsub('^"', ''):gsub('"$', ''):gsub("^'", ''):gsub("'$", '')
    local content, path
    dbg('INLINE-PLANTUML-WILL-RESOLVE: ' .. tostring(filename))
    if is_absolute(filename) then
      local f = filename:gsub('^file:///', ''):gsub('^file://', '')
      content, path = read_file(normalize_path(f)), normalize_path(f)
    else
      content, path = resolve_include_path(filename)
    end
    if content then
      dbg('INLINE-PLANTUML-RESOLVED: ' .. tostring(path or filename))
      content = inline_includes(content, 0, {})
      content = strip_directive_lines(content)

      -- Write dump to deterministic project-root .quarto with timestamp
      local pr = project_root()
      local ts = tostring(os.time())
      local dumpdir = pr:gsub('\\', '/') .. '/.quarto'
      pcall(function()
        local f = io.popen('mkdir "' .. dumpdir .. '" 2>nul')
        if f then f:close() end
      end)
      -- Ensure bounds
      content = ensure_uml_bounds(content)

      -- Write dumps only when debug env var is set
      local debug_on = (os.getenv('INLINE_PLANTUML_DEBUG') or '') ~= ''
      if debug_on then
        local dumpname = dumpdir .. '/inline-plantuml-dump-FINDME.puml'
        local temp = os.getenv('TEMP') or os.getenv('TMP') or '.'
        local tempdump = temp:gsub('\\', '/') .. '/inline-plantuml-dump-FINDME.puml'
        -- Explicitly announce where we will write
        dbg('INLINE-PLANTUML-WRITE-TO: ' .. dumpname)
        dbg('INLINE-PLANTUML-WRITE-TO-TEMP: ' .. tempdump)
        local fh, ferr = io.open(dumpname, 'wb')
        if fh then fh:write(content); fh:close() end
        local f2, e2 = io.open(tempdump, 'wb')
        if f2 then f2:write(content); f2:close() end
        local logname = dumpdir .. '/inline-plantuml-log.txt'
        local lf, le = io.open(logname, 'a')
        if lf then lf:write(ts .. '\t' .. (path or filename) .. '\t' .. dumpname .. '\t' .. tempdump .. '\n'); lf:close() end
      end

      cb.text = content
      return cb
    else
  dbg('INLINE-PLANTUML-RESOLVE-FAILED: ' .. tostring(filename))
      -- When debug is enabled, write a small log entry so the missing-file case is visible
      local debug_on = (os.getenv('INLINE_PLANTUML_DEBUG') or '') ~= ''
      if debug_on then
        local pr = project_root()
        local dumpdir = pr:gsub('\\', '/') .. '/.quarto'
        local logname = dumpdir .. '/inline-plantuml-log.txt'
        pcall(function()
          local lf, le = io.open(logname, 'a')
          if lf then lf:write(tostring(os.time()) .. '\tMISSING\t' .. (filename or '-') .. '\n'); lf:close() end
        end)
      end
      cb.text = string.format("' external file not found: %s", filename)
      return cb
    end
  end

  if cb.text and cb.text:match('!include') then
    cb.text = inline_includes(cb.text, 0, {})
    return cb
  end

  return nil
end
