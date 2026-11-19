# テンプレートの使い方

Rust プロジェクトのテンプレートです。新規プロジェクトの起点として利用できます。

このファイルはテンプレートの使い方の説明です。前提となる環境やビルド・テストの方法は [README.md](README.md) を参照してください。`rename-project` スクリプトでプロジェクト名を変更すると、このファイルは削除されます。

## 構成

```
.
├── .cargo/
│   └── config.toml         # Windows MSVC 向けの CRT 静的リンク設定
├── .editorconfig           # エディタ共通設定
├── .gitattributes          # 改行コード (LF) とバイナリファイルの扱い
├── .githooks/
│   └── pre-push            # push 前に check を実行する Git フック (install-hooks で有効化)
├── .gitignore
├── .vscode/
│   ├── extensions.json     # 推奨拡張機能 (rust-analyzer / CodeLLDB など)
│   ├── launch.json         # デバッグ設定 (CodeLLDB)
│   └── settings.json       # ワークスペース設定 (保存時フォーマット / clippy)
├── Cargo.toml              # プロジェクト定義・依存関係
├── Cargo.lock
├── build.rs                # Windows 向け exe リソース埋め込み (winresource)
├── rust-toolchain.toml     # Rust ツールチェーン (rustfmt / clippy / rust-src 付き)
├── rustfmt.toml            # rustfmt 設定
├── LICENSE
├── README.md               # プロジェクトの説明 (雛形)
├── TEMPLATE.md             # テンプレートの使い方 (このファイル)
├── assets/
│   └── icon.ico            # Windows 向け exe アイコン
├── src/
│   ├── lib.rs              # ライブラリ本体
│   └── main.rs             # バイナリエントリポイント
├── tests/
│   └── integration_test.rs # 統合テスト
└── scripts/
    ├── common/                 # 共通ヘルパー
    │   ├── cd-project-root.sh
    │   ├── cd-project-root.ps1
    │   ├── invoke-native.ps1
    │   └── wait-if-double-clicked.ps1
    ├── unix/                   # Linux / macOS 向けエントリポイント
    │   ├── build.sh
    │   ├── test.sh
    │   ├── clippy.sh
    │   ├── format.sh
    │   ├── check.sh
    │   ├── install-hooks.sh
    │   ├── uninstall-hooks.sh
    │   ├── rename-project.sh
    │   └── test-rename-project.sh  # rename-project のテスト
    └── windows/                # Windows 向けエントリポイント
        ├── build.ps1
        ├── test.ps1
        ├── clippy.ps1
        ├── format.ps1
        ├── check.ps1
        ├── install-hooks.ps1
        ├── uninstall-hooks.ps1
        └── rename-project.ps1
```

## 1. テンプレートから新規プロジェクトを作る

**Linux / macOS**

```bash
git clone <Template Repo URL> my-project
cd my-project
rm -rf .git
git init
```

**Windows**

```powershell
git clone <Template Repo URL> my-project
cd my-project
Remove-Item -Recurse -Force .git
git init
```

## 2. プロジェクト名を変更する

スクリプトで一括変更する場合 (推奨):

**Linux / macOS**

```bash
./scripts/unix/rename-project.sh my-project
./scripts/unix/rename-project.sh my-project "Your Name"   # 著作権者も同時に更新
```

**Windows**

```powershell
./scripts/windows/rename-project.ps1 my-project
./scripts/windows/rename-project.ps1 my-project "Your Name"
```

スクリプトは kebab-case（先頭は英小文字、以降は英小文字・数字・ハイフン）のみ受け付けます。`my_app` のようなアンダースコア区切りは指定できません。Rust のキーワード (`match` など) や予約された名前 (`std`, `test` など) も指定できません。`Cargo.toml` の `name` はそのまま使い、Rust の識別子（`use` など）ではハイフンをアンダースコアに置き換えます。

| kebab-case（スクリプトに渡す名前） | Rust 識別子 (`use` など) |
| ---------------------------------- | ------------------------ |
| `my-project`                       | `my_project`             |
| `my-app`                           | `my_app`                 |

スクリプトが自動で更新する箇所:

- `Cargo.toml` の `name`
- `src/main.rs` / `src/lib.rs` / `tests/integration_test.rs` の `use` 文とクレート doc コメント
- `.vscode/launch.json` のパッケージ名 / バイナリ名
- `README.md` のタイトルと、冒頭のテンプレートの案内 (削除)
- `TEMPLATE.md` (削除)
- `Cargo.lock` (`cargo check` で再生成)
- (第 2 引数指定時) `LICENSE` / `Cargo.toml` の著作権表記

手動で更新が必要な箇所:

- `Cargo.toml` の `description`, `repository` など
- `README.md` の概要
- `assets/icon.ico` (Windows 向け exe アイコン。同梱のものは 32x32 の 1 サイズのみで、エクスプローラーの大きいアイコン表示や高 DPI 環境ではぼやけるため、16 / 24 / 32 / 48 / 256 px を含む ico に差し替えることを推奨)

著作権表記は `LICENSE` と `Cargo.toml` の `[package.metadata.winresource]` の `LegalCopyright` で同じ形式 (`Copyright (c) <年> Your Name`) に揃えてください。第 2 引数で著作権者を指定すると、年は実行時の西暦で更新されます。

`rename-project` スクリプトは名前の変更後もプロジェクトに残るため、再実行して名前を付け直せます。不要になったら削除して構いません。

`rename-project` スクリプトを変更した場合は、`test-rename-project.sh` で動作を確認できます。プロジェクトの複製に対して `rename-project` を実行し、不正な引数の拒否、各ファイルの更新内容、改名後の `cargo test` を検証します。Windows では Git Bash から実行すると `rename-project.ps1` も検証し、sh 版と結果が一致することを確認します。

```bash
./scripts/unix/test-rename-project.sh
```

## 3. ビルド・実行・テスト

[README.md](README.md) を参照してください。
