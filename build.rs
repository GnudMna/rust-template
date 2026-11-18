/// Windows リソースの著作権表記。`LICENSE` と揃えて更新してください。
const LEGAL_COPYRIGHT: &str = "Copyright (c) 2026 Your Name";

// PascalCase の場合は定数として直接記述してください
const APP_NAME: &str = env!("CARGO_PKG_NAME");

/// アイコンパス
const ICON_PATH: &str = "assets/icon.ico";

fn main() {
    // ビルドスクリプト自身の変更時のみ再実行する(他のファイルの変更では再実行しない)
    println!("cargo:rerun-if-changed=build.rs");

    // `cfg(windows)` はビルド実行マシンの OS を指すため, ビルド対象の OS は環境変数で判定する
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }

    // アイコンパスを再実行条件に追加
    println!("cargo:rerun-if-changed={ICON_PATH}");

    let mut res = winresource::WindowsResource::new();

    // アイコン
    res.set_icon(ICON_PATH);

    // アプリ情報
    res.set("ProductName", APP_NAME);
    res.set("FileDescription", APP_NAME);

    // バージョン情報
    res.set("FileVersion", env!("CARGO_PKG_VERSION"));
    res.set("ProductVersion", env!("CARGO_PKG_VERSION"));

    // 著作権(メールアドレス形式の authors ではなく, LICENSE と同じ表記を使う)
    res.set("LegalCopyright", LEGAL_COPYRIGHT);

    if let Err(error) = res.compile() {
        panic!("Windows リソースの埋め込みに失敗: {error}");
    }
}
