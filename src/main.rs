//! `rust-template` 用のメインクレート

// Windowsでコンソールを出さないための設定
// GUIアプリケーションを作成する場合はコメントアウトを外す
// #![cfg_attr(windows, windows_subsystem = "windows")]

use rust_template::greet;

fn main() {
    println!("{}", greet("world"));
}
