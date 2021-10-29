//
//  ViewController.swift
//  scouting1072-recharge-ios
//
//  Created by Aydin Tiritoglu on 3/7/20.
//  Copyright © 2020 Aydin Tiritoglu. All rights reserved.
//

import UIKit
import AVFoundation

struct Cycle {
    var x: Int
    var y: Int
    var inner: Int
    var outer: Int
    var lower: Int
    var drops: Int
}

func stringToBinaryString(_ myString: String) -> String {
    let characterArray = [Character](myString)
    let asciiArray = characterArray.map { String($0).unicodeScalars.first!.value }
    let binaryArray = asciiArray.map ({ String($0, radix: 2)})
    return binaryArray.reduce("", {$0 + " " + $1})
}

func genInt(fromBitArray array: [Int]) -> Int {
    var n = 0
    for i in 0...array.count - 1 {
        n += array[i] << ((array.count - 1) - i)
    }
    return n
}

func genInt(fromBitArray slice: ArraySlice<Int>) -> Int {
    return genInt(fromBitArray: Array(slice))
}

let commentEncoding: [String: String] = ["100": " ", "010": ",", "001": ".", "1011": "e", "0001": "t", "11111": "a", "11100": "o", "11010": "n", "11001": "i", "10101": "s", "10100": "r", "01111": "h", "00001": "d", "00000": "l", "011101": "u", "011100": "c", "011010": "m", "011001": "f", "011000": "w", "1111011": "g", "1111010": "9", "1111001": "2", "1111000": "1", "1110111": "4", "1110110": "3", "1110101": "6", "1110100": "5", "1101111": "8", "1101110": "7", "1101101": "0", "1101100": "y", "1100001": "p", "1100000": "b", "0110110": "v", "11000101": ";", "11000100": "(", "01101111": "-", "01101110": "k", "1100011100": "?", "110001101": "!", "110001100": ":", "11000111111": "x", "11000111110": "j", "11000111101": "q", "11000111100": "z", "1100011101": "%"]

let usernames = ["22gloriaz", "21ankitak", "22kateo", "22connorw", "22dennisg", "21chloea", "22shounakg", "22pranavg", "22anirudhk", "22ethanh", "22chiragk", "22aidanl", "22alexl", "21harib", "21angelac", "22ethanc", "22zachc", "22arjund", "22alicef", "20finnf", "22adheetg", "22prakritj", "21arthurj", "22angiej", "23lauriej", "20jatink", "22shahzebl", "23willl", "23garyd", "22anishp", "23adap", "22anishkar", "20sanjayr", "23ariyar", "20rohans", "21ethans", "21aydint", "22michaelt", "22pranavv", "21aditiv", "22aimeew", "22alinay", "anand", "kaitlin", "rachel", "guest"]

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSizeTransform = CGAffineTransform()
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var bitArrays: [[Int]] = [[], [], [], [], [], [], [], []]
    var scanned: Set<Int> = []
    var ready = false
    var loc = false
    var player = AVAudioPlayer()
    var csvURL = URL(fileURLWithPath: "")

    @IBAction func scanReady(_ sender: Any) {
        ready = true
        print("ready")
    }

    @IBAction func share(_ sender: Any) {
        let shareSheet = UIActivityViewController(activityItems: [csvURL], applicationActivities: nil)
        shareSheet.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            if completed {
                let alertController = UIAlertController(title: "PogChamp", message: "Data transferred successfully.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertController, animated: true)
            } else if let activityError = activityError {
                let alertController = UIAlertController(title: "MonkaS", message: activityError.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertController, animated: true)
            }
        }
        self.present(shareSheet, animated: true)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if !ready { return }
        if metadataObjects.count == 0 { return }
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        let qrCode = metadataObj.descriptor as? CIQRCodeDescriptor

        if let bytes = qrCode?.errorCorrectedPayload, let version = qrCode?.symbolVersion {
            var lengthLength = 0
            switch version {
            case 1...9:
                lengthLength = 8
            case 10...40:
                lengthLength = 16
            default: break
            }
            var bitArray: [Int] = []
            let bitString = stringToBinaryString(String(data: bytes, encoding: .isoLatin1)!)
            for b in bitString.components(separatedBy: " ") {
                let byte = String(repeating: "0", count: 8 - b.count) + b
                for c in byte {
                    bitArray.append(Int(String(c))!)
                }
            }
            let prefix = 12 // honestly, screw eci
            let bitCount = genInt(fromBitArray: bitArray[prefix..<lengthLength + prefix]) * 8
            let slicedBitArray = Array(bitArray[lengthLength + prefix..<lengthLength + prefix + bitCount])
            let qrNumber = genInt(fromBitArray: slicedBitArray[2...4])
            let expected = genInt(fromBitArray: slicedBitArray[5...7])
            if qrNumber == 0 {
                loc = slicedBitArray[8] == 1
            }
            if !scanned.contains(qrNumber) {
                print("bitCount: \(bitCount)")
            }
            print(slicedBitArray.description.components(separatedBy: ", ").joined().dropFirst().dropLast())
            scanned.insert(qrNumber)
            bitArrays[qrNumber] = Array(slicedBitArray.dropFirst(qrNumber == 0 ? 9 : 8))
            var shouldProceed = true
            for i in 0...expected {
                if !scanned.contains(i) {
                    shouldProceed = false
                    break
                }
            }
            if shouldProceed {
                ready = false
                let fullBitArray = Array(bitArrays.joined())
                print(fullBitArray.description.components(separatedBy: ", ").joined().dropFirst().dropLast())
                if loc {
                    parseLocationData(fullBitArray)
                } else {
                    parseGamePieceData(fullBitArray)
                }
                scanned = []
                bitArrays = [[], [], [], [], [], [], [], []]
                let random = Int.random(in: 1...100)
                let file = random > 5 ? "r2" : "yoda"
                let path = Bundle.main.path(forResource: file, ofType: "mp3")!
                let url = URL(fileURLWithPath: path)
                do {
                    player = try AVAudioPlayer(contentsOf: url)
                    player.play()
                } catch {
                    print("couldn't play sound")
                }
            }
        }
    }

    func parseGamePieceData(_ bitArray: [Int]) {
        // The following variables are generated because this would be a massive pain to rewrite every time we change something
        let teamNumber = genInt(fromBitArray: bitArray[0...2])
        let matchNumber = genInt(fromBitArray: bitArray[3...9])
        let scouterID = genInt(fromBitArray: bitArray[10...15])
        let autonBottom = genInt(fromBitArray: bitArray[16...19])
        let autonMiddle = genInt(fromBitArray: bitArray[20...23])
        let autonTop = genInt(fromBitArray: bitArray[24...27])
        let bottom = genInt(fromBitArray: bitArray[28...33])
        let middle = genInt(fromBitArray: bitArray[34...39])
        let top = genInt(fromBitArray: bitArray[40...45])
        let brickedTime = genInt(fromBitArray: bitArray[46...52])
        let defenseTime = genInt(fromBitArray: bitArray[53...59])
        let canSpin = genInt(fromBitArray: bitArray[60...60]) == 1
        let rotationControl = genInt(fromBitArray: bitArray[61...61]) == 1
        let positionControl = genInt(fromBitArray: bitArray[62...62]) == 1
        let crossedInitialLine = genInt(fromBitArray: bitArray[63...63]) == 1
        let droppedPieces = genInt(fromBitArray: bitArray[64...67])
        let climbLocation = genInt(fromBitArray: bitArray[68...70])
        let controlPanelQuick = genInt(fromBitArray: bitArray[71...71]) == 1
        let controlPanelFirstTry = genInt(fromBitArray: bitArray[72...72]) == 1
        let climbIsRobust = genInt(fromBitArray: bitArray[73...73]) == 1
        let defenseIsEffective = genInt(fromBitArray: bitArray[74...74]) == 1
        let driverIsGood = genInt(fromBitArray: bitArray[75...75]) == 1
        let robotIsStable = genInt(fromBitArray: bitArray[76...76]) == 1
        // end of generation
        var i = 0
        var t = ""
        var comments = ""
        for b in bitArray[77..<bitArray.count] {
            t.append(String(b))
            if let c = commentEncoding[t] {
                if c == "(" && i == 1 {
                    comments.append(")")
                    i = 0
                } else {
                    if c == "(" {
                        i = 1
                    }
                    comments.append(c)
                }
                t = ""
            }
        }
        
        let commentSplit = comments.components(separatedBy: "%")
        let csvString = "\(teamNumber),\(matchNumber),\(usernames[scouterID]),\(autonBottom),\(autonMiddle),\(autonTop),\(bottom),\(middle),\(top),\(brickedTime),\(defenseTime),\(canSpin),\(rotationControl),\(positionControl),\(crossedInitialLine),\(droppedPieces),\(climbLocation),\(controlPanelQuick),\(controlPanelFirstTry),\(climbIsRobust),\(defenseIsEffective),\(driverIsGood),\(robotIsStable),\"\(commentSplit[0])\",\"\(commentSplit.count > 1 ? commentSplit[1] : "")\"\n"
        print(csvString)
        write(csvString)
    }

    func parseLocationData(_ bitArray: [Int]) {
        // The following variables are generated because this would be a massive pain to rewrite every time we change something
        let teamNumber = genInt(fromBitArray: bitArray[0...2])
        let matchNumber = genInt(fromBitArray: bitArray[3...9])
        let scouterID = genInt(fromBitArray: bitArray[10...15])
        let numberOfAutonCycles = genInt(fromBitArray: bitArray[16...17])
        var autonCycleArray: [Cycle] = []
        var newStart = 0
        for i in 0..<numberOfAutonCycles {
            let start = 18 + i * 19
            let x = genInt(fromBitArray: bitArray[start...start + 3])
            let y = genInt(fromBitArray: bitArray[start + 4...start + 6])
            let inner = genInt(fromBitArray: bitArray[start + 7...start + 9])
            let outer = genInt(fromBitArray: bitArray[start + 10...start + 12])
            let lower = genInt(fromBitArray: bitArray[start + 13...start + 15])
            let drops = genInt(fromBitArray: bitArray[start + 16...start + 18])
            let cycle = Cycle(x: x, y: y, inner: inner, outer: outer, lower: lower, drops: drops)
            autonCycleArray.append(cycle)
            newStart = 18 + (i + 1) * 19
        }
        let numberOfCycles = genInt(fromBitArray: bitArray[newStart...newStart + 4])
        var cycleArray: [Cycle] = []
        let newStartCopy = newStart + 5
        for i in 0..<numberOfCycles {
            let start = newStartCopy + i * 19
            let x = genInt(fromBitArray: bitArray[start...start + 3])
            let y = genInt(fromBitArray: bitArray[start + 4...start + 6])
            let inner = genInt(fromBitArray: bitArray[start + 7...start + 9])
            let outer = genInt(fromBitArray: bitArray[start + 10...start + 12])
            let lower = genInt(fromBitArray: bitArray[start + 13...start + 15])
            let drops = genInt(fromBitArray: bitArray[start + 16...start + 18])
            let cycle = Cycle(x: x, y: y, inner: inner, outer: outer, lower: lower, drops: drops)
            cycleArray.append(cycle)
            newStart = newStartCopy + (i + 1) * 19
        }
        let brickedTime = genInt(fromBitArray: bitArray[newStart + 0...newStart + 6])
        let defenseTime = genInt(fromBitArray: bitArray[newStart + 7...newStart + 13])
        let canSpin = genInt(fromBitArray: bitArray[newStart + 14...newStart + 14]) == 1
        let rotationControl = genInt(fromBitArray: bitArray[newStart + 15...newStart + 15]) == 1
        let positionControl = genInt(fromBitArray: bitArray[newStart + 16...newStart + 16]) == 1
        let crossedInitialLine = genInt(fromBitArray: bitArray[newStart + 17...newStart + 17]) == 1
        let climbLocation = genInt(fromBitArray: bitArray[newStart + 18...newStart + 20])
        let controlPanelQuick = genInt(fromBitArray: bitArray[newStart + 21...newStart + 21]) == 1
        let controlPanelFirstTry = genInt(fromBitArray: bitArray[newStart + 22...newStart + 22]) == 1
        let climbIsRobust = genInt(fromBitArray: bitArray[newStart + 23...newStart + 23]) == 1
        let defenseIsEffective = genInt(fromBitArray: bitArray[newStart + 24...newStart + 24]) == 1
        let driverIsGood = genInt(fromBitArray: bitArray[newStart + 25...newStart + 25]) == 1
        let robotIsStable = genInt(fromBitArray: bitArray[newStart + 26...newStart + 26]) == 1
        // end of generation
        var i = 0
        var t = ""
        var comments = ""
        for b in bitArray[newStart + 27..<bitArray.count] {
            t.append(String(b))
            if let c = commentEncoding[t] {
                if c == "(" && i == 1 {
                    comments.append(")")
                    i = 0
                } else {
                    if c == "(" {
                        i = 1
                    }
                    comments.append(c)
                }
                t = ""
            }
        }
        let commentSplit = comments.components(separatedBy: "%")
        let csvString = "\(teamNumber),\(matchNumber),\(usernames[scouterID]),\(numberOfAutonCycles),\(numberOfCycles),\(brickedTime),\(defenseTime),\(canSpin),\(rotationControl),\(positionControl),\(crossedInitialLine),\(climbLocation),\(controlPanelQuick),\(controlPanelFirstTry),\(climbIsRobust),\(defenseIsEffective),\(driverIsGood),\(robotIsStable),\"\(commentSplit[0])\",\"\(commentSplit.count > 1 ? commentSplit[1] : "")\"\n"
        print(csvString)
        write(csvString)
    }

    func write(_ csvString: String) {
        if let csvFile = FileHandle(forWritingAtPath: csvURL.path) {
            csvFile.seekToEndOfFile()
            csvFile.write(csvString.data(using: .utf8)!)
            csvFile.closeFile()
        } else {
            do {
                try csvString.data(using: .utf8)!.write(to: csvURL)
            } catch {
                let alertController = UIAlertController(title: "iOS, that's real BabyRage", message: "Can't create the data CSV. This is a very serious problem and should never happen; if it does, alert Aydin immediately.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                print("failed to write file")
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        captureSession.startRunning()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            let alertController = UIAlertController(title: "MonkaS", message: "Can't read the data CSV. This is a very serious problem and should never happen; if it does, alert Aydin immediately.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        csvURL = documentsURL.appendingPathComponent("data.csv")
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: AVMediaType.video, position: .back)
        let input = try! AVCaptureDeviceInput(device: deviceDiscoverySession.devices.first!)
        captureSession.addInput(input)
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = [.qr]
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.frame = view.layer.bounds
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(videoPreviewLayer!)
    }
}
