//! `rust-template` バイナリの統合テスト

use std::ffi::{OsStr, OsString};
use std::process::{Command, Output, Stdio};

fn bin() -> Command {
    Command::new(env!(concat!("CARGO_BIN_EXE_", env!("CARGO_PKG_NAME"))))
}

fn run(args: &[&str]) -> Output {
    run_os(args)
}

fn run_os<S: AsRef<OsStr>>(args: &[S]) -> Output {
    bin()
        .args(args)
        .output()
        .unwrap_or_else(|error| panic!("バイナリの起動に失敗しました: {error}"))
}

/// UTF-8 として不正なバイト列を含む引数
#[cfg(unix)]
fn invalid_unicode_arg() -> OsString {
    use std::os::unix::ffi::OsStringExt;

    OsString::from_vec(vec![0xFF])
}

/// 対になるサロゲートのない UTF-16 を含む引数
#[cfg(windows)]
fn invalid_unicode_arg() -> OsString {
    use std::os::windows::ffi::OsStringExt;

    OsString::from_wide(&[0xD800])
}

fn assert_success_stdout(output: &Output, expected_stdout: &str) {
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);

    assert!(
        output.status.success(),
        "終了コードが成功ではありません: status={:?}, stdout={stdout}, stderr={stderr}",
        output.status.code()
    );
    assert_eq!(stderr.as_ref(), "", "stderr が空ではありません: {stderr}");
    assert_eq!(stdout.as_ref(), expected_stdout);
}

/// 引数がない場合は既定の挨拶を出力すること
#[test]
fn prints_default_greeting_without_args() {
    assert_success_stdout(&run(&[]), "Hello, world!\n");
}

/// 渡された各引数に対して挨拶を出力すること
#[test]
fn prints_greeting_for_each_argument() {
    assert_success_stdout(&run(&["Alice", "Bob"]), "Hello, Alice!\nHello, Bob!\n");
}

/// 不正な Unicode を含む引数でも panic せず、置換文字に変換して挨拶を出力すること
#[test]
fn prints_greeting_for_invalid_unicode_argument() {
    assert_success_stdout(&run_os(&[invalid_unicode_arg()]), "Hello, \u{FFFD}!\n");
}

/// 出力先のパイプが途中で閉じられても panic せず正常終了すること
#[test]
fn exits_successfully_when_stdout_is_closed() {
    // パイプのバッファを超える量を出力させ、書き込み中にパイプが閉じられる状況を作る
    // (Windows のコマンドライン長の上限 32767 文字に収まる引数の数にする)
    let mut child = bin()
        .args(vec!["x"; 10_000])
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .unwrap_or_else(|error| panic!("バイナリの起動に失敗しました: {error}"));
    drop(child.stdout.take());

    let output = child
        .wait_with_output()
        .unwrap_or_else(|error| panic!("バイナリの終了待ちに失敗しました: {error}"));
    let stderr = String::from_utf8_lossy(&output.stderr);

    assert!(
        output.status.success(),
        "終了コードが成功ではありません: status={:?}, stderr={stderr}",
        output.status.code()
    );
    assert_eq!(stderr.as_ref(), "", "stderr が空ではありません: {stderr}");
}
