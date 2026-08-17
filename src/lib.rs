//! `rust-template` 用のライブラリクレート

/// 与えられた名前に対する挨拶メッセージを返す
///
/// # Arguments
/// * `name` - 挨拶する名前
///
/// # Returns
/// * `String` - 挨拶メッセージ
#[must_use]
pub fn greet(name: &str) -> String {
    format!("Hello, {name}!")
}

#[cfg(test)]
mod tests {
    use super::*;

    /// 挨拶メッセージが期待されるメッセージと一致すること
    #[test]
    fn greet_returns_expected_message() {
        assert_eq!(greet("world"), "Hello, world!");
    }
}
