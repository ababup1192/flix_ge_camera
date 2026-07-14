// Bake — 成果物（README 用のショーケース GIF）を生成する入口。
// 実行: make bake（実体は flix run --entrypoint Bake.all）

mod Bake {

    pub def all(): Unit \ IO =
        Gallery.bakeAll()
}
