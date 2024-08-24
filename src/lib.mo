import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";

module {

    public let WORD_SIZE : Nat = 64;

    func div_ceil(n : Nat, d : Nat) : Nat {
        (n + d - 1) / d;
    };

    public func fromIter(iter : Iter.Iter<Nat>) : BitMap {
        let bitmap = BitMap(8);
        for (n in iter) {
            bitmap.set(n, true);
        };

        bitmap;
    };

    public func fromArray(arr : [Nat]) : BitMap {
        fromIter(arr.vals());
    };

    /// A data structure for fast set operations on a set of integers each represented by a bit.
    public class BitMap(init_size : Nat) {

        let init_words : Nat = (init_size + WORD_SIZE - 1) / WORD_SIZE; // div_ceiling

        let words = Buffer.Buffer<Nat64>(init_words);

        for (_ in Iter.range(1, init_words)) {
            words.add(0);
        };

        // internally i like to think of the bitmap as a list of bits
        // that can either be filled or empty at any given position

        var filled_positions = 0;

        public func size() : Nat = filled_positions; // - not reliable yet, as it needs to be updated for each change during an intersection or union
        public func capacity() : Nat = words.size() * WORD_SIZE;

        func grow(new_size : Nat) {
            let additional_space_needed = new_size - capacity();
            let additional_words_needed = div_ceil(additional_space_needed, WORD_SIZE);

            for (_ in Iter.range(1, additional_words_needed)) {
                words.add(0);
            };

        };

        public func set(position : Nat, value : Bool) {

            if (position >= capacity()) {
                grow(position + 1); // + 1 because position is 0-indexed
            };

            let word_index = position / WORD_SIZE;
            let bit_index = Nat64.fromNat(position % WORD_SIZE);

            let word : Nat64 = words.get(word_index);
            let mask : Nat64 = 1 << bit_index;

            let prev_value = (word & mask) != 0;

            if (prev_value == value) {
                return;
            };

            if (value) {
                words.put(word_index, word | mask);
                filled_positions += 1;
            } else {
                words.put(word_index, word & ^mask);
                filled_positions -= 1;
            };

        };

        public func get(n : Nat) : Bool {
            if (n >= capacity()) {
                return false;
            };

            let word_index = n / WORD_SIZE;
            let bit_index = Nat64.fromNat(n % WORD_SIZE);

            let word : Nat64 = words.get(word_index);
            let mask : Nat64 = 1 << bit_index;

            return (word & mask) != 0;
        };

        public func getWord(n : Nat) : Nat64 {
            return words.get(n);
        };

        public func intersect(other : BitMap) {
            if (other.capacity() < capacity()) {
                // it's assumed that the bits at the positions that are not present in the other bitmap are false or empty
                // since they are all empty and it's an intersection, we can set all the bits in the extra words to 0

                let start = other.capacity() / WORD_SIZE;
                let end = capacity() / WORD_SIZE;

                for (i in Iter.range(start, end - 1)) {
                    words.put(i, 0);
                };

            };

            if (capacity() == 0) return;

            filled_positions := 0;

            let start = 0;
            let end = Nat.min(capacity(), other.capacity()) / WORD_SIZE;

            for (i in Iter.range(start, end - 1)) {
                let other_word = other.getWord(i);
                let curr_word = words.get(i);
                let new_word = curr_word & other_word;

                words.put(i, new_word);

                filled_positions += Nat64.toNat(Nat64.bitcountNonZero(new_word));
            };

        };

        public func union(other : BitMap) {
            if (other.capacity() > capacity()) {
                grow(other.capacity());
            };

            let start = 0;
            let end = Nat.min(capacity(), other.capacity()) / WORD_SIZE;

            if (capacity() == 0) return;

            filled_positions := 0;

            for (i in Iter.range(start, end - 1)) {
                let other_word = other.getWord(i);
                let curr_word = words.get(i);

                let new_word = curr_word | other_word;

                words.put(i, new_word);

                filled_positions += Nat64.toNat(Nat64.bitcountNonZero(new_word));
            };

        };

        public func vals() : Iter.Iter<Nat> {
            if (words.size() == 0) return { next = func() : ?Nat = null };

            var word_index = 0;
            var word : Nat64 = words.get(word_index);
            var n = 0;

            object {
                public func next() : ?Nat {

                    if (word_index >= words.size()) return null;

                    while (word == 0) {
                        n += WORD_SIZE;

                        word_index += 1;
                        if (word_index >= words.size()) return null;

                        word := words.get(word_index);
                    };

                    let position = Nat64.toNat(Nat64.bitcountTrailingZero(word));
                    word &= (word - 1); // Clear the least significant set bit

                    ?(n + position);

                };
            };

        };

        public func toArray() : [Nat] {
            let iter = vals();

            Array.tabulate(
                filled_positions,
                func(i : Nat) : Nat {
                    let ?val = iter.next() else Debug.trap("Unexpected end of iterator in toArray");
                    val;
                },
            );
        };

    };
};
