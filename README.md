# SpeakEasy

An iOS app designed to help non-verbal autistic children learn to speak and recognize objects through interactive flashcards and camera-based object recognition.

## Features

### Object Flashcards
- 60+ objects organized into 8 categories (Animals, Food, Toys, Household, Nature, Vehicles, Body Parts, Clothing)
- Large, colorful cards with SF Symbols icons
- Tap to hear pronunciation using text-to-speech

### Text-to-Speech
- Clear pronunciation of object names
- Adjustable speech rate for different learning speeds
- Powered by AVFoundation

### Camera Object Recognition
- Use the device camera or photo library to identify real-world objects
- Powered by Core ML and Vision framework with MobileNetV2
- Instant feedback with object name and pronunciation

### Progress Tracking
- Track learned objects with a star-based reward system
- Visual progress indicators for each category
- Celebration animations when learning new words
- Practice counter (3 practices = learned)

### Child-Friendly UI
- Large, colorful buttons designed for easy interaction
- Simple navigation with tab-based interface
- Engaging animations and visual feedback
- Bright, cheerful color scheme

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.0+

## Installation

1. Clone the repository
2. Open `SpeakEasy.xcodeproj` in Xcode
3. Build and run on a simulator or device

## Project Structure

```
SpeakEasy/
├── SpeakEasyApp.swift          # App entry point
├── Views/
│   ├── ContentView.swift       # Main tab view
│   ├── HomeView.swift          # Welcome screen with quick start
│   ├── CategoriesView.swift    # Category selection grid
│   ├── FlashcardListView.swift # Objects in a category
│   ├── FlashcardDetailView.swift # Individual flashcard
│   ├── CameraRecognitionView.swift # Camera/photo recognition
│   ├── ProgressView.swift      # Progress tracking
│   ├── SettingsView.swift      # App settings
│   └── CelebrationView.swift   # Celebration animation
├── Models/
│   ├── ObjectItem.swift        # Object data model
│   └── ObjectData.swift        # Sample object data
├── Services/
│   ├── SpeechService.swift     # Text-to-speech service
│   ├── ProgressManager.swift   # Progress tracking
│   └── CameraService.swift     # Camera and ML service
└── Assets.xcassets/            # App assets
```

## Privacy

The app requests the following permissions:
- **Camera**: For real-time object recognition
- **Photo Library**: To select images for object recognition

All processing is done on-device using Core ML.

## License

MIT License
