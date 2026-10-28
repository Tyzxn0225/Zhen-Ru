$templateFile = Join-Path $PSScriptRoot "npc_student1.tscn"
$template = Get-Content -Path $templateFile -Raw -Encoding UTF8

$npcs = @(
    @{ Name="NPCstudent2";  Folder="npcstudent2";  Png="npcstudent2.png" },
    @{ Name="NPCstudent3";  Folder="npcstudent3";  Png="npcstudent3.png" },
    @{ Name="NPCstudent4";  Folder="npcstudent4";  Png="npcstudent4.png" },
    @{ Name="NPCstudent5";  Folder="npcstudent5";  Png="npcstudent5.png" },
    @{ Name="NPCstudent6";  Folder="npcstudent6";  Png="npcstudent6.png" },
    @{ Name="NPCstudent7";  Folder="npcstudent7";  Png="npcstudent7.png" },
    @{ Name="NPCstudent8";  Folder="npcstudent8";  Png="npcstudent8.png" },
    @{ Name="NPCstudent9";  Folder="npcstudent9";  Png="npcstudent9.png" },
    @{ Name="NPCstudent10"; Folder="npcstudent10"; Png="npcstudent10.png" },
    @{ Name="NPC教授";       Folder="教授";       Png="教授.png" },
    @{ Name="NPC斜挎包男";   Folder="斜挎包男";   Png="斜挎包男.png" },
    @{ Name="NPC灰制服男";   Folder="灰制服男";   Png="灰制服男.png" },
    @{ Name="NPC白衬衫男";   Folder="白衬衫男";   Png="白衬衫男.png" },
    @{ Name="NPC粉旗袍女";   Folder="粉旗袍女";   Png="粉旗袍女.png" },
    @{ Name="NPC红围巾男";   Folder="红围巾男";   Png="红围巾男.png" },
    @{ Name="NPC绿旗袍阿姨"; Folder="绿旗袍阿姨"; Png="绿旗袍阿姨.png" },
    @{ Name="NPC邮差男";     Folder="邮差男";     Png="邮差男.png" },
    @{ Name="NPC长风衣男";   Folder="长风衣男";   Png="长风衣男.png" }
)

foreach ($npc in $npcs) {
    $content = $template
    
    # Replace the texture ext_resource line - change both path and uid
    $texturePath = "res://sample/AI GEME Characters/npc/$($npc.Folder)/$($npc.Png)"
    $content = $content -replace 'uid://cih5fy46x3cv7', 'uid://00000000000000'
    $content = $content -replace 'path="res://sample/AI GEME Characters/npc/npcstudent1/npcstudent1\.png"', "path=`"$texturePath`""
    
    # Replace the root node name
    $content = $content -replace '\[node name="NPCstudent1"', "[node name=`"$($npc.Name)`""
    
    # Reset animation to move_down and remove frame/frame_progress
    $content = $content -replace 'animation = &"move_right"', 'animation = &"move_down"'
    $content = $content -replace "`nframe = 1`nframe_progress = 0.8921863`n", "`n"
    
    # Generate unique scene uid
    $randomHex = -join ((1..13) | ForEach { '{0:x}' -f (Get-Random -Max 16) })
    $content = $content -replace 'uid://cvriyv5rkknsp', "uid://$randomHex"
    
    $filename = "npc_" + ($npc.Name -replace '^NPC', '') + ".tscn"
    $filepath = Join-Path $PSScriptRoot $filename
    
    [System.IO.File]::WriteAllText($filepath, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Created: $filename"
}

Write-Host "Done! Generated $($npcs.Count) files."
