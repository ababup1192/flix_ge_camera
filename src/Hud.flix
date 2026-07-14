// Hud — 画面に貼り付く +/− ズームボタンの幾何。「どこに・どの大きさで置くか」を
// 1箇所に集め、Controls（当たり判定）と View（描画）が同じ値を見る。状態は持たない。

mod Hud {

    /// ボタン円の半径（px）。
    pub def radius(): Float64 = 11.0

    /// + ボタン（ズームイン）の中心。画面右上に貼り付く（design = 画面サイズ）。
    pub def plusCenter(design: Vec2.Vec2): Vec2.Vec2 =
        { x = design#x - 18.0, y = 20.0 }

    /// − ボタン（ズームアウト）の中心。+ の真下。
    pub def minusCenter(design: Vec2.Vec2): Vec2.Vec2 =
        { x = design#x - 18.0, y = 48.0 }

    /// pos がボタン円の中にあるか（クリック・ホバーの当たり判定）。
    pub def inCircle(center: Vec2.Vec2, pos: Vec2.Vec2): Bool =
        Vec2.length(Vec2.sub(pos, center)) <= radius()
}
