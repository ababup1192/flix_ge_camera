# ゲーム開発の入口。
#   make run   … ゲームを起動する（窓が開く）
#   make test  … テストを実行する
#   make build … 実行できる形にビルドする
#   make check … 型検査だけ走らせる（一番速い確認）
#   make bake  … README 用のショーケース GIF を画面なしで焼いて docs/ へ置く
#
# macOS の GLFW はメインスレッド起動を要求するが、それは GameEngine.ensureMainThread() が
# -XstartOnFirstThread 付きで自分を再起動して満たす。だから run に特別なフラグは要らない。
# （-XstartOnFirstThread は java の起動引数専用で、JAVA_TOOL_OPTIONS 経由では
#  「Unrecognized option」で落ちる。だからここでは環境変数に入れず、素の flix を呼ぶ）

.PHONY: run test build check bake

run:
	flix run

test:
	JAVA_TOOL_OPTIONS="-Djava.awt.headless=true" flix test

build:
	flix build

check:
	flix check

bake:
	JAVA_TOOL_OPTIONS="-Djava.awt.headless=true" flix run --entrypoint Bake.all
	cp gallery/showcase.gif docs/showcase.gif
	@echo "docs/showcase.gif updated"
