/// アイコンパス
const ICON_PATH: &str = "assets/icon.ico";

fn main() {
    // 変更時のみ再実行する(`LegalCopyright` は Cargo.toml の `[package.metadata.winresource]` で指定する)
    println!("cargo::rerun-if-changed=build.rs");
    println!("cargo::rerun-if-changed=Cargo.toml");

    // `cfg(windows)` はビルド実行マシンの OS を指すため, ビルド対象の OS は環境変数で判定する
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }

    // アイコンパスを再実行条件に追加
    println!("cargo::rerun-if-changed={ICON_PATH}");

    // ProductName / FileDescription / FileVersion / ProductVersion は
    // winresource が Cargo のパッケージ情報から自動設定する
    let mut res = winresource::WindowsResource::new();
    res.set_icon(ICON_PATH);

    if let Err(error) = res.compile() {
        panic!("Windows リソースの埋め込みに失敗: {error}");
    }
}
