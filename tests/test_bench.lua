local unpack = table.unpack
local fmt = string.format

local bench = {}

function bench.get_cpuinfo_and_os_type()
    local cpuinfo
    local os_type

    -- 判断操作系统类型
    if package.config:sub(1, 1) == "\\" then -- 如果路径分隔符为反斜杠，则是 Windows
        os_type = "Windows"

        local temp_file = os.tmpname()
        os.execute("wmic cpu get Name /format:csv > " .. temp_file)
        cpuinfo = io.open(temp_file):read("*a")
        os.remove(temp_file)

    else -- 如果不是 Windows，则假设为 Unix 系列（macOS、Linux等）
        os_type = io.popen("uname -s"):read("*a"):gsub("\n", "") or "Unknown"

        if os_type == "Linux" then
            cpuinfo = io.open("/proc/cpuinfo"):read("*a")
        elseif os_type == "Darwin" then -- macOS
            cpuinfo = io.popen("sysctl -n machdep.cpu.brand_string"):read("*a")
        else
            error("Unsupported operating system: " .. tostring(os_type))
        end
    end

    return cpuinfo, os_type
end

function bench.print_system_info()
  print( fmt("Lua version   : %s", _VERSION) )
  local cpu, os = bench.get_cpuinfo_and_os_type()
  print( fmt("OS            : %s", os))
  print( fmt("cpu name      : %s", cpu) )
end

function bench.run(name, count, func)
  -- Run bench
  local res = {}
  for i = 1, count do
    local start_time = os.clock()
    func()
    table.insert(res, (os.clock() - start_time))
  end
  -- Calculate average
  local avg = 0
  for i, v in ipairs(res) do
    avg = avg + v
  end
  avg = avg / #res
  -- Build and return result table
  return {
    name = name,
    avg = avg,
    min = math.min(unpack(res)),
    max = math.max(unpack(res)),
    all = res,
  }
end

function bench.run_with_output(name, count, func)
    print(string.rep('-', 30))
    print(fmt('[%s] run ...', name))
    local res = bench.run(name, count, func)
    print('over')
    return res
end


------- fake -----------------------------------

local function generate_large_nested_table(rows, cols)
    local t = {}

    for r = 1, rows do
        local row = {}
        for c = 1, cols do
            --table.insert(row, (r - 1) * cols + c)
            table.insert(row, '12345\n12345\n12345\n12345\n12345')
        end
        table.insert(t, row)
    end

    return t
end

local function generate_large_depth_table(depth)
    local t = {}
    local tmp = t

    for d = 1, depth do
        tmp.sub = {}
        tmp = tmp.sub
    end
    tmp.key = 'last'

    return t
end

------- ready -----------------------------------
bench.print_system_info()

local pprint = loadfile('../pprint.lua')()

local bench_tb, bench_res

bench_tb = generate_large_nested_table(1000, 1000)
print('Generate bench table over, 1000 x 1000.')


bench_res = bench.run_with_output('PrettyPrinter:_format', 10, function ()
    pprint.PrettyPrinter():_format(bench_tb, 0, {}, 0)
end)
pprint.pprint(bench_res)


bench_res = bench.run_with_output('PrettyPrinter:pformat', 10, function ()
    pprint.PrettyPrinter():pformat(bench_tb)
end)
pprint.pprint(bench_res)


bench_res = bench.run_with_output('PrettyPrinter:pformat:compact', 10, function ()
    pprint.PrettyPrinter({compact=true}):pformat(bench_tb)
end)
pprint.pprint(bench_res)


bench_tb = generate_large_depth_table(5000)
print('Generate bench table over, depth 5000.')


bench_res = bench.run_with_output('PrettyPrinter:_format', 10, function ()
    pprint.PrettyPrinter():_format(bench_tb, 0, {}, 0)
end)
pprint.pprint(bench_res)


bench_res = bench.run_with_output('PrettyPrinter:pformat', 10, function ()
    pprint.PrettyPrinter():pformat(bench_tb)
end)
pprint.pprint(bench_res)


bench_res = bench.run_with_output('PrettyPrinter:pformat:compact', 10, function ()
    pprint.PrettyPrinter({compact=true}):pformat(bench_tb)
end)
pprint.pprint(bench_res)
