//
//  AppLocalization.swift
//  RisingStarKid
//
//  Lightweight localization helper for Chinese/English UI strings.
//

import Foundation

enum AppLocalization {
    static var isChineseMode: Bool {
        UserDefaults.standard.string(forKey: "speechLanguage") == "zh-CN"
    }

    static func localized(_ english: String, zh: String) -> String {
        isChineseMode ? zh : english
    }

    // MARK: - Common UI Strings

    static var settings: String { localized("Settings", zh: "设置") }
    static var account: String { localized("Account", zh: "账户") }
    static var name: String { localized("Name", zh: "名称") }
    static var email: String { localized("Email", zh: "邮箱") }
    static var signedInWith: String { localized("Signed in with", zh: "登录方式") }
    static var signOut: String { localized("Sign Out", zh: "退出登录") }
    static var signOutConfirm: String { localized("Are you sure you want to sign out?", zh: "确定要退出登录吗？") }
    static var cancel: String { localized("Cancel", zh: "取消") }
    static var reset: String { localized("Reset", zh: "重置") }
    static var speechSettings: String { localized("Speech Settings", zh: "语音设置") }
    static var language: String { localized("Language", zh: "语言") }
    static var speechSpeed: String { localized("Speech Speed", zh: "语速") }
    static var testVoice: String { localized("Test Voice", zh: "测试语音") }
    static var about: String { localized("About", zh: "关于") }
    static var version: String { localized("Version", zh: "版本") }
    static var developer: String { localized("Developer", zh: "开发者") }
    static var resetProgress: String { localized("Reset Progress", zh: "重置进度") }
    static var resetProgressConfirm: String {
        localized(
            "Are you sure you want to reset all progress? This cannot be undone.",
            zh: "确定要重置所有进度吗？此操作不可撤销。"
        )
    }
    static var resetAllData: String { localized("Reset All Data", zh: "重置所有数据") }

    // MARK: - Tab Bar & Home

    static var progress: String { localized("Progress", zh: "进度") }
    static var camera: String { localized("Camera", zh: "相机") }
    static var appTitle: String { localized("Rising Star Kid", zh: "启明星") }
    static var letsLearnTogether: String { localized("Let's learn together!", zh: "一起来学习吧！") }
    static var myDevelopment: String { localized("My Development", zh: "我的发展") }
    static var quickStart: String { localized("Quick Start", zh: "快速开始") }

    // MARK: - Dimension Hub

    static var learn: String { localized("Learn", zh: "学习") }
    static var storyMode: String { localized("Story Mode", zh: "故事模式") }
    static var playStory: String { localized("Play Story", zh: "开始故事") }
    static var scenes: String { localized("scenes", zh: "场景") }
    static var minutes: String { localized("min", zh: "分钟") }
    static var hello: String { localized("Hello", zh: "你好") }
    static var chooseArea: String { localized("Choose an area to practice", zh: "选择一个练习领域") }
    static var level: String { localized("Level", zh: "等级") }
    static var player: String { localized("Player", zh: "玩家") }

    // MARK: - Session Setup

    static var stageSetup: String { localized("Stage Setup", zh: "关卡设置") }
    static var duration: String { localized("Duration", zh: "时长") }
    static var minutesUnit: String { localized("min", zh: "分钟") }
    static var startStage: String { localized("Start Stage", zh: "开始关卡") }
    static var start: String { localized("Start", zh: "开始") }
    static var howLong: String { localized("How long do you want to practice?", zh: "你想练习多久？") }
    static var sessionDuration: String { localized("Session Duration", zh: "练习时长") }
    static var stagesCompletedToday: String { localized("stages completed today", zh: "今日已完成关卡") }
    static var gettingReady: String { localized("Getting ready...", zh: "准备中...") }
    static var startingSession: String { localized("Starting session...", zh: "开始中...") }

    // MARK: - Task Interaction

    static var submit: String { localized("Submit", zh: "提交") }
    static var next: String { localized("Next", zh: "下一个") }
    static var skip: String { localized("Skip", zh: "跳过") }
    static var hearAgain: String { localized("Hear Again", zh: "再听一次") }
    static var showHint: String { localized("Show Hint", zh: "显示提示") }
    static var correct: String { localized("Correct!", zh: "正确！") }
    static var tryAgain: String { localized("Try again!", zh: "再试一次！") }
    static var greatJob: String { localized("Great job!", zh: "做得好！") }
    static var levelUp: String { localized("Level Up!", zh: "升级！") }
    static var keepGoing: String { localized("Great job! Keep going!", zh: "做得好！继续加油！") }
    static var loading: String { localized("Loading...", zh: "加载中...") }
    static var done: String { localized("Done", zh: "完成") }
    static var close: String { localized("Close", zh: "关闭") }
    static var findPattern: String { localized("🔍 Find the pattern!", zh: "🔍 找出规律！") }
    static var watchCarefully: String { localized("👀 Watch carefully!", zh: "👀 仔细看！") }
    static var whatDidYouSee: String { localized("What did you see?", zh: "你看到了什么？") }
    static var matchThisOrder: String { localized("Match this order:", zh: "按顺序排列：") }
    static var dragToArrange: String { localized("Drag to arrange:", zh: "拖动排列：") }
    static var tapHere: String { localized("Tap here when you see the target!", zh: "看到目标时点这里！") }
    static var yourOrder: String { localized("Your order:", zh: "你的顺序：") }
    static var findWithCamera: String { localized("Find with Camera", zh: "用相机找") }
    static var pickAllMatch: String { localized("Pick all that match", zh: "选出所有匹配的") }
    static var youSaid: String { localized("You said:", zh: "你说了：") }
    static var taps: String { localized("Taps", zh: "点击次数") }
    static var tap: String { localized("TAP!", zh: "点！") }
    static var streak: String { localized("streak", zh: "连续") }
    static var left: String { localized("left", zh: "剩余") }
    static var completed: String { localized("completed", zh: "已完成") }
    static var stage: String { localized("Stage", zh: "关卡") }
    static var task: String { localized("Task", zh: "任务") }

    // MARK: - Session Summary

    static var stageSummary: String { localized("Stage Complete!", zh: "关卡完成！") }
    static var tasksCompleted: String { localized("Tasks Completed", zh: "完成任务数") }
    static var correctCount: String { localized("Correct", zh: "正确数") }
    static var accuracy: String { localized("Accuracy", zh: "正确率") }
    static var timeSpent: String { localized("Time Spent", zh: "用时") }
    static var durationLabel: String { localized("Duration", zh: "时长") }
    static var rewardsEarned: String { localized("Rewards Earned", zh: "获得奖励") }
    static var returnHome: String { localized("Return Home", zh: "返回首页") }

    // MARK: - Drag Sort

    static var dragToSort: String { localized("Drag each item to the right group:", zh: "把每个物品拖到正确的组：") }
    static var checkSort: String { localized("Check", zh: "检查") }

    // MARK: - Settings About Section

    static var aboutApp: String { localized("About Rising Star Kid", zh: "关于启明星") }
    static var madeWith: String { localized("Made with", zh: "用心制作") }
    static var love: String { localized("Love", zh: "❤️") }
    static var forKids: String { localized("For", zh: "为了") }
    static var specialKids: String { localized("Special Kids", zh: "特殊儿童") }
    static var aboutDescription: String {
        localized(
            "Rising Star Kid helps autistic children develop across 6 dimensions with adaptive learning, ABA-based reinforcement, and personalized content.",
            zh: "启明星帮助自闭症儿童在6个发展维度上进步，通过自适应学习、ABA强化训练和个性化内容。"
        )
    }
    static var resetSection: String { localized("Reset", zh: "重置") }
    static var resetDescription: String {
        localized(
            "Reset all progress and start fresh. This will remove all learned objects and stars.",
            zh: "重置所有进度，从头开始。这将清除所有已学物品和星星。"
        )
    }
    static var resetAllProgress: String { localized("Reset All Progress", zh: "重置所有进度") }

    // MARK: - Story Card

    static var bunnyStoryTitle: String { localized("Bunny's Birthday Party", zh: "小兔子的生日派对") }
    static var bunnyStoryDesc: String {
        localized(
            "Help Bunny prepare a birthday party! Find items, decorate, and greet friends.",
            zh: "帮小兔子准备生日派对！找物品、装饰、迎接朋友。"
        )
    }

    // MARK: - Dimension Labels

    static var dimObjectCognition: String { localized("Object Cognition", zh: "物体认知") }
    static var dimLanguageExpression: String { localized("Language Expression", zh: "语言表达") }
    static var dimLanguageComprehension: String { localized("Language Comprehension", zh: "语言理解") }
    static var dimLiteracy: String { localized("Literacy", zh: "读写能力") }
    static var dimSocialBehavior: String { localized("Social Behavior", zh: "社交行为") }
    static var dimCognitiveLogic: String { localized("Cognitive Logic", zh: "认知逻辑") }

    // MARK: - Object Name Translations (for options displayed to user)

    static let objectNames: [String: String] = [
        // Animals
        "dog": "狗", "cat": "猫", "bird": "鸟", "fish": "鱼", "rabbit": "兔子",
        "bear": "熊", "elephant": "大象", "lion": "狮子", "monkey": "猴子", "horse": "马",
        "cow": "牛", "pig": "猪", "chicken": "鸡", "duck": "鸭子", "frog": "青蛙",
        "snake": "蛇", "turtle": "乌龟", "whale": "鲸鱼", "dolphin": "海豚", "shark": "鲨鱼",
        "butterfly": "蝴蝶", "bee": "蜜蜂", "ant": "蚂蚁", "spider": "蜘蛛", "bug": "虫子",
        "penguin": "企鹅", "eagle": "鹰", "owl": "猫头鹰", "parrot": "鹦鹉", "fox": "狐狸",
        "deer": "鹿", "wolf": "狼", "zebra": "斑马", "giraffe": "长颈鹿", "panda": "熊猫",
        "koala": "考拉", "kangaroo": "袋鼠", "bat": "蝙蝠", "hen": "母鸡", "rooster": "公鸡",
        "lamb": "小羊", "goat": "山羊", "mouse": "老鼠", "rat": "大鼠", "hamster": "仓鼠",
        "squirrel": "松鼠", "hedgehog": "刺猬", "snail": "蜗牛", "worm": "蚯蚓",
        "caterpillar": "毛毛虫", "ladybug": "瓢虫", "dragonfly": "蜻蜓", "mosquito": "蚊子",
        "fly": "苍蝇", "crab": "螃蟹", "lobster": "龙虾", "octopus": "章鱼", "jellyfish": "水母",
        "starfish": "海星", "seahorse": "海马", "salmon": "三文鱼", "tuna": "金枪鱼",
        "goldfish": "金鱼", "tiger": "老虎", "leopard": "豹子", "cheetah": "猎豹",
        "hippo": "河马", "rhino": "犀牛", "gorilla": "大猩猩", "crocodile": "鳄鱼",
        "alligator": "短吻鳄", "camel": "骆驼", "donkey": "驴", "sheep": "绵羊",
        "turkey": "火鸡", "peacock": "孔雀", "flamingo": "火烈鸟", "pelican": "鹈鹕",
        "swan": "天鹅", "crow": "乌鸦", "sparrow": "麻雀", "pigeon": "鸽子",
        "seagull": "海鸥", "robin": "知更鸟", "woodpecker": "啄木鸟", "foal": "小马驹",

        // Fruits & Food
        "apple": "苹果", "banana": "香蕉", "orange": "橙子", "grape": "葡萄",
        "strawberry": "草莓", "watermelon": "西瓜", "pineapple": "菠萝", "mango": "芒果",
        "peach": "桃子", "pear": "梨", "cherry": "樱桃", "lemon": "柠檬", "lime": "酸橙",
        "coconut": "椰子", "kiwi": "猕猴桃", "blueberry": "蓝莓", "avocado": "牛油果",
        "tomato": "番茄", "carrot": "胡萝卜", "broccoli": "西兰花", "corn": "玉米",
        "potato": "土豆", "onion": "洋葱", "garlic": "大蒜", "pepper": "辣椒",
        "cucumber": "黄瓜", "lettuce": "生菜", "mushroom": "蘑菇", "pumpkin": "南瓜",
        "pizza": "披萨", "cake": "蛋糕", "cookie": "饼干", "bread": "面包",
        "sandwich": "三明治", "hamburger": "汉堡", "hotdog": "热狗", "rice": "米饭",
        "noodle": "面条", "soup": "汤", "salad": "沙拉", "egg": "鸡蛋",
        "cheese": "奶酪", "butter": "黄油", "milk": "牛奶", "juice": "果汁",
        "water": "水", "tea": "茶", "coffee": "咖啡", "ice cream": "冰淇淋",
        "chocolate": "巧克力", "candy": "糖果", "popcorn": "爆米花",

        // Body parts
        "hand": "手", "foot": "脚", "head": "头", "eye": "眼睛", "ear": "耳朵",
        "nose": "鼻子", "mouth": "嘴巴", "tooth": "牙齿", "hair": "头发",
        "finger": "手指", "arm": "手臂", "leg": "腿", "knee": "膝盖",
        "shoulder": "肩膀", "neck": "脖子", "back": "背", "stomach": "肚子",
        "heart": "心脏", "brain": "大脑", "bone": "骨头", "liver": "肝脏",

        // Vehicles & Transport
        "car": "汽车", "bus": "公共汽车", "truck": "卡车", "train": "火车",
        "airplane": "飞机", "helicopter": "直升机", "boat": "船", "ship": "轮船",
        "bicycle": "自行车", "motorcycle": "摩托车", "rocket": "火箭",
        "submarine": "潜水艇", "taxi": "出租车", "ambulance": "救护车",
        "fire truck": "消防车", "police car": "警车", "tractor": "拖拉机",

        // Household items
        "chair": "椅子", "table": "桌子", "bed": "床", "sofa": "沙发",
        "door": "门", "window": "窗户", "lamp": "灯", "clock": "时钟",
        "mirror": "镜子", "pillow": "枕头", "blanket": "毯子", "towel": "毛巾",
        "cup": "杯子", "plate": "盘子", "bowl": "碗", "spoon": "勺子",
        "fork": "叉子", "knife": "刀", "bottle": "瓶子", "key": "钥匙",
        "lock": "锁", "basket": "篮子", "box": "盒子", "bag": "包",
        "umbrella": "雨伞", "broom": "扫帚", "bucket": "水桶", "candle": "蜡烛",
        "vase": "花瓶", "fan": "风扇", "rug": "地毯", "curtain": "窗帘",

        // Clothing
        "hat": "帽子", "shoe": "鞋子", "shirt": "衬衫", "pants": "裤子",
        "dress": "裙子", "coat": "外套", "jacket": "夹克", "sock": "袜子",
        "glove": "手套", "scarf": "围巾", "belt": "腰带", "tie": "领带",
        "boots": "靴子", "sandal": "凉鞋", "sweater": "毛衣", "skirt": "短裙",

        // Tools & Objects
        "hammer": "锤子", "screwdriver": "螺丝刀", "wrench": "扳手", "saw": "锯子",
        "drill": "电钻", "nail": "钉子", "screw": "螺丝", "scissors": "剪刀",
        "needle": "针", "thread": "线", "rope": "绳子", "chain": "链子",
        "brush": "刷子", "paint": "油漆", "pencil": "铅笔", "pen": "钢笔",
        "eraser": "橡皮", "ruler": "尺子", "tape": "胶带", "glue": "胶水",
        "magnet": "磁铁", "battery": "电池", "flashlight": "手电筒", "compass": "指南针",
        "thermometer": "温度计", "scale": "秤", "lever": "杠杆", "wheel": "轮子",

        // Nature
        "tree": "树", "flower": "花", "grass": "草", "leaf": "叶子",
        "sun": "太阳", "moon": "月亮", "star": "星星", "cloud": "云",
        "rain": "雨", "snow": "雪", "wind": "风", "rainbow": "彩虹",
        "mountain": "山", "river": "河流", "lake": "湖", "ocean": "海洋",
        "island": "岛", "desert": "沙漠", "forest": "森林", "volcano": "火山",
        "rock": "石头", "sand": "沙子", "mud": "泥巴", "ice": "冰",
        "fire": "火", "smoke": "烟", "fog": "雾",

        // Shapes & Colors
        "circle": "圆形", "square": "正方形", "triangle": "三角形", "rectangle": "长方形",
        "diamond": "菱形", "oval": "椭圆形", "pentagon": "五边形", "hexagon": "六边形",
        "red": "红色", "blue": "蓝色", "green": "绿色", "yellow": "黄色",
        "orange_color": "橙色", "purple": "紫色", "pink": "粉色", "black": "黑色",
        "white": "白色", "brown": "棕色", "gray": "灰色", "gold": "金色",
        "Red": "红色", "Blue": "蓝色", "Green": "绿色", "Yellow": "黄色",
        "Orange": "橙色", "Purple": "紫色", "Pink": "粉色", "Black": "黑色",
        "White": "白色", "Brown": "棕色",
        "Red circle": "红色圆形", "Blue circle": "蓝色圆形", "Green circle": "绿色圆形",
        "Red square": "红色正方形", "Blue square": "蓝色正方形",
        "Red triangle": "红色三角形", "Blue triangle": "蓝色三角形",
        "Circle": "圆形", "Square": "正方形", "Triangle": "三角形", "Star": "星星",
        "Rectangle": "长方形", "Diamond": "菱形", "Oval": "椭圆形", "Heart": "爱心",

        // Music & Instruments
        "piano": "钢琴", "guitar": "吉他", "drum": "鼓", "violin": "小提琴",
        "trumpet": "小号", "flute": "笛子", "bell": "铃铛", "microphone": "麦克风",

        // Sports & Toys
        "ball": "球", "balloon": "气球", "kite": "风筝", "doll": "娃娃",
        "robot": "机器人", "puzzle": "拼图", "block": "积木", "dice": "骰子",
        "basketball": "篮球", "football": "足球", "baseball": "棒球", "tennis": "网球",

        // School
        "book": "书", "notebook": "笔记本", "backpack": "书包", "desk": "课桌",
        "blackboard": "黑板", "chalk": "粉笔", "crayon": "蜡笔", "marker": "马克笔",
        "calculator": "计算器", "globe": "地球仪", "map": "地图", "calendar": "日历",

        // Science
        "microscope": "显微镜", "telescope": "望远镜", "binoculars": "望远镜",
        "magnet_obj": "磁铁", "crystal": "水晶", "fossil": "化石", "mineral": "矿物",
        "pendulum": "钟摆", "prism": "棱镜", "beaker": "烧杯", "test_tube": "试管",

        // Space
        "planet": "行星", "asteroid": "小行星", "comet": "彗星", "meteor": "流星",
        "galaxy": "星系", "constellation": "星座", "space_station": "空间站",
        "satellite": "卫星", "nebula": "星云",

        // Buildings
        "house": "房子", "castle": "城堡", "bridge": "桥", "tower": "塔",
        "church": "教堂", "hospital": "医院", "school": "学校", "library": "图书馆",
        "wall": "墙", "fence": "围栏", "gate": "大门", "roof": "屋顶",

        // Weather & Sky
        "lightning": "闪电", "thunder": "雷", "tornado": "龙卷风", "storm": "暴风雨",
        "sunrise": "日出", "sunset": "日落", "frost": "霜",

        // Misc objects
        "gift": "礼物", "flag": "旗帜", "map_obj": "地图", "coin": "硬币",
        "money": "钱", "crown": "王冠", "ring": "戒指", "necklace": "项链",
        "watch": "手表", "glasses": "眼镜", "camera": "相机", "phone": "手机",
        "computer": "电脑", "television": "电视", "radio": "收音机",
        "guitar_obj": "吉他", "paint_brush": "画笔", "color_palette": "调色板",
        "chart": "图表", "trophy": "奖杯", "medal": "奖牌",
        "snowman": "雪人", "chopsticks": "筷子", "timer": "计时器",

        // Common option words (capitalized as they appear in task options)
        "Dog": "狗", "Cat": "猫", "Bird": "鸟", "Fish": "鱼", "Rabbit": "兔子",
        "Bear": "熊", "Elephant": "大象", "Lion": "狮子", "Monkey": "猴子", "Horse": "马",
        "Apple": "苹果", "Banana": "香蕉", "Grape": "葡萄", "Strawberry": "草莓",
        "Watermelon": "西瓜", "Pineapple": "菠萝", "Mango": "芒果", "Peach": "桃子",
        "Pear": "梨", "Cherry": "樱桃", "Lemon": "柠檬", "Coconut": "椰子",
        "Car": "汽车", "Bus": "公共汽车", "Truck": "卡车", "Train": "火车",
        "Airplane": "飞机", "Boat": "船", "Bicycle": "自行车", "Rocket": "火箭",
        "Chair": "椅子", "Table": "桌子", "Bed": "床", "Sofa": "沙发",
        "Door": "门", "Window": "窗户", "Lamp": "灯", "Clock": "时钟",
        "Cup": "杯子", "Plate": "盘子", "Bowl": "碗", "Spoon": "勺子",
        "Fork": "叉子", "Knife": "刀", "Bottle": "瓶子", "Key": "钥匙",
        "Hat": "帽子", "Shoe": "鞋子", "Shirt": "衬衫", "Dress": "裙子",
        "Coat": "外套", "Sock": "袜子", "Glove": "手套", "Umbrella": "雨伞",
        "Hammer": "锤子", "Scissors": "剪刀", "Pencil": "铅笔", "Pen": "钢笔",
        "Eraser": "橡皮", "Ruler": "尺子", "Brush": "刷子", "Needle": "针",
        "Tree": "树", "Flower": "花", "Sun": "太阳", "Moon": "月亮",
        "Cloud": "云", "Rain": "雨", "Snow": "雪", "Mountain": "山",
        "River": "河流", "Fire": "火", "Ice": "冰", "Rock": "石头",
        "Ball": "球", "Balloon": "气球", "Kite": "风筝", "Doll": "娃娃",
        "Robot": "机器人", "Block": "积木", "Book": "书", "Cake": "蛋糕",
        "Pizza": "披萨", "Cookie": "饼干", "Bread": "面包", "Egg": "鸡蛋",
        "Milk": "牛奶", "Water": "水", "Juice": "果汁",
        "Piano": "钢琴", "Guitar": "吉他", "Drum": "鼓", "Bell": "铃铛",
        "Frog": "青蛙", "Duck": "鸭子", "Whale": "鲸鱼", "Penguin": "企鹅",
        "Butterfly": "蝴蝶", "Spider": "蜘蛛", "Ant": "蚂蚁", "Bee": "蜜蜂",
        "Fox": "狐狸", "Wolf": "狼", "Deer": "鹿", "Tiger": "老虎",
        "Panda": "熊猫", "Owl": "猫头鹰", "Eagle": "鹰", "Snake": "蛇",
        "Turtle": "乌龟", "Crab": "螃蟹", "Shark": "鲨鱼", "Dolphin": "海豚",
        "Snail": "蜗牛", "Worm": "蚯蚓", "Hen": "母鸡",
        "Microscope": "显微镜", "Telescope": "望远镜", "Compass": "指南针",
        "Thermometer": "温度计", "Calculator": "计算器", "Magnet": "磁铁",
        "Basketball": "篮球", "Football": "足球", "Tennis": "网球",

        // Category names (for sort tasks)
        "Animal": "动物", "Animals": "动物", "animal": "动物", "animals": "动物",
        "Fruit": "水果", "Fruits": "水果", "fruit": "水果", "fruits": "水果",
        "Vehicle": "交通工具", "Vehicles": "交通工具", "vehicle": "交通工具",
        "Food": "食物", "food": "食物",
        "Clothing": "衣服", "clothing": "衣服", "Clothes": "衣服",
        "Furniture": "家具", "furniture": "家具",
        "Tool": "工具", "Tools": "工具", "tool": "工具", "tools": "工具",
        "Nature": "自然", "nature": "自然",
        "Living": "有生命", "Non-living": "无生命",
        "Plant": "植物", "Plants": "植物",
        "Insect": "昆虫", "Insects": "昆虫",
        "Round": "圆的", "Not round": "不圆的",
        "Has legs": "有腿", "No legs": "没有腿",
        "Can fly": "能飞", "Cannot fly": "不能飞",
        "Soft": "软的", "Hard": "硬的",
        "Edible": "能吃", "Not edible": "不能吃",
        "Musical": "乐器", "Not musical": "非乐器",

        // Emotions & States
        "Happy": "开心", "Sad": "伤心", "Angry": "生气", "Scared": "害怕",
        "Surprised": "惊讶", "Excited": "兴奋", "Tired": "累了",
        "hungry": "饿了", "cold": "冷", "hot": "热",
        "happy": "开心", "sad": "伤心", "angry": "生气", "scared": "害怕",
        "nervous": "紧张", "calm": "平静", "proud": "骄傲", "shy": "害羞",

        // Sizes & Directions
        "Big": "大", "Small": "小", "Tall": "高", "Short": "矮",
        "Long": "长", "Heavy": "重", "Light": "轻",
        "Left": "左", "Right": "右", "Up": "上", "Down": "下",
        "big": "大", "small": "小", "tall": "高", "short": "矮",
    ]

    /// Translate an option string to Chinese if a mapping exists.
    static func translateOption(_ option: String) -> String {
        guard isChineseMode else { return option }
        if let zh = objectNames[option] { return zh }
        if let zh = objectNames[option.lowercased()] { return zh }
        return option
    }
}
