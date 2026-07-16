// Shot — 代表シーンを画面なしで PNG に焼く（README 用 & clip の回帰検証の源）。
// 実行: flix run --entrypoint Shot.all → gallery/pip.png。
// プレイヤーをアリーナ左端の近くに立たせる: PiP が見る world 480×320 がアリーナの縁を
// またぐので、縮小タイルが窓の途中で途切れて虚空に変わる = Render.clipped の切り口と
// 「窓の外へは 1px も漏れない」ことが 1 枚に写る。

mod Shot {
    import java.io.File

    def design(): Vec2.Vec2 = { x = 320.0, y = 240.0 }
    def ttfPath(): String = "assets/Xolonium-Regular.ttf"

    pub def all(): Unit \ IO =
        discard (new File("gallery")).mkdirs();
        let atlas = HeadlessFont.buildUiAtlas(ttfPath(), "assets/none.txt");
        // 背景は project.json の clearColor と同じ値。窓（960×720 = design×3）と同じ見た目で焼く。
        let cfg = { design = design(), scale = 3,
                    background = { r = 0.133333f32, g = 0.125490f32, b = 0.203922f32 },
                    texturePath = Map.empty(), fontTtf = ttfPath(), fontAtlas = atlas,
                    outDir = "gallery", frameW = 960, frameH = 720,
                    gifDelayMs = 66, gifFps = 15 };
        // 合成は Gallery.worldCmds（実行時と同じ式）を借りる — PNG と GIF で絵がずれない。
        let (drawables, polygons) = Gallery.worldCmds(atlas, worldAtEdge());
        Bakery.renderPng(cfg, drawables, polygons, "pip");
        println("baked: gallery/pip.png")

    /// アリーナ左端のそば（カメラは追いつき済み）。initial から step を何百回も畳むより、
    /// 「見せたい瞬間」を値で直に書くほうが台本として読める。
    def worldAtEdge(): World.World =
        { x = -300.0, y = 0.0, cam = { x = -300.0, y = 0.0 },
          zoom = 1.0, zoomTarget = 1.0, hoverPlus = false, hoverMinus = false }
}
