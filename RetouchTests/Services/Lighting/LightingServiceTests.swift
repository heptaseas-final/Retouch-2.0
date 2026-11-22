import Testing
@testable import Retouch

@MainActor
struct LightingServiceTests {
    func makeService() -> LightingService {
        let engine = LightingEngine(camera: CameraSessionManager(), config: LightingConfig())
        return LightingService(engine: engine, brightnessController: BrightnessController(), isAppActive: true)
    }

    @Test func setAutoResetsBrightnessAndColor() {
        let service = makeService()
        service.setBrightness(0.8)
        service.select(.warm)
        #expect(service.isAutoBrightness == false)
        #expect(service.selectedColor == .warm)

        service.setAuto(true)

        #expect(service.isAutoBrightness == true)
        #expect(service.selectedColor == .white)
        #expect(service.filterColor == nil)
    }

    @Test func lightModeOffReturnsToAuto() {
        let service = makeService()
        service.setLightMode(.on(.cool))
        #expect(service.selectedColor == .cool)
        #expect(service.brightness == 1)

        service.setLightMode(.off)

        #expect(service.isAutoBrightness == true)
        #expect(service.selectedColor == .white)
    }

    @Test func lightButtonRampsScreenBrightnessInsteadOfJumping() {
        let controller = BrightnessController()
        controller.set(0.3)
        let engine = LightingEngine(camera: CameraSessionManager(), config: LightingConfig())
        let service = LightingService(engine: engine, brightnessController: controller, isAppActive: true)

        service.setLightMode(.on(.white))

        #expect(controller.target == 1)
        #expect(controller.current == 0.3)
    }
}
