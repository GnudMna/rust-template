//! Library crate for `rust-template`.

/// Returns a greeting message for the given name.
#[must_use]
pub fn greet(name: &str) -> String {
    format!("Hello, {name}!")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn greet_returns_expected_message() {
        assert_eq!(greet("world"), "Hello, world!");
    }
}
