// World — ゲームの状態そのもの。ここには「いま何がどうなっているか」の値だけを置く。
// 絵や入力や外の世界（窓・時計）はここに持ち込まない。それらは View と Controls と App の担当。

mod World {

    /// プレイヤーの中心座標（x, y）・カメラの中心（cam）・ズーム（zoom が現在値、
    /// zoomTarget が目標値。ボタンで目標を変え、毎フレーム現在値が目標へ寄る）・
    /// ボタンのホバー状態（hoverPlus / hoverMinus。View が光らせるのに使う）。
    /// 位置はどれも world 座標。画面サイズはここに持たない — 必要な計算は
    /// View が App.ViewCtx の visible から、Controls が Frame の viewport から出す。
    pub type alias World = {
        x = Float64, y = Float64, cam = Vec2.Vec2,
        zoom = Float64, zoomTarget = Float64,
        hoverPlus = Bool, hoverMinus = Bool
    }

    /// このフレームの入力（横・縦の軸値。-1 / 0 / +1）。Controls がキーからこの形に写す。
    pub type alias Input = { x = Float64, y = Float64 }

    /// プレイヤーの1辺の長さ（正方形）。
    pub def size(): Float64 = 16.0

    /// 星空に浮かぶアリーナ（プレイヤーが動ける床）の矩形。タイル1辺 32px に揃えてある。
    /// step がプレイヤーの壁に使い、View が床タイルと縁取りを描く。
    pub def arena(): Rect2.Rect2 =
        { position = { x = -352.0, y = -256.0 }, size = { x = 1024.0, y = 768.0 } }

    /// カメラが映してよい範囲 = アリーナ + 星空の余白。端に立つと縁の向こうに
    /// 星の虚空が見え、その先でカメラが止まる（余白ゼロだと星が一生映らない）。
    pub def cameraBounds(): Rect2.Rect2 =
        let a = arena();
        let m = 128.0;
        { position = { x = a#position#x - m, y = a#position#y - m },
          size = { x = a#size#x + 2.0 * m, y = a#size#y + 2.0 * m } }

    /// 1秒あたりの移動速度（world 座標 px/秒）。
    pub def speed(): Float64 = 120.0

    /// カメラの追従仕様。k は1秒あたりの寄せ率（大きいほどすぐ追いつく）、
    /// deadzone を広げるとプレイヤーが帯の中で動く間はカメラが据え置きになる。
    pub def follow(): CameraRig.Follow = { deadzone = 0.0, k = 5.0 }

    /// ボタン1回で掛かる・割られるズームの倍率。
    pub def zoomStep(): Float64 = 1.25

    /// ズームの下限（引き）と上限（寄り）。下限 0.2 の視界は 1600×1200 —
    /// アリーナ（1024×768）の周りに星空がたっぷり見える全景になる
    /// （視界が bounds より広いので camera bounds が中央に固定してくれる）。
    pub def zoomMin(): Float64 = 0.2
    pub def zoomMax(): Float64 = 2.5

    /// ズームが目標へ寄っていく速さ（1/秒。カメラの follow と同じ lerp 方式）。
    pub def zoomEase(): Float64 = 8.0

    /// ゲーム開始時の状態。プレイヤーもカメラも design の真ん中・ズーム等倍。
    pub def initial(design: Vec2.Vec2): World =
        let center = { x = design#x / 2.0, y = design#y / 2.0 };
        { x = center#x, y = center#y, cam = center,
          zoom = 1.0, zoomTarget = 1.0, hoverPlus = false, hoverMinus = false }

    /// ズームイン: 目標倍率を1段寄せる（上限あり）。実際の寄りは step の補間が担う。
    pub def zoomIn(world: World): World =
        { zoomTarget = clampZoom(world#zoomTarget * zoomStep()) | world }

    /// ズームアウト: 目標倍率を1段引く（下限あり）。
    pub def zoomOut(world: World): World =
        { zoomTarget = clampZoom(world#zoomTarget / zoomStep()) | world }

    def clampZoom(z: Float64): Float64 =
        Float64.max(zoomMin(), Float64.min(z, zoomMax()))

    /// 入力と経過時間から次の状態を作る（純粋）。
    /// プレイヤーは入力どおりに動く（アリーナの縁が壁）。カメラは CameraRig.followDelta で、
    /// ズームは目標値への lerp で、それぞれ遅れて滑らかに追いかける。
    pub def step(input: Input, dt: Float64, world: World): World =
        let a = arena();
        let half = size() / 2.0;
        let nx = CameraRig.clampAxis(a#position#x + half, a#position#x + a#size#x - half,
                     world#x + input#x * speed() * dt);
        let ny = CameraRig.clampAxis(a#position#y + half, a#position#y + a#size#y - half,
                     world#y + input#y * speed() * dt);
        let zt = Float64.min(1.0, zoomEase() * dt);
        { x = nx, y = ny,
          cam = { x = world#cam#x + CameraRig.followDelta(follow(), dt, nx, world#cam#x),
                  y = world#cam#y + CameraRig.followDelta(follow(), dt, ny, world#cam#y) },
          zoom = world#zoom + (world#zoomTarget - world#zoom) * zt
          | world }
}
