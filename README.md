# rust-template

> このリポジトリは Rust プロジェクトのテンプレートです。新規プロジェクトの作り方は [TEMPLATE.md](TEMPLATE.md) を参照してください。 <!-- template-notice: rename-project がこの行を削除する -->

<!-- プロジェクトの概要を記述してください -->

## 前提

- **共通**: [rustup](https://rustup.rs/)。ツールチェーンは `rust-toolchain.toml` に従って rustup が自動でインストールします (インストールされない場合はプロジェクトルートで `rustup toolchain install` を実行してください)。OS のパッケージマネージャーで入れた Rust では `rust-toolchain.toml` が効かず、`Cargo.toml` の `rust-version` より古い場合はビルドできません。
- **Linux**: C リンカ (`cc`)。Debian / Ubuntu では `build-essential`、Fedora では `gcc` パッケージなどで入ります。
- **macOS**: Xcode Command Line Tools (`xcode-select --install`)。
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

## Git フック (任意)

push 前に `check` スクリプトを自動で実行する Git フック (`.githooks/pre-push`) を用意しています。`core.hooksPath` はクローンに引き継がれないため、クローンごとに次のスクリプトで有効にしてください。

**Linux / macOS**

```bash
./scripts/unix/install-hooks.sh     # 有効にする (core.hooksPath を .githooks に設定)
./scripts/unix/uninstall-hooks.sh   # 無効にする (core.hooksPath の設定を解除)
```

**Windows**

```powershell
./scripts/windows/install-hooks.ps1
./scripts/windows/uninstall-hooks.ps1
```

- 検査するのは push するコミットではなく作業ツリーの内容です。コミットしていない変更があると結果が異なる場合があります
- 一時的に省略する場合は `git push --no-verify` を使います
- 有効にしている間は `.git/hooks` やグローバル設定の `core.hooksPath` にあるフックは使われません (有効にする時点で該当するフックがあれば表示します)
- `core.hooksPath` が既に別の値に設定されている場合は、上書きや解除をせずにエラーにします
- フックは Windows では `scripts/windows/check.ps1` を、それ以外では `scripts/unix/check.sh` を実行します

## 含まれる設定

- **Edition 2024** / `rust-toolchain.toml` でツールチェーンを固定 (更新時は `rust-toolchain.toml` の `channel` と `Cargo.toml` の `rust-version` を揃えて変更)
- **誤公開の防止** (`Cargo.toml` の `publish = false`。crates.io に公開する場合は削除)
- **Clippy / Rust lints** (`unsafe_code = forbid` など)
- **Release プロファイル** (LTO・strip 有効)
- **CRT の静的リンク** (`.cargo/config.toml` で Windows MSVC ターゲットのみ `+crt-static`。VC++ 再頒布可能パッケージなしで exe が動作)
  - 環境変数 `RUSTFLAGS` (または `CARGO_ENCODED_RUSTFLAGS`) を設定すると、この指定は使われません。その場合は `-C target-feature=+crt-static` も含めてください。静的リンクが外れると `build.rs` がビルド時に警告します
  - Windows MSVC ではこの指定が `build.rustflags` より優先されるため、`~/.cargo/config.toml` などで設定した `build.rustflags` はこのプロジェクトでは使われません
- **Windows リソース** (`build.rs` + `winresource` でアイコン・バージョン・著作権を exe に埋め込み。ビルド対象 OS が Windows の場合のみ `CARGO_CFG_TARGET_OS` で判定して実行。`winresource` は Windows 上でのビルドでのみ依存に含めるため、Linux / macOS では余分なビルドが発生しない代わりに、そこから Windows 向けにクロスビルドした exe には埋め込まれない)
- **エディタ設定** (`.editorconfig`, `.gitattributes`, `.vscode/` で rust-analyzer 推奨・保存時フォーマット・CodeLLDB デバッグ)
- **Git フック** (`.githooks/pre-push` で push 前に `check` を実行。`install-hooks` スクリプトで有効にした場合のみ)
- **ユニットテスト** (`src/lib.rs`) と **統合テスト** (`tests/`)

## ライセンス

MIT (利用時に `LICENSE` を適宜変更してください)
