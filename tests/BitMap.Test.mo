import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import { test; suite; skip } "mo:test";

import BitMap "../src";
import Fuzz "mo:fuzz";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Set "mo:map/Set";

let fuzz = Fuzz.Fuzz();

let limit = 10_000;

let inputs = [
    Buffer.Buffer<Nat>(limit),
    Buffer.Buffer<Nat>(limit),
    Buffer.Buffer<Nat>(limit),
];

let fullset = Set.new<Nat>();
let intersect_set = Set.new<Nat>();
let { nhash } = Set;

func run_tests(limit : Nat, key_space : Nat, { inputs : [Buffer.Buffer<Nat>]; fullset : Set.Set<Nat>; intersect_set : Set.Set<Nat> }) {
    inputs[0].clear();
    inputs[1].clear();
    inputs[2].clear();

    Set.clear(fullset);
    Set.clear(intersect_set);

    for (i in Iter.range(0, limit)) {
        let n1 = fuzz.nat.randomRange(0, key_space);
        let n2 = fuzz.nat.randomRange(0, key_space);
        let n3 = fuzz.nat.randomRange(0, key_space);

        inputs[0].add(n1);
        inputs[1].add(n2);
        inputs[2].add(n3);

        Set.add(fullset, nhash, n1);
        Set.add(fullset, nhash, n2);
        Set.add(fullset, nhash, n3);

        if (n1 == n2 and n2 == n3) {
            Set.add(intersect_set, nhash, n1);
        };

    };

    Buffer.removeDuplicates(inputs[0], Nat.compare);
    Buffer.removeDuplicates(inputs[1], Nat.compare);
    Buffer.removeDuplicates(inputs[2], Nat.compare);

    let bitmaps = Buffer.Buffer<BitMap.BitMap>(3);

    test(
        "add()",
        func() {
            let bitmap = BitMap.BitMap(8);

            for (n in inputs[0].vals()) {
                bitmap.set(n, true);
                assert bitmap.get(n) == true;
            };

            assert bitmap.size() == inputs[0].size();

            bitmaps.add(bitmap);

        },
    );

    test(
        "addAll()",
        func() {
            let bitmap = BitMap.BitMap(8);

            for (n in inputs[1].vals()) {
                bitmap.set(n, true);
            };

            assert bitmap.size() == inputs[1].size();

            for (n in inputs[1].vals()) {
                assert bitmap.get(n) == true;
            };

            bitmaps.add(bitmap);

        },
    );

    test(
        "fromArray()",
        func() {
            let bitmap = BitMap.fromArray(Buffer.toArray(inputs[2]));

            assert bitmap.size() == inputs[2].size();

            for (n in inputs[2].vals()) {
                assert bitmap.get(n) == true;
            };

            bitmaps.add(bitmap);

        },
    );

    test(
        "clone()",
        func() {
            let bitmap = bitmaps.get(0).clone();

            assert bitmap.size() == inputs[0].size();
            assert bitmaps.get(0).size() == inputs[0].size();

            for (n in inputs[0].vals()) {
                assert bitmap.get(n) == true;
            };

            for (n in inputs[0].vals()) {
                assert bitmaps.get(0).get(n) == true;
            };
        },
    );

    test(
        "vals()",
        func() {
            let bitmap = bitmaps.get(0).clone();

            assert bitmap.size() == inputs[0].size();

            for (n in inputs[0].vals()) {
                assert bitmap.get(n) == true;
            };
        },
    );

    test(
        "union()",
        func() {
            let bitmap1 = bitmaps.get(0).clone();
            let bitmap2 = bitmaps.get(1);
            let bitmap3 = bitmaps.get(2);

            bitmap1.union(bitmap2);
            bitmap1.union(bitmap3);

            for (n in Set.keys(fullset)) {
                assert bitmap1.get(n) == true;
            };

        },

    );

    test(
        "multiUnion()",
        func() {

            let bitmap = BitMap.multiUnion(bitmaps.vals());

            for (n in Set.keys(fullset)) {
                assert bitmap.get(n) == true;
            };
        },
    );

    test(
        "intersect()",
        func() {
            let bitmap1 = bitmaps.get(0).clone();
            let bitmap2 = bitmaps.get(1);
            let bitmap3 = bitmaps.get(2);

            bitmap1.intersect(bitmap2);
            bitmap1.intersect(bitmap3);

            for (n in Set.keys(intersect_set)) {
                assert bitmap1.get(n) == true;
            };

        },
    );

    test(
        "multiIntersect()",
        func() {

            let bitmap = BitMap.multiIntersect(bitmaps.vals());

            for (n in Set.keys(intersect_set)) {
                assert bitmap.get(n) == true;
            };
        },
    );

    test(
        "difference()",
        func() {
            let bitmap1 = bitmaps.get(0);
            let bitmap2 = bitmaps.get(1);

            let bitmap_difference = bitmap1.clone();

            bitmap_difference.difference(bitmap2);

            for (n in bitmap1.vals()) {
                if (bitmap2.get(n)) {
                    assert bitmap_difference.get(n) == false;
                } else {
                    assert bitmap_difference.get(n) == true;
                };
            };

            for (n in bitmap2.vals()) {
                if (bitmap1.get(n)) {
                    assert bitmap_difference.get(n) == false;
                } else {
                    assert bitmap_difference.get(n) == true;
                };
            };

            for (n in bitmap_difference.vals()) {
                if (bitmap1.get(n) and bitmap2.get(n)) {
                    assert false;
                };
            };

        },
    );

    // test(
    //     "difference() - 2nd bitmap is larger than 1st",
    //     func() {
    //         let bitmap1 = BitMap.BitMap(8);
    //         for (n in [1, 2, 3, 4, 5].vals()) {
    //             bitmap1.set(n, true);
    //         };

    //         let bitmap2 = BitMap.BitMap(8);

    //         for (n in [1, 2, 3, 4, 5, 64, 65, 66, 67, 68, 782, 783, 784, 785, 786].vals()) {
    //             bitmap2.set(n, true);
    //         };

    //         bitmap1.difference(bitmap2);

    //         for (n in [64, 65, 66, 67, 68, 782, 783, 784, 785, 786].vals()) {
    //             assert bitmap1.get(n) == false;
    //         };

    //     },
    // );

    // test(
    //     "multiDifference()",
    //     func() {
    //         let bitmap = BitMap.multiDifference(bitmaps.vals());

    //         let bitmap1 = bitmaps.get(0);
    //         let bitmap2 = bitmaps.get(1);
    //         let bitmap3 = bitmaps.get(2);

    //         // for (n in bitmap.vals()) {
    //         //     if (bitmap1.get(n) and bitmap2.get(n) and bitmap3.get(n)) {
    //         //         assert false;
    //         //     };
    //         // };

    //         for (n in bitmap1.vals()) {
    //             if (bitmap2.get(n) or bitmap3.get(n)) {
    //                 assert bitmap.get(n) == false;
    //             } else {
    //                 assert bitmap.get(n) == true;
    //             };
    //         };

    //         for (n in bitmap2.vals()) {
    //             if (bitmap1.get(n) or bitmap3.get(n)) {
    //                 assert bitmap.get(n) == false;
    //             } else {
    //                 assert bitmap.get(n) == true;
    //             };
    //         };

    //         for (n in bitmap3.vals()) {
    //             if (bitmap1.get(n) or bitmap2.get(n)) {
    //                 assert bitmap.get(n) == false;
    //             } else {
    //                 assert bitmap.get(n) == true;
    //             };
    //         };

    //     },
    // );
};

suite(
    "BitMap: limit = 10_000, key_space = 30_000",
    func() {
        run_tests(10_000, 30_000, { inputs; fullset; intersect_set });
    },
);

suite(
    "BitMap: limit = 10_000, key_space = 500_000",
    func() {
        run_tests(10_000, 500_000, { inputs; fullset; intersect_set });
    },
);
