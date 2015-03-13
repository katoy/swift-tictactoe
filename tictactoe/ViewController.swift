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
    @IBOutlet weak var chooseRandom: UIButton!
    @IBOutlet weak var chooseNormal: UIButton!
    @IBOutlet weak var chooseMinMax: UIButton!
    @IBOutlet weak var computerBrain: UILabel!
    @IBOutlet weak var btnUndo: UIButton!

    var done = false
    var aiDeciding = false
    var cells: [Player] = []
    var v_cells: [Player] = []
    var plays: [Int] = []
    var play_count = 0
    var images = [UIImageView]()

    let aiBrains = [
        (brain: aiHandRandom, name: "ランダム"),     // 0
        (brain: aiHandBasic,  name: "定石"),        // 1
        (brain: aiHandMinmax, name: "Ｍｉｎmａｘ"),  // 2
    ]
    var aiBrain = aiHandRandom

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
        done = false
        reset()
        if sender.tag == 1 {
            startPlayer = .UserPlayer
        } else {
            startPlayer = .ComputerPlayer
            aiTurn(aiBrain(self))
        }
    }

    @IBAction func chooseAiBrain(sender: UIButton) {
        let kind = sender.tag
        aiBrain = aiBrains[kind].brain
        computerBrain.text = sender.titleLabel?.text
    }

    @IBAction func clickBtnUndo(sender: AnyObject) {
        undoGame()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        resetImages()
        reset()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func get_enemy_player(player:Player) -> Player {
        return (player == Player.ComputerPlayer) ? Player.UserPlayer : Player.ComputerPlayer
    }
    // See http://stackoverflow.com/questions/24026510/how-do-i-shuffle-an-array-in-swift
    func shuffle<C: MutableCollectionType where C.Index == Int>(var list: C) -> C {
        let count = countElements(list)
        for i in 0..<(count - 1) {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            swap(&list[i], &list[j])
        }
        return list
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
        userMessage.text = ""
        updateScore()
    }

    // 最後の手を１つ取り消す。
    func undoOnePlay() -> Player? {
        if play_count == 0 {
            return nil
        }

        let idx = play_count - 1
        let hand = plays[idx]
        let who = cells[hand]

        images[hand].image = nil
        cells[hand] = Player.none
        plays[idx] = 0
        play_count -= 1
        return who
    }

    // 一つ前の user の手までを取り消す。
    func undoGame() {
        // スコアの値を戻す
        if let winer = checkGame(cells) {
            countWin[winer] = countWin[winer]! - 1
        } else if has_empty_cell(cells) == false {
            countWin[.none] = countWin[.none]! - 1
        }
        updateScore()

        // 手を戻す
        if let who = undoOnePlay() {
            if who == Player.ComputerPlayer {
                undoOnePlay()
            }
        }
        done = false
        userMessage.text = ""
    }

    func updateScore() {
        countWinUser.text      = "\(countWin[.UserPlayer]!)"
        countWinComputer.text  = "\(countWin[.ComputerPlayer]!)"
        countDraw.text         = "\(countWin[.none]!)"
    }

    func resetImages() {
        images = [
            image0, image1, image2,
            image3, image4, image5,
            image6 ,image7 ,image8
        ]

        for (tagIndex, imageView) in enumerate(images) {
            imageView.userInteractionEnabled = true
            imageView.tag = tagIndex
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "imageClicked:"))
        }
    }
    //Gesture Reocgnizer method
    func imageClicked(reco: UITapGestureRecognizer) {
        var imageViewTapped = reco.view as UIImageView

        //println(cells[imageViewTapped.tag])
        //println(aiDeciding)
        //println("done = \(done)")

        if cells[imageViewTapped.tag] == Player.none && !aiDeciding && !done {
            setImageForPos(imageViewTapped.tag, player:.UserPlayer)
            checkForWin()
            aiTurn(aiBrain(self))
        }
    }


    func setImageForPos(tag: Int, player: Player){
        let playerMark = player == .UserPlayer ? "x" : "o"
        // println("setting: \(player) mark \(playerMark) tag: \(tag)")
        cells[tag] = player
        images[tag].image = UIImage(named: playerMark)
        plays[play_count] = tag
        play_count += 1
    }

    // 与えられた盤面の勝者を返す。
    func checkGame(cells: [Player]) -> Player? {
        for posAry in lines {
            let who = cells[posAry[0]]
            if who != .none && who == cells[posAry[1]] && who == cells[posAry[2]] {
                return who
            }
        }
        return nil // 勝負はまだ決まっていない。
    }

    // 空きのマスがあるかを調べる。
    func has_empty_cell(cells: [Player]) -> Bool {
        for c in cells {
            if c == Player.none {
                return true
            }
        }
        return false
        //let idx = find(cells, Player.none)
        //return idx != nil
    }
    func checkForWin() {
        if done {
            return
        }

        let names = [Player.ComputerPlayer: "コンピュータ", Player.UserPlayer: "あなた"]
        let winer = checkGame(cells)
        // 勝負がついている
        if let winer = checkGame(cells) {
            userMessage.text = "\(names[winer]!) の勝ちです！"
            done = true
            countWin[winer] = 1 + countWin[winer]!
        } else if has_empty_cell(cells) {
            // 空いているマス目があれば、ゲームは継続する
            return
        } else {
            // 引き分け
            done = true
            userMessage.text = "引き分けですね!"
            countWin[.none] = 1 + countWin[.none]!
        }
        updateScore()
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

    func rowCheck(player:Player) -> Int? {
        let acceptableFinds = ["011", "110", "101"]
        for line in lines {
            let result = checkFor(player, inList: line)
            if let findPattern = find(acceptableFinds, result) {
                return whereToPlay(result, line: line)
            }
        }
        return nil
    }

    func isOccupied(spot:Int) -> Bool {
        // println("occupied \(spot)")
        if cells[spot] != Player.none {
            return true
        }
        return false
    }


    func firstAvailable(#isCorner:Bool) -> Int? {
        let spots = shuffle(isCorner ? [0,2,6,8] : [1,3,5,7])
        for spot in spots {
            // println("checking \(spot)")
            if !isOccupied(spot) {
                // println("not occupied \(spot)")
                return spot
            }
        }
        return nil
    }

    func whereToPlay(pattern:String, line:[Int]) -> Int? {
        // pattern 中の 0 の位置に相当する line の値を返す。
        //   例： pattern: "101" なら line[1] を返す
        for (index, p) in enumerate(pattern) {
            if p == "0" {
                return line[index]
            }
        }
        return nil
    }

    func aiTurn(brain: () -> Int?) {
        if done {
            return
        }

        aiDeciding = true
        let hand = brain()
        setImageForPos(hand!, player: .ComputerPlayer)
        checkForWin()
        aiDeciding = false
    }

    // 空いているマスをランダムに選ぶ。
    func aiHandRandom() -> Int? {
        let spots = shuffle([0, 1, 2, 3, 4, 5, 6, 7, 8])
        for pos in spots {
            if !isOccupied(pos){
                return pos
            }
        }
        return nil
    }

    // 通常の戦略に従って手を選ぶ。
    func aiHandBasic() -> Int? {
        // We (the computer) have two in a row
        if let winHand = rowCheck(.ComputerPlayer) {
            return winHand
        }
        // They (the player) have two in a row
        if let defenceHand = rowCheck(.UserPlayer)? {
            return defenceHand
        }
        // center
        if !isOccupied(4) {
            return 4
        }
        // corner
        if let cornerAvailable = firstAvailable(isCorner: true){
            return cornerAvailable
        }
        // side
        if let sideAvailable = firstAvailable(isCorner: false){
            return sideAvailable
        }
        return nil
    }

    func v_play_one(player: Player, v_hand: Int) -> Int { // return score
        let enemy_player = get_enemy_player(player)
        v_cells[v_hand] = player

        let winer = checkGame(v_cells)
        if winer != Player.none {
            var ans: Int? = nil
            if winer == player {
                ans = 1  // 勝ち
            } else if winer == enemy_player {
                ans = -1 // 負け
            } else if has_empty_cell(v_cells) == false {
                ans = 0  // 引き分け
            }
            // ゲーム終了ならスコアを返す。
            if ans != nil {
                v_cells[v_hand] = Player.none
                return ans!
            }
        }

        // 反対側のプレーヤが手を指す。
        var max_score = -10
        for (w_hand, w_cell) in enumerate(v_cells) {
            if w_cell == .none {
                let score = v_play_one(enemy_player, v_hand: w_hand)
                if score > max_score {
                    max_score = score
                    if score >= 1 {
                        break
                    }
                }
            }
        }
        v_cells[v_hand] = Player.none
        return max_score * (-1)
    }

    // 与えられた状況での、空きマスのスコアを計算
    func get_hands_with_score(player: Player, v_cells: [Player]) -> [(Int, Int)] {
        let enemy_player = get_enemy_player(player)
        var ans: [(Int, Int)] = []

        var work_cells = v_cells  // 複写
        for (w_hand, w_cell) in enumerate(v_cells) {
            if w_cell != Player.none {
                continue
            }

            work_cells[w_hand] = player
            let winer = checkGame(work_cells)
            if winer == player {
                return [(w_hand, 1)]    // 勝ち。検索は打ち切る。
            } else if winer == enemy_player {
                ans += [(w_hand, -1)]   // 負け。検索を続ける。
            } else if has_empty_cell(work_cells) == false {
                ans += [(w_hand, 0)]    // 引き分け。検索を続ける。
            } else { // 敵の最善手を探す。
                let enemy_hand = get_best_hand_with_score(enemy_player, v_cells: work_cells)
                ans += [(w_hand, (-1) * enemy_hand.1)]
            }
            work_cells[w_hand] = Player.none
        }
        return ans
    }

    // 与えられた状況でのベストな手を選ぶ。
    func get_best_hand_with_score(player: Player, v_cells: [Player]) -> (Int, Int) {
        var max_score = -10
        var max_score_hand: Int? = nil
        for hand in get_hands_with_score(player, v_cells: v_cells) {
            if hand.1 == 1 {
                return hand
            }
            if max_score <= hand.1 {
                max_score = hand.1
                max_score_hand = hand.0
            }
        }
        return (max_score_hand!, max_score)
    }

    // ミニマックス法を使って手を選ぶ。
    func aiHandMinmax() -> Int? {
        // 一手目なら、センターを無条件で選ぶ。
        if play_count <= 1 && cells[4] == .none {
            return 4  // センター
        }
        let hand_info = get_best_hand_with_score(Player.ComputerPlayer, v_cells: cells)
        return hand_info.0
    }
}