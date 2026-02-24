use ::aztec::macros::aztec;
use token::Token;
mod test;

unconstrained fn sqrt_unconstrained(y: u128) -> u128 {
    // full Babylonian method, no loop restrictions here
    if y <= 3 {
        if y == 0 { 0 } else { 1 }
    } else {
        let mut z = y;
        let mut x = y / 2 + 1;
        while x < z {
            z = x;
            x = (y / x + x) / 2;
        }
        z
    }
}

#[aztec]
pub contract UniV2Pair {
    use std::ops::{Add, Sub};
    use super::{Token, sqrt_unconstrained};
    use ::aztec::{
        macros::{
            functions::{authorize_once, external, initializer, view, internal},
            storage::{storage},
        },
        state_vars::{PublicMutable, PublicImmutable},
        messages::message_delivery::MessageDelivery,
    };
    use ::aztec::protocol::address::AztecAddress;
    use aztec::context;

    global inital_supply: u128 = 1000;

    #[storage]
    struct Storage<Context> {
        factory: PublicImmutable<AztecAddress, Context>,
        token_1: PublicImmutable<AztecAddress, Context>,
        token_2: PublicImmutable<AztecAddress, Context>,
        counter: PublicMutable<Field, Context>,
        liquidity_token: PublicImmutable<AztecAddress, Context>,
        reserve_1: PublicMutable<u128, Context>,
        reserve_2: PublicMutable<u128, Context>,
        // ToDo: Implement custom type
        // ToDo: Implement optional protocol fee
        cummulative_price_1: PublicMutable<u128, Context>,
        cummulative_price_2: PublicMutable<u128, Context>,
    }

    #[external("public")]
    #[initializer]
    fn constructor(_factory: AztecAddress, _liquidity_token: AztecAddress, _token_1: AztecAddress, _token_2: AztecAddress) {
        self.storage.factory.initialize(_factory);
        self.storage.token_1.initialize(_token_1);
        self.storage.token_1.initialize(_token_2);

        self.storage.liquidity_token.initialize(_liquidity_token);
        let mint_call = Token::at(self.storage.liquidity_token.read())
            .mint_to_public(AztecAddress::zero(), inital_supply);
        self.call(mint_call);
    }

    #[internal("public")]
    fn get_reserves() -> (u128, u128) {
        (self.storage.reserve_1, self.storage.reserve_2)
    }

    #[internal("public")]
    fn update_reserves(reserve_1: u128, reserve_2: u128) {
        self.storage.reserve_1.write(reserve_1);
        self.storage.reserve_2.write(reserve_2);
    }

    #[authorize_once("from", "authwit_nonce")]
    #[external("public")]
    fn mint(from: AztecAddress, authwit_nonce: Field) -> u128 {
        // check the balance of the contract
        let token_1 = Token::at(self.storage.token_1.read());
        let token_2 = Token::at(self.storage.token_2.read());
        let lp = Token::at(self.storage.liquidity_token.read());

        let balance_1 = self.view(token_1.balance_of_public(self.address));
        let balance_2 = self.view(token_2.balance_of_public(self.address));
        let lp_total_supply = self.view(lp.total_supply());

        let (reserve_1, reserve_2) = get_reserves();
        let amount_1 = balance_1 - reserve_1;
        let amount_2 = balance_2 - reserve_2;

        let mut lp_tokens = 0;

        // Ensure overflow doesn't happen here
        if lp_total_supply == inital_supply {
            let lp_tokens_minted = sqrt_unconstrained(amount_1 * amount_2);
            lp_tokens = lp_tokens_minted - inital_supply;
        } else {
            let lp_tokens_1 = (amount_1 * balance_1) / reserve_1;
            let lp_tokens_2 = (amount_2 * balance_2) / reserve_2;

            if lp_tokens_1 > lp_tokens_2 {
                lp_tokens = lp_tokens_2;
            } else {
                lp_tokens = lp_tokens_1;
            }
        }

        assert(lp_tokens > 0);
        let mint_call = lp
            .mint_to_public(from, lp_tokens);
        self.call(mint_call);

        update_reserves(balance_1, balance_2);
        // ToDo: feeOn
    }


    #[authorize_once("from", "authwit_nonce")]
    #[external("public")]
    fn burn(from: AztecAddress, authwit_nonce: Field) -> u128 {
        // check the balance of the contract
        let token_1 = Token::at(self.storage.token_1.read());
        let token_2 = Token::at(self.storage.token_2.read());
        let lp = Token::at(self.storage.liquidity_token.read());

        let mut balance_1 = self.view(token_1.balance_of_public(self.address));
        let mut balance_2 = self.view(token_2.balance_of_public(self.address));
        let lp_total_supply = self.view(lp.total_supply());
        let lp_balance = self.view(lp.balance_of_public(self.address));

        let amount_1 = lp_balance * balance_1 / lp_total_supply;
        let amount_2 = lp_balance * balance_2 / lp_total_supply;

        assert(amount_1 > 0);
        assert(amount_2 > 0);

        let burn_call = lp.burn_public(self.address, lp_balance, 0);
        self.call(burn_call);

        let transfer_1 = token_1.transfer_public_to_public(self.address, from, amount_1, 0);
        let transfer_2 = token_2.transfer_public_to_public(self.address, from, amount_2, 0);
        self.call(transfer_1);
        self.call(transfer_2);

        balance_1 = self.view(token_1.balance_of_public(self.address));
        balance_2 = self.view(token_2.balance_of_public(self.address));

        update_reserves(balance_1, balance_2);
        // ToDo: feeOn
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