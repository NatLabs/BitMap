import Iter "mo:base@0.16.0/Iter";
import { test; suite } "mo:test";

import SparseBitMap64 "../src/SparseBitMap64";
import Fuzz "mo:fuzz";
import Buffer "mo:base@0.16.0/Buffer";
import Nat "mo:base@0.16.0/Nat";
import Set "mo:map@9.0.1/Set";

let fuzz = Fuzz.Fuzz();

let limit = 100;

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

    // Buffer.removeDuplicates(inputs[0], Nat.compare);
    // Buffer.removeDuplicates(inputs[1], Nat.compare);
    // Buffer.removeDuplicates(inputs[2], Nat.compare);

    let bitmaps = Buffer.Buffer<SparseBitMap64.SparseBitMap64>(3);

    test(
        "add()",
        func() {
            let bitmap = SparseBitMap64.new();

            for (n in inputs[0].vals()) {
                SparseBitMap64.add(bitmap, n);
                assert SparseBitMap64.get(bitmap, n) == true;
            };

            assert SparseBitMap64.size(bitmap) == inputs[0].size();

            bitmaps.add(bitmap);

        },
    );

    test(
        "addAll()",
        func() {
            let bitmap = SparseBitMap64.new();

            SparseBitMap64.addAll(bitmap, inputs[1].vals());

            assert SparseBitMap64.size(bitmap) == inputs[1].size();

            for (n in inputs[1].vals()) {
                assert SparseBitMap64.get(bitmap, n) == true;
            };

            bitmaps.add(bitmap);

        },
    );

    test(
        "fromArray()",
        func() {
            let bitmap = SparseBitMap64.fromArray(Buffer.toArray(inputs[2]));

            assert SparseBitMap64.size(bitmap) == inputs[2].size();

            for (n in inputs[2].vals()) {
                assert SparseBitMap64.get(bitmap, n) == true;
            };

            bitmaps.add(bitmap);

        },
    );

    test(
        "clone()",
        func() {
            let bitmap = SparseBitMap64.clone(bitmaps.get(0));

            assert SparseBitMap64.size(bitmap) == inputs[0].size();
            assert SparseBitMap64.size(bitmaps.get(0)) == inputs[0].size();

            for (n in inputs[0].vals()) {
                assert SparseBitMap64.get(bitmap, n) == true;
            };

            for (n in inputs[0].vals()) {
                assert SparseBitMap64.get(bitmaps.get(0), n) == true;
            };
        },
    );

    test(
        "vals()",
        func() {
            let bitmap = SparseBitMap64.clone(bitmaps.get(0));

            assert SparseBitMap64.size(bitmap) == inputs[0].size();

            for (n in inputs[0].vals()) {
                assert SparseBitMap64.get(bitmap, n) == true;
            };
        },
    );

    test(
        "union()",
        func() {
            let bitmap1 = SparseBitMap64.clone(bitmaps.get(0));
            let bitmap2 = bitmaps.get(1);
            let bitmap3 = bitmaps.get(2);

            SparseBitMap64.unionInPlace(bitmap1, bitmap2);
            SparseBitMap64.unionInPlace(bitmap1, bitmap3);

            for (n in Set.keys(fullset)) {
                assert SparseBitMap64.get(bitmap1, n) == true;
            };

        },

    );

    test(
        "multiUnion()",
        func() {

            let bitmap = SparseBitMap64.multiUnion(bitmaps.vals());

            for (n in Set.keys(fullset)) {
                assert SparseBitMap64.get(bitmap, n) == true;
            };
        },
    );

    test(
        "intersect()",
        func() {
            let bitmap1 = SparseBitMap64.clone(bitmaps.get(0));
            let bitmap2 = bitmaps.get(1);
            let bitmap3 = bitmaps.get(2);

            SparseBitMap64.intersectInPlace(bitmap1, bitmap2);
            SparseBitMap64.intersectInPlace(bitmap1, bitmap3);

            for (n in Set.keys(intersect_set)) {
                assert SparseBitMap64.get(bitmap1, n) == true;
            };

        },
    );

    test(
        "multiIntersect()",
        func() {

            let bitmap = SparseBitMap64.multiIntersect(bitmaps.vals());

            for (n in Set.keys(intersect_set)) {
                assert SparseBitMap64.get(bitmap, n) == true;
            };
        },
    );

    test(
        "difference()",
        func() {
            let bitmap1 = bitmaps.get(0);
            let bitmap2 = bitmaps.get(1);

            let bitmap_difference = SparseBitMap64.clone(bitmap1);

            SparseBitMap64.differenceInPlace(bitmap_difference, bitmap2);

            // SparseBitMap implements set difference: bitmap1 - bitmap2
            // Should keep bits only in bitmap1, remove bits in both
            for (n in SparseBitMap64.vals(bitmap1)) {
                if (SparseBitMap64.get(bitmap2, n)) {
                    assert SparseBitMap64.get(bitmap_difference, n) == false;
                } else {
                    assert SparseBitMap64.get(bitmap_difference, n) == true;
                };
            };

            // Bits only in bitmap2 should not be in the difference
            for (n in SparseBitMap64.vals(bitmap2)) {
                if (not SparseBitMap64.get(bitmap1, n)) {
                    assert SparseBitMap64.get(bitmap_difference, n) == false;
                };
            };

        },
    );

    test(
        "difference() - 2nd bitmap is larger than 1st",
        func() {
            let bitmap1 = SparseBitMap64.new();
            for (n in [1, 2, 3, 4, 5].vals()) {
                SparseBitMap64.add(bitmap1, n);
            };

            let bitmap2 = SparseBitMap64.new();

            for (n in [1, 2, 3, 4, 5, 64, 65, 66, 67, 68, 782, 783, 784, 785, 786].vals()) {
                SparseBitMap64.add(bitmap2, n);
            };

            SparseBitMap64.differenceInPlace(bitmap1, bitmap2);

            // With set difference: bitmap1 - bitmap2
            // - All bits in bitmap1 were also in bitmap2, so bitmap1 should be empty
            for (n in [1, 2, 3, 4, 5].vals()) {
                assert SparseBitMap64.get(bitmap1, n) == false;
            };

            // - Bits only in bitmap2 should not be added to bitmap1
            for (n in [64, 65, 66, 67, 68, 782, 783, 784, 785, 786].vals()) {
                assert SparseBitMap64.get(bitmap1, n) == false;
            };

            assert SparseBitMap64.size(bitmap1) == 0;

        },
    );

    test(
        "symmetricDifference() - 2nd bitmap is larger than 1st",
        func() {
            let bitmap1 = SparseBitMap64.new();
            for (n in [1, 2, 3, 4, 5].vals()) {
                SparseBitMap64.add(bitmap1, n);
            };

            let bitmap2 = SparseBitMap64.new();

            for (n in [1, 2, 3, 4, 5, 64, 65, 66, 67, 68, 782, 783, 784, 785, 786].vals()) {
                SparseBitMap64.add(bitmap2, n);
            };

            SparseBitMap64.symmetricDifferenceInPlace(bitmap1, bitmap2);

            // With symmetric difference: bits in either bitmap1 or bitmap2, but not both
            // - Bits in both bitmaps (1-5) should be removed
            for (n in [1, 2, 3, 4, 5].vals()) {
                assert SparseBitMap64.get(bitmap1, n) == false;
            };

            // - Bits only in bitmap2 (64-786) should now be in bitmap1
            for (n in [64, 65, 66, 67, 68, 782, 783, 784, 785, 786].vals()) {
                assert SparseBitMap64.get(bitmap1, n) == true;
            };

            assert SparseBitMap64.size(bitmap1) == 10;

        },
    );

    test(
        "toArray()",
        func() {
            let bitmap = SparseBitMap64.clone(bitmaps.get(0));
            let arr = SparseBitMap64.toArray(bitmap);

            assert arr.size() == inputs[0].size();

            for (n in arr.vals()) {
                assert SparseBitMap64.get(bitmap, n) == true;
            };
        },
    );
};

suite(
    "SparseBitMap64: key_space < 2^64",
    func() {
        run_tests(limit, 2 ** 64, { inputs; fullset; intersect_set });
    },
);
