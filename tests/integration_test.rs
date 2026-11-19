//! `rust-template` バイナリの統合テスト

use std::process::{Command, Output};

fn bin() -> Command {
    Command::new(env!(concat!("CARGO_BIN_EXE_", env!("CARGO_PKG_NAME"))))
}

fn run(args: &[&str]) -> Output {
    bin()
        .args(args)
        .output()
        .unwrap_or_else(|error| panic!("バイナリの起動に失敗しました: {error}"))
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
