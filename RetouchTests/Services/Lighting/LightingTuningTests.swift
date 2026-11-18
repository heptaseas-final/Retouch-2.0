//
//  LightingTuningTests.swift
//  Retouch
//
//  Created by Davin P on 18/11/26.
//


import Testing
@testable import Retouch

@MainActor
struct LightingTuningTests {
    @Test func unchangedClosenessIsNotPublished() {
        #expect(!LightingTuning.closenessNeedsPublish(from: 0.4, to: 0.4))
    }

    @Test func tinyClosenessChangeIsNotPublished() {
        #expect(!LightingTuning.closenessNeedsPublish(from: 0.4, to: 0.405))
    }

    @Test func stepSizedClosenessChangeIsPublished() {
        #expect(LightingTuning.closenessNeedsPublish(from: 0.4, to: 0.4 + LightingTuning.closenessPublishStep))
    }

    @Test func reachingEitherEndIsAlwaysPublished() {
        #expect(LightingTuning.closenessNeedsPublish(from: 0.004, to: 0))
        #expect(LightingTuning.closenessNeedsPublish(from: 0.996, to: 1))
    }
}