use rust_template::{greet, names_from_args};

#[test]
fn integration_greet() {
    assert_eq!(greet("integration"), "Hello, integration!");
}

#[test]
fn integration_names_from_args() {
    assert_eq!(names_from_args(["integration"]), ["integration"]);
}
