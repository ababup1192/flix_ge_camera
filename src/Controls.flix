// Controls — 入力の割り当て。App が用意したフレーム（キー・マウス・dt）を World の変化に
// 写す。ここは純粋（外の世界に触れない）: マウスの生読みは App が Frame に焼いてある。
// キーとの対応は walkTable の表 1 枚が持ち、判定ロジックは生のキーを知らない。

mod Controls {
    use GameEngine.Key

    /// 移動の意図。どのキーがどの向きかは walkTable が決める（WASD と矢印の両対応）。
    enum Walk with Eq {
        case WLeft
        case WRight
        case WUp
        case WDown
    }

    /// WASD と矢印の両対応の移動表。
    def walkTable(): InputMap.Table[Walk] =
        (Key.A, Walk.WLeft)  :: (Key.Left, Walk.WLeft) ::
        (Key.D, Walk.WRight) :: (Key.Right, Walk.WRight) ::
        (Key.W, Walk.WUp)    :: (Key.Up, Walk.WUp) ::
        (Key.S, Walk.WDown)  :: (Key.Down, Walk.WDown) :: Nil

    /// このフレームのキーを World.Input へ写す。同じ向きの 2 系統キーは 1 回に丸まり
    /// （二重加速しない）、逆向きの同時押しは足し合わせで 0（止まる）。
    pub def inputOf(frame: App.Frame): World.Input =
        InputMap.held(walkTable(), frame)
            |> List.foldLeft((acc, w) -> { let d = dirOf(w); { x = acc#x + d#x, y = acc#y + d#y } },
                             { x = 0.0, y = 0.0 })

    /// 意図 → 単位ベクトル（y は画面座標で下向きが正）。
    def dirOf(w: Walk): World.Input =
        match w {
            case Walk.WLeft  => { x = -1.0, y = 0.0 }
            case Walk.WRight => { x = 1.0, y = 0.0 }
            case Walk.WUp    => { x = 0.0, y = -1.0 }
            case Walk.WDown  => { x = 0.0, y = 1.0 }
        }

    /// 毎フレームのシステム: キーを Input へ写し、World を1歩進める。
    pub def step(frame: App.Frame, world: World.World): World.World =
        World.step(inputOf(frame), frame#dt, world)

    /// 毎フレームのシステム: +/− ボタンのホバーとクリック。カーソルが円に乗っていれば
    /// ホバーを立て（View が光らせる）、クリックのエッジならズームの目標を1段動かす。
    /// ボタンは画面に貼り付いているので、判定は screen 座標（frame#cursor）そのまま。
    pub def zoomButtons(frame: App.Frame, world: World.World): World.World =
        let overPlus  = Hud.inCircle(Hud.plusCenter(frame#viewport),  frame#cursor);
        let overMinus = Hud.inCircle(Hud.minusCenter(frame#viewport), frame#cursor);
        let hovered = { hoverPlus = overPlus, hoverMinus = overMinus | world };
        if (frame#mouseClicked and overPlus) World.zoomIn(hovered)
        else if (frame#mouseClicked and overMinus) World.zoomOut(hovered)
        else hovered
}
