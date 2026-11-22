extension OnboardingStep {
    var analyticsName: String {
        switch self {
        case .placeHand: "place_hand"
        case .retouchKnows: "retouch_knows"
        case .noNeedToTap: "no_need_to_tap"
        case .swipeModes: "swipe_modes"
        case .zoomedOnArea: "zoomed_on_area"
        case .needLight: "need_light"
        case .tapForWarm: "tap_for_warm"
        case .tapForCool: "tap_for_cool"
        case .tapForWhite: "tap_for_white"
        case .tapToTurnOff: "tap_to_turn_off"
        case .overallIntro: "overall_intro"
        case .overallCheck: "overall_check"
        case .tapRecording: "tap_recording"
        case .reviewRecording: "review_recording"
        case .done: "done"
        }
    }
}
