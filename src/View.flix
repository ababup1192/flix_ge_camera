// View — World から「(置き場所, 見せたい物) のリスト」への投影（純粋）。
// ここに状態は無い: 描画物は渡された World から毎フレーム作り直すだけ。
// 置き場所は world 座標のまま組む。カメラのずらし（world → screen）は Main の
// App.withCamera が引き受けるので、ここに座標変換のコードは無い。
// 「いま何が見えているか」は App が ViewCtx の visible で教えてくれるので、
// 背景はその範囲だけ市松模様を敷く — どこまで動いても途切れない。

mod View {

    // 描く高さ（z）。数が大きいほど手前。
    def zTile(): Int32 = 0
    def zPlayer(): Int32 = 10

    /// プレイヤーの色（明るい青）。
    def playerColor(): Color = { r = 0.388235f32, g = 0.607843f32, b = 1.000000f32 }

    /// 市松模様の2色（暗めのグレー。clearColor より少し明るい程度に抑える）。
    def tileColorA(): Color = { r = 0.141176f32, g = 0.141176f32, b = 0.180392f32 }
    def tileColorB(): Color = { r = 0.188235f32, g = 0.188235f32, b = 0.235294f32 }

    /// 背景タイルの1辺の長さ（world 座標 px）。
    def tileSize(): Float64 = 32.0

    /// アリーナ縁取りの色（プレイヤーと同系の青）とその z（タイルの上・プレイヤーの下）。
    def rimColor(): Color = { r = 0.388235f32, g = 0.607843f32, b = 1.000000f32 }
    def zRim(): Int32 = 1

    /// World を描画コマンドの列へ写す。ctx の atlas は文字を描くとき使うが、今は使わない。
    pub def frame(ctx: App.ViewCtx, world: World.World): List[Render.PlacedItem] =
        background(ctx#visible) ::: rim() :: player(world) :: Nil

    /// アリーナの縁取り: 中はほんのり・縁は細いリング。「ここまでが床」を一目で見せる。
    def rim(): Render.PlacedItem =
        let a = World.arena();
        { at = a#position,
          item = Render.box(a#size, rimColor(), zRim())
                     |> Render.fade(0.04f32)
                     |> Render.outline(rimColor(), 2.0) }

    /// App.withCamera に渡す「画面中央に映したい world 座標」。カメラ状態そのもの。
    pub def cameraCenter(world: World.World): Vec2.Vec2 = world#cam

    /// プレイヤーの四角（world 座標）。boxAt が中心 → 左上の換算を済ませてくれる。
    def player(world: World.World): Render.PlacedItem =
        let s = World.size();
        Render.boxAt({ x = world#x, y = world#y }, { x = s, y = s }, playerColor(), zPlayer())

    /// アリーナの床 = 市松模様（world 座標の PlacedItem 列）。「見えている範囲」と
    /// 「アリーナ」の交わりのタイルだけを組む — 画面外も床の外も1枚も作らない。
    /// 行×列の総当たりは forM（List はモナドなのでリスト内包として使える）で書く。
    def background(visible: Rect2.Rect2): List[Render.PlacedItem] =
        let ts = tileSize();
        let a = World.arena();
        // 見える範囲とアリーナ、両方に乗っているタイル番号の帯（アリーナは 32px に整列済み）。
        let c0 = Int32.max(tileIndex(visible#position#x / ts), tileIndex(a#position#x / ts));
        let r0 = Int32.max(tileIndex(visible#position#y / ts), tileIndex(a#position#y / ts));
        let c1 = Int32.min(tileIndex((visible#position#x + visible#size#x) / ts) + 2,
                           tileIndex((a#position#x + a#size#x) / ts));
        let r1 = Int32.min(tileIndex((visible#position#y + visible#size#y) / ts) + 2,
                           tileIndex((a#position#y + a#size#y) / ts));
        forM (r <- List.range(r0, r1); c <- List.range(c0, c1))
            yield tile(c, r)

    /// 市松の1枚（タイル番号 → world 座標の PlacedItem）。番号の偶奇で2色を塗り分ける
    /// ので、スクロールしても模様は world に固定される。
    def tile(col: Int32, row: Int32): Render.PlacedItem =
        let ts = tileSize();
        // Int32.modulo は負でも 0/1 を返すので、負の index でも市松が崩れない。
        let color = if (Int32.modulo(col + row, 2) == 0) tileColorA() else tileColorB();
        { at = { x = Int32.toFloat64(col) * ts, y = Int32.toFloat64(row) * ts },
          item = Render.box({ x = ts, y = ts }, color, zTile()) }

    /// world 座標 / タイル辺 の商をタイル index（床関数）へ。
    def tileIndex(q: Float64): Int32 =
        Float64.floor(q) |> Float64.tryToInt32 |> Option.getWithDefault(0)

    // ── 視差レイヤ: 星空 ──
    // App.addParallaxLayer がカメラの動きに factor を掛けた速さで流すので、
    // ここは world 座標で「見えている範囲のセルに星を撒く」だけ。
    // 星の絵の決定（密度・段数・色・形）はぜんぶこの place にある —
    // エンジンの Scatter は撒く仕組みだけ。

    def zFar(): Int32 = -20
    def zNear(): Int32 = -10

    /// 星の3段階の明るさ（暗い群青 → 淡い青 → 白に近い青）。
    def starDim(): Color    = { r = 0.301961f32, g = 0.345098f32, b = 0.501961f32 }
    def starMid(): Color    = { r = 0.529412f32, g = 0.611765f32, b = 0.800000f32 }
    def starBright(): Color = { r = 0.831373f32, g = 0.890196f32, b = 1.000000f32 }

    /// 遠景の星（カメラの 1/4 の速さでゆっくり流れる）。Main が factor 0.25 で繋ぐ。
    pub def farStars(ctx: App.ViewCtx, _world: World.World): List[Render.PlacedItem] =
        Scatter.field(ctx#visible, { cell = 48.0, salt = 11 },
            (cell, rand) -> starPlace(48.0, zFar(), cell, rand))

    /// 近景の星（半分の速さ・まばらで大きめ）。Main が factor 0.55 で繋ぐ。
    pub def nearStars(ctx: App.ViewCtx, _world: World.World): List[Render.PlacedItem] =
        Scatter.field(ctx#visible, { cell = 96.0, salt = 47 },
            (cell, rand) -> starPlace(96.0, zNear(), cell, rand))

    /// セル1個ぶんの星（半分のセルは空）。セル内のどこに置くか・明るさ3段も蛇口から引く。
    def starPlace(cell: Float64, z: Int32,
                  at: {col = Int32, row = Int32}, rand: Int32 -> Float64): List[Render.PlacedItem] =
        if (rand(0) > 0.5) Nil
        else {
            let px = (Int32.toFloat64(at#col) + rand(1)) * cell;
            let py = (Int32.toFloat64(at#row) + rand(2)) * cell;
            let b = rand(3);
            let (color, size) =
                if (b < 0.6) (starDim(), 1.0)
                else if (b < 0.9) (starMid(), 2.0)
                else (starBright(), 3.0);
            { at = { x = px, y = py },
              item = Render.box({ x = size, y = size }, color, z) } :: Nil
        }

    // ── HUD: +/− ズームボタン（画面に貼り付く。カメラもズームも掛からない）──

    def zHud(): Int32 = 100

    /// ボタンの文字サイズ。
    def hudFontSize(): Float64 = 14.0

    /// ボタンの色。ホバーで地と縁が明るくなり「押せそう」に見せる。
    def buttonBase(): Color  = { r = 0.196078f32, g = 0.215686f32, b = 0.294118f32 }
    def buttonHover(): Color = { r = 0.274510f32, g = 0.333333f32, b = 0.470588f32 }
    def ringBase(): Color    = { r = 0.450980f32, g = 0.521569f32, b = 0.650980f32 }
    def ringHover(): Color   = { r = 0.388235f32, g = 0.607843f32, b = 1.000000f32 }
    def labelColor(): Color  = { r = 0.921569f32, g = 0.941176f32, b = 1.000000f32 }

    /// HUD の投影: +（ズームイン）と −（ズームアウト）の2ボタン。
    /// ホバー状態は Controls.zoomButtons が World に立てたものを読むだけ。
    pub def hud(ctx: App.ViewCtx, world: World.World): List[Render.PlacedItem] =
        let design = ctx#visible#size;  // HUD の visible は常に画面全体
        List.append(
            button(ctx#atlas, Hud.plusCenter(design),  "+", world#hoverPlus),
            button(ctx#atlas, Hud.minusCenter(design), "-", world#hoverMinus))

    /// ボタン1個 = 円（縁つき）+ 中央寄せの文字。Text.measure で実寸を測って
    /// 中心から半分ずらすので、文字は円のまんなかに乗る。
    def button(atlas: FontAtlas, center: Vec2.Vec2, label: String, hover: Bool): List[Render.PlacedItem] =
        let base = if (hover) buttonHover() else buttonBase();
        let ring = if (hover) ringHover() else ringBase();
        let circle = Render.circleAt(center, Hud.radius(), base, zHud());
        let ringed = { item = Render.outline(ring, 1.5, circle#item) | circle };
        let dims = Text.measure(Text.make(label, atlas, hudFontSize()));
        let text = { at = Vec2.sub(center, Vec2.div(dims, 2.0)),
                     item = Render.textTinted(label, atlas, hudFontSize(), labelColor(), zHud() + 1) };
        ringed :: text :: Nil
}
