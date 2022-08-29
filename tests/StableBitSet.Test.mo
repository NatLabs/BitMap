import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import ActorSpec "./utils/ActorSpec";

import SBSet "../src/StableBitSet";

let {
    assertTrue; assertFalse; assertAllTrue; describe; it; skip; pending; run
} = ActorSpec;

let success = run([
    describe("StableBitSet Tests", [
        it("new()", do {
            let bitset = SBSet.new();
            assertTrue (  SBSet.size(bitset) == 0 );
        }),
        it("replace", do{
            let bitset = SBSet.new();

            assertAllTrue([
                SBSet.replace(bitset, 1),
                SBSet.replace(bitset, 4),

                SBSet.contains(bitset, 1),
                SBSet.contains(bitset, 4),

                not SBSet.replace(bitset, 1),
                SBSet.contains(bitset, 1),
                SBSet.size(bitset) == 2
            ])
        }),
        it("put", do{
            let bitset = SBSet.new();

            SBSet.put(bitset, 2);
            SBSet.put(bitset, 4);
            SBSet.put(bitset, 2);

            assertAllTrue([
                SBSet.contains(bitset, 2),
                SBSet.contains(bitset, 4),
                SBSet.size(bitset) == 2
            ])
        }),
        it("remove", do{
            let bitset = SBSet.new();

            SBSet.put(bitset, 2);
            SBSet.put(bitset, 4);
            SBSet.put(bitset, 6);

            assertAllTrue([
                SBSet.size(bitset) == 3,

                SBSet.remove(bitset, 4),
                not SBSet.contains(bitset, 4),
                SBSet.size(bitset) == 2,

                SBSet.remove(bitset, 2),
                not SBSet.contains(bitset, 2),
                SBSet.size(bitset) == 1,
            ])
        }),
        it("delete", do{
            let bitset = SBSet.new();

            SBSet.put(bitset, 2);
            SBSet.put(bitset, 4);
            SBSet.put(bitset, 6);

            SBSet.delete(bitset, 2);
            SBSet.delete(bitset, 4);

            assertAllTrue([
                not SBSet.contains(bitset, 2),
                not SBSet.contains(bitset, 4),
                SBSet.contains(bitset, 6),
                SBSet.size(bitset) == 1,
            ])
        }),
        it("equal", do{
            let a = SBSet.new();
            let b = SBSet.new();

            SBSet.put(a, 2);
            SBSet.put(b, 2);

            SBSet.put(a, 4);
            SBSet.put(b, 4);

            assertAllTrue([
                SBSet.size(a) == 2,
                SBSet.size(b) == 2,
                SBSet.equal(a, b),
            ])
        }),
        it("fromIter", do{
            let nats = [1, 2, 2, 4];

            let bitset = SBSet.fromIter(nats.vals());

            assertAllTrue([
                SBSet.size(bitset) == 3,
                SBSet.contains(bitset, 1),
                SBSet.contains(bitset, 2),
                SBSet.contains(bitset, 4),
            ])
        }),
        it("toIter", do{
            let bitset = SBSet.new();

            SBSet.put(bitset, 1);
            SBSet.put(bitset, 2);
            SBSet.put(bitset, 4);

            assertAllTrue([
                SBSet.size(bitset) == 3,
                Iter.toArray(SBSet.toIter(bitset)) == [
                    1, 2, 4
                ]
            ])
        }),
    ])
]);

if(success == false){
  Debug.trap("\1b[46;41mTests failed\1b[0m");
}else{
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
