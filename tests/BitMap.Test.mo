import Iter "mo:base@0.16.0/Iter";
import { test; suite } "mo:test";

import BitMap "../src";
import Fuzz "mo:fuzz";
import Buffer "mo:base@0.16.0/Buffer";
import Nat "mo:base@0.16.0/Nat";
import Set "mo:map@9.0.1/Set";

let fuzz = Fuzz.Fuzz();

let limit = 1_000;

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

    let bitmaps = Buffer.Buffer<BitMap.BitMap>(3);

    test(
        "add()",
        func() {
            let bitmap = BitMap.new(8);

            for (n in inputs[0].vals()) {
                BitMap.set(bitmap, n, true);
                assert BitMap.get(bitmap, n) == true;
            };

            // Size should equal unique values just from inputs[0]
            let set_0 = Set.new<Nat>();
            for (n in inputs[0].vals()) {
                Set.add(set_0, nhash, n);
            };
            assert BitMap.size(bitmap) == Set.size(set_0);

            bitmaps.add(bitmap);

        },
    );

    test(
        "addAll()",
        func() {
            let bitmap = BitMap.new(8);

            for (n in inputs[1].vals()) {
                BitMap.set(bitmap, n, true);
            };

            let set_1 = Set.new<Nat>();
            for (n in inputs[1].vals()) {
                Set.add(set_1, nhash, n);
            };
            assert BitMap.size(bitmap) == Set.size(set_1);

            for (n in inputs[1].vals()) {
                assert BitMap.get(bitmap, n) == true;
            };

            bitmaps.add(bitmap);

        },
    );

    test(
        "fromArray()",
        func() {
            let bitmap = BitMap.fromArray(Buffer.toArray(inputs[2]));

            let set_2 = Set.new<Nat>();
            for (n in inputs[2].vals()) {
                Set.add(set_2, nhash, n);
            };
            assert BitMap.size(bitmap) == Set.size(set_2);

            for (n in inputs[2].vals()) {
                assert BitMap.get(bitmap, n) == true;
            };

            bitmaps.add(bitmap);

        },
    );

    test(
        "clone()",
        func() {
            let bitmap = BitMap.clone(bitmaps.get(0));

            let set_0 = Set.new<Nat>();
            for (n in inputs[0].vals()) {
                Set.add(set_0, nhash, n);
            };
            assert BitMap.size(bitmap) == Set.size(set_0);
            assert BitMap.size(bitmaps.get(0)) == Set.size(set_0);

            for (n in inputs[0].vals()) {
                assert BitMap.get(bitmap, n) == true;
            };

            for (n in inputs[0].vals()) {
                assert BitMap.get(bitmaps.get(0), n) == true;
            };
        },
    );

    test(
        "vals()",
        func() {
            let bitmap = BitMap.clone(bitmaps.get(0));

            let set_0 = Set.new<Nat>();
            for (n in inputs[0].vals()) {
                Set.add(set_0, nhash, n);
            };
            assert BitMap.size(bitmap) == Set.size(set_0);

            for (n in inputs[0].vals()) {
                assert BitMap.get(bitmap, n) == true;
            };
        },
    );

    test(
        "union()",
        func() {
            let bitmap1 = BitMap.clone(bitmaps.get(0));
            let bitmap2 = bitmaps.get(1);
            let bitmap3 = bitmaps.get(2);

            BitMap.unionInPlace(bitmap1, bitmap2);
            BitMap.unionInPlace(bitmap1, bitmap3);

            for (n in Set.keys(fullset)) {
                assert BitMap.get(bitmap1, n) == true;
            };

        },

    );

    test(
        "multiUnion()",
        func() {

            let bitmap = BitMap.multiUnion(bitmaps.vals());

            for (n in Set.keys(fullset)) {
                assert BitMap.get(bitmap, n) == true;
            };
        },
    );

    test(
        "intersect()",
        func() {
            let bitmap1 = BitMap.clone(bitmaps.get(0));
            let bitmap2 = bitmaps.get(1);
            let bitmap3 = bitmaps.get(2);

            BitMap.intersectInPlace(bitmap1, bitmap2);
            BitMap.intersectInPlace(bitmap1, bitmap3);

            for (n in Set.keys(intersect_set)) {
                assert BitMap.get(bitmap1, n) == true;
            };

        },
    );

    test(
        "multiIntersect()",
        func() {

            let bitmap = BitMap.multiIntersect(bitmaps.vals());

            for (n in Set.keys(intersect_set)) {
                assert BitMap.get(bitmap, n) == true;
            };
        },
    );

    test(
        "difference()",
        func() {
            let bitmap1 = bitmaps.get(0);
            let bitmap2 = bitmaps.get(1);

            let bitmap_difference = BitMap.clone(bitmap1);

            BitMap.differenceInPlace(bitmap_difference, bitmap2);

            // Set difference: bitmap1 - bitmap2
            // Should contain bits that are in bitmap1 but not in bitmap2
            for (n in BitMap.vals(bitmap1)) {
                if (BitMap.get(bitmap2, n)) {
                    // Bit is in both, should be removed
                    assert BitMap.get(bitmap_difference, n) == false;
                } else {
                    // Bit only in bitmap1, should be kept
                    assert BitMap.get(bitmap_difference, n) == true;
                };
            };

            // Bits only in bitmap2 should not be in the result
            for (n in BitMap.vals(bitmap2)) {
                if (not BitMap.get(bitmap1, n)) {
                    assert BitMap.get(bitmap_difference, n) == false;
                };
            };

            // Result should only contain bits from bitmap1 that are not in bitmap2
            for (n in BitMap.vals(bitmap_difference)) {
                assert BitMap.get(bitmap1, n) == true;
                assert BitMap.get(bitmap2, n) == false;
            };

        },
    );

    test(
        "difference() - 2nd bitmap is larger than 1st",
        func() {
            let bitmap1 = BitMap.new(8);
            for (n in [1, 2, 3, 4, 5].vals()) {
                BitMap.set(bitmap1, n, true);
            };

            let bitmap2 = BitMap.new(8);

            for (n in [1, 2, 3, 4, 5, 64, 65, 66, 67, 68, 782, 783, 784, 785, 786].vals()) {
                BitMap.set(bitmap2, n, true);
            };

            BitMap.differenceInPlace(bitmap1, bitmap2);

            // With set difference (A - B):
            // - Bits in both bitmaps (1-5) should be removed
            for (n in [1, 2, 3, 4, 5].vals()) {
                assert BitMap.get(bitmap1, n) == false;
            };

            // - Bits only in bitmap2 (64-786) should NOT be in bitmap1
            for (n in [64, 65, 66, 67, 68, 782, 783, 784, 785, 786].vals()) {
                assert BitMap.get(bitmap1, n) == false;
            };

            // bitmap1 should be empty
            assert BitMap.size(bitmap1) == 0;

        },
    );

    test(
        "symmetricDifference() - 2nd bitmap is larger than 1st",
        func() {
            let bitmap1 = BitMap.new(8);
            for (n in [1, 2, 3, 4, 5].vals()) {
                BitMap.set(bitmap1, n, true);
            };

            let bitmap2 = BitMap.new(8);

            for (n in [1, 2, 3, 4, 5, 64, 65, 66, 67, 68, 782, 783, 784, 785, 786].vals()) {
                BitMap.set(bitmap2, n, true);
            };

            BitMap.symmetricDifferenceInPlace(bitmap1, bitmap2);

            // With symmetric difference (XOR):
            // - Bits in both bitmaps (1-5) should be removed (XOR gives 0)
            for (n in [1, 2, 3, 4, 5].vals()) {
                assert BitMap.get(bitmap1, n) == false;
            };

            // - Bits only in bitmap2 (64-786) should now be in bitmap1 (XOR adds them)
            for (n in [64, 65, 66, 67, 68, 782, 783, 784, 785, 786].vals()) {
                assert BitMap.get(bitmap1, n) == true;
            };

            assert BitMap.size(bitmap1) == 10;

        },
    );
};

suite(
    "BitMap: key_space < 2^24",
    func() {
        run_tests(limit, 2 ** 16, { inputs; fullset; intersect_set });
    },
);
