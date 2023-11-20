module game_hero::hero {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use std::option::{Self, Option};
    use sui::transfer;
    use sui::sui::SUI;

    const EMonsterWon: u64 = 0;
    const EPaymentTooLow: u64 = 1;
    const EGameIdMismatch: u64 = 2;

    struct Hero has key, store {
        id: UID,
        hp: u64,
        mana: u64,
        level: u8,
        experience: u64,
        sword: Option<Sword>,
        armor: Option<Armor>,
        game_id: ID,
    }

    struct Sword has key, store {
        id: UID,
        magic: u64,
        strength: u64,
        game_id: ID,
    }

    struct Potion has key, store {
        id: UID,
        potency: u64,
        game_id: ID,
    }

    struct Armor has key,store {
        id: UID,
        guard: u64,
        game_id: ID,
    }

    struct Monter has key {
        id: UID,
        hp: u64,
        strength: u64,
        game_id: ID,
    }

    struct GameInfo has key {
        id: UID,
        admin: address
    }

    struct GameAdmin has key {
        id: UID,
        monter_created: u64,
        potions_created: u64,
        game_id: ID,
    }

    struct MonterSlainEvent has copy, drop {
        slayer_address: address,
        hero: ID,
        monter: ID,
        game_id: ID,
    }

    fun create(ctx: &mut TxContext){
        let sender = tx_context::sender(ctx);
        let id = object::new(ctx);
        let game_id = object::uid_to_inner(&id);

        transfer::freeze_object(GameInfo {
            id,
            admin: sender
        });

        transfer::transfer(
            GameAdmin {
                id: object::new(ctx),
                game_id,
                monter_created: 0,
                potions_created: 0
            }, 
            sender
        )
    }

    #[allow(unused_function)]
    fun init(ctx: &mut TxContext) {
        // Create a new game with Info & Admin
        create(ctx);
    }

    // --- Gameplay ---
    public entry fun attack(game: &GameInfo, hero: &mut Hero, monter: Monter, ctx: &TxContext) {
        /// Completed this code to hero can attack Monter
        /// after attack, if success hero will up_level hero, up_level_sword and up_level_armor.
        let Monter {id: monster_id, hp: hp, strength: monster_strength, game_id: _} = monter;
        let monster_hp = hp;
        let hero_strength = hero_strength(hero);
        let hero_hp = hero.hp;

        while (monster_hp > hero.hp) {
            if (hero_strength >= monster_hp){
                monster_hp = 0;
                break;
            };
            monster_hp - hero_strength;

            assert!(monster_strength > hero_hp, EMonsterWon);
            hero_hp - monster_strength;
        };

        object::delete(monster_id);

        hero.hp = hero_hp;

        up_level_hero(hero, 1);

        if (option::is_some(&hero.sword)) {
            level_up_sword(option::borrow_mut(&mut hero.sword), 5);
        };
    }

    public entry fun p2p_play(game: &GameInfo, hero1: &mut Hero, hero2: &mut Hero, ctx: &TxContext) {
        let _game_id = object::id(game);
        assert!(_game_id == hero1.game_id, EGameIdMismatch);
        assert!(_game_id == hero2.game_id, EGameIdMismatch);

        let hero1_strength = hero_strength(hero1);
        let hero1_defense = hero_guard(hero1);
        let hero1_hp = hero1.hp;
        let hero2_strength = hero_strength(hero2);
        let hero2_defense = hero_guard(hero2);
        let hero2_hp = hero2.hp;

        while (hero1_hp > 0 && hero2_hp > 0) {
            hero1_hp - (hero2_strength - hero1_defense);
            hero2_hp - (hero1_strength - hero2_defense);
        };
        
        if (hero2_hp <= 0) {
            up_level_hero(hero1, 2);
        };

        if (hero1_hp <= 0) {
            up_level_hero(hero2, 2);
        };
    }

    public fun up_level_hero(hero: &Hero, level: u8): u8 {
        // calculator strength
        hero.level + level
    }

    public fun hero_strength(hero: &Hero): u64 {
        // calculator strength
        let strength = if (option::is_some(&hero.sword)) {
            sword_strength(option::borrow(&hero.sword))
        } else {
            0
        };

        hero.experience + strength
    }

    public fun hero_guard(hero: &Hero): u64 {
        // calculator strength
        let guard = if (option::is_some(&hero.armor)) {
            option::borrow(&hero.armor).guard
        } else {
            0
        };
        guard
    }

    fun level_up_sword(sword: &mut Sword, amount: u64) {
        // up power/strength for sword
        sword.strength + amount;
    }

    public fun sword_strength(sword: &Sword): u64 {
        // calculator strength of sword follow magic + strength
        sword.strength + sword.magic
    }

    public fun heal(hero: &mut Hero, potion: Potion) {
        // use the potion to heal
        let Potion { id, potency, game_id: _} = potion;
        object::delete(id);
        hero.hp + potency;
    }

    public fun equip_sword(hero: &mut Hero, new_sword: Sword): Option<Sword> {
        // change another sword
        option::swap_or_fill(&mut hero.sword, new_sword)
    }

    // --- Object creation ---
    public fun create_sword(game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext): Sword {
        // Create a sword, streight depends on payment amount
        let value = coin::value(&payment);
        assert!(value >= 10, EPaymentTooLow);

        transfer::public_transfer(payment, game.admin);

        Sword {
            id: object::new(ctx),
            strength: value * 10,
            magic: value,
            game_id: object::id(game)
        }
    }

    public fun create_armor(game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext): Armor {
        // Create a sword, streight depends on payment amount
        let value = coin::value(&payment);
        assert!(value >= 10, EPaymentTooLow);

        transfer::public_transfer(payment, game.admin);

        Armor {
            id: object::new(ctx),
            guard: value * 15,
            game_id: object::id(game)
        }
    }

    public entry fun acquire_hero(
        game: &GameInfo, payment_sword: Coin<SUI>, payment_armor: Coin<SUI>, ctx: &mut TxContext
    ) {
        // call function create_armor
        // call function create_sword
        // call function create_hero
        let sender = tx_context::sender(ctx);
        let new_sword = create_sword(game, payment_sword, ctx);
        let new_armor = create_armor(game, payment_armor, ctx);
        let new_hero = create_hero(game, new_sword, new_armor, ctx);

        transfer::public_transfer(new_hero, sender);
    }

    public fun create_hero(game: &GameInfo, sword: Sword, armor: Armor, ctx: &mut TxContext): Hero {
        // Create a new hero
        Hero {
            id: object::new(ctx),
            hp: 100,
            experience: 0,
            level: 0,
            mana: 100,
            sword: option::some(sword),
            armor: option::some(armor),
            game_id: object::id(game)
        }
    }

    public entry fun send_potion(game: &GameInfo, payment: Coin<SUI>, player: address, ctx: &mut TxContext) {
        // send potion to hero, so that hero can healing
        let potency = coin::value(&payment);
        transfer::public_transfer(
            Potion {
                id: object::new(ctx),
                potency,
                game_id: object::id(game)
                },
            player
        );
        transfer::public_transfer(payment, game.admin)
    }

    public entry fun send_monter(game: &GameInfo, admin: &mut GameAdmin, hp: u64, strength: u64, player: address, ctx: &mut TxContext) {
        // send monter to hero to attacks
        let _game_id = object::id(game);
        assert!(_game_id == admin.game_id, EGameIdMismatch);
        admin.monter_created = admin.monter_created + 1;
        transfer::transfer(
            Monter {
                id: object::new(ctx),
                hp,
                strength,
                game_id: _game_id
            },
            player
        )
    }
}
