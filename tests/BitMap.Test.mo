import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import { test; suite; skip } "mo:test";

import BitMap "../src";

test(
    "init()",
    func() {
        let bitmap = BitMap.BitMap(8);

        bitmap.set(64, true);

        assert bitmap.get(64) == true;

    },
);

test(
    "union",
    func() {
        let bitmap1 = BitMap.BitMap(8);
        let bitmap2 = BitMap.BitMap(8);

        bitmap1.set(1, true);
        bitmap2.set(64, true);

        assert bitmap1.get(1) == true;
        assert bitmap2.get(64) == true;

        bitmap1.union(bitmap2);

        assert bitmap1.get(1) == true;
        assert bitmap1.get(64) == true;

        for (i in Iter.range(0, bitmap1.capacity() - 1)) {
            if (i != 1 and i != 64) {
                assert bitmap1.get(i) == false;
            };
        };

    },

);

test(
    "intersect",
    func() {
        let bitmap1 = BitMap.BitMap(8);
        let bitmap2 = BitMap.BitMap(8);

        bitmap1.set(1, true);
        assert bitmap1.get(1) == true;
        bitmap1.set(64, true);
        assert bitmap1.get(64) == true;

        bitmap2.set(64, true);
        assert bitmap2.get(64) == true;

        bitmap1.intersect(bitmap2);

        assert bitmap1.get(1) == false;
        assert bitmap1.get(64) == true;

        for (i in Iter.range(0, bitmap1.capacity() - 1)) {
            if (i != 64) {
                assert bitmap1.get(i) == false;
            };
        };

    },
);

test(
    "vals()",
    func() {
        let bitmap = BitMap.BitMap(8);

        bitmap.set(1, true);
        bitmap.set(64, true);

        let vals = bitmap.vals();

        assert vals.next() == ?1;
        assert vals.next() == ?64;
        assert vals.next() == null;

        bitmap.set(2, true);
        bitmap.set(324, true);

        assert bitmap.toArray() == [1, 2, 64, 324];
    },
);

test(
    "fromArray()",
    func() {
        let bitmap = BitMap.fromArray([1, 2, 64, 324]);

        assert bitmap.get(1) == true;
        assert bitmap.get(2) == true;
        assert bitmap.get(64) == true;
        assert bitmap.get(324) == true;
    },
);

test(
    "multiUnion",
    func() {
        let bitmap1 = BitMap.BitMap(8);
        bitmap1.set(1, true);

        let bitmap2 = BitMap.BitMap(8);
        bitmap2.set(64, true);

        let bitmap3 = BitMap.BitMap(8);
        bitmap3.set(128, true);

        let bitmap = BitMap.multiUnion([bitmap1, bitmap2, bitmap3].vals()); // the returned bitmap is one of the input bitmaps

        assert bitmap.toArray() == [1, 64, 128];

    },
);

test(
    "multiIntersect",
    func() {
        let bitmap1 = BitMap.BitMap(8);
        bitmap1.set(1, true);
        bitmap1.set(64, true);
        bitmap1.set(128, true);

        let bitmap2 = BitMap.BitMap(8);
        bitmap2.set(64, true);
        bitmap2.set(128, true);

        let bitmap3 = BitMap.BitMap(8);
        bitmap3.set(128, true);
        bitmap3.set(256, true);

        let bitmap = BitMap.multiIntersect([bitmap1, bitmap2, bitmap3].vals()); // the returned bitmap is one of the input bitmaps

        assert bitmap.toArray() == [128];
    },
);
