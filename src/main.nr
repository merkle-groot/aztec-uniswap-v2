use ::aztec::macros::aztec;
use token::Token;
mod test;

#[aztec]
pub contract UniV2Pair {
    use std::ops::{Add, Sub};
    use super::Token;
    use ::aztec::{
        macros::{
            functions::{external, initializer, view},
            storage::{storage}
        },
        state_vars::{PublicMutable, PublicImmutable},
        messages::message_delivery::MessageDelivery,
    };
    use ::aztec::protocol::address::AztecAddress;

    #[storage]
    struct Storage<Context> {
        counter: PublicMutable<Field, Context>,
        lp_address: PublicImmutable<AztecAddress, Context>,
    }

    #[external("public")]
    #[initializer]
    fn constructor(liquidity_token: AztecAddress, _nonce: Field) {
        self.storage.counter.write(0);
        self.storage.lp_address.initialize(liquidity_token);
        self.call::<14, 2, ()>(Token::at(self.storage.lp_address.read()).mint_to_public(self.address, 1000 as u128));
    }

    #[external("public")]
    fn increment() {
        let updated_value = self.storage.counter.read().add(1);
        self.storage.counter.write(updated_value);
    }

    #[external("public")]
    fn decrement() {
        let updated_value = self.storage.counter.read().sub(1);
        self.storage.counter.write(updated_value);
    }

    #[external("public")]
    #[view]
    fn get_counter() -> Field {
        self.storage.counter.read()
    }
}