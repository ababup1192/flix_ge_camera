// Gallery — カメラショーケースの GIF/PNG を画面なしで焼く。
// World.step は純粋なので、台本（毎フレームの入力とズーム目標）を畳むだけで
// 実プレイと同じ World の列が得られる。絵は App が組むのと同じ合成
// （bounds クランプ → 視差レイヤ → 主レイヤ → HUD）を worldCmds が再現する。
// 実行: make bake（実体は flix run --entrypoint Bake.all）

mod Gallery {
    import java.io.File

    // ── 焼き込み設定 ──

    def design(): Vec2.Vec2 = { x = 320.0, y = 240.0 }
    def ttfPath(): String = "assets/Xolonium-Regular.ttf"
    def outDir(): String = "gallery"
    /// シミュレーションの1フレーム（30fps）。stride 2 で間引くので GIF は 15fps・66ms。
    def dt(): Float64 = 1.0 / 30.0

    /// 背景は project.json の clearColor と同じ値。
    def clearColor(): Color = { r = 0.133333f32, g = 0.125490f32, b = 0.203922f32 }

    def config(atlas: FontAtlas): Bakery.BakeConfig =
        { design = design(), scale = 1, background = clearColor(),
          texturePath = Map.empty(), fontTtf = ttfPath(), fontAtlas = atlas,
          outDir = outDir(), frameW = 320, frameH = 240,
          gifDelayMs = 66, gifFps = 15 }

    /// ウィンドウなしで焼き込んだフォント（ボタンの +/− は ASCII なのでこれで足りる）。
    def atlas(): FontAtlas \ IO =
        HeadlessFont.buildUiAtlas(ttfPath(), "assets/none.txt")

    // ── 本番と同じ絵の合成（App.sceneItems の再現）──

    /// World を描画コマンドへ投影する: bounds でクランプした center から
    /// 星空2層（視差）→ アリーナ → HUD の順に、実行時とまったく同じ式で組む。
    /// pub なのは Shot（静止画焼き）が同じ合成を共有するため — 焼き方が2通りあると
    /// 「GIF と PNG で絵が違う」が起こり得る。
    pub def worldCmds(atlas: FontAtlas, world: World.World):
            (List[GameEngine.Drawable], List[GameEngine.PolygonRenderCmd]) =
        let d = design();
        let z = CameraRig.safeZoom(world#zoom);
        let seen = Vec2.div(d, z);
        let center = CameraRig.clampCenter(bounds = World.cameraBounds(), seen = seen, world#cam);
        let far  = layerItems(atlas, world, 0.25, View.farStars,  center, z, d);
        let near = layerItems(atlas, world, 0.55, View.nearStars, center, z, d);
        let ctx = { atlas = atlas, visible = App.visibleOf(Some(center), z, d) };
        let hudCtx = { atlas = atlas, visible = App.visibleOf(None, 1.0, d) };
        let main = App.composeScene(Some(center), z, d,
            { world = View.frame(ctx, world), hud = View.hud(hudCtx, world) });
        Render.draw(List.append(far, List.append(near, main)))

    /// 視差レイヤ1枚: 見かけの camera（parallaxCenter）で culling も合成も行う。
    def layerItems(atlas: FontAtlas, world: World.World, factor: Float64,
                   lview: (App.ViewCtx, World.World) -> List[Render.PlacedItem],
                   center: Vec2.Vec2, z: Float64, d: Vec2.Vec2): List[Render.PlacedItem] =
        let lc = CameraRig.parallaxCenter(factor, center, design = d);
        let lctx = { atlas = atlas, visible = App.visibleOf(Some(lc), z, d) };
        App.composeScene(Some(lc), z, d, { world = lview(lctx, world), hud = Nil })

    // ── 台本（純粋な World.step を畳んで World の列を作る）──

    /// 台本の1節: frames フレームのあいだ input で歩き、ズーム目標を zoomTo にする。
    type alias Cue = { frames = Int32, input = World.Input, zoomTo = Float64 }

    def cue(frames: Int32, x: Float64, y: Float64, zoomTo: Float64): Cue =
        { frames = frames, input = { x = x, y = y }, zoomTo = zoomTo }

    /// 台本を先頭から畳み、全フレームの World を並べる（GIF のコマの源）。
    def script(cues: List[Cue], w0: World.World): List[World.World] =
        let runCue = (acc, c) -> {
            let (framesAcc, latest) = acc;
            let armed = { zoomTarget = c#zoomTo | latest };
            let (ws, last) = List.foldLeft((inner, _i) -> {
                    let (ws0, w) = inner;
                    let w1 = World.step(c#input, dt(), w);
                    (w1 :: ws0, w1)
                }, (Nil, armed), List.range(0, c#frames));
            (List.append(framesAcc, List.reverse(ws)), last)
        };
        let (all, _last) = List.foldLeft(runCue, (w0 :: Nil, w0), cues);
        all

    // ── 焼く ──

    /// ショーケース1本: 端まで歩いて星の余白でカメラが止まり、引いて全景、寄り直して戻る。
    pub def bakeAll(): Unit \ IO =
        discard (new File(outDir())).mkdirs();
        let font = atlas();
        // 出発点は右壁の少し手前（壁到達までの歩きを GIF に収める）。
        let w0 = { x = 480.0, cam = { x = 480.0, y = 120.0 } | World.initial(design()) };
        let cues =
               cue(50, 1.0, 0.0, 1.0)    // 右の壁まで歩く → カメラが星の余白の縁で止まる
            :: cue(12, 0.0, 0.0, 1.0)    // 一呼吸（リングの向こうに星空）
            :: cue(26, 0.0, 1.0, 1.0)    // 縁に沿って下へ（星と床の視差が見える）
            :: cue(42, 0.0, 0.0, 0.2)    // 引き切る → アリーナが星空に浮かぶ全景
            :: cue(30, -1.0, -0.5, 0.2)  // 全景のまま歩く（カメラは中央に固定）
            :: cue(36, 0.0, 0.0, 1.0)    // 寄り直して戻る（ループ向け）
            :: Nil;
        discard Bakery.bakeGif(config(font), script(cues, w0), 2,
            w -> worldCmds(font, w), "showcase");
        println("baked: ${outDir()}/showcase.gif")
}
