// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Cocoa

class TapModel: NSObject {
    @objc dynamic var running: Bool = false
    
}

class ViewController: NSViewController {
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var tapButton: NSButton!
    @IBOutlet weak var tapsLabel: NSTextField!
    @IBOutlet weak var highscoreLabel: NSTextField!
    @IBOutlet weak var infoLabel: NSTextField!

    let timeInterval: TimeInterval = 5
    var running: Bool = false
    var intervalTimer: Timer?
    var timeoutTimer: Timer?
    var recoveryTimer: Timer?
    var t0: Date = Date()
    var deltas: [TimeInterval] = []
    var lastTap: Date = Date()
    var variance: Double = 0 {
        didSet {

        }
    }
    var stddev: Double = 0 {
        didSet {

        }
    }
    var meanDelta: Double = 0 {
        didSet {

        }
    }
    var highscore: Int = 0 {
        didSet {
            UserDefaults.standard.set(highscore, forKey: "highscore")
            highscoreLabel.stringValue = "\(highscore)"
        }
    }

    @objc func refresh(_ sender: Any) {
        let dt: TimeInterval = -t0.timeIntervalSinceNow
        progressIndicator.doubleValue = progressIndicator.maxValue - dt
    }

    @objc func timedOut(_ sender: Any) {
        intervalTimer?.invalidate()
        timeoutTimer?.invalidate()
        if deltas.count > highscore {
            highscore = deltas.count
        }
        running = false
        tapButton.isEnabled = false
        tapButton.title = "Recovering …"
        progressIndicator.doubleValue = progressIndicator.minValue
        progressIndicator.stopAnimation(nil)
        recoveryTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(recover), userInfo: nil, repeats: false)
        calcStatistics()
    }

    func calcStatistics() {
        guard deltas.count > 2 else { return }
        debugPrint(deltas)
        let total = deltas.reduce(0, +)
        let max_delta = deltas.max()!
        let min_delta = deltas.min()!
        meanDelta = total / Double(deltas.count)
        let squared_diffs = deltas.map { value -> Double in
            let diff = value - self.meanDelta
            return diff * diff
        }
        debugPrint(squared_diffs)
        variance = squared_diffs.reduce(0, +) / Double(deltas.count - 1)
        stddev = sqrt(variance)
        debugPrint(deltas.count, meanDelta, max_delta, min_delta, variance, stddev)
    }

    func reset() {
        running = false
        tapButton.title = "Start"
        tapsLabel.stringValue = "0"
        progressIndicator.doubleValue = progressIndicator.maxValue
        infoLabel.stringValue =
        """
        How often can you click in \(String(format: "%.1f", timeInterval)) seconds?
        The countdown starts immediately after pressing the \(tapButton.title) button.
        """
    }

    @objc func recover(_ sender: Any) {
        tapsLabel.stringValue = "\(deltas.count)"
        tapButton.isEnabled = true
        reset()
    }

    fileprivate func launchGame() {
        progressIndicator.minValue = 0
        progressIndicator.maxValue = timeInterval
        progressIndicator.startAnimation(nil)
        tapButton.title = "Tap me as fast as possible"
        running = true
        deltas = []
        deltas.reserveCapacity(50)
        intervalTimer = Timer.scheduledTimer(timeInterval: 1.0 / 120, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        timeoutTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(timedOut), userInfo: nil, repeats: false)
        t0 = Date()
        lastTap = t0
    }

    @IBAction func tapped(_ sender: Any) {
        if running {
            let dt = -lastTap.timeIntervalSinceNow
            deltas.append(dt)
            lastTap = Date()
            tapsLabel.stringValue = "\(deltas.count)"
        } else {
            launchGame()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        highscore = UserDefaults.standard.integer(forKey: "highscore")
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    override func viewDidAppear() {
        reset()
    }

    override func mouseDown(with event: NSEvent) {
        if running {
            let dt = -lastTap.timeIntervalSinceNow
            deltas.append(dt)
            lastTap = Date()
            tapsLabel.stringValue = "\(deltas.count)"
        }
    }
}

