// use crate::UniV2Pair;
// use aztec::{protocol::address::AztecAddress, test::helpers::test_environment::TestEnvironment};

// pub unconstrained fn setup(
//     with_account_contracts: bool,
// ) -> (TestEnvironment, AztecAddress, AztecAddress) {
//     // Setup env, generate keys
//     let mut env = TestEnvironment::new();
//     let (owner, recipient) = if with_account_contracts {
//         let owner = env.create_contract_account();
//         let recipient = env.create_contract_account();
//         (owner, recipient)
//     } else {
//         let owner = env.create_light_account();
//         let recipient = env.create_light_account();

//         (owner, recipient)
//     };

//     // Deploy token contract
//     let initializer_call = UniV2Pair::interface().constructor();
//     let uni_contract_address =
//         env.deploy("UniV2Pair").with_public_initializer(owner, initializer_call);
//     (env, uni_contract_address, owner)
// }

// #[test]
// unconstrained fn testCounter() {
//     let (env, token_contract_address, owner) = setup(false);
//     let current_counter = env.view_public(UniV2Pair::at(token_contract_address).get_counter());

//     assert_eq(current_counter, 0);

//     env.call_public(owner, UniV2Pair::at(token_contract_address).increment());

//     let current_counter = env.view_public(UniV2Pair::at(token_contract_address).get_counter());
//     assert_eq(current_counter, 1);

//     env.call_public(owner, UniV2Pair::at(token_contract_address).decrement());

//     let current_counter = env.view_public(UniV2Pair::at(token_contract_address).get_counter());
//     assert_eq(current_counter, 0);
// }