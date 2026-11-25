#if MapLibreDeveloper
    import Mockable
#endif

#if MapLibreDeveloper
    @Mockable
#endif
protocol CameraUpdateRunning: AnyObject {
    @MainActor var isRunning: Bool { get }
    @MainActor func run(_ update: @escaping @MainActor () -> Void)
    @MainActor func finish()
    @MainActor func cancel()
}
