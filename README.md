# rust-template

> このリポジトリは Rust プロジェクトのテンプレートです。新規プロジェクトの作り方は [TEMPLATE.md](TEMPLATE.md) を参照してください。 <!-- template-notice: rename-project がこの行を削除する -->

<!-- プロジェクトの概要を記述してください -->

## 前提

- **Windows**: [PowerShell 7 以上](https://github.com/PowerShell/PowerShell/releases) (`pwsh`)。スクリプトは UTF-8 (BOM なし) です。`.ps1` は既定の関連付けではダブルクリックするとメモ帳で開かれます。ダブルクリックで実行したい場合は、`.ps1` の関連付けを `pwsh` に変更してください。関連付けを変更してエクスプローラーからダブルクリックで実行した場合は、結果を確認できるよう Enter 待ちになります (ターミナルからの実行では待ちません)。
- **Windows ビルド (デバッグ / リリース共通)**: Visual Studio Build Tools など MSVC ツールチェーン (C++ ワークロード、リンカと Windows SDK の `rc.exe` を含む) が必要です。

## ビルド・実行・テスト

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

`check` スクリプトは `--locked` 付きで実行するため、`Cargo.lock` が `Cargo.toml` の変更に追従していない場合も失敗します。その場合は `cargo build` などで `Cargo.lock` を更新してからコミットしてください。

## 含まれる設定

- **Edition 2024** / `rust-toolchain.toml` でツールチェーンを固定 (更新時は `rust-toolchain.toml` の `channel` と `Cargo.toml` の `rust-version` を揃えて変更)
- **誤公開の防止** (`Cargo.toml` の `publish = false`。crates.io に公開する場合は削除)
- **Clippy / Rust lints** (`unsafe_code = forbid` など)
- **Release プロファイル** (LTO・strip 有効)
- **CRT の静的リンク** (`.cargo/config.toml` で Windows MSVC ターゲットのみ `+crt-static`。VC++ 再頒布可能パッケージなしで exe が動作)
- **Windows リソース** (`build.rs` + `winresource` でアイコン・バージョン・著作権を exe に埋め込み。ビルド対象 OS が Windows の場合のみ `CARGO_CFG_TARGET_OS` で判定して実行)
- **エディタ設定** (`.editorconfig`, `.gitattributes`, `.vscode/` で rust-analyzer 推奨・保存時フォーマット・CodeLLDB デバッグ)
- **ユニットテスト** (`src/lib.rs`) と **統合テスト** (`tests/`)

## ライセンス

MIT (利用時に `LICENSE` を適宜変更してください)
