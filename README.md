# rust-template

Rust プロジェクトのテンプレートです。新規プロジェクトの起点として利用できます。

## 構成

```
.
├── .editorconfig           # エディタ共通設定
├── .gitattributes          # 改行コード (LF) とバイナリファイルの扱い
├── .gitignore
├── .vscode/
│   ├── extensions.json     # 推奨拡張機能 (rust-analyzer など)
│   └── settings.json       # ワークスペース設定 (保存時フォーマット / clippy)
├── Cargo.toml              # プロジェクト定義・依存関係・WiX メタデータ
├── Cargo.lock
├── build.rs                # Windows 向け exe リソース埋め込み (winres)
├── rust-toolchain.toml     # Rust ツールチェーン (1.96 + rustfmt / clippy)
├── rustfmt.toml            # rustfmt 設定
├── LICENSE
├── assets/
│   └── icon.ico            # Windows 向けアイコン (exe / MSI 共通)
├── wix/
│   └── main.wxs            # MSI 定義 (cargo-wix)。wix/ の他ファイルは .gitignore 対象
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
    ├── linux/                  # Linux 向けエントリポイント
    │   ├── build.sh
    │   ├── test.sh
    │   ├── clippy.sh
    │   ├── format.sh
    │   ├── check.sh
    │   └── rename-project.sh
    ├── macos/                  # macOS 向けエントリポイント
    │   ├── build.sh
    │   ├── test.sh
    │   ├── clippy.sh
    │   ├── format.sh
    │   ├── check.sh
    │   └── rename-project.sh
    └── windows/                # Windows 向けエントリポイント
        ├── build.ps1
        ├── build-msi.ps1
        ├── test.ps1
        ├── clippy.ps1
        ├── format.ps1
        ├── check.ps1
        └── rename-project.ps1
```

## 使い方

### 前提

- **Windows**: [PowerShell 7 以上](https://github.com/PowerShell/PowerShell/releases) (`pwsh`)。スクリプトは UTF-8 (BOM なし) です。エクスプローラーからダブルクリックで実行した場合は、結果を確認できるよう Enter 待ちになります (ターミナルからの実行では待ちません)。
- **Windows リリースビルド / MSI**: Visual Studio Build Tools など MSVC ツールチェーン (C++ ワークロード) が必要です。
- **MSI 作成 (Windows)**: [cargo-wix](https://github.com/volks73/cargo-wix) と [WiX Toolset v3.14.1](https://github.com/wixtoolset/wix3/releases) が必要です。コード署名証明書は不要です。

```powershell
cargo install cargo-wix --locked
winget install WiXToolset.WiXToolset
```

### 1. テンプレートから新規プロジェクトを作る

```bash
git clone <Template Repo URL> my-project
cd my-project
rm -rf .git
git init
```

### 2. プロジェクト名を変更する

スクリプトで一括変更する場合 (推奨):

**Linux**

```bash
./scripts/linux/rename-project.sh my-project
./scripts/linux/rename-project.sh my-project "Your Name"   # 著作権者も同時に更新
```

**macOS**

```bash
./scripts/macos/rename-project.sh my-project
./scripts/macos/rename-project.sh my-project "Your Name"   # 著作権者も同時に更新
```

**Windows**

```powershell
./scripts/windows/rename-project.ps1 my-project
./scripts/windows/rename-project.ps1 my-project "Your Name"
```

`Cargo.toml` の `name` を変更し、ハイフン区切りの名前は Rust の識別子規則に合わせてアンダースコアに置き換えます。

| Cargo.toml の `name` | Rust 識別子 (`use` など) |
| -------------------- | ------------------------ |
| `my-project`         | `my_project`             |
| `my_app`             | `my_app`                 |

スクリプトが自動で更新する箇所:

- `Cargo.toml` の `name`
- `src/main.rs` / `tests/integration_test.rs` の `use` 文
- `src/lib.rs` のクレート doc コメント
- `wix/main.wxs` のプロジェクト名
- `[package.metadata.wix]` の `upgrade-guid` / `path-guid` / `binary-guid` / `shortcut-guid` (MSI 用。別アプリとの衝突を防ぐため再生成)
- `Cargo.lock` (`cargo check` で再生成)
- (第 2 引数指定時) `LICENSE` / `build.rs` の著作権表記
- (第 2 引数指定時) `wix/main.wxs` の `Manufacturer` とレジストリキー

手動で更新が必要な箇所:

- `Cargo.toml` の `description`, `authors`, `repository` など
- `README.md` のタイトル
- `assets/icon.ico` (Windows 向け exe / MSI アイコン)

著作権表記は `LICENSE` と `build.rs` の `LEGAL_COPYRIGHT` で同じ形式 (`Copyright (c) 2026 Your Name`) に揃えてください。

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

**Linux**

```bash
./scripts/linux/build.sh          # デバッグビルド
./scripts/linux/build.sh --release
./scripts/linux/test.sh
./scripts/linux/clippy.sh
./scripts/linux/format.sh
./scripts/linux/check.sh          # CI 向け一括チェック (fmt / clippy / test / doc)
```

**macOS**

```bash
./scripts/macos/build.sh          # デバッグビルド
./scripts/macos/build.sh --release
./scripts/macos/test.sh
./scripts/macos/clippy.sh
./scripts/macos/format.sh
./scripts/macos/check.sh          # CI 向け一括チェック (fmt / clippy / test / doc)
```

**Windows**

```powershell
./scripts/windows/build.ps1
./scripts/windows/build.ps1 --release
./scripts/windows/test.ps1
./scripts/windows/clippy.ps1
./scripts/windows/format.ps1
./scripts/windows/check.ps1       # CI 向け一括チェック (fmt / clippy / test / doc)
./scripts/windows/build-msi.ps1       # MSI インストーラー作成
./scripts/windows/build-msi.ps1 -SkipBuild
```

MSI は `target/wix/` に `{パッケージ名}-{バージョン}-{アーキテクチャ}.msi` として出力されます。`cargo wix` を直接使うこともできます。

## 含まれる設定

- **Edition 2024** / `rust-version = "1.96"` (`rust-toolchain.toml` で固定)
- **Clippy / Rust lints** (`unsafe_code = forbid` など)
- **Release プロファイル** (LTO・strip 有効)
- **Windows リソース** (`build.rs` + `winres` でアイコン・バージョン・著作権を exe に埋め込み。`winres` は Windows ビルド時のみ依存)
- **Windows MSI** (`wix/main.wxs` + `cargo-wix`)
  - ユーザー単位インストール (`InstallScope='perUser'` → `%LOCALAPPDATA%\{プロジェクト名}`)
  - 日本語 UI (`culture = "ja-JP"` / `Language='1041'`)
  - スタートメニューショートカット
  - 任意の PATH 追加 (機能ツリーで選択)
  - EULA ダイアログは無効 (ウェルカム画面から直接カスタマイズ画面へ)
  - 署名なし
- **エディタ設定** (`.editorconfig`, `.gitattributes`, `.vscode/` で rust-analyzer 推奨・保存時フォーマット)
- **ユニットテスト** (`src/lib.rs`) と **統合テスト** (`tests/`)

## ライセンス

MIT (利用時に `Cargo.toml` の `authors` や `LICENSE` を適宜変更してください)
