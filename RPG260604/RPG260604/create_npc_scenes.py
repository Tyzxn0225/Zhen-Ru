import os

# NPC角色列表
npc_characters = [
    ("CaveLion2", "cavelion2_12345"),
    ("Cavegirl", "cavegirl_12345"),
    ("Cavegirl2", "cavegirl2_12345"),
    ("Caveman", "caveman_12345"),
    ("Caveman2", "caveman2_12345"),
    ("DemonGreen", "demongreen_12345"),
    ("DemonRed", "demonred_12345"),
    ("EggBoy", "eggboy_12345"),
    ("EggGirl", "egggirl_12345"),
    ("Eskimo", "eskimo_12345"),
]

# 模板内容
template = """[gd_scene format=3 uid="uid://{uid}"]

[ext_resource type="PackedScene" uid="uid://chdwh20454cxx" path="res://Scenes/npc/npc_simple.tscn" id="1_7txs2"]
[ext_resource type="Texture2D" uid="uid://{char_lower}_idle" path="res://Sprites/Actor/Characters/{character}/SeparateAnim/Idle.png" id="2_ahryu"]
[ext_resource type="Texture2D" uid="uid://{char_lower}_walk" path="res://Sprites/Actor/Characters/{character}/SeparateAnim/Walk.png" id="3_gy0td"]

[sub_resource type="AtlasTexture" id="AtlasTexture_o7q2f"]
atlas = ExtResource("2_ahryu")
region = Rect2(0, 0, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_fcbfq"]
atlas = ExtResource("2_ahryu")
region = Rect2(32, 0, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_y2ks6"]
atlas = ExtResource("2_ahryu")
region = Rect2(48, 0, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_wabnd"]
atlas = ExtResource("2_ahryu")
region = Rect2(16, 0, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_xgj48"]
atlas = ExtResource("3_gy0td")
region = Rect2(0, 0, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_w2280"]
atlas = ExtResource("3_gy0td")
region = Rect2(0, 16, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_4bjun"]
atlas = ExtResource("3_gy0td")
region = Rect2(0, 32, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_ux56r"]
atlas = ExtResource("3_gy0td")
region = Rect2(0, 48, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_awf1u"]
atlas = ExtResource("3_gy0td")
region = Rect2(32, 0, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_w60v2"]
atlas = ExtResource("3_gy0td")
region = Rect2(32, 16, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_5l0ga"]
atlas = ExtResource("3_gy0td")
region = Rect2(32, 32, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_gbtmp"]
atlas = ExtResource("3_gy0td")
region = Rect2(32, 48, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_ek70o"]
atlas = ExtResource("3_gy0td")
region = Rect2(48, 0, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_2o4rk"]
atlas = ExtResource("3_gy0td")
region = Rect2(48, 16, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_cua16"]
atlas = ExtResource("3_gy0td")
region = Rect2(48, 32, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_j42fv"]
atlas = ExtResource("3_gy0td")
region = Rect2(48, 48, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_eeqd0"]
atlas = ExtResource("3_gy0td")
region = Rect2(16, 0, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_ykvar"]
atlas = ExtResource("3_gy0td")
region = Rect2(16, 16, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_sfpsx"]
atlas = ExtResource("3_gy0td")
region = Rect2(16, 32, 16, 16)

[sub_resource type="AtlasTexture" id="AtlasTexture_s56mr"]
atlas = ExtResource("3_gy0td")
region = Rect2(16, 48, 16, 16)

[sub_resource type="SpriteFrames" id="SpriteFrames_{char_lower}"]
animations = [{{
"frames": [{{
"duration": 1.0,
"texture": SubResource("AtlasTexture_o7q2f")
}}],
"loop": false,
"name": &"idle_down",
"speed": 5.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": SubResource("AtlasTexture_fcbfq")
}}],
"loop": false,
"name": &"idle_left",
"speed": 5.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": SubResource("AtlasTexture_y2ks6")
}}],
"loop": false,
"name": &"idle_right",
"speed": 5.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": SubResource("AtlasTexture_wabnd")
}}],
"loop": false,
"name": &"idle_up",
"speed": 5.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": SubResource("AtlasTexture_xgj48")
}}, {{
"duration": 1.0,
"texture": SubResource("AtlasTexture_w2280")
}}, {{
"duration": 1.0,
"texture": SubResource("AtlasTexture_4bjun")
}}, {{
"duration": 1.0,
"texture": SubResource("AtlasTexture_ux56r")
}}],
"loop": true,
"name": &"move_down",
"speed": 8.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": SubResource("AtlasTexture_awf1u")
}}, {{
"duration": 1.0,
"texture": SubResource("AtlasTexture_w60v2")
}}, {{
"duration": 1.0,
"texture": SubResource("AtlasTexture_5l0ga")
}}, {{
"duration": 1.0,
"texture": SubResource("AtlasTexture_gbtmp")
}}],
"loop": true,
"name": &"move_left",
"speed": 8.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": SubResource("AtlasTexture_ek70o")
}}, {{
"duration": 1.0,
"texture": SubResource("AtlasTexture_2o4rk")
}}, {{
"duration": 1.0,
"texture": SubResource("AtlasTexture_cua16")
}}, {{
"duration": 1.0,
"texture": SubResource("AtlasTexture_j42fv")
}}],
"loop": true,
"name": &"move_right",
"speed": 8.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": SubResource("AtlasTexture_eeqd0")
}}, {{
"duration": 1.0,
"texture": SubResource("AtlasTexture_ykvar")
}}, {{
"duration": 1.0,
"texture": SubResource("AtlasTexture_sfpsx")
}}, {{
"duration": 1.0,
"texture": SubResource("AtlasTexture_s56mr")
}}],
"loop": true,
"name": &"move_up",
"speed": 8.0
}}]

[node name="NPC{character}" unique_id=465579294 instance=ExtResource("1_7txs2")]

[node name="AnimatedSprite2D" parent="." index="1" unique_id=2121836141]
sprite_frames = SubResource("SpriteFrames_{char_lower}")
animation = &"idle_down"
"""

# 输出目录
output_dir = r"e:\AAA big one\A godot\MY DEMO\rpg-260427\Scenes\npc"

# 生成场景文件
for character, uid in npc_characters:
    char_lower = character.lower()
    filename = f"pc_{char_lower}.tscn"
    filepath = os.path.join(output_dir, filename)
    
    content = template.format(
        uid=uid,
        character=character,
        char_lower=char_lower
    )
    
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
    
    print(f"Created: {filepath}")

print("\n所有NPC场景文件已生成！")