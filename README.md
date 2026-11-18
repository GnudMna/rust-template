# rust-template

Rust プロジェクトのテンプレートです。新規プロジェクトの起点として利用できます。

## 構成

```
.
├── .editorconfig           # エディタ共通設定
├── .gitattributes          # 改行コード (LF) とバイナリファイルの扱い
├── .gitignore
├── .vscode/
│   ├── extensions.json     # 推奨拡張機能 (rust-analyzer / CodeLLDB など)
│   ├── launch.json         # デバッグ設定 (CodeLLDB)
│   └── settings.json       # ワークスペース設定 (保存時フォーマット / clippy)
├── Cargo.toml              # プロジェクト定義・依存関係
├── Cargo.lock
├── build.rs                # Windows 向け exe リソース埋め込み (winresource)
├── rust-toolchain.toml     # Rust ツールチェーン (1.96 + rustfmt / clippy)
├── rustfmt.toml            # rustfmt 設定
├── LICENSE
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
    │   └── wait-if-double-clicked.ps1
    ├── unix/                   # Linux / macOS 向けエントリポイント
    │   ├── build.sh
    │   ├── test.sh
    │   ├── clippy.sh
    │   ├── format.sh
    │   ├── check.sh
    │   └── rename-project.sh
    └── windows/                # Windows 向けエントリポイント
        ├── build.ps1
        ├── test.ps1
        ├── clippy.ps1
        ├── format.ps1
        ├── check.ps1
        └── rename-project.ps1
```

## 使い方

### 前提

- **Windows**: [PowerShell 7 以上](https://github.com/PowerShell/PowerShell/releases) (`pwsh`)。スクリプトは UTF-8 (BOM なし) です。エクスプローラーからダブルクリックで実行した場合は、結果を確認できるよう Enter 待ちになります (ターミナルからの実行では待ちません)。
- **Windows リリースビルド**: Visual Studio Build Tools など MSVC ツールチェーン (C++ ワークロード) が必要です。

### 1. テンプレートから新規プロジェクトを作る

```bash
git clone <Template Repo URL> my-project
cd my-project
rm -rf .git
git init
```

### 2. プロジェクト名を変更する

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

スクリプトは kebab-case（先頭は英小文字、以降は英小文字・数字・ハイフン）のみ受け付けます。`my_app` のようなアンダースコア区切りは指定できません。`Cargo.toml` の `name` はそのまま使い、Rust の識別子（`use` など）ではハイフンをアンダースコアに置き換えます。

| kebab-case（スクリプトに渡す名前） | Rust 識別子 (`use` など) |
| ---------------------------------- | ------------------------ |
| `my-project`                       | `my_project`             |
| `my-app`                           | `my_app`                 |

スクリプトが自動で更新する箇所:

- `Cargo.toml` の `name`
- `src/main.rs` / `src/lib.rs` / `tests/integration_test.rs` の `use` 文とクレート doc コメント
- `.vscode/launch.json` のパッケージ名 / バイナリ名
- `Cargo.lock` (`cargo check` で再生成)
- (第 2 引数指定時) `LICENSE` / `build.rs` の著作権表記

手動で更新が必要な箇所:

- `Cargo.toml` の `description`, `authors`, `repository` など
- `README.md` のタイトル
- `assets/icon.ico` (Windows 向け exe アイコン)

著作権表記は `LICENSE` と `build.rs` の `LEGAL_COPYRIGHT` で同じ形式 (`Copyright (c) <年> Your Name`) に揃えてください。第 2 引数で著作権者を指定すると、年は実行時の西暦で更新されます。

### 3. ビルド・実行・テスト

`cargo` を直接使う場合:

```bash
cargo build
cargo run
cargo test
cargo clippy --all-targets -- -D warnings
cargo fmt
```

スクリプトを使う場合 (どこから実行してもプロジェクトルートに移動してから実行します):

**Linux / macOS**

```bash
./scripts/unix/build.sh          # デバッグビルド
./scripts/unix/build.sh --release
./scripts/unix/test.sh
./scripts/unix/clippy.sh
./scripts/unix/format.sh
./scripts/unix/check.sh          # CI 向け一括チェック (fmt / clippy / test / doc)
```

**Windows**

```powershell
./scripts/windows/build.ps1
./scripts/windows/build.ps1 --release
./scripts/windows/test.ps1
./scripts/windows/clippy.ps1
./scripts/windows/format.ps1
./scripts/windows/check.ps1       # CI 向け一括チェック (fmt / clippy / test / doc)
```

## 含まれる設定

- **Edition 2024** / `rust-version = "1.96"` (`rust-toolchain.toml` で固定)
- **Clippy / Rust lints** (`unsafe_code = forbid` など)
- **Release プロファイル** (LTO・strip 有効)
- **Windows リソース** (`build.rs` + `winresource` でアイコン・バージョン・著作権を exe に埋め込み。ビルド対象 OS が Windows の場合のみ `CARGO_CFG_TARGET_OS` で判定して実行)
- **エディタ設定** (`.editorconfig`, `.gitattributes`, `.vscode/` で rust-analyzer 推奨・保存時フォーマット・CodeLLDB デバッグ)
- **ユニットテスト** (`src/lib.rs`) と **統合テスト** (`tests/`)

## ライセンス

MIT (利用時に `Cargo.toml` の `authors` や `LICENSE` を適宜変更してください)
