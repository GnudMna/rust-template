//! `rust-template` 用のメインクレート

// Windowsでコンソールを出さないための設定
// GUIアプリケーションを作成する場合はコメントアウトを外す
// #![cfg_attr(windows, windows_subsystem = "windows")]

use std::env;

use rust_template::{greet, names_from_args};

fn main() {
    for name in names_from_args(env::args().skip(1)) {
        println!("{}", greet(&name));
    }
}
