// Controls — 入力の割り当て。App が用意したフレーム（キー・マウス・dt）を World の変化に
// 写す。ここは純粋（外の世界に触れない）: マウスの生読みは App が Frame に焼いてある。

mod Controls {
    use GameEngine.Key

    /// このフレームのキーを World.Input へ写す。App.axis が左右・上下の押し下げを
    /// -1 / 0 / +1 の軸値に畳む（両押しは 0・押しっぱなしも効く）。
    pub def inputOf(frame: App.Frame): World.Input =
        { x = App.axis(negative = Key.Left, positive = Key.Right, frame),
          y = App.axis(negative = Key.Up,   positive = Key.Down,  frame) }

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
