import os
import re
import random
import string

dir_path = r"E:\AAA big one\A godot\MY DEMO\RPG260604\sample\AI GEME Characters\npc"
os.chdir(dir_path)

with open("npc_student1.tscn", "r", encoding="utf-8") as f:
    template = f.read()

def new_uid():
    chars = string.ascii_lowercase + string.digits
    s = ''.join(random.choice(chars) for _ in range(13))
    return f"uid://{s}"

def new_sub_id(prefix, suffix):
    chars = string.ascii_lowercase + string.digits
    s = ''.join(random.choice(chars) for _ in range(5))
    return f"{prefix}_{suffix}_{s}"

npcs = [
    ("npcstudent2", "npcstudent2.png", "NPCstudent2", "npc_student2.tscn", "stud2"),
    ("npcstudent3", "npcstudent3.png", "NPCstudent3", "npc_student3.tscn", "stud3"),
    ("npcstudent4", "npcstudent4.png", "NPCstudent4", "npc_student4.tscn", "stud4"),
    ("npcstudent5", "npcstudent5.png", "NPCstudent5", "npc_student5.tscn", "stud5"),
    ("npcstudent6", "npcstudent6.png", "NPCstudent6", "npc_student6.tscn", "stud6"),
    ("npcstudent7", "npcstudent7.png", "NPCstudent7", "npc_student7.tscn", "stud7"),
    ("npcstudent8", "npcstudent8.png", "NPCstudent8", "npc_student8.tscn", "stud8"),
    ("npcstudent9", "npcstudent9.png", "NPCstudent9", "npc_student9.tscn", "stud9"),
    ("npcstudent10", "npcstudent10.png", "NPCstudent10", "npc_student10.tscn", "stud10"),
    ("教授", "教授.png", "NPC教授", "npc_教授.tscn", "jiaos"),
    ("斜挎包男", "斜挎包男.png", "NPC斜挎包男", "npc_斜挎包男.tscn", "xiek"),
    ("灰制服男", "灰制服男.png", "NPC灰制服男", "npc_灰制服男.tscn", "huiz"),
    ("白衬衫男", "白衬衫男.png", "NPC白衬衫男", "npc_白衬衫男.tscn", "baic"),
    ("粉旗袍女", "粉旗袍女.png", "NPC粉旗袍女", "npc_粉旗袍女.tscn", "fenq"),
    ("红围巾男", "红围巾男.png", "NPC红围巾男", "npc_红围巾男.tscn", "hong"),
    ("绿旗袍阿姨", "绿旗袍阿姨.png", "NPC绿旗袍阿姨", "npc_绿旗袍阿姨.tscn", "lvqi"),
    ("邮差男", "邮差男.png", "NPC邮差男", "npc_邮差男.tscn", "youd"),
    ("长风衣男", "长风衣男.png", "NPC长风衣男", "npc_长风衣男.tscn", "chan"),
]

for folder, png, node_name, out_file, suffix in npcs:
    c = template
    
    # Replace scene uid
    c = re.sub(r'uid://cvriyv5rkknsp', new_uid(), c)
    
    # Replace texture path
    tex_path = f"res://sample/AI GEME Characters/npc/{folder}/{png}"
    c = c.replace(
        'path="res://sample/AI GEME Characters/npc/npcstudent1/npcstudent1.png"',
        f'path="{tex_path}"'
    )
    
    # Replace texture ext_resource uid
    c = c.replace('uid://cih5fy46x3cv7', new_uid())
    
    # Replace node name
    c = c.replace('[node name="NPCstudent1"', f'[node name="{node_name}"')
    
    # Make all sub_resource IDs unique with suffix
    def replace_sub_id(m):
        return f'{m.group(1)}{m.group(2)}_{suffix}'
    
    c = re.sub(r'(id=")(AtlasTexture_\w+)(")', 
               lambda m: f'id="{m.group(2)}_{suffix}"', c)
    c = re.sub(r'(SubResource\(")(AtlasTexture_\w+)("\))',
               lambda m: f'SubResource("{m.group(2)}_{suffix}")', c)
    c = re.sub(r'(id=")(SpriteFrames_\w+)(")',
               lambda m: f'id="{m.group(2)}_{suffix}"', c)
    c = re.sub(r'(SubResource\(")(SpriteFrames_\w+)("\))',
               lambda m: f'SubResource("{m.group(2)}_{suffix}")', c)
    c = re.sub(r'(id=")(CircleShape2D_\w+)(")',
               lambda m: f'id="{m.group(2)}_{suffix}"', c)
    c = re.sub(r'(SubResource\(")(CircleShape2D_\w+)("\))',
               lambda m: f'SubResource("{m.group(2)}_{suffix}")', c)
    
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(c)
    
    print(f"OK: {out_file}")

print(f"\nDone! {len(npcs)} files generated.")
