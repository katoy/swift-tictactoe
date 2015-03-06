//
//  ViewController.swift
//  tictactoe
//
//  Created by katoy on 2015/01/02.
//  Copyright (c) 2015年 Youichi Kato. All rights reserved.
//

// See https://www.youtube.com/watch?v=LkYpoRj-7hA
//     https://github.com/skipallmighty/SwiftTacToe

import UIKit

class ViewController: UIViewController {

    enum Player: Int {
        case
        none = 0,             // empty
        UserPlayer = 1,       // user
        ComputerPlayer = -1   // computer
    }
    var startPlayer: Player = .UserPlayer
    let PlayerImage = [1: "o", -1: "x"]
    var drawGameCount = 0
    var userWinCount = 0
    var computerWinCount = 0

    //  [0  1  2]
    //  [3  4  5]
    //  [6  7  8]
    @IBOutlet var image0: UIImageView!
    @IBOutlet var image1: UIImageView!
    @IBOutlet var image2: UIImageView!
    @IBOutlet var image3: UIImageView!
    @IBOutlet var image4: UIImageView!
    @IBOutlet var image5: UIImageView!
    @IBOutlet var image6: UIImageView!
    @IBOutlet var image7: UIImageView!
    @IBOutlet var image8: UIImageView!

    @IBOutlet var chooseO: UIButton!
    @IBOutlet var chooseX: UIButton!
    @IBOutlet var btnReset: UIButton! = nil
    @IBOutlet var userMessage: UILabel! = nil
    @IBOutlet var countWinUser: UILabel!
    @IBOutlet var countWinComputer: UILabel!
    @IBOutlet var countDraw: UILabel!


    var done = false
    var aiDeciding = false
    var cells: [Player] = []
    var plays: [Int] = []
    var play_count = 0
    var images = [UIImageView]()
    let lines = [
            [0, 1, 2],  // 横 1 行目
            [3, 4, 5],  //    2 行目
            [6, 7, 8],  //    3 行目
            [0, 3, 6],  // 縦 1 列目
            [1, 4, 7],  //    2 列目
            [2, 5, 8],  //    3 列目
            [0, 4, 8],  // 斜  \
            [2, 4, 6],  //     /
    ]
    var countWin = [
            Player.UserPlayer: 0,
            Player.ComputerPlayer: 0,
            Player.none: 0
    ]

    @IBAction func clickReset(sender: UIButton) {
        done = false
        userMessage.text = ""
        reset()
    }
    @IBAction func clickChoose(sender: UIButton) {
        if sender.tag == 1 {
            startPlayer = .UserPlayer
        } else {
            startPlayer = .ComputerPlayer
            aiTurn()
        }
    }
    func reset() {
        for imageView in images {
            imageView.image = nil
        }
        cells = [
            Player.none, Player.none, Player.none,
            Player.none, Player.none, Player.none,
            Player.none, Player.none, Player.none
        ]
        play_count = 0
        plays = [
            0, 0, 0,
            0, 0, 0,
            0, 0, 0
        ]
        userMessage.text       = ""
        countWinUser.text      = "\(userWinCount)"
        countWinComputer.text  = "\(computerWinCount)"
        countDraw.text         = "\(drawGameCount)"

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setImages()
        reset()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setImages() {
        images = [
            image0, image1, image2,
            image3, image4, image5,
            image6 ,image7 ,image8
        ]
        var tagIndex = 0
        for imageView in images {
            imageView.userInteractionEnabled = true
            imageView.tag = tagIndex
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "imageClicked:"))

            tagIndex += 1
        }
    }
    //Gesture Reocgnizer method
    func imageClicked(reco: UITapGestureRecognizer) {
        var imageViewTapped = reco.view as UIImageView

        println(cells[imageViewTapped.tag])
        //println(aiDeciding)
        //println("done = \(done)")

        if cells[imageViewTapped.tag] ==  Player.none && !aiDeciding && !done {
            setImageForPos(imageViewTapped.tag, player:.UserPlayer)
        }

        checkForWin()
        aiTurn()
    }

    func setImageForPos(tag: Int, player: Player){
        let playerMark = player == .UserPlayer ? "x" : "o"
        println("setting: \(player) mark \(playerMark) tag: \(tag)")
        cells[tag] = player
        images[tag].image = UIImage(named: playerMark)
    }

    func checkForWinLine(value: Player, posAry: [Int]) -> Bool {
        return cells[posAry[0]] == value && cells[posAry[1]] == value && cells[posAry[2]] == value
    }

    func checkForWin(){
        //first row across
        let who = ["コンピュータ": Player.ComputerPlayer, "あなた": Player.UserPlayer]
        for posAry in lines {
            for (key, player) in who {
                if checkForWinLine(player, posAry: posAry) {
                    userMessage.text = "\(key) の勝ちです！"
                    done = true;
                    if (player == .UserPlayer) {
                        userWinCount += 1
                    } else if (player == .ComputerPlayer) {
                        computerWinCount += 1
                    }
                    return
                }
            }
        }
    }

    func checkFor(value:Player, inList:[Int]) -> String {
        var conclusion = ""
        for cell in inList {
            if cells[cell] == value {
                conclusion += "1"
            } else if cells[cell] == .none {
                conclusion += "0"
            }
        }
        return conclusion
    }

    func rowCheck(#value:Player) -> (String, [Int])? {
        var acceptableFinds = ["011", "110", "101"]
        for line in lines {
            let result = checkFor(value, inList: line)
            let findPattern = find(acceptableFinds, result)
            if findPattern != nil {
                return (result, line)
            }
        }
        return nil
    }

    func isOccupied(spot:Int) -> Bool {
        println("occupied \(spot)")
        if cells[spot] != Player.none {
            return true
        }
        return false
    }

    func firstAvailable(#isCorner:Bool) -> Int? {
        var spots = isCorner ? [0,2,6,8] : [1,3,5,7]
        for spot in spots {
            println("checking \(spot)")
            if !isOccupied(spot) {
                println("not occupied \(spot)")
                return spot
            }
        }
        return nil
    }

    func whereToPlay(pattern:String, line:[Int]) -> Int {
        switch pattern {
        case "011":
            return line[0]
        case "101":
            return line[1]
        case "110":
            return line[2]
        default:
            line[1]
        }
        return line[1]
    }

    func aiTurn() {
        if done {
            return
        }
        aiDeciding = true

        // We (the computer) have two in a row
        if let result = rowCheck(value: Player.ComputerPlayer) {
            println("コンピュタ側が２目の列があります。")
            let whereToPlayResult = whereToPlay(result.0, line: result.1)
            if !isOccupied(whereToPlayResult) {
                setImageForPos(whereToPlayResult, player: .ComputerPlayer)
                aiDeciding = false
                checkForWin()
                return
            }
        }

        // They (the player) have two in a row
        if let result = rowCheck(value: Player.UserPlayer)? {
            let whereToPlayResult = whereToPlay(result.0, line: result.1)
            if !isOccupied(whereToPlayResult) {
                setImageForPos(whereToPlayResult, player: .ComputerPlayer)
                aiDeciding = false
                checkForWin()
                return
            }
        }

        // center
        if !isOccupied(4) {
            setImageForPos(4, player: .ComputerPlayer)
            aiDeciding = false
            checkForWin()
            return
        }

        // corner
        if let cornerAvailable = firstAvailable(isCorner: true){
            setImageForPos(cornerAvailable, player: .ComputerPlayer)
            aiDeciding = false
            checkForWin()
            return
        }

        // side
        if let sideAvailable = firstAvailable(isCorner: false){
            setImageForPos(sideAvailable, player: .ComputerPlayer)
            aiDeciding = false
            checkForWin()
            return
        }

        userMessage.text = "引き分けですね!"
        drawGameCount += 1
        reset()
        aiDeciding = false
    }
  }

