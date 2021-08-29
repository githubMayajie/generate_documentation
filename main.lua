local format = string.format
local gsub = string.gsub
local sub = string.sub
local find = string.find
local gmatch = string.gmatch
local match = string.match

local concat = table.concat

local execute = os.execute

local fopen = io.open
local popen = io.popen
local close = io.close
local flush = io.flush
local read = io.read
local write = io.write
local exists = io.exists

local function runCommand(cmd)
    local lines = {}
    local output = popen(cmd):read'*a'
    local index = 1
    for line in gmatch(output,"([^\n]*)\n?") do
        lines[index] = line
        index = index + 1
    end
    return lines
end

local function removeSidesBlank(content)
    local find,_,value = find(content,'^%s*(%S*)%s*$')
    if find then
        return value
    else
        return content
    end
end

-- check os
local isWindows = false
local isLinux = false   -- not test
local isMacOS = false   -- not test
local cpath = package.cpath
-- *.dll *.so *.dylib
-- get last six chars from cpath
local lastSixChar = cpath:sub(#cpath - 6)
local dyLibNameSuffix = match(lastSixChar,"([dlsoyib]*)$")
if dyLibNameSuffix == "dll" then
    isWindows = true
elseif dyLibNameSuffix == "so" then
    isLinux = true
elseif dyLibNameSuffix == "dylib" then
    isMacOS = true
else
    error("parse package.cpath error")
end
local dirSeparate = '/'
if isWindows then
    dirSeparate = '\\'
end

-- get current dir
local currentDir = nil
local function getCurrentDir()
    if currentDir then
        return currentDir
    end
    local function getFirstLine(cmd)
        return removeSidesBlank(runCommand(cmd)[1])
    end
    if isWindows then
        currentDir = getFirstLine("cd")
    else
        currentDir = getFirstLine("pwd")
    end
    return currentDir
end
currentDir = getCurrentDir()

-- add current dir to path and cpath
local currentDirCpath = format("%s%s?.%s",currentDir,dirSeparate,dyLibNameSuffix)
local currentDirPath = format("%s%s?.lua",currentDir,dirSeparate)
if not find(package.cpath,currentDirCpath) then
    package.cpath = format("%s;%s",package.cpath,currentDirCpath)
end
if not find(package.path,currentDirPath) then
    package.path = format("%s;%s",package.path,currentDirPath)
end

-- add dump function
-- copy from https://github.com/mah0x211/lua-dump/blob/master/dump.lua
local not_print_dump = require("dump")
local function dump(value)
    return print(not_print_dump(value,2))
end


local function getLastModifiedTime(path)
    if exists(path) then
        local function parseTime(line)
            local find,_,year,month,day,hour,minute = find("^%s*(%d*)/(%d*)/(%d*)%s*(%d*):(%d*)")
            if #year == 4 and #month == 2 and #day == 2 and #hour == 2 and #minute == 2 then
                return true,format("%s%s%s%s%s",year,month,day,hour,minute)
            end
        end
        local cmdFormat = ""
        if isWindows then
            cmdFormat = format("dir %s /TW",path)
        else
            cmdFormat = [[stat -f "%Sm" -t "%Y/%m/%d %H:%M" ]] .. path
        end
        local lines = runCommand(cmdFormat)
        for i,line in ipairs(lines) do
            local isFind,ret = parseTime(line)
            if isFind then
                return ret
            end
        end
    end
    error(format("get file(%s) last modifed time error",path))
end

local function getAllFiles(dir)
    local cmdFormat = ""
    if isWindows then
        cmdFormat = format("dir %s /A-D /S /B",dir)
    else
        cmdFormat = format("find %s -type f",dir)
    end
    local lines = runCommand(cmdFormat)
    local paths = {}
    for i,line in ipairs(lines) do
        paths[i] = removeSidesBlank(line)
    end
    return paths
end

local ctx = {}
local parseAt,parseEnum,parseUnion,parseFunc
local blankRegex = ' \t'
local numRegex = '0-9'
local alphaRegex = 'a-zA-Z'
local alNumRegex = alphaRegex .. numRegex
local alNumBlankRegex = alNumRegex .. blankRegex

parseAt = function(line)
    local firstChar = line:sub(1,1)
    if firstChar == '@' then
        return true,removeSidesBlank(line:sub(2))
    end
    return false
end

parseEnum = function(line)
    --[[
        url: https://en.cppreference.com/w/cpp/language/enum
        syntax:
            enum-key attr(optional) enum-name(optional) enum-base(optional)(C++11) { enumerator-list(optional) }
            enum-key attr(optional) enum-name enum-base(optional) ;
    ]]
end


--for exit lua5.3 interactive env
os.exit()
