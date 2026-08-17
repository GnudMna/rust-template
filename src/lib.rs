//! `rust-template` 用のライブラリクレート

/// 引数がない場合に使う既定の名前
pub const DEFAULT_NAME: &str = "world";

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

/// コマンドライン引数から挨拶する名前の一覧を返す
///
/// 空の引数は無視する。有効な引数が一つもない場合は [`DEFAULT_NAME`] を使う。
///
/// # Arguments
/// * `args` - プログラム名を除いたコマンドライン引数
///
/// # Returns
/// * 挨拶する名前の一覧
#[must_use]
pub fn names_from_args(args: impl IntoIterator<Item = impl AsRef<str>>) -> Vec<String> {
    let names: Vec<String> = args
        .into_iter()
        .map(|name| name.as_ref().to_owned())
        .filter(|name| !name.is_empty())
        .collect();

    if names.is_empty() {
        vec![DEFAULT_NAME.to_owned()]
    } else {
        names
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// 挨拶メッセージが期待されるメッセージと一致すること
    #[test]
    fn greet_returns_expected_message() {
        assert_eq!(greet("world"), "Hello, world!");
    }

    /// 引数がない場合は既定の名前を使うこと
    #[test]
    fn names_from_args_defaults_when_empty() {
        let names = names_from_args(Vec::<String>::new());
        assert_eq!(names, vec![DEFAULT_NAME.to_owned()]);
    }

    /// 空文字列の引数は無視して既定の名前を使うこと
    #[test]
    fn names_from_args_ignores_empty_strings() {
        let names = names_from_args(["", ""]);
        assert_eq!(names, vec![DEFAULT_NAME.to_owned()]);
    }

    /// 渡された引数を名前として使うこと
    #[test]
    fn names_from_args_uses_provided_names() {
        let names = names_from_args(["Alice", "", "Bob"]);
        assert_eq!(names, ["Alice", "Bob"]);
    }
}
