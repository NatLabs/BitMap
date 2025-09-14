import Vector "mo:vector";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";

module {
  public let WORD_SIZE : Nat = 64;

  public type BitMap = {
    words : Vector.Vector<Nat64>;
    filled_positions : Nat;
  };

  func div_ceil(n : Nat, d : Nat) : Nat {
    (n + d - 1) / d;
  };

  public func empty() : BitMap {
    {
      words = Vector.new<Nat64>();
      filled_positions = 0;
    };
  };

  public func new(init_size : Nat) : BitMap {
    let init_words : Nat = div_ceil(init_size, WORD_SIZE);
    let words = Vector.new<Nat64>();

    for (_ in Iter.range(1, init_words)) {
      Vector.add(words, 0 : Nat64);
    };

    {
      words = words;
      filled_positions = 0;
    };
  };

  public func fromIter(iter : Iter.Iter<Nat>) : BitMap {
    var bitmap = new(1024);
    for (n in iter) {
      bitmap := set(bitmap, n, true);
    };
    bitmap;
  };

  public func fromArray(arr : [Nat]) : BitMap {
    fromIter(arr.vals());
  };

  public func size(bitmap : BitMap) : Nat = bitmap.filled_positions;

  public func capacity(bitmap : BitMap) : Nat = Vector.size(bitmap.words) * WORD_SIZE;

  public func clone(bitmap : BitMap) : BitMap {
    {
      words = Vector.clone(bitmap.words);
      filled_positions = bitmap.filled_positions;
    };
  };

  func grow(bitmap : BitMap, new_size : Nat) : BitMap {
    let current_capacity = capacity(bitmap);
    if (new_size <= current_capacity) return bitmap;

    let additional_space_needed = Int.abs(new_size - current_capacity);
    let additional_words_needed = div_ceil(additional_space_needed, WORD_SIZE);

    let new_words = Vector.clone(bitmap.words);
    for (_ in Iter.range(1, additional_words_needed)) {
      Vector.add(new_words, 0 : Nat64);
    };

    {
      words = new_words;
      filled_positions = bitmap.filled_positions;
    };
  };

  public func set(bitmap : BitMap, position : Nat, value : Bool) : BitMap {
    var result = bitmap;
    if (position >= capacity(bitmap)) {
      result := grow(bitmap, position + 1);
    };

    let word_index = position / WORD_SIZE;
    let bit_index = Nat64.fromNat(position % WORD_SIZE);

    let word : Nat64 = Vector.get(result.words, word_index);
    let mask : Nat64 = 1 << bit_index;

    let prev_value = (word & mask) != 0;

    if (prev_value == value) {
      return result;
    };

    let new_words = Vector.clone(result.words);
    var new_filled_positions = result.filled_positions;

    if (value) {
      Vector.put(new_words, word_index, word | mask);
      new_filled_positions += 1;
    } else {
      Vector.put(new_words, word_index, word & ^mask);
      new_filled_positions -= 1;
    };

    {
      words = new_words;
      filled_positions = new_filled_positions;
    };
  };

  public func get(bitmap : BitMap, n : Nat) : Bool {
    if (n >= capacity(bitmap)) {
      return false;
    };

    let word_index = n / WORD_SIZE;
    let bit_index = Nat64.fromNat(n % WORD_SIZE);

    let word : Nat64 = Vector.get(bitmap.words, word_index);
    let mask : Nat64 = 1 << bit_index;

    (word & mask) != 0;
  };

  public func getWord(bitmap : BitMap, n : Nat) : Nat64 {
    Vector.get(bitmap.words, n);
  };

  public func intersect(bitmap1 : BitMap, bitmap2 : BitMap) : BitMap {
    let result_words = Vector.new<Nat64>();
    var filled_positions = 0;

    let min_words = Nat.min(Vector.size(bitmap1.words), Vector.size(bitmap2.words));

    for (i in Iter.range(0, min_words - 1)) {
      let word1 = Vector.get(bitmap1.words, i);
      let word2 = Vector.get(bitmap2.words, i);
      let new_word = word1 & word2;

      Vector.add(result_words, new_word);
      filled_positions += Nat64.toNat(Nat64.bitcountNonZero(new_word));
    };

    {
      words = result_words;
      filled_positions = filled_positions;
    };
  };

  public func union(bitmap1 : BitMap, bitmap2 : BitMap) : BitMap {
    let result_words = Vector.new<Nat64>();
    var filled_positions = 0;

    let min_words = Nat.min(Vector.size(bitmap1.words), Vector.size(bitmap2.words));

    // Process common words
    for (i in Iter.range(0, min_words - 1)) {
      let word1 = Vector.get(bitmap1.words, i);
      let word2 = Vector.get(bitmap2.words, i);
      let new_word = word1 | word2;

      Vector.add(result_words, new_word);
      filled_positions += Nat64.toNat(Nat64.bitcountNonZero(new_word));
    };

    // Copy remaining words from the larger bitmap
    if (Vector.size(bitmap1.words) > min_words) {
      for (i in Iter.range(min_words, Vector.size(bitmap1.words) - 1)) {
        let word = Vector.get(bitmap1.words, i);
        Vector.add(result_words, word);
        filled_positions += Nat64.toNat(Nat64.bitcountNonZero(word));
      };
    } else if (Vector.size(bitmap2.words) > min_words) {
      for (i in Iter.range(min_words, Vector.size(bitmap2.words) - 1)) {
        let word = Vector.get(bitmap2.words, i);
        Vector.add(result_words, word);
        filled_positions += Nat64.toNat(Nat64.bitcountNonZero(word));
      };
    };

    {
      words = result_words;
      filled_positions = filled_positions;
    };
  };

  public func difference(bitmap1 : BitMap, bitmap2 : BitMap) : BitMap {
    let result_words = Vector.new<Nat64>();
    var filled_positions = 0;

    let min_words = Nat.min(Vector.size(bitmap1.words), Vector.size(bitmap2.words));

    // Process common words
    for (i in Iter.range(0, min_words - 1)) {
      let word1 = Vector.get(bitmap1.words, i);
      let word2 = Vector.get(bitmap2.words, i);
      let new_word = word1 & ^word2; // bitmap1 AND NOT bitmap2

      Vector.add(result_words, new_word);
      filled_positions += Nat64.toNat(Nat64.bitcountNonZero(new_word));
    };

    // Copy remaining words from bitmap1 if it's larger
    if (Vector.size(bitmap1.words) > min_words) {
      for (i in Iter.range(min_words, Vector.size(bitmap1.words) - 1)) {
        let word = Vector.get(bitmap1.words, i);
        Vector.add(result_words, word);
        filled_positions += Nat64.toNat(Nat64.bitcountNonZero(word));
      };
    };

    {
      words = result_words;
      filled_positions = filled_positions;
    };
  };

  public func vals(bitmap : BitMap) : Iter.Iter<Nat> {
    if (Vector.size(bitmap.words) == 0) return { next = func() : ?Nat = null };

    var word_index = 0;
    var word : Nat64 = Vector.get(bitmap.words, word_index);
    var n = 0;

    object {
      public func next() : ?Nat {
        if (word_index >= Vector.size(bitmap.words)) return null;

        while (word == 0) {
          n += WORD_SIZE;
          word_index += 1;
          if (word_index >= Vector.size(bitmap.words)) return null;
          word := Vector.get(bitmap.words, word_index);
        };

        let position = Nat64.toNat(Nat64.bitcountTrailingZero(word));
        word &= (word - 1); // Clear the least significant set bit

        ?(n + position);
      };
    };
  };

  public func toArray(bitmap : BitMap) : [Nat] {
    let iter = vals(bitmap);

    Array.tabulate(
      bitmap.filled_positions,
      func(i : Nat) : Nat {
        let ?val = iter.next() else Debug.trap("Unexpected end of iterator in toArray");
        val;
      },
    );
  };

  public func multiUnion(bitmaps : Iter.Iter<BitMap>) : BitMap {
    var result = switch (bitmaps.next()) {
      case (?first) { first };
      case (null) { return empty() };
    };

    label merging_bitmaps loop switch (bitmaps.next()) {
      case (?bitmap2) {
        result := union(result, bitmap2);
      };
      case (null) break merging_bitmaps;
    };

    result;
  };

  public func multiIntersect(bitmaps : Iter.Iter<BitMap>) : BitMap {
    var result = switch (bitmaps.next()) {
      case (?first) { first };
      case (null) { return empty() };
    };

    label merging_bitmaps loop switch (bitmaps.next()) {
      case (?bitmap2) {
        result := intersect(result, bitmap2);
      };
      case (null) break merging_bitmaps;
    };

    result;
  };

};
