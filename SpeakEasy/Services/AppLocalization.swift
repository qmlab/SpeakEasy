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

    // MARK: - Learning Session

    static var learn: String { localized("Learn", zh: "学习") }
    static var storyMode: String { localized("Story Mode", zh: "故事模式") }
    static var playStory: String { localized("Play Story", zh: "开始故事") }
    static var scenes: String { localized("scenes", zh: "场景") }
    static var minutes: String { localized("min", zh: "分钟") }

    // MARK: - Session Setup

    static var stageSetup: String { localized("Stage Setup", zh: "关卡设置") }
    static var duration: String { localized("Duration", zh: "时长") }
    static var minutesUnit: String { localized("min", zh: "分钟") }
    static var startStage: String { localized("Start Stage", zh: "开始关卡") }
    static var howLong: String { localized("How long do you want to practice?", zh: "你想练习多久？") }

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
    static var loading: String { localized("Loading...", zh: "加载中...") }
    static var done: String { localized("Done", zh: "完成") }
    static var close: String { localized("Close", zh: "关闭") }

    // MARK: - Session Summary

    static var stageSummary: String { localized("Stage Complete!", zh: "关卡完成！") }
    static var tasksCompleted: String { localized("Tasks Completed", zh: "完成任务数") }
    static var accuracy: String { localized("Accuracy", zh: "正确率") }
    static var timeSpent: String { localized("Time Spent", zh: "用时") }
    static var returnHome: String { localized("Return Home", zh: "返回首页") }

    // MARK: - Drag Sort

    static var dragToSort: String { localized("Drag each item to the right group:", zh: "把每个物品拖到正确的组：") }
    static var checkSort: String { localized("Check", zh: "检查") }
}
