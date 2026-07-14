// エントリーポイント。ここでゲームを組み立てて起動する。
//
// App に部品を繋ぐ: 出発点の World（World.initial）・毎フレームの処理（Controls.step と
// Controls.zoomButtons）・絵への写し（View.frame）・カメラ（View.cameraCenter）・
// ズーム（w#zoom）・画面固定の HUD（View.hud = +/− ボタン）。
// 窓・時計・キー・マウス・描画・カメラのずらしといった外の世界の処理は App が引き受けるので、
// ゲーム側は純粋な関数を渡すだけでよい。外の世界に触れる処理（effect）は隠さず with で並べる。
//
// このゲームは「星空に浮かぶアリーナで四角を動かす」ミニマルなカメラのショーケース:
// 追従（followDelta）・端で止まるカメラ（withCameraBounds）・+/− ボタンの寄り引き（withZoom）・
// 二層の星空（addParallaxLayer）・画面固定 UI（withHudView）が全部入っている。
// 自分のゲームにするには、まず World / Controls / View を
// いじる。音や設定リロードが要るなら App.withAudio / App.reloadOn を足す（breakout 例が参考になる）。

def main(): Unit \ IO =
    if (GameEngine.ensureMainThread()) ()
    else {
        run {
            // makeWith: App が画面サイズ（project.json の designWidth/Height）を読んで
            // World.initial に渡してくれる。ゲーム側で画面サイズをベタ書きしない。
            App.makeWith(World.initial)
                |> App.addSystem(Controls.step)
                |> App.addSystem(Controls.zoomButtons)
                |> App.withView(View.frame)
                |> App.withCamera(View.cameraCenter)
                |> App.withCameraBounds(_ -> World.cameraBounds())
                |> App.withZoom(w -> w#zoom)
                |> App.addParallaxLayer(0.25, View.farStars)
                |> App.addParallaxLayer(0.55, View.nearStars)
                |> App.withHudView(View.hud)
                |> App.launch
        } with LwjglLayer.withProject(".")
          with Fs.FileRead.runWithIO
    }
