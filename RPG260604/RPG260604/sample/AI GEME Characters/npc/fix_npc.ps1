$ErrorActionPreference = "Stop"
$dir = "E:\AAA big one\A godot\MY DEMO\RPG260604\sample\AI GEME Characters\npc"
[System.IO.Directory]::SetCurrentDirectory($dir)
$template = [System.IO.File]::ReadAllText("npc_student1.tscn", [System.Text.UTF8Encoding]::new($false))

function New-Uid {
    $chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    $s = -join ((1..13) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    return "uid://${s}"
}

function New-SubId($prefix, $suffix) {
    $chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    $s = -join ((1..5) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    return "${prefix}_${suffix}_${s}"
}

$npcs = @(
    @{Png="npcstudent2/npcstudent2.png"; NodeName="NPCstudent2"; OutFile="npc_student2.tscn"},
    @{Png="npcstudent3/npcstudent3.png"; NodeName="NPCstudent3"; OutFile="npc_student3.tscn"},
    @{Png="npcstudent4/npcstudent4.png"; NodeName="NPCstudent4"; OutFile="npc_student4.tscn"},
    @{Png="npcstudent5/npcstudent5.png"; NodeName="NPCstudent5"; OutFile="npc_student5.tscn"},
    @{Png="npcstudent6/npcstudent6.png"; NodeName="NPCstudent6"; OutFile="npc_student6.tscn"},
    @{Png="npcstudent7/npcstudent7.png"; NodeName="NPCstudent7"; OutFile="npc_student7.tscn"},
    @{Png="npcstudent8/npcstudent8.png"; NodeName="NPCstudent8"; OutFile="npc_student8.tscn"},
    @{Png="npcstudent9/npcstudent9.png"; NodeName="NPCstudent9"; OutFile="npc_student9.tscn"},
    @{Png="npcstudent10/npcstudent10.png"; NodeName="NPCstudent10"; OutFile="npc_student10.tscn"}
)

$cnNpcs = @(
    @{Png="CN_JiaoShou/CN_JiaoShou.png"; NodeName="NPCJiaoShou"; OutFile="npc_JiaoShou.tscn"},
    @{Png="CN_XieKuaBaoNan/CN_XieKuaBaoNan.png"; NodeName="NPCXieKuaBaoNan"; OutFile="npc_XieKuaBaoNan.tscn"}
)

# For Chinese-named NPCs using temp ASCII names to avoid encoding issues
$cnNpcs = @(
    @{Png="temp_cn/jiaoshou.png"; NodeName="NPCjiaoshou"; OutFile="npc_jiaoshou_temp.tscn"}
)

# Actually skip the complex approach. Let's just do students.

# The issue: Chinese chars cause encoding problems in PowerShell. 
# Strategy: Write file content directly with replace operations, using the Write tool afterwards.
# Let me just produce the student files with unique IDs.

$suffixes = @(
    "stud2", "stud3", "stud4", "stud5", "stud6",
    "stud7", "stud8", "stud9", "stud10"
)

for ($i = 0; $i -lt 9; $i++) {
    $num = $i + 2
    $png = "npcstudent${num}/npcstudent${num}.png"
    $nodeName = "NPCstudent${num}"
    $outFile = "npc_student${num}.tscn"
    $suffix = $suffixes[$i]
    
    $c = $template
    
    # Replace scene uid
    $c = $c -replace "^\[gd_scene.*$", "[gd_scene load_steps=32 format=3 uid=`"$(New-Uid)`"]"
    
    # Replace texture ext_resource: change both uid and path
    $texUid = New-Uid
    # Replace the entire line with path containing correct PNG
    $c = $c -replace 'uid://cih5fy46x3cv7', $texUid
    $c = $c -replace 'path="res://sample/AI GEME Characters/npc/npcstudent1/npcstudent1\.png"', "path=`"res://sample/AI GEME Characters/npc/${png}`""
    
    # Replace node name
    $c = $c -replace '\[node name="NPCstudent1"', "[node name=`"${nodeName}`""
    
    # Make sub_resource IDs unique
    # Pattern: id="AtlasTexture_XXXXX" -> id="AtlasTexture_XXXXX_$suffix"
    $c = $c -replace 'id="(AtlasTexture_\w+)"', "id=`"`${1}_${suffix}`""
    $c = $c -replace 'SubResource\("(AtlasTexture_\w+)"\)', "SubResource(`"`${1}_${suffix}`")"
    $c = $c -replace 'id="(SpriteFrames_\w+)"', "id=`"`${1}_${suffix}`""
    $c = $c -replace 'SubResource\("(SpriteFrames_\w+)"\)', "SubResource(`"`${1}_${suffix}`")"
    $c = $c -replace 'id="(CircleShape2D_\w+)"', "id=`"`${1}_${suffix}`""
    $c = $c -replace 'SubResource\("(CircleShape2D_\w+)"\)', "SubResource(`"`${1}_${suffix}`")"
    
    [System.IO.File]::WriteAllText($outFile, $c, [System.Text.UTF8Encoding]::new($false))
    Write-Host "OK: $outFile"
}

Write-Host "9 student files done"
