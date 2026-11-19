//! `rust-template` 用のメインクレート

// Windowsでコンソールを出さないための設定
// GUIアプリケーションを作成する場合はコメントアウトを外す
// #![cfg_attr(windows, windows_subsystem = "windows")]

use std::env;
use std::io::{self, Write};
use std::process::ExitCode;

use rust_template::{greet, names_from_args};

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        // 出力先のパイプが閉じられた場合 (`| head` など) はエラーにせず終了する
        Err(error) if error.kind() == io::ErrorKind::BrokenPipe => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("エラー: {error}");
            ExitCode::FAILURE
        }
    }
}

/// コマンドライン引数の各名前に対する挨拶を標準出力に書き出す
///
/// # Errors
/// 標準出力への書き込みに失敗した場合
fn run() -> io::Result<()> {
    let names = names_from_args(
        env::args_os()
            .skip(1)
            .map(|arg| arg.to_string_lossy().into_owned()),
    );

    // `println!` は書き込みに失敗すると panic するため、ロックした標準出力に書き込んでエラーを返す
    let mut stdout = io::stdout().lock();
    for name in names {
        writeln!(stdout, "{}", greet(&name))?;
    }
    stdout.flush()
}
