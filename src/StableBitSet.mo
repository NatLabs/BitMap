import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import SBB "mo:StableBitBuffer/StableBitBuffer";
import Itertools "mo:Itertools/Iter";

module{
    public type StableBitSet = {
        bitArray : SBB.StableBitBuffer;
        var cardinality : Nat;
    };

    public func new() : StableBitSet{
        {
            bitArray = SBB.newPresized(#Nat32, 8);
            var cardinality = 0;
        }
    };

    public func replace(self : StableBitSet, n: Nat) : Bool{
        let {bitArray} = self;

        if (n >= SBB.size(bitArray)){
            let overflow = (n - SBB.size(bitArray)) + 1; 
            SBB.grow(bitArray, overflow, false);
        };
        
        let prev = SBB.get(bitArray, n);
        SBB.set(bitArray, n, true);

        if (prev == false){
            self.cardinality +=1;
            true
        }else{
            false
        }
    };

    public func put(self : StableBitSet, n : Nat){
        ignore replace(self, n);
    };

    public func remove(self : StableBitSet, n : Nat ) : Bool {
        if (n >= SBB.size(self.bitArray)){
            return false;
        };

        let prev = SBB.get(self.bitArray, n);
        SBB.set(self.bitArray, n, false);

        if (prev == true){
            self.cardinality -=1;
            true
        }else{
            false
        }
    };

    public func delete(self : StableBitSet, n : Nat) {
        ignore remove(self, n)
    };

    public func contains(self : StableBitSet, n: Nat) : Bool {
        SBB.get(self.bitArray, n) == true
    };

    public func size(self : StableBitSet) : Nat{
        self.cardinality
    };

    public func equal(self : StableBitSet, other : StableBitSet) : Bool{
        if (not (size(self) == size(self))){
            return false;
        };

        let selfBlocks = SBB.blocks(self.bitArray);
        let otherBlocks = SBB.blocks(other.bitArray);

        for ((a, b) in Itertools.zip(selfBlocks, otherBlocks)){
            if (not (a == b)){
                return false;
            };
        };

        true
    };

    // public func intersect(self : StableBitSet, other : StableBitSet) : StableBitSet{
    //     let selfBlocks = SBB.blocks(self.bitArray);
    //     let otherBlocks = SBB.blocks(other.bitArray);

    //     for ((a, b) in Itertools.zip(selfBlocks, otherBlocks)){
    //         if (not (a == b)){
    //             return false;
    //         };
    //     };
    // };

    // public func intersectInPlace(self : StableBitSet, other : StableBitSet) : StableBitSet{
    //     let selfBlocks = SBB.blocks(self.bitArray);
    //     let otherBlocks = SBB.blocks(other.bitArray);

    //     for ((a, b) in Itertools.zip(selfBlocks, otherBlocks)){
    //         self.bitArray.buffer[]
    //     };
    // };

    public func fromIter(iter : Iter.Iter<Nat>) : StableBitSet{
        let bitset = new();

        for (n in iter){
            put(bitset, n);
        };

        bitset
    };

    public func toIter(self : StableBitSet) : Iter.Iter<Nat>{
        Itertools.filterMap(
            Itertools.enumerate(SBB.toIter(self.bitArray)),
            func((i, exists) : (Nat, Bool)) : Bool {
                exists
            },
            func((i, exists) : (Nat, Bool)) : Nat {
                i
            }
        )
    };

    public func fromArray(arr : [Nat]) : StableBitSet{
        fromIter(arr.vals())
    };

    public func toArray(self : StableBitSet) : [Nat] {
        Iter.toArray(toIter(self))
    };

    public func toBitArray(self : StableBitSet) : SBB.StableBitBuffer {
        SBB.clone(self.bitArray)
    };
};