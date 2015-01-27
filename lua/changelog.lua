local changelog_table
local PAGE_SIZE=30
local function add_change( chg )
    --table.insert( changelog_table, chg )
    --table.sort( changelog_table, function(a,b) return a.date<b.date end)
    local ind 
    for i=1,#changelog_table do
        if changelog_table[i].date > chg.date then
            ind=i
            break
        end
    end

    if ind then
        table.insert( changelog_table, ind, chg )
    else
        table.insert( changelog_table, chg ) 
    end
        
end
local function handle_changelog_con( d )
    local change={}
    local stat
    local cmd=""

    local funcs={
        getdate=function( self, d, cmd )
            if not(stat=="getdate") then
                stat="getdate"
                -- Set the default date
                change.date=os.time()
                sendtochar(d.character,
                        ("Enter date: [%s]"):format( os.date("%Y/%m/%d")))
                return
            end

            if not(cmd=="") then
                local Y,M,D=cmd:match("(%d%d%d%d)/(%d%d)/(%d%d)")

                if not Y then
                    sendtochar(d.character, "Date format is: YYYY/MM/DD\n\r")
                    return
                end
                change.date=os.time{year=Y, month=M, day=D}
            end

            return self:getauthor( d, "" )
        end,
        getauthor=function( self, d, cmd )
            if not(stat=="getauthor") then
                stat="getauthor"
                -- Set the default author
                change.author=d.character.name
                sendtochar( d.character,
                        ("Enter author: [%s]"):format( change.author))
                return
            end

            if not(cmd=="") then
                change.author=cmd
            end

            return self:getdesc( d, "" )
        end,
        getdesc=function( self, d, cmd )
            if not(stat=="getdesc") then
                stat="getdesc"
                sendtochar(d.character, "Enter the change description:\n\r")
                return
            end

            change.desc=cmd
            return self:confirm( d, "" )
        end,
        confirm=function( self, d, cmd )
            if not(stat=="confirm") then
                stat="confirm"
                -- Show the summary
                sendtochar(d.character, ([[
Timestamp:
%s

Author:
%s

Description:
%s

Save change? [Y/n]
]]):format( os.date("%Y/%m/%d %H:%M", change.date), change.author, change.desc))
                return
            end

            if cmd=="n" then
                sendtochar(d.character, "Change aborted!\n\r")
                return true
            elseif cmd=="Y" then
                add_change(change)
                sendtochar(d.character, "Change saved!\n\r")
                return true
            else
                sendtochar(d.character, "Save change? [Y/n]\n\r")
                return
            end
        end
    }

    funcs:getdate( d, "")
    while true do
        cmd=coroutine.yield()
        --sendtochar( d.character, "You entered: "..cmd.."\n\r")

        if funcs[stat](funcs, d, cmd) then break end
    end

    return
end

local function show_change_entry( ch, i )
    local ent=changelog_table[i]
    sendtochar( ch, ("%4d. %s {G%-10s{x %s\n\r"):format(
            i,
            os.date("%Y/%m/%d",ent.date),
            ent.author,
            ent.desc))
end

local function show_change_page( ch, pagenum )
    local start,fin

    start = 1 + ((pagenum-1) * PAGE_SIZE)
    fin = math.min(start-1+PAGE_SIZE, #changelog_table)

    sendtochar( ch, "Page "..pagenum.."\n\r")
    for i=start,fin do
        show_change_entry( ch, i )
    end
                
end

local function changelog_browse_con( d )
    local cmd
    local pagenum=1
    while true do
        show_change_page( d.character, pagenum )  
        sendtochar( d.character,
            "[q]uit, [n]ext, [p]rev, [f]irst, [l]ast, or #\n\r")
        
        cmd=coroutine.yield()
        
        if cmd=="q" then
            -- quit
            return
        elseif cmd=="n" then
            -- next page
            local newnum=pagenum+1
            if newnum<1 or newnum>math.ceil(#changelog_table/PAGE_SIZE) then
                sendtochar(d.character, "Already at last page.\n\r")
            else
                pagenum=newnum
            end
        elseif cmd=="p" then
            -- previous page
            if pagenum<2 then
                sendtochar(d.character, "Already at first page.\n\r")
            else
                pagenum=pagenum-1
            end
        elseif cmd=="f" then
            -- first page
            pagenum=1
        elseif cmd=="l" then
            -- last page
            pagenum=math.ceil(#changelog_table/PAGE_SIZE)
        elseif tonumber(cmd) then
            local newnum=tonumber(cmd)
            if newnum<1 or newnum>math.ceil(#changelog_table/PAGE_SIZE) then
                sendtochar(d.character, "No such page.\n\r")
            else
                pagenum=newnum
            end
        end
    end
end    

local function changelog_remove_con( d, ind )
    local cmd
    local ent=changelog_table[ind]
    if not ent then
        sendtochar( d.character, "No such entry.\n\r")
        return
    end

    show_change_entry( d.character, ind)
    sendtochar( d.character, "Delete this entry? 'Y' to confirm.\n\r")

    cmd=coroutine.yield()

    if not(cmd=="Y") then
        sendtochar( d.character, "Cancelled. Change not removed.\n\r")
        return
    end

    -- Make sure indexes haven't shifted since the confirmation
    if not changelog_table[ind]==ent then
        sendtochar( d.character, "Indexes have shifted, please try again.\n\r")
        return
    end

    table.remove(changelog_table, ind)
    sendtochar( d.character, "Change removed.\n\r")
end

local function changelog_usage( ch )
    sendtochar( ch, [[
changelog show            -- Show 30 most recent changes.
changelog browse          -- Browse changes page by page.
]])
    if ch.level>=108 then
        sendtochar( ch, [[
changelog add             -- Add a change.
changelog remove [#index] -- Remove a change
]])
    end
end

function do_changelog( ch, argument )
    if not ch.ispc then return end

    local args=arguments(argument)
    
    if args[1]=="show" then
        local ttl=#changelog_table
        if ttl<1 then return end
        local page=tonumber(args[2])
        local start
        local fin
        if page then
            if page<1 or page>math.ceil(ttl/PAGE_SIZE) then
                sendtochar(ch, "Invalid page number.\n\r")
                return
            end

            show_change_page( ch, page)
            return
        else
            fin=ttl
            start=math.max(1,fin-PAGE_SIZE+1)
        end

        for i=start,fin do
            show_change_entry( ch, i)
        end
        return

    elseif args[1]=="browse" then
        start_con_handler( ch.descriptor, changelog_browse_con, ch.descriptor)
        return 

    elseif args[1]=="remove" then
        local num=args[2] and tonumber(args[2])
        if not num then
            changelog_usage( ch )
            return
        end

        start_con_handler( ch.descriptor, changelog_remove_con, ch.descriptor, num) 
        return
    end

    if ch.level>=108 then
        if args[1]=="add" then
            local d=ch.descriptor
            start_con_handler( d, handle_changelog_con, d)
            return
        end

        if args[1]=="remove" then
            sendtochar( ch, "Not implemented yet.\n\r")
            return
        end 
    end

    changelog_usage(ch)

end

function load_changelog()
    changelog_table={}
    local f=loadfile("changelog_table.lua")

    if f==nil then return end

    local tmp=f()
    if tmp then changelog_table=tmp end
end

function save_changelog()
    local f=io.open("changelog_table.lua", "w")
    out,saved=serialize.save("changelog_table", changelog_table)
    f:write(out)

    f:close()
end
