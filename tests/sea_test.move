module game_hero::hero_test {
    use sui::test_scenario;
    use sui::coin;
    use game_hero::hero::{Self, GameInfo, GameAdmin, Hero, Monter};
    use game_hero::sea_hero::{Self, SeaHeroAdmin, SeaMonster};
    use game_hero::sea_hero_helper::{Self, HelpMeSlayThisMonster};

    #[test]
    fun test_slay_monter() {
        let admin = @0x123123;
        let player = @0x88688;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            hero::create(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin = coin::mint_for_testing(1000, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        test_scenario::next_tx(scenario, admin);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let admin_cap: GameAdmin = test_scenario::take_from_sender<GameAdmin>(scenario);

            hero::send_monter(game_ref, &mut admin_cap, 100, 2, player, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_immutable(game);
        };

         test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let admin_cap: GameAdmin = test_scenario::take_from_sender<GameAdmin>(scenario);

            let hero: Hero = test_scenario::take_from_sender<Hero>(scenario);
            let monster: Monter = test_scenario::take_from_sender<Monter>(scenario);

            hero::attack(game_ref,&mut hero, monster, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_to_sender(scenario, hero);
            test_scenario::return_immutable(game);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_slay_sea_monter() {
        let admin = @0x123123;
        let player = @0x88688;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            sea_hero::public_init_for_test(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin = coin::mint_for_testing(1000, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        test_scenario::next_tx(scenario, admin);
        {
            let sea_admin_cap: SeaHeroAdmin = test_scenario::take_from_sender<SeaHeroAdmin>(scenario);

            sea_hero::create_sea_monster(&mut sea_admin_cap, 10, player, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, sea_admin_cap);
        };

         test_scenario::next_tx(scenario, player);
        {
            let hero: Hero = test_scenario::take_from_sender<Hero>(scenario);
            let monster: SeaMonster = test_scenario::take_from_sender<SeaMonster>(scenario);

            let reward = sea_hero::slay(&hero, monster);

            test_scenario::return_to_sender(scenario, hero);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_hero_helper_slay() {
        let admin = @0xADADADAD;
        let player1 = @0x111111;
        let player2 = @0x222222;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            sea_hero:public_init_for_test(test_scenario::ctx(scenario));
        };

        // create hero 1
        test_scenario::next_tx(scenario, player1);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin = coin::mint_for_testing(1000, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };
        // create hero 2
        test_scenario::next_tx(scenario, player2);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin = coin::mint_for_testing(800, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        // create sea monster
        test_scenario::next_tx(scenario, admin);
        {
            let sea_admin_cap: SeaHeroAdmin = test_scenario::take_from_sender<SeaHeroAdmin>(scenario);

            sea_hero::create_sea_monster(&mut sea_admin_cap, 10, player1, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, sea_admin_cap);
        };

        // hero 1 create help
        test_scenario::next_tx(scenario, player1);
        {
            let monster: SeaMonster = test_scenario::take_from_sender<SeaMonster>(scenario);

            sea_hero_helper::create_help(monster, 15, player2, test_scenario::ctx(scenario));
        };

        // hero 2 attack sea monster
        test_scenario::next_tx(scenario, player2);
        {
            let hero: Hero = test_scenario::take_from_sender<Hero>(scenario);
            let wrapper: HelpMeSlayThisMonster = test_scenario::take_from_sender<HelpMeSlayThisMonster>(scenario);

            sea_hero_helper::attack(&hero, wrapper, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, hero);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_hero_attack_hero() {
        let admin = @0xADADADAD;
        let player1 = @0x111111;
        let player2 = @0x222222;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            sea_hero::new(test_scenario::ctx(scenario));
        };

        // create hero 1
        test_scenario::next_tx(scenario, player1);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin = coin::mint_for_testing(1000, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };
        // create hero 2
        test_scenario::next_tx(scenario, player2);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin = coin::mint_for_testing(800, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        // hero 1 vs hero 2
        test_scenario::next_tx(scenario, admin);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let admin_cap: GameAdmin = test_scenario::take_from_sender<GameAdmin>(scenario);

            let hero: Hero = test_scenario::take_from_sender<Hero>(scenario);
            let monster: Monter = test_scenario::take_from_sender<Monter>(scenario);

            hero::p2p_play(game_ref,&mut hero1, &mut hero2, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_to_sender(scenario, hero);
            test_scenario::return_immutable(game);
        };
        test_scenario::end(scenario_val);
    }
}
