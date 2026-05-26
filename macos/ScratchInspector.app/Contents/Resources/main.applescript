use AppleScript version "2.4"
use framework "Foundation"
use scripting additions

on run
    -- 1. Prompt for file
    set theFile to (choose file with prompt "Select a Scratch Project (.sb3 or .sb2)" of type {"sb3", "sb2"})
    set posixPath to POSIX path of theFile
    set fileName to name of (info for theFile)
    
    -- 2. Extract JSON (using system unzip)
    set tempDir to "/tmp/scratch_analyze"
    do shell script "rm -rf " & tempDir & " && mkdir -p " & tempDir
    do shell script "unzip -q " & quoted form of posixPath & " project.json -d " & tempDir
    
    -- 3. Parse JSON
    set jsonPath to tempDir & "/project.json"
    set jsonData to (current application's NSData's dataWithContentsOfFile:(current application's NSString's stringWithString:jsonPath))
    set projectData to (current application's NSJSONSerialization's JSONObjectWithData:jsonData options:0 |error|:(missing value))
    
    -- 4. Logic to identify format and count
    set report to "AUDIT REPORT: " & fileName & linefeed & "==============================" & linefeed
    
    if (projectData's valueForKey:"targets") is not missing value then
        -- SB3 Logic
        set report to report & "[Format: Scratch 3.0]" & linefeed & linefeed
        set targets to projectData's valueForKey:"targets"
        repeat with target in targets
            set name to (target's valueForKey:"name") as string
            set costumes to (target's valueForKey:"costumes")'s |count|()
            -- Count scripts: blocks where parent is null and opcode is a trigger
            set blocks to (target's valueForKey:"blocks")
            set scriptCount to 0
            repeat with bKey in (blocks's allKeys())
                set bData to (blocks's valueForKey:bKey)
                if (bData's valueForKey:"parent") is missing value then
                    set op to (bData's valueForKey:"opcode") as string
                    if op contains "event_" or op contains "clone" or op contains "definition" then
                        set scriptCount to scriptCount + 1
                    end if
                end if
            end repeat
            set report to report & "Sprite: " & name & linefeed & "  • Costumes: " & costumes & linefeed & "  • Scripts:  " & scriptCount & linefeed & linefeed
        end repeat
        
    else if (projectData's valueForKey:"children") is not missing value then
        -- SB2 Logic
        set report to report & "[Format: Scratch 2.0]" & linefeed & linefeed
        set children to projectData's valueForKey:"children"
        repeat with obj in children
            if (obj's valueForKey:"objName") is not missing value then
                set name to (obj's valueForKey:"objName") as string
                set costumes to (obj's valueForKey:"costumes")'s |count|()
                set scripts to (obj's valueForKey:"scripts")'s |count|()
                set report to report & "Sprite: " & name & linefeed & "  • Costumes: " & costumes & linefeed & "  • Scripts:  " & scripts & linefeed & linefeed
            end if
        end repeat
    end if
    
    -- 5. Display result
    display dialog report with title "Scratch Audit Results" buttons {"OK"} default button "OK"
end run
