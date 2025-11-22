import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";

import Bench "mo:bench";
import Fuzz "mo:fuzz";

import BitMap "../src";
import SparseBitMap32 "../src/SparseBitMap32";
import SparseBitMap64 "../src/SparseBitMap64";

module {
    public func init() : Bench.Bench {
        let bench = Bench.Bench();

        bench.name("BitMap vs SparseBitMap32 vs SparseBitMap64 benchmarks");
        bench.description("Benchmarking the performance of different bitmap implementations");

        bench.cols([
            "BitMap",
            "SparseBitMap32",
            "SparseBitMap64",
        ]);

        bench.rows([
            "load 1M sequential ids",

            "random ids in 24 bit key space: 10k",
            "random ids in 24 bit key space: 100k",
            "random ids in 24 bit key space: 1M",

            "random ids in 27 bit key space: 10k",
            "random ids in 27 bit key space: 100k",
            "random ids in 27 bit key space: 1M",

            "random ids in 32 bit key space: 10k",
            "random ids in 32 bit key space: 100k",
            "random ids in 32 bit key space: 1M",

            "random ids in 64 bit key space: 10k",
            "random ids in 64 bit key space: 100k",
            "random ids in 64 bit key space: 1M",

            // "load 10k random ids in 64 bit key space",
            // "load 10k random ids in 96 bit key space",

            // "load 32 bit random ids in 64 bit key space",
            // "load 500k random ids in 64 bit key space",
            // "load 800k random ids in 64 bit key space",

            // "union() of 3 BitMaps: 10k ids in 32 bit key space",
            // "multiUnion() of 3 BitMaps: 10k ids in 32 bit key space",

            // "union() of 3 BitMaps: 50k ids in 32 bit key space",
            // "multiUnion() of 3 BitMaps: 50k ids in 32 bit key space",

            // "union() of 3 BitMaps: 10k ids in 64 bit key space",
            // "multiUnion() of 3 BitMaps: 10k ids in 64 bit key space",

            // "union() of 3 BitMaps: 80k ids in 32 bit key space",
            // "multiUnion() of 3 BitMaps: 80k ids in 32 bit key space",

            // "intersect() of 3 BitMaps: 10k ids in 32 bit key space",
            // "multiIntersect() of 3 BitMaps: 10k ids in 32 bit key space",

            // "intersect() of 3 BitMaps: 50k ids in 32 bit key space",
            // "multiIntersect() of 3 BitMaps: 50k ids in 32 bit key space",

            // "intersect() of 3 BitMaps: 80k ids in 32 bit key space",
            // "multiIntersect() of 3 BitMaps: 80k ids in 32 bit key space",

            // "intersect() of 3 BitMaps: 10k ids in 64 bit key space",
            // "multiIntersect() of 3 BitMaps: 10k ids in 64 bit key space",

        ]);

        let fuzz = Fuzz.Fuzz();

        func random_nats(size : Nat, start : Nat, end : Nat, opt_smaller_array_same_key_space : ?[Nat]) : [Nat] {

            let smaller_array_same_key_space = switch (opt_smaller_array_same_key_space) {
                case (?arr) { arr };
                case (null) { [] };
            };

            Array.tabulate(
                size,
                func(i : Nat) : Nat {
                    if (i < smaller_array_same_key_space.size()) {
                        smaller_array_same_key_space.get(i);
                    } else {
                        fuzz.nat.randomRange(start, end);
                    };
                },
            );
        };

        func random_nats_iter(size : Nat, start : Nat, end : Nat) : Iter.Iter<Nat> {

            Iter.map(
                Iter.range(0, size),
                func(i : Nat) : Nat {
                    fuzz.nat.randomRange(start, end);
                },
            );
        };

        let limit = 10_000;

        let sequential_ids = 1_000_000;

        let random_ids_in_24_bit_key_space_1 = 10_000;
        let random_ids_in_24_bit_key_space_2 = 100_000;
        let random_ids_in_24_bit_key_space_3 = 1_000_000;

        let random_ids_in_27_bit_key_space_1 = 10_000;
        let random_ids_in_27_bit_key_space_2 = 100_000;
        let random_ids_in_27_bit_key_space_3 = 1_000_000;

        let random_ids_in_32_bit_key_space_1 = 10_000;
        let random_ids_in_32_bit_key_space_2 = 100_000;
        let random_ids_in_32_bit_key_space_3 = 1_000_000;

        let random_ids_in_64_bit_key_space_1 = 10_000;
        let random_ids_in_64_bit_key_space_2 = 100_000;
        let random_ids_in_64_bit_key_space_3 = 1_000_000;

        // let random_10k_in_32_bit_key_space_2 = random_nats(limit, 0, (2 ** 32), null);
        // let random_10k_in_32_bit_key_space_3 = random_nats(limit, 0, (2 ** 32), null);

        // let BitMaps_10k_in_32_bit_key_space = [
        //     BitMap.fromIter(random_ids_in_32_bit_key_space_1.vals()),
        //     BitMap.fromIter(random_10k_in_32_bit_key_space_2.vals()),
        //     BitMap.fromIter(random_10k_in_32_bit_key_space_3.vals()),
        // ];

        // let random_50k_in_32_bit_key_space_2 = random_nats(50_000, 0, (2 ** 32), null);
        // let random_50k_in_32_bit_key_space_3 = random_nats(50_000, 0, (2 ** 32), null);

        // let BitMaps_50k_in_32_bit_key_space = [
        //     BitMap.fromIter(random_100k_in_32_bit_key_space_1.vals()),
        //     BitMap.fromIter(random_50k_in_32_bit_key_space_2.vals()),
        //     BitMap.fromIter(random_50k_in_32_bit_key_space_3.vals()),
        // ];

        // let random_80k_in_32_bit_key_space_2 = random_nats(80_000, 0, (2 ** 32), null);
        // let random_80k_in_32_bit_key_space_3 = random_nats(80_000, 0, (2 ** 32), null);

        // let BitMaps_80k_in_32_bit_key_space = [
        //     BitMap.fromIter(random_1M_in_32_bit_key_space_1.vals()),
        //     BitMap.fromIter(random_80k_in_32_bit_key_space_2.vals()),
        //     BitMap.fromIter(random_80k_in_32_bit_key_space_3.vals()),
        // ];

        // let random_10k_in_64_bit_key_space_1 = random_nats(limit, 0, (2 ** 64), null);
        // let random_10k_in_64_bit_key_space_2 = random_nats(limit, 0, (2 ** 64), null);
        // let random_10k_in_64_bit_key_space_3 = random_nats(limit, 0, (2 ** 64), null);

        // let BitMaps_10k_in_64_bit_key_space = [
        //     BitMap.fromIter(random_10k_in_64_bit_key_space_1.vals()),
        //     BitMap.fromIter(random_10k_in_64_bit_key_space_2.vals()),
        //     BitMap.fromIter(random_10k_in_64_bit_key_space_3.vals()),
        // ];

        // let random_10k_in_96_bit_key_space = random_nats(limit, 0, (2 ** 96), null);

        // let random_32_bit_in_64_bit_key_space = random_nats((2 ** 32), 0, (2 ** 64), ?random_10k_in_64_bit_key_space_1);
        // let random_500k_in_64_bit_key_space = random_nats(500_000, 0, (2 ** 64), ?random_32_bit_in_64_bit_key_space);
        // let random_800k_in_64_bit_key_space = random_nats(800_000, 0, (2 ** 64), ?random_500k_in_64_bit_key_space);

        // let SparseBitMap32s_10k_in_32_bit_key_space = [
        //     SparseBitMap32.fromIter(random_ids_in_32_bit_key_space_1.vals()),
        //     SparseBitMap32.fromIter(random_10k_in_32_bit_key_space_2.vals()),
        //     SparseBitMap32.fromIter(random_10k_in_32_bit_key_space_3.vals()),
        // ];

        // let SparseBitMap32s_50k_in_32_bit_key_space = [
        //     SparseBitMap32.fromIter(random_100k_in_32_bit_key_space_1.vals()),
        //     SparseBitMap32.fromIter(random_50k_in_32_bit_key_space_2.vals()),
        //     SparseBitMap32.fromIter(random_50k_in_32_bit_key_space_3.vals()),
        // ];

        // let SparseBitMap32s_80k_in_32_bit_key_space = [
        //     SparseBitMap32.fromIter(random_1M_in_32_bit_key_space_1.vals()),
        //     SparseBitMap32.fromIter(random_80k_in_32_bit_key_space_2.vals()),
        //     SparseBitMap32.fromIter(random_80k_in_32_bit_key_space_3.vals()),
        // ];

        // let SparseBitMap32s_10k_in_64_bit_key_space = [
        //     SparseBitMap32.fromIter(random_10k_in_64_bit_key_space_1.vals()),
        //     SparseBitMap32.fromIter(random_10k_in_64_bit_key_space_2.vals()),
        //     SparseBitMap32.fromIter(random_10k_in_64_bit_key_space_3.vals()),
        // ];

        bench.runner(
            func(row, col) = switch (col, row) {

                case ("BitMap", "load 1M sequential ids") {
                    ignore BitMap.fromIter(Iter.range(0, sequential_ids));
                };

                case ("BitMap", "random ids in 24 bit key space: 10k") {
                    ignore BitMap.fromIter(
                        random_nats_iter(random_ids_in_24_bit_key_space_1, 0, (2 ** 24))
                    );
                };

                case ("BitMap", "random ids in 24 bit key space: 100k") {
                    ignore BitMap.fromIter(
                        random_nats_iter(random_ids_in_24_bit_key_space_2, 0, (2 ** 24))
                    );
                };

                case ("BitMap", "random ids in 24 bit key space: 1M") {
                    ignore BitMap.fromIter(
                        random_nats_iter(random_ids_in_24_bit_key_space_3, 0, (2 ** 24))
                    );
                };

                case ("BitMap", "random ids in 27 bit key space: 10k") {
                    ignore BitMap.fromIter(
                        random_nats_iter(random_ids_in_27_bit_key_space_1, 0, (2 ** 27))
                    );
                };

                case ("BitMap", "random ids in 27 bit key space: 100k") {
                    ignore BitMap.fromIter(
                        random_nats_iter(random_ids_in_27_bit_key_space_2, 0, (2 ** 27))
                    );
                };

                case ("BitMap", "random ids in 27 bit key space: 1M") {
                    ignore BitMap.fromIter(
                        random_nats_iter(random_ids_in_27_bit_key_space_3, 0, (2 ** 27))
                    );
                };

                case ("BitMap", "random ids in 32 bit key space: 10k") {
                    ignore BitMap.fromIter(
                        random_nats_iter(random_ids_in_32_bit_key_space_1, 0, (2 ** 32))
                    );
                };

                // case ("BitMap", "load 10k random ids in 64 bit key space") {
                //     ignore BitMap.fromIter(
                //         random_10k_in_64_bit_key_space_2.vals()
                //     );
                // };

                // case ("BitMap", "load 10k random ids in 96 bit key space") {
                //     ignore BitMap.fromIter(
                //         random_10k_in_96_bit_key_space.vals()
                //     );
                // };

                case ("BitMap", "random ids in 32 bit key space: 100k") {
                    ignore BitMap.fromIter(
                        random_nats_iter(random_ids_in_32_bit_key_space_2, 0, (2 ** 32))
                    );
                };

                case ("BitMap", "random ids in 32 bit key space: 1M") {
                    // ignore BitMap.fromIter(
                    //     random_nats_iter(random_ids_in_32_bit_key_space_3, 0, (2 ** 32))
                    // );
                };

                case ("BitMap", "random ids in 64 bit key space: 10k") {
                    // ignore BitMap.fromIter(
                    //     random_nats_iter(random_ids_in_64_bit_key_space_1, 0, (2 ** 64))
                    // );
                };

                case ("BitMap", "random ids in 64 bit key space: 100k") {
                    // ignore BitMap.fromIter(
                    //     random_nats_iter(random_ids_in_64_bit_key_space_2, 0, (2 ** 64))
                    // );
                };

                case ("BitMap", "random ids in 64 bit key space: 1M") {
                    // ignore BitMap.fromIter(
                    //     random_nats_iter(random_ids_in_64_bit_key_space_3, 0, (2 ** 64))
                    // );
                };

                // case ("BitMap", "load 10k random ids in 64 bit key space") {
                //     ignore BitMap.fromIter(
                //         random_32_bit_in_64_bit_key_space.vals()
                //     );
                // };

                // case ("BitMap", "load 500k random ids in 64 bit key space") {
                //     ignore BitMap.fromIter(
                //         random_500k_in_64_bit_key_space.vals()
                //     );
                // };

                // case ("BitMap", "load 800k random ids in 64 bit key space") {
                //     ignore BitMap.fromIter(
                //         random_800k_in_64_bit_key_space.vals()
                //     );
                // };

                // case ("BitMap", "union() of 3 BitMaps: 10k ids in 32 bit key space") {
                //     let BitMap1 = BitMaps_10k_in_32_bit_key_space[0].clone();
                //     let BitMap2 = BitMaps_10k_in_32_bit_key_space[1];
                //     let BitMap3 = BitMaps_10k_in_32_bit_key_space[2];

                //     BitMap1.union(BitMap2);
                //     BitMap1.union(BitMap3);
                // };

                // case ("BitMap", "multiUnion() of 3 BitMaps: 10k ids in 32 bit key space") {
                //     ignore BitMap.multiUnion(
                //         BitMaps_10k_in_32_bit_key_space.vals()
                //     );
                // };

                // case ("BitMap", "union() of 3 BitMaps: 50k ids in 32 bit key space") {
                //     let BitMap1 = BitMaps_50k_in_32_bit_key_space[0].clone();
                //     let BitMap2 = BitMaps_50k_in_32_bit_key_space[1];
                //     let BitMap3 = BitMaps_50k_in_32_bit_key_space[2];

                //     BitMap1.union(BitMap2);
                //     BitMap1.union(BitMap3);
                // };

                // case ("BitMap", "multiUnion() of 3 BitMaps: 50k ids in 32 bit key space") {
                //     ignore BitMap.multiUnion(
                //         BitMaps_50k_in_32_bit_key_space.vals()
                //     );
                // };

                // case ("BitMap", "union() of 3 BitMaps: 10k ids in 64 bit key space") {
                //     let BitMap1 = BitMaps_10k_in_64_bit_key_space[0].clone();
                //     let BitMap2 = BitMaps_10k_in_64_bit_key_space[1];
                //     let BitMap3 = BitMaps_10k_in_64_bit_key_space[2];

                //     BitMap1.union(BitMap2);
                //     BitMap1.union(BitMap3);
                // };

                // case ("BitMap", "multiUnion() of 3 BitMaps: 10k ids in 64 bit key space") {
                //     ignore BitMap.multiUnion(
                //         BitMaps_10k_in_64_bit_key_space.vals()
                //     );
                // };

                // case ("BitMap", "union() of 3 BitMaps: 80k ids in 32 bit key space") {
                //     let BitMap1 = BitMaps_80k_in_32_bit_key_space[0].clone();
                //     let BitMap2 = BitMaps_80k_in_32_bit_key_space[1];
                //     let BitMap3 = BitMaps_80k_in_32_bit_key_space[2];

                //     BitMap1.union(BitMap2);
                //     BitMap1.union(BitMap3);
                // };

                // case ("BitMap", "multiUnion() of 3 BitMaps: 80k ids in 32 bit key space") {
                //     ignore BitMap.multiUnion(
                //         BitMaps_80k_in_32_bit_key_space.vals()
                //     );
                // };

                // case ("BitMap", "intersect() of 3 BitMaps: 10k ids in 32 bit key space") {
                //     let BitMap1 = BitMaps_10k_in_32_bit_key_space[0].clone();
                //     let BitMap2 = BitMaps_10k_in_32_bit_key_space[1];
                //     let BitMap3 = BitMaps_10k_in_32_bit_key_space[2];

                //     BitMap1.intersect(BitMap2);
                //     BitMap1.intersect(BitMap3);
                // };

                // case ("BitMap", "multiIntersect() of 3 BitMaps: 10k ids in 32 bit key space") {
                //     ignore BitMap.multiIntersect(
                //         BitMaps_10k_in_32_bit_key_space.vals()
                //     );
                // };

                // case ("BitMap", "intersect() of 3 BitMaps: 50k ids in 32 bit key space") {
                //     let BitMap1 = BitMaps_50k_in_32_bit_key_space[0].clone();
                //     let BitMap2 = BitMaps_50k_in_32_bit_key_space[1];
                //     let BitMap3 = BitMaps_50k_in_32_bit_key_space[2];

                //     BitMap1.intersect(BitMap2);
                //     BitMap1.intersect(BitMap3);
                // };

                // case ("BitMap", "multiIntersect() of 3 BitMaps: 50k ids in 32 bit key space") {
                //     ignore BitMap.multiIntersect(
                //         BitMaps_50k_in_32_bit_key_space.vals()
                //     );
                // };

                // case ("BitMap", "intersect() of 3 BitMaps: 80k ids in 32 bit key space") {
                //     let BitMap1 = BitMaps_80k_in_32_bit_key_space[0].clone();
                //     let BitMap2 = BitMaps_80k_in_32_bit_key_space[1];
                //     let BitMap3 = BitMaps_80k_in_32_bit_key_space[2];

                //     BitMap1.intersect(BitMap2);
                //     BitMap1.intersect(BitMap3);
                // };

                // case ("BitMap", "multiIntersect() of 3 BitMaps: 80k ids in 32 bit key space") {
                //     ignore BitMap.multiIntersect(
                //         BitMaps_80k_in_32_bit_key_space.vals()
                //     );
                // };

                // case ("BitMap", "intersect() of 3 BitMaps: 10k ids in 64 bit key space") {
                //     let BitMap1 = BitMaps_10k_in_64_bit_key_space[0].clone();
                //     let BitMap2 = BitMaps_10k_in_64_bit_key_space[1];
                //     let BitMap3 = BitMaps_10k_in_64_bit_key_space[2];

                //     BitMap1.intersect(BitMap2);
                //     BitMap1.intersect(BitMap3);
                // };

                // case ("BitMap", "multiIntersect() of 3 BitMaps: 10k ids in 64 bit key space") {
                //     ignore BitMap.multiIntersect(
                //         BitMaps_10k_in_64_bit_key_space.vals()
                //     );
                // };

                case ("SparseBitMap32", "load 1M sequential ids") {
                    ignore SparseBitMap32.fromIter(Iter.range(0, sequential_ids));
                };

                case ("SparseBitMap32", "random ids in 24 bit key space: 10k") {
                    ignore SparseBitMap32.fromIter(
                        random_nats_iter(random_ids_in_24_bit_key_space_1, 0, (2 ** 24))
                    );
                };

                case ("SparseBitMap32", "random ids in 24 bit key space: 100k") {
                    ignore SparseBitMap32.fromIter(
                        random_nats_iter(random_ids_in_24_bit_key_space_2, 0, (2 ** 24))
                    );
                };

                case ("SparseBitMap32", "random ids in 24 bit key space: 1M") {
                    ignore SparseBitMap32.fromIter(
                        random_nats_iter(random_ids_in_24_bit_key_space_3, 0, (2 ** 24))
                    );
                };

                case ("SparseBitMap32", "random ids in 27 bit key space: 10k") {
                    ignore SparseBitMap32.fromIter(
                        random_nats_iter(random_ids_in_27_bit_key_space_1, 0, (2 ** 27))
                    );
                };

                case ("SparseBitMap32", "random ids in 27 bit key space: 100k") {
                    ignore SparseBitMap32.fromIter(
                        random_nats_iter(random_ids_in_27_bit_key_space_2, 0, (2 ** 27))
                    );
                };

                case ("SparseBitMap32", "random ids in 27 bit key space: 1M") {
                    ignore SparseBitMap32.fromIter(
                        random_nats_iter(random_ids_in_27_bit_key_space_3, 0, (2 ** 27))
                    );
                };

                case ("SparseBitMap32", "random ids in 32 bit key space: 10k") {
                    ignore SparseBitMap32.fromIter(
                        random_nats_iter(random_ids_in_32_bit_key_space_1, 0, (2 ** 32))
                    );
                };

                // case ("SparseBitMap32", "load 10k random ids in 64 bit key space") {
                //     ignore SparseBitMap32.fromIter(
                //         random_10k_in_64_bit_key_space_2.vals()
                //     );
                // };

                // case ("SparseBitMap32", "load 10k random ids in 96 bit key space") {
                //     ignore SparseBitMap32.fromIter(
                //         random_10k_in_96_bit_key_space.vals()
                //     );
                // };

                case ("SparseBitMap32", "random ids in 32 bit key space: 100k") {
                    ignore SparseBitMap32.fromIter(
                        random_nats_iter(random_ids_in_32_bit_key_space_2, 0, (2 ** 32))
                    );
                };

                case ("SparseBitMap32", "random ids in 32 bit key space: 1M") {
                    ignore SparseBitMap32.fromIter(
                        random_nats_iter(random_ids_in_32_bit_key_space_3, 0, (2 ** 32))
                    );
                };

                case ("SparseBitMap32", "random ids in 64 bit key space: 10k") {
                    // ignore SparseBitMap32.fromIter(
                    //     random_nats_iter(random_ids_in_64_bit_key_space_1, 0, (2 ** 64))
                    // );
                };

                case ("SparseBitMap32", "random ids in 64 bit key space: 100k") {
                    // ignore SparseBitMap32.fromIter(
                    //     random_nats_iter(random_ids_in_64_bit_key_space_2, 0, (2 ** 64))
                    // );
                };

                case ("SparseBitMap32", "random ids in 64 bit key space: 1M") {
                    // ignore SparseBitMap32.fromIter(
                    //     random_nats_iter(random_ids_in_64_bit_key_space_3, 0, (2 ** 64))
                    // );
                };

                // SparseBitMap64 benchmarks
                case ("SparseBitMap64", "load 1M sequential ids") {
                    ignore SparseBitMap64.fromIter(Iter.range(0, sequential_ids));
                };

                case ("SparseBitMap64", "random ids in 24 bit key space: 10k") {
                    ignore SparseBitMap64.fromIter(
                        random_nats_iter(random_ids_in_24_bit_key_space_1, 0, (2 ** 24))
                    );
                };

                case ("SparseBitMap64", "random ids in 24 bit key space: 100k") {
                    ignore SparseBitMap64.fromIter(
                        random_nats_iter(random_ids_in_24_bit_key_space_2, 0, (2 ** 24))
                    );
                };

                case ("SparseBitMap64", "random ids in 24 bit key space: 1M") {
                    ignore SparseBitMap64.fromIter(
                        random_nats_iter(random_ids_in_24_bit_key_space_3, 0, (2 ** 24))
                    );
                };

                case ("SparseBitMap64", "random ids in 27 bit key space: 10k") {
                    ignore SparseBitMap64.fromIter(
                        random_nats_iter(random_ids_in_27_bit_key_space_1, 0, (2 ** 27))
                    );
                };

                case ("SparseBitMap64", "random ids in 27 bit key space: 100k") {
                    ignore SparseBitMap64.fromIter(
                        random_nats_iter(random_ids_in_27_bit_key_space_2, 0, (2 ** 27))
                    );
                };

                case ("SparseBitMap64", "random ids in 27 bit key space: 1M") {
                    ignore SparseBitMap64.fromIter(
                        random_nats_iter(random_ids_in_27_bit_key_space_3, 0, (2 ** 27))
                    );
                };

                case ("SparseBitMap64", "random ids in 32 bit key space: 10k") {
                    ignore SparseBitMap64.fromIter(
                        random_nats_iter(random_ids_in_32_bit_key_space_1, 0, (2 ** 32))
                    );
                };

                case ("SparseBitMap64", "random ids in 32 bit key space: 100k") {
                    ignore SparseBitMap64.fromIter(
                        random_nats_iter(random_ids_in_32_bit_key_space_2, 0, (2 ** 32))
                    );
                };

                case ("SparseBitMap64", "random ids in 32 bit key space: 1M") {
                    ignore SparseBitMap64.fromIter(
                        random_nats_iter(random_ids_in_32_bit_key_space_3, 0, (2 ** 32))
                    );
                };

                case ("SparseBitMap64", "random ids in 64 bit key space: 10k") {
                    ignore SparseBitMap64.fromIter(
                        random_nats_iter(random_ids_in_64_bit_key_space_1, 0, (2 ** 64))
                    );
                };

                case ("SparseBitMap64", "random ids in 64 bit key space: 100k") {
                    ignore SparseBitMap64.fromIter(
                        random_nats_iter(random_ids_in_64_bit_key_space_2, 0, (2 ** 64))
                    );
                };

                case ("SparseBitMap64", "random ids in 64 bit key space: 1M") {
                    // ignore SparseBitMap64.fromIter(
                    //     random_nats_iter(random_ids_in_64_bit_key_space_3, 0, (2 ** 64))
                    // );
                };

                // // case ("SparseBitMap32", "load 32 bit random ids in 64 bit key space") {
                // //     ignore SparseBitMap32.fromIter(
                // //         random_32_bit_in_64_bit_key_space.vals()
                // //     );
                // // };

                // // case ("SparseBitMap32", "load 500k random ids in 64 bit key space") {
                // //     ignore SparseBitMap32.fromIter(
                // //         random_500k_in_64_bit_key_space.vals()
                // //     );
                // // };

                // // case ("SparseBitMap32", "load 800k random ids in 64 bit key space") {
                // //     ignore SparseBitMap32.fromIter(
                // //         random_800k_in_64_bit_key_space.vals()
                // //     );
                // // };

                // case ("SparseBitMap32", "union() of 3 BitMaps: 10k ids in 32 bit key space") {
                //     let SparseBitMap321 = SparseBitMap32s_10k_in_32_bit_key_space[0].clone();
                //     let SparseBitMap322 = SparseBitMap32s_10k_in_32_bit_key_space[1];
                //     let SparseBitMap323 = SparseBitMap32s_10k_in_32_bit_key_space[2];

                //     SparseBitMap321.union(SparseBitMap322);
                //     SparseBitMap321.union(SparseBitMap323);
                // };

                // case ("SparseBitMap32", "multiUnion() of 3 BitMaps: 10k ids in 32 bit key space") {
                //     ignore SparseBitMap32.multiUnion(
                //         SparseBitMap32s_10k_in_32_bit_key_space.vals()
                //     );
                // };

                // case ("SparseBitMap32", "union() of 3 BitMaps: 50k ids in 32 bit key space") {
                //     let SparseBitMap321 = SparseBitMap32s_50k_in_32_bit_key_space[0].clone();
                //     let SparseBitMap322 = SparseBitMap32s_50k_in_32_bit_key_space[1];
                //     let SparseBitMap323 = SparseBitMap32s_50k_in_32_bit_key_space[2];

                //     SparseBitMap321.union(SparseBitMap322);
                //     SparseBitMap321.union(SparseBitMap323);
                // };

                // case ("SparseBitMap32", "multiUnion() of 3 BitMaps: 50k ids in 32 bit key space") {
                //     ignore SparseBitMap32.multiUnion(
                //         SparseBitMap32s_50k_in_32_bit_key_space.vals()
                //     );
                // };

                // case ("SparseBitMap32", "union() of 3 BitMaps: 80k ids in 32 bit key space") {
                //     let SparseBitMap321 = SparseBitMap32s_80k_in_32_bit_key_space[0].clone();
                //     let SparseBitMap322 = SparseBitMap32s_80k_in_32_bit_key_space[1];
                //     let SparseBitMap323 = SparseBitMap32s_80k_in_32_bit_key_space[2];

                //     SparseBitMap321.union(SparseBitMap322);
                //     SparseBitMap321.union(SparseBitMap323);
                // };

                // case ("SparseBitMap32", "multiUnion() of 3 BitMaps: 80k ids in 32 bit key space") {
                //     ignore SparseBitMap32.multiUnion(
                //         SparseBitMap32s_80k_in_32_bit_key_space.vals()
                //     );
                // };

                // case ("SparseBitMap32", "union() of 3 BitMaps: 10k ids in 64 bit key space") {
                //     let SparseBitMap321 = SparseBitMap32s_10k_in_64_bit_key_space[0].clone();
                //     let SparseBitMap322 = SparseBitMap32s_10k_in_64_bit_key_space[1];
                //     let SparseBitMap323 = SparseBitMap32s_10k_in_64_bit_key_space[2];

                //     SparseBitMap321.union(SparseBitMap322);
                //     SparseBitMap321.union(SparseBitMap323);
                // };

                // case ("SparseBitMap32", "multiUnion() of 3 BitMaps: 10k ids in 64 bit key space") {
                //     ignore SparseBitMap32.multiUnion(
                //         SparseBitMap32s_10k_in_64_bit_key_space.vals()
                //     );
                // };

                // case ("SparseBitMap32", "intersect() of 3 BitMaps: 10k ids in 32 bit key space") {
                //     let SparseBitMap321 = SparseBitMap32s_10k_in_32_bit_key_space[0].clone();
                //     let SparseBitMap322 = SparseBitMap32s_10k_in_32_bit_key_space[1];
                //     let SparseBitMap323 = SparseBitMap32s_10k_in_32_bit_key_space[2];

                //     SparseBitMap321.intersect(SparseBitMap322);
                //     SparseBitMap321.intersect(SparseBitMap323);
                // };

                // case ("SparseBitMap32", "multiIntersect() of 3 BitMaps: 10k ids in 32 bit key space") {
                //     ignore SparseBitMap32.multiIntersect(
                //         SparseBitMap32s_10k_in_32_bit_key_space.vals()
                //     );
                // };

                // case ("SparseBitMap32", "intersect() of 3 BitMaps: 50k ids in 32 bit key space") {
                //     let SparseBitMap321 = SparseBitMap32s_50k_in_32_bit_key_space[0].clone();
                //     let SparseBitMap322 = SparseBitMap32s_50k_in_32_bit_key_space[1];
                //     let SparseBitMap323 = SparseBitMap32s_50k_in_32_bit_key_space[2];

                //     SparseBitMap321.intersect(SparseBitMap322);
                //     SparseBitMap321.intersect(SparseBitMap323);
                // };

                // case ("SparseBitMap32", "multiIntersect() of 3 BitMaps: 50k ids in 32 bit key space") {
                //     ignore SparseBitMap32.multiIntersect(
                //         SparseBitMap32s_50k_in_32_bit_key_space.vals()
                //     );
                // };

                // case ("SparseBitMap32", "intersect() of 3 BitMaps: 80k ids in 32 bit key space") {
                //     let SparseBitMap321 = SparseBitMap32s_80k_in_32_bit_key_space[0].clone();
                //     let SparseBitMap322 = SparseBitMap32s_80k_in_32_bit_key_space[1];
                //     let SparseBitMap323 = SparseBitMap32s_80k_in_32_bit_key_space[2];

                //     SparseBitMap321.intersect(SparseBitMap322);
                //     SparseBitMap321.intersect(SparseBitMap323);
                // };

                // case ("SparseBitMap32", "multiIntersect() of 3 BitMaps: 80k ids in 32 bit key space") {
                //     ignore SparseBitMap32.multiIntersect(
                //         SparseBitMap32s_80k_in_32_bit_key_space.vals()
                //     );
                // };

                // case ("SparseBitMap32", "intersect() of 3 BitMaps: 10k ids in 64 bit key space") {
                //     let SparseBitMap321 = SparseBitMap32s_10k_in_64_bit_key_space[0].clone();
                //     let SparseBitMap322 = SparseBitMap32s_10k_in_64_bit_key_space[1];
                //     let SparseBitMap323 = SparseBitMap32s_10k_in_64_bit_key_space[2];

                //     SparseBitMap321.intersect(SparseBitMap322);
                //     SparseBitMap321.intersect(SparseBitMap323);
                // };

                // case ("SparseBitMap32", "multiIntersect() of 3 BitMaps: 10k ids in 64 bit key space") {
                //     ignore SparseBitMap32.multiIntersect(
                //         SparseBitMap32s_10k_in_64_bit_key_space.vals()
                //     );
                // };

                case (_) {
                    Debug.trap("Should be unreachable:\n row = \"" # debug_show row # "\" and col = \"" # debug_show col # "\"");
                };
            }
        );

        bench;
    };
};
