//
//  SpeechServiceTests.swift
//  SpeakEasyTests
//
//  Tests for speech recognition with mock sound input for simulator testing
//

import XCTest
@testable import SpeakEasy

final class SpeechServiceTests: XCTestCase {
    var speechService: SpeechService!
    var mockProvider: MockSpeechRecognitionProvider!
    
    override func setUp() {
        super.setUp()
        speechService = SpeechService()
        mockProvider = MockSpeechRecognitionProvider()
        speechService.mockProvider = mockProvider
    }
    
    override func tearDown() {
        speechService = nil
        mockProvider = nil
        super.tearDown()
    }
    
    func testPerfectMatch() {
        let expectation = XCTestExpectation(description: "Perfect match rating")
        mockProvider.mockText = "apple"
        mockProvider.mockDelay = 0.1
        
        speechService.startListening(targetWord: "apple") { rating in
            XCTAssertEqual(rating, 5.0, accuracy: 0.01, "Perfect match should give 5.0 stars")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testCaseInsensitiveMatch() {
        let expectation = XCTestExpectation(description: "Case insensitive match")
        mockProvider.mockText = "APPLE"
        mockProvider.mockDelay = 0.1
        
        speechService.startListening(targetWord: "apple") { rating in
            XCTAssertEqual(rating, 5.0, accuracy: 0.01, "Case insensitive match should give 5.0 stars")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testPartialMatch() {
        let expectation = XCTestExpectation(description: "Partial match rating")
        mockProvider.mockText = "app"
        mockProvider.mockDelay = 0.1
        
        speechService.startListening(targetWord: "apple") { rating in
            XCTAssertGreaterThan(rating, 2.0, "Partial match should give more than 2 stars")
            XCTAssertLessThan(rating, 5.0, "Partial match should give less than 5 stars")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testContainsTargetWord() {
        let expectation = XCTestExpectation(description: "Contains target word")
        mockProvider.mockText = "I see an apple"
        mockProvider.mockDelay = 0.1
        
        speechService.startListening(targetWord: "apple") { rating in
            XCTAssertGreaterThan(rating, 3.0, "Containing target word should give more than 3 stars")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testCompletelyWrongWord() {
        let expectation = XCTestExpectation(description: "Wrong word rating")
        mockProvider.mockText = "banana"
        mockProvider.mockDelay = 0.1
        
        speechService.startListening(targetWord: "apple") { rating in
            XCTAssertLessThan(rating, 2.0, "Completely wrong word should give less than 2 stars")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testEmptyRecognition() {
        let expectation = XCTestExpectation(description: "Empty recognition")
        mockProvider.mockText = ""
        mockProvider.mockDelay = 0.1
        
        speechService.startListening(targetWord: "apple") { rating in
            XCTAssertEqual(rating, 0.0, accuracy: 0.01, "Empty recognition should give 0 stars")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testSimilarSoundingWord() {
        let expectation = XCTestExpectation(description: "Similar sounding word")
        mockProvider.mockText = "appel"
        mockProvider.mockDelay = 0.1
        
        speechService.startListening(targetWord: "apple") { rating in
            XCTAssertGreaterThan(rating, 3.5, "Similar sounding word should give more than 3.5 stars")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testMultiWordObject() {
        let expectation = XCTestExpectation(description: "Multi-word object")
        mockProvider.mockText = "teddy bear"
        mockProvider.mockDelay = 0.1
        
        speechService.startListening(targetWord: "teddy bear") { rating in
            XCTAssertEqual(rating, 5.0, accuracy: 0.01, "Perfect multi-word match should give 5.0 stars")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testLevenshteinDistance() {
        XCTAssertEqual(speechService.calculateRating(recognized: "apple", target: "apple"), 5.0, accuracy: 0.01)
        XCTAssertEqual(speechService.calculateRating(recognized: "", target: "apple"), 0.0, accuracy: 0.01)
        
        let rating1 = speechService.calculateRating(recognized: "aple", target: "apple")
        XCTAssertGreaterThan(rating1, 3.5, "One character difference should give high rating")
        
        let rating2 = speechService.calculateRating(recognized: "xyz", target: "apple")
        XCTAssertLessThan(rating2, 1.5, "Completely different word should give low rating")
    }
    
    func testRecognizedTextIsStored() {
        let expectation = XCTestExpectation(description: "Recognized text stored")
        mockProvider.mockText = "hello world"
        mockProvider.mockDelay = 0.1
        
        speechService.startListening(targetWord: "hello") { _ in
            XCTAssertEqual(self.speechService.recognizedText, "hello world")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testLastRatingIsStored() {
        let expectation = XCTestExpectation(description: "Last rating stored")
        mockProvider.mockText = "apple"
        mockProvider.mockDelay = 0.1
        
        speechService.startListening(targetWord: "apple") { rating in
            XCTAssertEqual(self.speechService.lastRating, rating)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}

final class ProgressManagerTests: XCTestCase {
    var progressManager: ProgressManager!
    
    override func setUp() {
        super.setUp()
        progressManager = ProgressManager()
        progressManager.resetProgress()
    }
    
    override func tearDown() {
        progressManager.resetProgress()
        progressManager = nil
        super.tearDown()
    }
    
    func testRecordRating() {
        progressManager.recordRating(id: "test-object-1", name: "Apple", rating: 3.5)
        
        XCTAssertEqual(progressManager.lastRatingForId("test-object-1"), 3.5, accuracy: 0.01)
        XCTAssertEqual(progressManager.practiceCountForId("test-object-1"), 1)
    }
    
    func testHighRatingMarksAsLearned() {
        progressManager.recordRating(id: "test-object-2", name: "Banana", rating: 4.5)
        
        XCTAssertTrue(progressManager.isLearnedById("test-object-2"), "Rating >= 4.0 should mark as learned")
    }
    
    func testLowRatingDoesNotMarkAsLearned() {
        progressManager.recordRating(id: "test-object-3", name: "Car", rating: 2.5)
        
        XCTAssertFalse(progressManager.isLearnedById("test-object-3"), "Rating < 4.0 should not mark as learned")
    }
    
    func testMultipleRatingsUpdateLastRating() {
        progressManager.recordRating(id: "test-object-4", name: "Dog", rating: 2.0)
        progressManager.recordRating(id: "test-object-4", name: "Dog", rating: 3.5)
        progressManager.recordRating(id: "test-object-4", name: "Dog", rating: 4.8)
        
        XCTAssertEqual(progressManager.lastRatingForId("test-object-4"), 4.8, accuracy: 0.01)
        XCTAssertEqual(progressManager.practiceCountForId("test-object-4"), 3)
    }
    
    func testInfiniteRetries() {
        for i in 1...10 {
            progressManager.recordRating(id: "test-object-5", name: "Cat", rating: 1.0)
            XCTAssertEqual(progressManager.practiceCountForId("test-object-5"), i)
        }
    }
}

final class StarRatingCalculationTests: XCTestCase {
    var speechService: SpeechService!
    
    override func setUp() {
        super.setUp()
        speechService = SpeechService()
    }
    
    override func tearDown() {
        speechService = nil
        super.tearDown()
    }
    
    func testFractionalStars() {
        let rating1 = speechService.calculateRating(recognized: "appl", target: "apple")
        XCTAssertGreaterThan(rating1, 4.0)
        XCTAssertLessThan(rating1, 5.0)
        
        let rating2 = speechService.calculateRating(recognized: "ap", target: "apple")
        XCTAssertGreaterThan(rating2, 2.0)
        XCTAssertLessThan(rating2, 4.0)
    }
    
    func testRatingRange() {
        let testCases = [
            ("apple", "apple", 5.0, 5.0),
            ("", "apple", 0.0, 0.0),
            ("a", "apple", 0.0, 2.0),
            ("appl", "apple", 4.0, 5.0),
            ("xyz", "apple", 0.0, 1.5)
        ]
        
        for (recognized, target, minRating, maxRating) in testCases {
            let rating = speechService.calculateRating(recognized: recognized, target: target)
            XCTAssertGreaterThanOrEqual(rating, minRating, "Rating for '\(recognized)' vs '\(target)' should be >= \(minRating)")
            XCTAssertLessThanOrEqual(rating, maxRating, "Rating for '\(recognized)' vs '\(target)' should be <= \(maxRating)")
        }
    }
}
