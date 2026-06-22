use rust_template::greet;

#[test]
fn integration_greet() {
    assert_eq!(greet("integration"), "Hello, integration!");
}
