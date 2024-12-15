import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";

import Bench "mo:bench";
import Fuzz "mo:fuzz";

import BitMap "../src";
import SparseBitMap "../src/SparseBitMap";

module {
    public func init() : Bench.Bench {
        let bench = Bench.Bench();

        bench.name("BitMap vs SparseBitMap benchmarks");
        bench.description("Benchmarking the performance of union() with 1k ids");

        bench.cols([
            "BitMap",
            "SparseBitMap",
        ]);

        bench.rows([
            "load 10k sequential ids",

            "load 10k random ids in 100k key space",
            "load 10k random ids in 1M key space",
            "load 10k random ids in 10M key space",

            "load 50k random ids in 100k key space",
            "load 80k random ids in 100k key space",

            // "load 100k random ids in 1M key space",
            // "load 500k random ids in 1M key space",
            // "load 800k random ids in 1M key space",

            "union() of 3 BitMaps: 10k ids in 100k key space",
            "multiUnion() of 3 BitMaps: 10k ids in 100k key space",

            "union() of 3 BitMaps: 50k ids in 100k key space",
            "multiUnion() of 3 BitMaps: 50k ids in 100k key space",

            "union() of 3 BitMaps: 10k ids in 1M key space",
            "multiUnion() of 3 BitMaps: 10k ids in 1M key space",

            "union() of 3 BitMaps: 80k ids in 100k key space",
            "multiUnion() of 3 BitMaps: 80k ids in 100k key space",

            "intersect() of 3 BitMaps: 10k ids in 100k key space",
            "multiIntersect() of 3 BitMaps: 10k ids in 100k key space",

            "intersect() of 3 BitMaps: 50k ids in 100k key space",
            "multiIntersect() of 3 BitMaps: 50k ids in 100k key space",

            "intersect() of 3 BitMaps: 80k ids in 100k key space",
            "multiIntersect() of 3 BitMaps: 80k ids in 100k key space",

            "intersect() of 3 BitMaps: 10k ids in 1M key space",
            "multiIntersect() of 3 BitMaps: 10k ids in 1M key space",

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

        let limit = 10_000;

        let random_10k_in_100k_key_space_1 = random_nats(limit, 0, 100_000, null);
        let random_10k_in_100k_key_space_2 = random_nats(limit, 0, 100_000, null);
        let random_10k_in_100k_key_space_3 = random_nats(limit, 0, 100_000, null);

        let BitMaps_10k_in_100k_key_space = [
            BitMap.fromIter(random_10k_in_100k_key_space_1.vals()),
            BitMap.fromIter(random_10k_in_100k_key_space_2.vals()),
            BitMap.fromIter(random_10k_in_100k_key_space_3.vals()),
        ];

        let random_50k_in_100k_key_space_1 = random_nats(50_000, 0, 100_000, null);
        let random_50k_in_100k_key_space_2 = random_nats(50_000, 0, 100_000, null);
        let random_50k_in_100k_key_space_3 = random_nats(50_000, 0, 100_000, null);

        let BitMaps_50k_in_100k_key_space = [
            BitMap.fromIter(random_50k_in_100k_key_space_1.vals()),
            BitMap.fromIter(random_50k_in_100k_key_space_2.vals()),
            BitMap.fromIter(random_50k_in_100k_key_space_3.vals()),
        ];

        let random_80k_in_100k_key_space_1 = random_nats(80_000, 0, 100_000, null);
        let random_80k_in_100k_key_space_2 = random_nats(80_000, 0, 100_000, null);
        let random_80k_in_100k_key_space_3 = random_nats(80_000, 0, 100_000, null);

        let BitMaps_80k_in_100k_key_space = [
            BitMap.fromIter(random_80k_in_100k_key_space_1.vals()),
            BitMap.fromIter(random_80k_in_100k_key_space_2.vals()),
            BitMap.fromIter(random_80k_in_100k_key_space_3.vals()),
        ];

        let random_10k_in_1M_key_space_1 = random_nats(limit, 0, 1_000_000, null);
        let random_10k_in_1M_key_space_2 = random_nats(limit, 0, 1_000_000, null);
        let random_10k_in_1M_key_space_3 = random_nats(limit, 0, 1_000_000, null);

        let BitMaps_10k_in_1M_key_space = [
            BitMap.fromIter(random_10k_in_1M_key_space_1.vals()),
            BitMap.fromIter(random_10k_in_1M_key_space_2.vals()),
            BitMap.fromIter(random_10k_in_1M_key_space_3.vals()),
        ];

        let random_10k_in_10M_key_space = random_nats(limit, 0, 10_000_000, null);

        // let random_100k_in_1M_key_space = random_nats(100_000, 0, 1_000_000, ?random_10k_in_1M_key_space_1);
        // let random_500k_in_1M_key_space = random_nats(500_000, 0, 1_000_000, ?random_100k_in_1M_key_space);
        // let random_800k_in_1M_key_space = random_nats(800_000, 0, 1_000_000, ?random_500k_in_1M_key_space);

        let SparseBitMaps_10k_in_100k_key_space = [
            SparseBitMap.fromIter(random_10k_in_100k_key_space_1.vals()),
            SparseBitMap.fromIter(random_10k_in_100k_key_space_2.vals()),
            SparseBitMap.fromIter(random_10k_in_100k_key_space_3.vals()),
        ];

        let SparseBitMaps_50k_in_100k_key_space = [
            SparseBitMap.fromIter(random_50k_in_100k_key_space_1.vals()),
            SparseBitMap.fromIter(random_50k_in_100k_key_space_2.vals()),
            SparseBitMap.fromIter(random_50k_in_100k_key_space_3.vals()),
        ];

        let SparseBitMaps_80k_in_100k_key_space = [
            SparseBitMap.fromIter(random_80k_in_100k_key_space_1.vals()),
            SparseBitMap.fromIter(random_80k_in_100k_key_space_2.vals()),
            SparseBitMap.fromIter(random_80k_in_100k_key_space_3.vals()),
        ];

        let SparseBitMaps_10k_in_1M_key_space = [
            SparseBitMap.fromIter(random_10k_in_1M_key_space_1.vals()),
            SparseBitMap.fromIter(random_10k_in_1M_key_space_2.vals()),
            SparseBitMap.fromIter(random_10k_in_1M_key_space_3.vals()),
        ];

        bench.runner(
            func(row, col) = switch (col, row) {

                case ("BitMap", "load 10k sequential ids") {
                    ignore BitMap.fromIter(Iter.range(0, limit - 1));
                };

                case ("BitMap", "load 10k random ids in 100k key space") {
                    ignore BitMap.fromIter(
                        random_10k_in_100k_key_space_1.vals()
                    );
                };

                case ("BitMap", "load 10k random ids in 1M key space") {
                    ignore BitMap.fromIter(
                        random_10k_in_1M_key_space_2.vals()
                    );
                };

                case ("BitMap", "load 10k random ids in 10M key space") {
                    ignore BitMap.fromIter(
                        random_10k_in_10M_key_space.vals()
                    );
                };

                case ("BitMap", "load 50k random ids in 100k key space") {
                    ignore BitMap.fromIter(
                        random_50k_in_100k_key_space_1.vals()
                    );
                };

                case ("BitMap", "load 80k random ids in 100k key space") {
                    ignore BitMap.fromIter(
                        random_80k_in_100k_key_space_1.vals()
                    );
                };

                // case ("BitMap", "load 100k random ids in 1M key space") {
                //     ignore BitMap.fromIter(
                //         random_100k_in_1M_key_space.vals()
                //     );
                // };

                // case ("BitMap", "load 500k random ids in 1M key space") {
                //     ignore BitMap.fromIter(
                //         random_500k_in_1M_key_space.vals()
                //     );
                // };

                // case ("BitMap", "load 800k random ids in 1M key space") {
                //     ignore BitMap.fromIter(
                //         random_800k_in_1M_key_space.vals()
                //     );
                // };

                case ("BitMap", "union() of 3 BitMaps: 10k ids in 100k key space") {
                    let BitMap1 = BitMaps_10k_in_100k_key_space[0].clone();
                    let BitMap2 = BitMaps_10k_in_100k_key_space[1];
                    let BitMap3 = BitMaps_10k_in_100k_key_space[2];

                    BitMap1.union(BitMap2);
                    BitMap1.union(BitMap3);
                };

                case ("BitMap", "multiUnion() of 3 BitMaps: 10k ids in 100k key space") {
                    ignore BitMap.multiUnion(
                        BitMaps_10k_in_100k_key_space.vals()
                    );
                };

                case ("BitMap", "union() of 3 BitMaps: 50k ids in 100k key space") {
                    let BitMap1 = BitMaps_50k_in_100k_key_space[0].clone();
                    let BitMap2 = BitMaps_50k_in_100k_key_space[1];
                    let BitMap3 = BitMaps_50k_in_100k_key_space[2];

                    BitMap1.union(BitMap2);
                    BitMap1.union(BitMap3);
                };

                case ("BitMap", "multiUnion() of 3 BitMaps: 50k ids in 100k key space") {
                    ignore BitMap.multiUnion(
                        BitMaps_50k_in_100k_key_space.vals()
                    );
                };

                case ("BitMap", "union() of 3 BitMaps: 10k ids in 1M key space") {
                    let BitMap1 = BitMaps_10k_in_1M_key_space[0].clone();
                    let BitMap2 = BitMaps_10k_in_1M_key_space[1];
                    let BitMap3 = BitMaps_10k_in_1M_key_space[2];

                    BitMap1.union(BitMap2);
                    BitMap1.union(BitMap3);
                };

                case ("BitMap", "multiUnion() of 3 BitMaps: 10k ids in 1M key space") {
                    ignore BitMap.multiUnion(
                        BitMaps_10k_in_1M_key_space.vals()
                    );
                };

                case ("BitMap", "union() of 3 BitMaps: 80k ids in 100k key space") {
                    let BitMap1 = BitMaps_80k_in_100k_key_space[0].clone();
                    let BitMap2 = BitMaps_80k_in_100k_key_space[1];
                    let BitMap3 = BitMaps_80k_in_100k_key_space[2];

                    BitMap1.union(BitMap2);
                    BitMap1.union(BitMap3);
                };

                case ("BitMap", "multiUnion() of 3 BitMaps: 80k ids in 100k key space") {
                    ignore BitMap.multiUnion(
                        BitMaps_80k_in_100k_key_space.vals()
                    );
                };

                case ("BitMap", "intersect() of 3 BitMaps: 10k ids in 100k key space") {
                    let BitMap1 = BitMaps_10k_in_100k_key_space[0].clone();
                    let BitMap2 = BitMaps_10k_in_100k_key_space[1];
                    let BitMap3 = BitMaps_10k_in_100k_key_space[2];

                    BitMap1.intersect(BitMap2);
                    BitMap1.intersect(BitMap3);
                };

                case ("BitMap", "multiIntersect() of 3 BitMaps: 10k ids in 100k key space") {
                    ignore BitMap.multiIntersect(
                        BitMaps_10k_in_100k_key_space.vals()
                    );
                };

                case ("BitMap", "intersect() of 3 BitMaps: 50k ids in 100k key space") {
                    let BitMap1 = BitMaps_50k_in_100k_key_space[0].clone();
                    let BitMap2 = BitMaps_50k_in_100k_key_space[1];
                    let BitMap3 = BitMaps_50k_in_100k_key_space[2];

                    BitMap1.intersect(BitMap2);
                    BitMap1.intersect(BitMap3);
                };

                case ("BitMap", "multiIntersect() of 3 BitMaps: 50k ids in 100k key space") {
                    ignore BitMap.multiIntersect(
                        BitMaps_50k_in_100k_key_space.vals()
                    );
                };

                case ("BitMap", "intersect() of 3 BitMaps: 80k ids in 100k key space") {
                    let BitMap1 = BitMaps_80k_in_100k_key_space[0].clone();
                    let BitMap2 = BitMaps_80k_in_100k_key_space[1];
                    let BitMap3 = BitMaps_80k_in_100k_key_space[2];

                    BitMap1.intersect(BitMap2);
                    BitMap1.intersect(BitMap3);
                };

                case ("BitMap", "multiIntersect() of 3 BitMaps: 80k ids in 100k key space") {
                    ignore BitMap.multiIntersect(
                        BitMaps_80k_in_100k_key_space.vals()
                    );
                };

                case ("BitMap", "intersect() of 3 BitMaps: 10k ids in 1M key space") {
                    let BitMap1 = BitMaps_10k_in_1M_key_space[0].clone();
                    let BitMap2 = BitMaps_10k_in_1M_key_space[1];
                    let BitMap3 = BitMaps_10k_in_1M_key_space[2];

                    BitMap1.intersect(BitMap2);
                    BitMap1.intersect(BitMap3);
                };

                case ("BitMap", "multiIntersect() of 3 BitMaps: 10k ids in 1M key space") {
                    ignore BitMap.multiIntersect(
                        BitMaps_10k_in_1M_key_space.vals()
                    );
                };

                case ("SparseBitMap", "load 10k sequential ids") {
                    ignore SparseBitMap.fromIter(Iter.range(0, limit - 1));
                };

                case ("SparseBitMap", "load 10k random ids in 100k key space") {
                    ignore SparseBitMap.fromIter(
                        random_10k_in_100k_key_space_1.vals()
                    );
                };

                case ("SparseBitMap", "load 10k random ids in 1M key space") {
                    ignore SparseBitMap.fromIter(
                        random_10k_in_1M_key_space_2.vals()
                    );
                };

                case ("SparseBitMap", "load 10k random ids in 10M key space") {
                    ignore SparseBitMap.fromIter(
                        random_10k_in_10M_key_space.vals()
                    );
                };

                case ("SparseBitMap", "load 50k random ids in 100k key space") {
                    ignore SparseBitMap.fromIter(
                        random_50k_in_100k_key_space_1.vals()
                    );
                };

                case ("SparseBitMap", "load 80k random ids in 100k key space") {
                    ignore SparseBitMap.fromIter(
                        random_80k_in_100k_key_space_1.vals()
                    );
                };

                // case ("SparseBitMap", "load 100k random ids in 1M key space") {
                //     ignore SparseBitMap.fromIter(
                //         random_100k_in_1M_key_space.vals()
                //     );
                // };

                // case ("SparseBitMap", "load 500k random ids in 1M key space") {
                //     ignore SparseBitMap.fromIter(
                //         random_500k_in_1M_key_space.vals()
                //     );
                // };

                // case ("SparseBitMap", "load 800k random ids in 1M key space") {
                //     ignore SparseBitMap.fromIter(
                //         random_800k_in_1M_key_space.vals()
                //     );
                // };

                case ("SparseBitMap", "union() of 3 BitMaps: 10k ids in 100k key space") {
                    let SparseBitMap1 = SparseBitMaps_10k_in_100k_key_space[0].clone();
                    let SparseBitMap2 = SparseBitMaps_10k_in_100k_key_space[1];
                    let SparseBitMap3 = SparseBitMaps_10k_in_100k_key_space[2];

                    SparseBitMap1.union(SparseBitMap2);
                    SparseBitMap1.union(SparseBitMap3);
                };

                case ("SparseBitMap", "multiUnion() of 3 BitMaps: 10k ids in 100k key space") {
                    ignore SparseBitMap.multiUnion(
                        SparseBitMaps_10k_in_100k_key_space.vals()
                    );
                };

                case ("SparseBitMap", "union() of 3 BitMaps: 50k ids in 100k key space") {
                    let SparseBitMap1 = SparseBitMaps_50k_in_100k_key_space[0].clone();
                    let SparseBitMap2 = SparseBitMaps_50k_in_100k_key_space[1];
                    let SparseBitMap3 = SparseBitMaps_50k_in_100k_key_space[2];

                    SparseBitMap1.union(SparseBitMap2);
                    SparseBitMap1.union(SparseBitMap3);
                };

                case ("SparseBitMap", "multiUnion() of 3 BitMaps: 50k ids in 100k key space") {
                    ignore SparseBitMap.multiUnion(
                        SparseBitMaps_50k_in_100k_key_space.vals()
                    );
                };

                case ("SparseBitMap", "union() of 3 BitMaps: 80k ids in 100k key space") {
                    let SparseBitMap1 = SparseBitMaps_80k_in_100k_key_space[0].clone();
                    let SparseBitMap2 = SparseBitMaps_80k_in_100k_key_space[1];
                    let SparseBitMap3 = SparseBitMaps_80k_in_100k_key_space[2];

                    SparseBitMap1.union(SparseBitMap2);
                    SparseBitMap1.union(SparseBitMap3);
                };

                case ("SparseBitMap", "multiUnion() of 3 BitMaps: 80k ids in 100k key space") {
                    ignore SparseBitMap.multiUnion(
                        SparseBitMaps_80k_in_100k_key_space.vals()
                    );
                };

                case ("SparseBitMap", "union() of 3 BitMaps: 10k ids in 1M key space") {
                    let SparseBitMap1 = SparseBitMaps_10k_in_1M_key_space[0].clone();
                    let SparseBitMap2 = SparseBitMaps_10k_in_1M_key_space[1];
                    let SparseBitMap3 = SparseBitMaps_10k_in_1M_key_space[2];

                    SparseBitMap1.union(SparseBitMap2);
                    SparseBitMap1.union(SparseBitMap3);
                };

                case ("SparseBitMap", "multiUnion() of 3 BitMaps: 10k ids in 1M key space") {
                    ignore SparseBitMap.multiUnion(
                        SparseBitMaps_10k_in_1M_key_space.vals()
                    );
                };

                case ("SparseBitMap", "intersect() of 3 BitMaps: 10k ids in 100k key space") {
                    let SparseBitMap1 = SparseBitMaps_10k_in_100k_key_space[0].clone();
                    let SparseBitMap2 = SparseBitMaps_10k_in_100k_key_space[1];
                    let SparseBitMap3 = SparseBitMaps_10k_in_100k_key_space[2];

                    SparseBitMap1.intersect(SparseBitMap2);
                    SparseBitMap1.intersect(SparseBitMap3);
                };

                case ("SparseBitMap", "multiIntersect() of 3 BitMaps: 10k ids in 100k key space") {
                    ignore SparseBitMap.multiIntersect(
                        SparseBitMaps_10k_in_100k_key_space.vals()
                    );
                };

                case ("SparseBitMap", "intersect() of 3 BitMaps: 50k ids in 100k key space") {
                    let SparseBitMap1 = SparseBitMaps_50k_in_100k_key_space[0].clone();
                    let SparseBitMap2 = SparseBitMaps_50k_in_100k_key_space[1];
                    let SparseBitMap3 = SparseBitMaps_50k_in_100k_key_space[2];

                    SparseBitMap1.intersect(SparseBitMap2);
                    SparseBitMap1.intersect(SparseBitMap3);
                };

                case ("SparseBitMap", "multiIntersect() of 3 BitMaps: 50k ids in 100k key space") {
                    ignore SparseBitMap.multiIntersect(
                        SparseBitMaps_50k_in_100k_key_space.vals()
                    );
                };

                case ("SparseBitMap", "intersect() of 3 BitMaps: 80k ids in 100k key space") {
                    let SparseBitMap1 = SparseBitMaps_80k_in_100k_key_space[0].clone();
                    let SparseBitMap2 = SparseBitMaps_80k_in_100k_key_space[1];
                    let SparseBitMap3 = SparseBitMaps_80k_in_100k_key_space[2];

                    SparseBitMap1.intersect(SparseBitMap2);
                    SparseBitMap1.intersect(SparseBitMap3);
                };

                case ("SparseBitMap", "multiIntersect() of 3 BitMaps: 80k ids in 100k key space") {
                    ignore SparseBitMap.multiIntersect(
                        SparseBitMaps_80k_in_100k_key_space.vals()
                    );
                };

                case ("SparseBitMap", "intersect() of 3 BitMaps: 10k ids in 1M key space") {
                    let SparseBitMap1 = SparseBitMaps_10k_in_1M_key_space[0].clone();
                    let SparseBitMap2 = SparseBitMaps_10k_in_1M_key_space[1];
                    let SparseBitMap3 = SparseBitMaps_10k_in_1M_key_space[2];

                    SparseBitMap1.intersect(SparseBitMap2);
                    SparseBitMap1.intersect(SparseBitMap3);
                };

                case ("SparseBitMap", "multiIntersect() of 3 BitMaps: 10k ids in 1M key space") {
                    ignore SparseBitMap.multiIntersect(
                        SparseBitMaps_10k_in_1M_key_space.vals()
                    );
                };

                case (_) {
                    Debug.trap("Should be unreachable:\n row = \"" # debug_show row # "\" and col = \"" # debug_show col # "\"");
                };
            }
        );

        bench;
    };
};
