require 'corelib/enumerable'

class Hash
  include Enumerable

  def self.[](*objs)
    `$opal.hash.apply(null, objs)`
  end

  def self.allocate
    %x{
      var hash = new self.$$alloc;

      hash.map  = {};
      hash.keys = [];
      hash.none = nil;
      hash.proc = nil;

      return hash;
    }
  end

  def initialize(defaults = undefined, &block)
    %x{
      self.none = (defaults === undefined ? nil : defaults);
      self.proc = block;
    }
    self
  end

  def ==(other)
    %x{
      if (self === other) {
        return true;
      }

      if (!other.map || !other.keys) {
        return false;
      }

      if (self.keys.length !== other.keys.length) {
        return false;
      }

      var map  = self.map,
          map2 = other.map;

      for (var i = 0, length = self.keys.length; i < length; i++) {
        var key = self.keys[i], obj = map[key], obj2 = map2[key];
        if (obj2 === undefined || #{`obj` != `obj2`}) {
          return false;
        }
      }

      return true;
    }
  end

  def [](key)
    %x{
      var map = self.map;

      if ($opal.hasOwnProperty.call(map, key)) {
        return map[key];
      }

      var proc = #@proc;

      if (proc !== nil) {
        return #{ `proc`.call self, key };
      }

      return #@none;
    }
  end

  def []=(key, value)
    %x{
      var map = self.map;

      if (!$opal.hasOwnProperty.call(map, key)) {
        self.keys.push(key);
      }

      map[key] = value;

      return value;
    }
  end

  def assoc(object)
    %x{
      var keys = self.keys, key;

      for (var i = 0, length = keys.length; i < length; i++) {
        key = keys[i];

        if (#{`key` == object}) {
          return [key, self.map[key]];
        }
      }

      return nil;
    }
  end

  def clear
    %x{
      self.map = {};
      self.keys = [];
      return self;
    }
  end

  def clone
    %x{
      var map  = {},
          keys = [];

      for (var i = 0, length = self.keys.length; i < length; i++) {
        var key   = self.keys[i],
            value = self.map[key];

        keys.push(key);
        map[key] = value;
      }

      var hash = new self.$$class.$$alloc();

      hash.map  = map;
      hash.keys = keys;
      hash.none = self.none;
      hash.proc = self.proc;

      return hash;
    }
  end

  def default(val = undefined)
    %x{
      if (val !== undefined && self.proc !== nil) {
        return #{@proc.call(self, val)};
      }
      return self.none;
    }
  end

  def default=(object)
    %x{
      self.proc = nil;
      return (self.none = object);
    }
  end

  def default_proc
    @proc
  end

  def default_proc=(proc)
    %x{
      if (proc !== nil) {
        proc = #{Opal.coerce_to!(proc, Proc, :to_proc)};

        if (#{proc.lambda?} && #{proc.arity.abs} != 2) {
          #{raise TypeError, "default_proc takes two arguments"};
        }
      }
      self.none = nil;
      return (self.proc = proc);
    }
  end

  def delete(key, &block)
    %x{
      var map  = self.map, result = map[key];

      if (result != null) {
        delete map[key];
        self.keys.$delete(key);

        return result;
      }

      if (block !== nil) {
        return #{block.call(key)};
      }
      return nil;
    }
  end

  def delete_if(&block)
    return enum_for :delete_if unless block

    %x{
      var map = self.map, keys = self.keys, value;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i], obj = map[key];

        if ((value = block(key, obj)) === $breaker) {
          return $breaker.$v;
        }

        if (value !== false && value !== nil) {
          keys.splice(i, 1);
          delete map[key];

          length--;
          i--;
        }
      }

      return self;
    }
  end

  alias dup clone

  def each(&block)
    return enum_for :each unless block

    %x{
      var map  = self.map,
          keys = self.keys;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key   = keys[i],
            value = $opal.$yield1(block, [key, map[key]]);

        if (value === $breaker) {
          return $breaker.$v;
        }
      }

      return self;
    }
  end

  def each_key(&block)
    return enum_for :each_key unless block

    %x{
      var keys = self.keys;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i];

        if (block(key) === $breaker) {
          return $breaker.$v;
        }
      }

      return self;
    }
  end

  alias each_pair each

  def each_value(&block)
    return enum_for :each_value unless block

    %x{
      var map = self.map, keys = self.keys;

      for (var i = 0, length = keys.length; i < length; i++) {
        if (block(map[keys[i]]) === $breaker) {
          return $breaker.$v;
        }
      }

      return self;
    }
  end

  def empty?
    `self.keys.length === 0`
  end

  alias eql? ==

  def fetch(key, defaults = undefined, &block)
    %x{
      var value = self.map[key];

      if (value != null) {
        return value;
      }

      if (block !== nil) {
        var value;

        if ((value = block(key)) === $breaker) {
          return $breaker.$v;
        }

        return value;
      }

      if (defaults != null) {
        return defaults;
      }

      #{ raise KeyError, "key not found" };
    }
  end

  def flatten(level=undefined)
    %x{
      var map = self.map, keys = self.keys, result = [];

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i], value = map[key];

        result.push(key);

        if (value.$$is_array) {
          if (level == null || level === 1) {
            result.push(value);
          }
          else {
            result = result.concat(#{`value`.flatten(`level - 1`)});
          }
        }
        else {
          result.push(value);
        }
      }

      return result;
    }
  end

  def has_key?(key)
    `$opal.hasOwnProperty.call(self.map, key)`
  end

  def has_value?(value)
    %x{
      for (var assoc in self.map) {
        if (#{`self.map[assoc]` == value}) {
          return true;
        }
      }

      return false;
    }
  end

  def hash
    `self.$$id`
  end

  alias include? has_key?

  def index(object)
    %x{
      var map = self.map, keys = self.keys;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i];

        if (#{`map[key]` == object}) {
          return key;
        }
      }

      return nil;
    }
  end

  def indexes(*keys)
    %x{
      var result = [], map = self.map, val;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i], val = map[key];

        if (val != null) {
          result.push(val);
        }
        else {
          result.push(self.none);
        }
      }

      return result;
    }
  end

  alias indices indexes

  def inspect
    %x{
      var inspect = [], keys = self.keys, map = self.map;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i], val = map[key];

        if (val === self) {
          inspect.push(#{`key`.inspect} + '=>' + '{...}');
        } else {
          inspect.push(#{`key`.inspect} + '=>' + #{`map[key]`.inspect});
        }
      }

      return '{' + inspect.join(', ') + '}';
    }
  end

  def invert
    %x{
      var result = $opal.hash(), keys = self.keys, map = self.map,
          keys2 = result.keys, map2 = result.map;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i], obj = map[key];

        keys2.push(obj);
        map2[obj] = key;
      }

      return result;
    }
  end

  def keep_if(&block)
    return enum_for :keep_if unless block

    %x{
      var map = self.map, keys = self.keys, value;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i], obj = map[key];

        if ((value = block(key, obj)) === $breaker) {
          return $breaker.$v;
        }

        if (value === false || value === nil) {
          keys.splice(i, 1);
          delete map[key];

          length--;
          i--;
        }
      }

      return self;
    }
  end

  alias key index

  alias key? has_key?

  def keys
    `self.keys.slice(0)`
  end

  def length
    `self.keys.length`
  end

  alias member? has_key?

  def merge(other, &block)
    %x{
      if (! #{Hash === other}) {
        other = #{Opal.coerce_to!(other, Hash, :to_hash)};
      }

      var keys = self.keys, map = self.map,
          result = $opal.hash(), keys2 = result.keys, map2 = result.map;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i];

        keys2.push(key);
        map2[key] = map[key];
      }

      var keys = other.keys, map = other.map;

      if (block === nil) {
        for (var i = 0, length = keys.length; i < length; i++) {
          var key = keys[i];

          if (map2[key] == null) {
            keys2.push(key);
          }

          map2[key] = map[key];
        }
      }
      else {
        for (var i = 0, length = keys.length; i < length; i++) {
          var key = keys[i];

          if (map2[key] == null) {
            keys2.push(key);
            map2[key] = map[key];
          }
          else {
            map2[key] = block(key, map2[key], map[key]);
          }
        }
      }

      return result;
    }
  end

  def merge!(other, &block)
    %x{
      if (! #{Hash === other}) {
        other = #{Opal.coerce_to!(other, Hash, :to_hash)};
      }

      var keys = self.keys, map = self.map,
          keys2 = other.keys, map2 = other.map;

      if (block === nil) {
        for (var i = 0, length = keys2.length; i < length; i++) {
          var key = keys2[i];

          if (map[key] == null) {
            keys.push(key);
          }

          map[key] = map2[key];
        }
      }
      else {
        for (var i = 0, length = keys2.length; i < length; i++) {
          var key = keys2[i];

          if (map[key] == null) {
            keys.push(key);
            map[key] = map2[key];
          }
          else {
            map[key] = block(key, map[key], map2[key]);
          }
        }
      }

      return self;
    }
  end

  def rassoc(object)
    %x{
      var keys = self.keys, map = self.map;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i], obj = map[key];

        if (#{`obj` == object}) {
          return [key, obj];
        }
      }

      return nil;
    }
  end

  def reject(&block)
    return enum_for :reject unless block

    %x{
      var keys = self.keys, map = self.map,
          result = $opal.hash(), map2 = result.map, keys2 = result.keys;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i], obj = map[key], value;

        if ((value = block(key, obj)) === $breaker) {
          return $breaker.$v;
        }

        if (value === false || value === nil) {
          keys2.push(key);
          map2[key] = obj;
        }
      }

      return result;
    }
  end

  def replace(other)
    %x{
      var map = self.map = {}, keys = self.keys = [];

      for (var i = 0, length = other.keys.length; i < length; i++) {
        var key = other.keys[i];
        keys.push(key);
        map[key] = other.map[key];
      }

      return self;
    }
  end

  def select(&block)
    return enum_for :select unless block

    %x{
      var keys = self.keys, map = self.map,
          result = $opal.hash(), map2 = result.map, keys2 = result.keys;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i], obj = map[key], value;

        if ((value = block(key, obj)) === $breaker) {
          return $breaker.$v;
        }

        if (value !== false && value !== nil) {
          keys2.push(key);
          map2[key] = obj;
        }
      }

      return result;
    }
  end

  def select!(&block)
    return enum_for :select! unless block

    %x{
      var map = self.map, keys = self.keys, value, result = nil;

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i], obj = map[key];

        if ((value = block(key, obj)) === $breaker) {
          return $breaker.$v;
        }

        if (value === false || value === nil) {
          keys.splice(i, 1);
          delete map[key];

          length--;
          i--;
          result = self
        }
      }

      return result;
    }
  end

  def shift
    %x{
      var keys = self.keys, map = self.map;

      if (keys.length) {
        var key = keys[0], obj = map[key];

        delete map[key];
        keys.splice(0, 1);

        return [key, obj];
      }

      return nil;
    }
  end

  alias size length

  alias_method :store, :[]=

  def to_a
    %x{
      var keys = self.keys, map = self.map, result = [];

      for (var i = 0, length = keys.length; i < length; i++) {
        var key = keys[i];
        result.push([key, map[key]]);
      }

      return result;
    }
  end

  def to_h
    %x{
      var hash   = new Opal.Hash.$$alloc,
          cloned = #{clone};

      hash.map  = cloned.map;
      hash.keys = cloned.keys;
      hash.none = cloned.none;
      hash.proc = cloned.proc;

      return hash;
    }
  end

  def to_hash
    self
  end

  alias to_s inspect

  alias update merge!

  alias value? has_value?

  alias values_at indexes

  def values
    %x{
      var map    = self.map,
          result = [];

      for (var key in map) {
        result.push(map[key]);
      }

      return result;
    }
  end
end
