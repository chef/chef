
# based on https://github.com/ruby/ruby/blob/d41838c8d4c5b6fe956b07ade79f2d4954fd7c68/test/ruby/test_hash.rb
# see https://github.com/ruby/ruby/blob/2cd6800fd8437b1f862f3f5c44db877159271d17/COPYING
# for the applicable ruby license.

require 'spec_helper'

describe Chef::Node::AttributeTrait::Decorator do

  class Test
    include Chef::Node::AttributeTrait::Decorator
  end

  def hash_new(obj = nil, &block)
    d = Test.new
    d.wrapped_object = Hash.new(obj ? obj : block)
    d
  end

  def hash_bracket(*args)
    Test[*args]
  end

  it "Hash" do
    x = hash_bracket(1=>2, 2=>4, 3=>6)
    y = hash_bracket(1=>2, 2=>4, 3=>6)

    expect(2).to eql(x[1])

    expect {
         for k,v in y
           raise if k*2 != v
         end
    }.not_to raise_error

    expect(3).to eql(x.length)
    expect(x.send(:has_key?, 1)).to be true
    expect(x.send(:has_value?, 4)).to be true
    expect([4,6]).to eql(x.values_at(2,3))
    expect({1=>2, 2=>4, 3=>6}).to eql(x)

    z = y.keys.join(":")
    expect("1:2:3").to eql(z)

    z = y.values.join(":")
    expect("2:4:6").to eql(z)
    expect(x).to eql(y)

    y.shift
    expect(2).to eql(y.length)

    z = [1,2]
    y[z] = 256
    expect(256).to eql(y[z])

    x = hash_new(0)
    x[1] = 1
    expect(1).to eql(x[1])
    expect(0).to eql(x[2])

    #x = hash_new([])
    #expect([]).to eql(x[22])
    #expect(x[22]).to equal(x[22])

    #x = hash_new{[]}
    #expect([]).to eql(x[22])
    #expect(x[22]).not_to equal(x[22])

    #x = hash_new{|h,kk| z = kk; h[kk] = kk*2}
    #z = 0
    #expect(44).to eql(x[22])
    #expect(22).to eql(z)
    #z = 0
    #expect(44).to eql(x[22])
    #expect(0).to eql(z)
    #x.default = 5
    #expect(5).to eql(x[23])

    #x = hash_new
    #def x.default(k)
    #  $z = k
    #  self[k] = k*2
    #end
    #$z = 0
    #expect(44).to eql(x[22])
    #expect(22).to eql($z)
    #$z = 0
    #expect(44).to eql(x[22])
    #expect(0).to eql($z)
  end

  before do
    @h = hash_bracket(
      1 => 'one', 2 => 'two', 3 => 'three',
      self => 'self', true => 'true', nil => 'nil',
      'nil' => nil
    )
  end

#  it "#initialize_copy bad" do
#    h = hash_bracket(Class.new(Hash) {
#      def initialize_copy(h)
#        super(Object.new)
#      end
#    }.new)
#    expect { h.dup }.to raise_error(TypeError)
#  end

  it "#initialize_copy clear" do
    h = hash_bracket(1=>2)
    d = Test.new
    d.wrapped_object = {}
    h.instance_eval {initialize_copy(d)}
    expect(h.empty?).to be true
  end

  it "#initialize_copy self" do
    h = hash_bracket(1=>2)
    h.instance_eval {initialize_copy(h)}
    expect(2).to eql(h[1])
  end

#  it "#dup will rehash" do
#    skip "we deep-dup"
#    set1 = hash_bracket()
#    set2 = hash_bracket(set1 => true)
#
#    set1[set1] = true
#
#    expect(set2).to eql(set2.dup)
#  end

#  def test_s_AREF
#    h = @cls["a" => 100, "b" => 200]
#    expect(100).to eql(h['a'])
#    expect(200).to eql(h['b'])
#    assert_nil(h['c'])
#
#    h = @cls.[]("a" => 100, "b" => 200)
#    expect(100).to eql(h['a'])
#    expect(200).to eql(h['b'])
#    assert_nil(h['c'])
#  end

  it "#new" do
    h = hash_new
    expect(h.kind_of?(Hash)).to be true
    expect(h.default).to be nil
    expect(h['spurious']).to be nil

    h = hash_new('default')
    expect(h.kind_of?(Hash)).to be true
    expect(h.default).to eql('default')
    expect(h['spurious']).to eql('default')
  end

  it "#[]" do # '[]'
    t = Time.now
    h = hash_bracket(
      1 => 'one', 2 => 'two', 3 => 'three',
      self => 'self', t => 'time', nil => 'nil',
      'nil' => nil
    )

    expect('one').to eql(  h[1])
    expect('two').to eql(  h[2])
    expect('three').to eql(h[3])
    expect('self').to eql( h[self])
    expect('time').to eql( h[t])
    expect('nil').to eql(  h[nil])
    expect(nil).to eql(    h['nil'])
    expect(nil).to eql(    h['koala'])

    h1 = h.dup
    h1.default = :default

    expect('one').to eql(   h1[1])
    expect('two').to eql(   h1[2])
    expect('three').to eql( h1[3])
    #expect('self').to eql(  h1[self])
    expect('time').to eql(  h1[t])
    expect('nil').to eql(   h1[nil])
    expect(nil).to eql(     h1['nil'])
    expect(:default).to eql(h1['koala'])
  end

  it "#[]=" do
    t = Time.now
    h = hash_new
    h[1]     = 'one'
    h[2]     = 'two'
    h[3]     = 'three'
    h[self]  = 'self'
    h[t]     = 'time'
    h[nil]   = 'nil'
    h['nil'] = nil
    expect('one').to eql(  h[1])
    expect('two').to eql(  h[2])
    expect('three').to eql(h[3])
    expect('self').to eql( h[self])
    expect('time').to eql( h[t])
    expect('nil').to eql(  h[nil])
    expect(nil).to eql(    h['nil'])
    expect(nil).to eql(    h['koala'])

    h[1] = 1
    h[nil] = 99
    h['nil'] = nil
    z = [1,2]
    h[z] = 256
    expect(1).to eql(      h[1])
    expect('two').to eql(  h[2])
    expect('three').to eql(h[3])
    expect('self').to eql( h[self])
    expect('time').to eql( h[t])
    expect(99).to eql(     h[nil])
    expect(nil).to eql(    h['nil'])
    expect(nil).to eql(    h['koala'])
    expect(256).to eql(    h[z])
  end

#  it "#[] fstring key" do
#    skip "suspect this doesn't work by design with decorators"
#    h = hash_bracket("abc" => 1)
#    before = GC.stat(:total_allocated_objects)
#    5.times{ h["abc"] }
#    expect(GC.stat(:total_allocated_objects)).to eql(before)
#  end

  it "test_ASET_fstring_key" do
    pending "seems odd this doesn't work"
    a, b = hash_new, hash_new
    expect(a["abc"] = 1).to eql(1)
    expect(b["abc"] = 1).to eql(1)
    expect(a.keys[0]).to equal(b.keys[0])
  end

  it "test_NEWHASH_fstring_key" do
    a = hash_bracket("ABC" => :t)
    b = hash_bracket("ABC" => :t)
    expect(a.keys[0]).to equal(b.keys[0])
    expect("ABC".freeze).to equal(a.keys[0])
  end

  it "#==" do # '=='
    h1 = hash_bracket( "a" => 1, "c" => 2 )
    h2 = hash_bracket( "a" => 1, "c" => 2, 7 => 35 )
    h3 = hash_bracket( "a" => 1, "c" => 2, 7 => 35 )
    h4 = hash_bracket( )
    expect(h1).to be == h1
    expect(h2).to be == h2
    expect(h3).to be == h3
    expect(h4).to be == h4
    expect(h1).not_to be == h2
    expect(h2).to be == h3
    expect(h3).not_to be == h4
  end

  it "#clear" do
    expect(@h.size).to be > 0
    @h.clear
    expect(0).to eql(@h.size)
    expect(@h[1]).to be nil
  end

#  it "test_clone" do
#    for taint in [ false, true ]
#      for frozen in [ false, true ]
#        a = @h.clone
#        a.taint  if taint
#        a.freeze if frozen
#        b = a.clone
#
#        expect(a).to eql(b)
#        expect(a).not_to eql(b)
#        expect(a.frozen?).to eql(b.frozen?)
#        expect(a.tainted?).to eql(b.tainted?)
#      end
#    end
#  end

  it "#default" do
    expect(@h.default).to be nil
    h = hash_new(:xyzzy)
    expect(:xyzzy).to eql(h.default)
  end

  it "#default=" do
    expect(@h.default).to be nil
    @h.default = :xyzzy
    expect(:xyzzy).to eql(@h.default)
  end

  it "#delete" do
    h1 = hash_bracket( 1 => 'one', 2 => 'two', true => 'true' )
    h2 = hash_bracket( 1 => 'one', 2 => 'two' )
    h3 = hash_bracket( 2 => 'two' )

    expect('true').to eql(h1.delete(true))
    expect(h2).to eql(h1)

    expect('one').to eql(h1.delete(1))
    expect(h3).to eql(h1)

    expect('two').to eql(h1.delete(2))
    expect(hash_bracket()).to eql(h1)

    expect(h1.delete(99)).to be nil
    expect(hash_bracket()).to eql(h1)

    expect('default 99').to eql(h1.delete(99) {|i| "default #{i}" })
  end

  it "#delete_if" do
    base = hash_bracket( 1 => 'one', 2 => false, true => 'true', 'cat' => 99 )
    h1   = hash_bracket( 1 => 'one', 2 => false, true => 'true' )
    h2   = hash_bracket( 2 => false, 'cat' => 99 )
    h3   = hash_bracket( 2 => false )

    h = base.dup
    expect(h).to eql(h.delete_if { false })
    expect(hash_bracket()).to eql(h.delete_if { true })

    h = base.dup
    expect(h1).to eql(h.delete_if {|k,v| k.instance_of?(String) })
    expect(h1).to eql(h)

    h = base.dup
    expect(h2).to eql(h.delete_if {|k,v| v.instance_of?(String) })
    expect(h2).to eql(h)

    h = base.dup
    expect(h3).to eql(h.delete_if {|k,v| v })
    expect(h3).to eql(h)

    h = base.dup
    n = 0
    h.delete_if {|*a|
      n += 1
      expect(2).to eql(a.size)
      expect(base[a[0]]).to eql(a[1])
      h.shift
      true
    }
    expect(base.size).to eql(n)
  end

  it "#keep_if" do
    h = hash_bracket(1=>2,3=>4,5=>6)
    expect({3=>4,5=>6}).to eql(h.keep_if {|k,v| k + v >= 7 })
    h = hash_bracket(1=>2,3=>4,5=>6)
    expect({1=>2,3=>4,5=>6}).to eql(h.keep_if{true})
  end

#  def test_dup
#    for taint in [ false, true ]
#      for frozen in [ false, true ]
#        a = @h.dup
#        a.taint  if taint
#        a.freeze if frozen
#        b = a.dup
#
#        expect(a).to eql(b)
#        assert_not_same(a, b)
#        expect(false).to eql(b.frozen?)
#        expect(a.tainted?).to eql(b.tainted?)
#      end
#    end
#  end

  it "test_dup_equality" do
    skip "we deep-dup which breaks this"
    h = hash_bracket('k' => 'v')
    expect(h).to eql(h.dup)
    h1 = hash_bracket(h => 1)
    expect(h1).to eql(h1.dup)
    h[1] = 2
    expect(h1).to eql(h1.dup)
  end

  it "#each" do
    count = 0
    hash_bracket().each { |k, v| count + 1 }
    expect(0).to eql(count)

    h = @h
    h.each do |k, v|
      expect(v).to eql(h.delete(k))
    end
    expect(hash_bracket()).to eql(h)

    h = hash_bracket()
    h[1] = 1
    h[2] = 2
    expect([[1,1],[2,2]]).to eql(h.each.to_a)
  end

  it "#each_key" do
    count = 0
    hash_bracket().each_key { |k| count + 1 }
    expect(0).to eql(count)

    h = @h
    h.each_key do |k|
      h.delete(k)
    end
    expect(hash_bracket()).to eql(h)
  end

  it "#each_pair" do
    count = 0
    hash_bracket().each_pair { |k, v| count + 1 }
    expect(0).to eql(count)

    h = @h
    h.each_pair do |k, v|
      expect(v).to eql(h.delete(k))
    end
    expect(hash_bracket()).to eql(h)
  end

  it "#each_value" do
    res = []
    hash_bracket().each_value { |v| res << v }
    expect(0).to eql([].length)

    @h.each_value { |v| res << v }
    expect(0).to eql([].length)

    expected = []
    @h.each { |k, v| expected << v }

    expect([]).to eql(expected - res)
    expect([]).to eql(res - expected)
  end

  it "#empty?" do
    expect(hash_bracket().empty?).to be true
    expect(@h.empty?).to be false
  end

  it "#fetch" do
    expect('gumbygumby').to eql(@h.fetch('gumby') {|k| k * 2 })
    expect('pokey').to eql(@h.fetch('gumby', 'pokey'))

    expect('one').to eql(@h.fetch(1))
    expect(nil).to eql(@h.fetch('nil'))
    expect('nil').to eql(@h.fetch(nil))
  end

  it "#fetch error" do
    expect { hash_bracket().fetch(1) }.to raise_error(KeyError)
    expect { @h.fetch('gumby') }.to raise_error(KeyError)
    expect { @h.fetch('gumby'*20) }.to raise_error(
      KeyError,
      /key not found: "gumbygumby.*\.\.\.\z/
    )
  end

  it "test_key2?" do
    expect(hash_bracket().key?(1)).to be false
    expect(hash_bracket().key?(nil)).to be false
    expect(@h.send(:key?, nil)).to be true
    expect(@h.send(:key?, 1)).to be true
    expect(@h.key?('gumby')).to be false
  end

  it "#value?" do
    expect(hash_bracket().value?(1)).to be false
    expect(hash_bracket().value?(nil)).to be false
    expect(@h.value?('one')).to be true
    expect(@h.value?(nil)).to be true
    expect(@h.value?('gumby')).to be false
  end

  it "#include?" do
    expect(hash_bracket().include?(1)).to be false
    expect(hash_bracket().include?(1)).to be false
    expect(@h.send(:include?, nil)).to be true
    expect(@h.send(:include?, 1)).to be true
    expect(@h.send(:include?, 'gumby')).to be false
  end

  it "#key" do
    expect(1).to eql(    @h.key('one'))
    expect(nil).to eql(  @h.key('nil'))
    expect('nil').to eql(@h.key(nil))

    expect(nil).to eql(  @h.key('gumby'))
    expect(nil).to eql(  hash_bracket().key('gumby'))
  end

  it "#values_at" do
    res = @h.values_at('dog', 'cat', 'horse')
    expect(3).to eql(res.length)
    expect([nil, nil, nil]).to eql(res)

    res = @h.values_at
    expect(0).to eql(res.length)

    res = @h.values_at(3, 2, 1, nil)
    expect(res.length).to eql(4)
    expect(res).to eql(%w( three two one nil ))

    res = @h.values_at(3, 99, 1, nil)
    expect(res.length).to eql(4)
    expect(res).to eql(['three', nil, 'one', 'nil'])
  end

  it "#fetch_values" do
    pending "ruby 2.3 only"
    res = @h.fetch_values
    expect(0).to eql(res.length)

    res = @h.fetch_values(3, 2, 1, nil)
    expect(4).to eql(res.length)
    expect(%w( three two one nil )).to eql(res)

    expect { @h.fetch_values(3, 'invalid') }.to raise_error(KeyError)

    res = @h.fetch_values(3, 'invalid') { |k| k.upcase }
    expect(%w( three INVALID )).to eql(res)
  end

  it "#invert" do
    h = @h.invert
    expect(1).to eql(h['one'])
    expect(true).to eql(h['true'])
    expect(nil).to eql( h['nil'])

    h.each do |k, v|
      expect(@h.send(:key?, v)).to be true    # not true in general, but works here
    end

    h = hash_bracket('a' => 1, 'b' => 2, 'c' => 1).invert
    expect(2).to eql(h.length)
    expect(%w[a c].include?(h[1])).to be true
    expect('b').to eql(h[2])
  end

  it "#key?" do
    expect(hash_bracket().key?(1)).to be false
    expect(hash_bracket().key?(nil)).to be false
    expect(@h.send(:key?, nil)).to be true
    expect(@h.send(:key?, 1)).to be true
    expect(@h.key?('gumby')).to be false
  end

  it "#keys" do
    expect([]).to eql(hash_bracket().keys)

    keys = @h.keys
    expected = []
    @h.each { |k, v| expected << k }
    expect([]).to eql(keys - expected)
    expect([]).to eql(expected - keys)
  end

  it "#length?" do
    expect(0).to eql(hash_bracket().length)
    expect(7).to eql(@h.length)
  end

  it "#member?" do
    expect(hash_bracket().member?(1)).to be false
    expect(hash_bracket().member?(nil)).to be false
    expect(@h.send(:member?, nil)).to be true
    expect(@h.send(:member?, 1)).to be true
    expect(@h.member?('gumby')).to be false
  end

  it "#rehash" do
    a = [ "a", "b" ]
    c = [ "c", "d" ]
    h = hash_bracket( a => 100, c => 300 )
    expect(100).to eql(h[a])
    a[0] = "z"
    expect(h[a]).to be nil
    h.rehash
    expect(100).to eql(h[a])
  end

  it "#reject" do
    expect({3=>4,5=>6}).to eql(hash_bracket(1=>2,3=>4,5=>6).reject {|k, v| k + v < 7 })

    base = hash_bracket( 1 => 'one', 2 => false, true => 'true', 'cat' => 99 )
    h1   = hash_bracket( 1 => 'one', 2 => false, true => 'true' )
    h2   = hash_bracket( 2 => false, 'cat' => 99 )
    h3   = hash_bracket( 2 => false )

    h = base.dup
    expect(h).to eql(h.reject { false })
    expect(hash_bracket()).to eql(h.reject { true })

    h = base.dup
    expect(h1).to eql(h.reject {|k,v| k.instance_of?(String) })

    expect(h2).to eql(h.reject {|k,v| v.instance_of?(String) })

    expect(h3).to eql(h.reject {|k,v| v })
    expect(base).to eql(h)

    h.instance_variable_set(:@foo, :foo)
    h.default = 42
    h.taint
    #h = EnvUtil.suppress_warning {h.reject {false}}
    #assert_instance_of(Hash, h)
    #assert_not_predicate(h, :tainted?)
    #assert_nil(h.default)
    #assert_not_send([h, :instance_variable_defined?, :@foo])
  end

  it "#reject!" do
    base = hash_bracket( 1 => 'one', 2 => false, true => 'true', 'cat' => 99 )
    h1   = hash_bracket( 1 => 'one', 2 => false, true => 'true' )
    h2   = hash_bracket( 2 => false, 'cat' => 99 )
    h3   = hash_bracket( 2 => false )

    h = base.dup
    expect(nil).to eql(h.reject! { false })
    expect(hash_bracket()).to eql( h.reject! { true })

    h = base.dup
    expect(h1).to eql(h.reject! {|k,v| k.instance_of?(String) })
    expect(h1).to eql(h)

    h = base.dup
    expect(h2).to eql(h.reject! {|k,v| v.instance_of?(String) })
    expect(h2).to eql(h)

    h = base.dup
    expect(h3).to eql(h.reject! {|k,v| v })
    expect(h3).to eql(h)
  end

  it "#replace" do
    h = hash_bracket( 1 => 2, 3 => 4 )
    h1 = h.replace(hash_bracket( 9 => 8, 7 => 6 ))
    expect(h).to eql(h1)
    expect(8).to eql(h[9])
    expect(6).to eql(h[7])
    expect(h[1]).to be nil
    expect(h[2]).to be nil
  end

  it "#replace bug9230" do
    h = hash_bracket()
    h.replace(hash_bracket())
    expect(h.empty?).to be true

    h = hash_bracket()
    h.replace(hash_bracket().compare_by_identity)
    expect(h.compare_by_identity?).to be true
  end

  it "#shift" do
    h = @h.dup

    @h.length.times {
      k, v = h.shift
      next if v == 'self'   # FIXME: related to other failures with 'self'
      expect(@h.send(:key?, k)).to be true
      expect(@h[k]).to eql(v)
    }

    expect(0).to eql(h.length)
  end

  it "#size" do
    expect(0).to eql(hash_bracket().length)
    expect(7).to eql(@h.length)
  end

  it "#sort" do
    h = hash_bracket().sort
    expect([]).to eql(h)

    h = hash_bracket( 1 => 1, 2 => 1 ).sort
    expect([[1,1], [2,1]]).to eql(h)

    h = hash_bracket( 'cat' => 'feline', 'ass' => 'asinine', 'bee' => 'beeline' )
    h1 = h.sort
    expect([ %w(ass asinine), %w(bee beeline), %w(cat feline)]).to eql(h1)
  end

#  def test_store
#    t = Time.now
#    h = @cls.new
#    h.store(1, 'one')
#    h.store(2, 'two')
#    h.store(3, 'three')
#    h.store(self, 'self')
#    h.store(t,  'time')
#    h.store(nil, 'nil')
#    h.store('nil', nil)
#    expect('one').to eql(  h[1])
#    expect('two').to eql(  h[2])
#    expect('three').to eql(h[3])
#    expect('self').to eql( h[self])
#    expect('time').to eql( h[t])
#    expect('nil').to eql(  h[nil])
#    expect(nil).to eql(    h['nil'])
#    expect(nil).to eql(    h['koala'])
#
#    h.store(1, 1)
#    h.store(nil,  99)
#    h.store('nil', nil)
#    expect(1).to eql(      h[1])
#    expect('two').to eql(  h[2])
#    expect('three').to eql(h[3])
#    expect('self').to eql( h[self])
#    expect('time').to eql( h[t])
#    expect(99).to eql(     h[nil])
#    expect(nil).to eql(    h['nil'])
#    expect(nil).to eql(    h['koala'])
#  end
#
#  def test_to_a
#    expect([]).to eql(hash_bracket().to_a)
#    expect([[1,2]]).to eql(@cls[ 1=>2 ].to_a)
#    a = @cls[ 1=>2, 3=>4, 5=>6 ].to_a
#    expect([1,2]).to eql(a.delete([1,2]))
#    expect([3,4]).to eql(a.delete([3,4]))
#    expect([5,6]).to eql(a.delete([5,6]))
#    expect(0).to eql(a.length)
#
#    h = @cls[ 1=>2, 3=>4, 5=>6 ]
#    h.taint
#    a = h.to_a
#    expect(true).to eql(a.tainted?)
#  end
#
#  def test_to_hash
#    h = @h.to_hash
#    expect(@h).to eql(h)
#    assert_instance_of(@cls, h)
#  end
#
#  def test_to_h
#    h = @h.to_h
#    expect(@h).to eql(h)
#    assert_instance_of(Hash, h)
#  end

  it "nil#to_h" do
    h = nil.to_h
    expect(hash_new).to eql(h)
    expect(h.default).to be nil
    expect(h.default_proc).to be nil
  end

#  it "#to_s" do
#    skip "we override inspect to have more info"
#    begin
#      h = hash_bracket( 1 => 2, "cat" => "dog", 1.5 => :fred )
#      expect(h.inspect).to eql(h.to_s)
#      $, = ":"
#      expect(h.inspect).to eql(h.to_s)
#      h = hash_bracket()
#      expect(h.inspect).to eql(h.to_s)
#    ensure
#      $, = nil
#    end
#  end

  def test_update
    h1 = hash_bracket( 1 => 2, 2 => 3, 3 => 4 )
    h2 = hash_bracket( 2 => 'two', 4 => 'four' )

    ha = hash_bracket( 1 => 2, 2 => 'two', 3 => 4, 4 => 'four' )
    hb = hash_bracket( 1 => 2, 2 => 3, 3 => 4, 4 => 'four' )

    expect(ha).to eql(h1.update(h2))
    expect(ha).to eql(h1)

    h1 = hash_bracket( 1 => 2, 2 => 3, 3 => 4 )
    h2 = hash_bracket( 2 => 'two', 4 => 'four' )

    expect(hb).to eql(h2.update(h1))
    expect(hb).to eql(h2)
  end

#  def test_value2?
#    assert_not_send([hash_bracket(), :value?, 1])
#    assert_not_send([hash_bracket(), :value?, nil])
#    expect(@h.send(:value?, nil)).to be true
#    expect(@h.send(:value?, 'one')).to be true
#    assert_not_send([@h, :value?, 'gumby'])
#  end
#
#  def test_values
#    expect([]).to eql(hash_bracket().values)
#
#    vals = @h.values
#    expected = []
#    @h.each { |k, v| expected << v }
#    expect([]).to eql(vals - expected)
#    expect([]).to eql(expected - vals)
#  end
#
#  def test_intialize_wrong_arguments
#    assert_raise(ArgumentError) do
#      Hash.new(0) { }
#    end
#  end
#
#  def test_create
#    expect({1=>2, 3=>4}).to eql(@cls[[[1,2],[3,4]]])
#    assert_raise(ArgumentError) { Hash[0, 1, 2] }
#    assert_warning(/wrong element type Fixnum at 1 /) {@cls[[[1, 2], 3]]}
#    bug5406 = '[ruby-core:39945]'
#    assert_raise(ArgumentError, bug5406) { @cls[[[1, 2], [3, 4, 5]]] }
#    expect({1=>2, 3=>4}).to eql(@cls[1,2,3,4])
#    o = Object.new
#    def o.to_hash() {1=>2} end
#    expect({1=>2}, @cls[o]).to eql("[ruby-dev:34555]")
#  end
#
#  def test_rehash2
#    h = @cls[1 => 2, 3 => 4]
#    expect(h.dup).to eql(h.rehash)
#    assert_raise(RuntimeError) { h.each { h.rehash } }
#    expect({}).to eql(hash_bracket().rehash)
#  end
#
#  def test_fetch2
#    expect(:bar, @h.fetch(0).to eql(:foo) { :bar })
#  end
#
#  def test_default_proc
#    h = @cls.new {|hh, k| hh + k + "baz" }
#    expect("foobarbaz", h.default_proc.call("foo").to eql("bar"))
#    assert_nil(h.default_proc = nil)
#    assert_nil(h.default_proc)
#    h.default_proc = ->(_,_){ true }
#    expect(true).to eql(h[:nope])
#    h = hash_bracket()
#    assert_nil(h.default_proc)
#  end
#
#  def test_shift2
#    h = @cls.new {|hh, k| :foo }
#    h[1] = 2
#    expect([1, 2]).to eql(h.shift)
#    expect(:foo).to eql(h.shift)
#    expect(:foo).to eql(h.shift)
#
#    h = @cls.new(:foo)
#    h[1] = 2
#    expect([1, 2]).to eql(h.shift)
#    expect(:foo).to eql(h.shift)
#    expect(:foo).to eql(h.shift)
#
#    h =@cls[1=>2]
#    h.each { expect([1, 2]).to eql(h.shift) }
#  end
#
#  def test_shift_none
#    h = @cls.new {|hh, k| "foo"}
#    def h.default(k = nil)
#      super.upcase
#    end
#    expect("FOO").to eql(h.shift)
#  end
#
#  def test_reject_bang2
#    expect({1=>2}, @cls[1=>2,3=>4].reject! {|k).to eql(v| k + v == 7 })
#    assert_nil(@cls[1=>2,3=>4].reject! {|k, v| k == 5 })
#    assert_nil(hash_bracket().reject! { })
#  end
#
#  def test_select
#    expect({3=>4,5=>6}, @cls[1=>2,3=>4,5=>6].select {|k).to eql(v| k + v >= 7 })
#
#    base = @cls[ 1 => 'one', '2' => false, true => 'true', 'cat' => 99 ]
#    h1   = @cls[ '2' => false, 'cat' => 99 ]
#    h2   = @cls[ 1 => 'one', true => 'true' ]
#    h3   = @cls[ 1 => 'one', true => 'true', 'cat' => 99 ]
#
#    h = base.dup
#    expect(h).to eql(h.select { true })
#    expect(hash_bracket()).to eql(h.select { false })
#
#    h = base.dup
#    expect(h1).to eql(h.select {|k,v| k.instance_of?(String) })
#
#    expect(h2).to eql(h.select {|k,v| v.instance_of?(String) })
#
#    expect(h3).to eql(h.select {|k,v| v })
#    expect(base).to eql(h)
#
#    h.instance_variable_set(:@foo, :foo)
#    h.default = 42
#    h.taint
#    h = h.select {true}
#    assert_instance_of(Hash, h)
#    assert_not_predicate(h, :tainted?)
#    assert_nil(h.default)
#    assert_not_send([h, :instance_variable_defined?, :@foo])
#  end
#
#  def test_select!
#    h = @cls[1=>2,3=>4,5=>6]
#    expect(h, h.select! {|k).to eql(v| k + v >= 7 })
#    expect({3=>4,5=>6}).to eql(h)
#    h = @cls[1=>2,3=>4,5=>6]
#    expect(nil).to eql(h.select!{true})
#  end
#
#  def test_clear2
#    expect({}).to eql(@cls[1=>2,3=>4,5=>6].clear)
#    h = @cls[1=>2,3=>4,5=>6]
#    h.each { h.clear }
#    expect({}).to eql(h)
#  end
#
#  def test_replace2
#    h1 = @cls.new { :foo }
#    h2 = @cls.new
#    h2.replace h1
#    expect(:foo).to eql(h2[0])
#
#    assert_raise(ArgumentError) { h2.replace() }
#    assert_raise(TypeError) { h2.replace(1) }
#    h2.freeze
#    assert_raise(ArgumentError) { h2.replace() }
#    assert_raise(RuntimeError) { h2.replace(h1) }
#    assert_raise(RuntimeError) { h2.replace(42) }
#  end
#
#  def test_size2
#    expect(0).to eql(hash_bracket().size)
#  end
#
#  def test_equal2
#    assert_not_equal(0, hash_bracket())
#    o = Object.new
#    o.instance_variable_set(:@cls, @cls)
#    def o.to_hash; hash_bracket(); end
#    def o.==(x); true; end
#    expect({}).to eql(o)
#    def o.==(x); false; end
#    assert_not_equal({}, o)
#
#    h1 = @cls[1=>2]; h2 = @cls[3=>4]
#    assert_not_equal(h1, h2)
#    h1 = @cls[1=>2]; h2 = @cls[1=>4]
#    assert_not_equal(h1, h2)
#  end

  it "test_eql" do
    expect(hash_bracket().eql?(0)).to be false
    o = Object.new
    o.instance_variable_set(:@cls, Hash)
    def o.to_hash; hash_bracket(); end
    def o.eql?(x); true; end
    expect(hash_bracket().send(:eql?, o)).to be true
    def o.eql?(x); false; end
    expect(hash_bracket().eql?(o)).to be false
  end

  it "test_hash2" do
    expect(hash_bracket().hash).to be_kind_of(Integer)
    h = hash_bracket(1=>2)
    h.shift
    expect({}).to eql(h)
    expect({}.hash).to eql(h.hash)
    expect(hash_bracket().hash).not_to eql(0)
  end

  it "test_update2" do
    h1 = hash_bracket(1=>2, 3=>4)
    h2 = hash_bracket(1=>3, 5=>7)
    h1.update(h2) {|k, v1, v2| k + v1 + v2 }
    expect(hash_bracket(1=>6, 3=>4, 5=>7)).to eql(h1)
  end

  it "#merge" do
    h1 = hash_bracket(1=>2, 3=>4)
    h2 = hash_bracket({1=>3, 5=>7})
    expect({1=>3, 3=>4, 5=>7}).to eql(h1.merge(h2))
    expect({1=>6, 3=>4, 5=>7}).to eql(h1.merge(h2) {|k, v1, v2| k + v1 + v2 })
  end

  it "#assoc" do
    expect([3,4]).to eql(hash_bracket(1=>2, 3=>4, 5=>6).assoc(3))
    expect(hash_bracket(1=>2, 3=>4, 5=>6).assoc(4)).to be nil
    expect([1.0,1]).to eql(hash_bracket(1.0=>1).assoc(1))
  end

#  def test_assoc_compare_by_identity
#    h = hash_bracket()
#    h.compare_by_identity
#    h["a"] = 1
#    h["a".dup] = 2
#    expect(["a",1]).to eql(h.assoc("a"))
#  end

  it "#rassoc" do
    expect([3,4]).to eql(hash_bracket(1=>2, 3=>4, 5=>6).rassoc(4))
    expect({1=>2, 3=>4, 5=>6}.rassoc(3)).to be nil
  end

  it "#flatten" do
    expect([[1], [2]]).to eql(hash_bracket([1] => [2]).flatten)

    a =  hash_bracket(1=> "one", 2 => [2,"two"], 3 => [3, ["three"]])
    expect([1, "one", 2, [2, "two"], 3, [3, ["three"]]]).to eql(a.flatten)
    expect([[1, "one"], [2, [2, "two"]], [3, [3, ["three"]]]]).to eql(a.flatten(0))
    expect([1, "one", 2, [2, "two"], 3, [3, ["three"]]]).to eql(a.flatten(1))
    expect([1, "one", 2, 2, "two", 3, 3, ["three"]]).to eql(a.flatten(2))
    expect([1, "one", 2, 2, "two", 3, 3, "three"]).to eql(a.flatten(3))
    expect([1, "one", 2, 2, "two", 3, 3, "three"]).to eql(a.flatten(-1))
    expect { a.flatten(Object) }.to raise_error(TypeError)
  end
#
#  def test_callcc
#    h = @cls[1=>2]
#    c = nil
#    f = false
#    h.each { callcc {|c2| c = c2 } }
#    unless f
#      f = true
#      c.call
#    end
#    assert_raise(RuntimeError) { h.each { h.rehash } }
#
#    h = @cls[1=>2]
#    c = nil
#    assert_raise(RuntimeError) do
#      h.each { callcc {|c2| c = c2 } }
#      h.clear
#      c.call
#    end
#  end
#
#  def test_callcc_iter_level
#    bug9105 = '[ruby-dev:47803] [Bug #9105]'
#    h = @cls[1=>2, 3=>4]
#    c = nil
#    f = false
#    h.each {callcc {|c2| c = c2}}
#    unless f
#      f = true
#      c.call
#    end
#    assert_nothing_raised(RuntimeError, bug9105) do
#      h.each {|i, j|
#        h.delete(i);
#        assert_not_equal(false, i, bug9105)
#      }
#    end
#  end
#
#  def test_callcc_escape
#    bug9105 = '[ruby-dev:47803] [Bug #9105]'
#    assert_nothing_raised(RuntimeError, bug9105) do
#      h=hash_bracket()
#      cnt=0
#      c = callcc {|cc|cc}
#      h[cnt] = true
#      h.each{|i|
#        cnt+=1
#        c.call if cnt == 1
#      }
#    end
#  end
#
#  def test_callcc_reenter
#    bug9105 = '[ruby-dev:47803] [Bug #9105]'
#    assert_nothing_raised(RuntimeError, bug9105) do
#      h = @cls[1=>2,3=>4]
#      c = nil
#      f = false
#      h.each { |i|
#        callcc {|c2| c = c2 } unless c
#        h.delete(1) if f
#      }
#      unless f
#        f = true
#        c.call
#      end
#    end
#  end
#
#  def test_threaded_iter_level
#    bug9105 = '[ruby-dev:47807] [Bug #9105]'
#    h = @cls[1=>2]
#    2.times.map {
#      f = false
#      th = Thread.start {h.each {f = true; sleep}}
#      Thread.pass until f
#      Thread.pass until th.stop?
#      th
#    }.each {|th| th.run; th.join}
#    assert_nothing_raised(RuntimeError, bug9105) do
#      h[5] = 6
#    end
#    expect(6, h[5]).to eql(bug9105)
#  end
#
#  def test_compare_by_identity
#    a = "foo"
#    assert_not_predicate(hash_bracket(), :compare_by_identity?)
#    h = @cls[a => "bar"]
#    assert_not_predicate(h, :compare_by_identity?)
#    h.compare_by_identity
#    assert_predicate(h, :compare_by_identity?)
#    #expect("bar").to eql(h[a])
#    assert_nil(h["foo"])
#
#    bug8703 = '[ruby-core:56256] [Bug #8703] copied identhash'
#    h.clear
#    assert_predicate(h.dup, :compare_by_identity?, bug8703)
#  end

  it "test_same_key" do
    h = hash_bracket(a=[], 1)
    a << 1
    h[[]] = 2
    a.clear
    cnt = 0
    r = h.each{ break nil if (cnt+=1) > 100 }
    expect(r).not_to be nil
  end

#  class ObjWithHash
#    def initialize(value, hash)
#      @value = value
#      @hash = hash
#    end
#    attr_reader :value, :hash
#
#    def eql?(other)
#      @value == other.value
#    end
#  end
#
#  def test_hash_hash
#    expect({0=>2,11=>1}.hash).to eql(@cls[11=>1,0=>2].hash)
#    o1 = ObjWithHash.new(0,1)
#    o2 = ObjWithHash.new(11,1)
#    expect({o1=>1,o2=>2}.hash).to eql(@cls[o2=>2,o1=>1].hash)
#  end

  it "test_hash_bignum_hash" do
    x = 2<<(32-3)-1
    expect({x=>1}.hash).to eql(hash_bracket(x=>1).hash)
    x = 2<<(64-3)-1
    expect({x=>1}.hash).to eql(hash_bracket(x=>1).hash)

    o = Object.new
    def o.hash; 2 << 100; end
    expect({o=>1}.hash).to eql(hash_bracket(o=>1).hash)
  end

  it "test_hash_poped" do
    expect { eval("a = 1; hash_bracket(a => a); a") }.not_to raise_error
  end

  it "test_recursive_key" do
    h = hash_bracket()
    expect { h[h] = :foo }.not_to raise_error
    h.rehash
    expect(:foo).to eql(h[h])
  end

  it "test_inverse_hash" do
    [hash_bracket(1=>2), hash_bracket(123=>"abc")].each do |h|
      expect(h.hash).not_to eql(h.invert.hash)
    end
  end

#  def test_recursive_hash_value_struct
#    bug9151 = '[ruby-core:58567] [Bug #9151]'
#
#    s = Struct.new(:x) {def hash; [x,""].hash; end}
#    a = s.new
#    b = s.new
#    a.x = b
#    b.x = a
#    assert_nothing_raised(SystemStackError, bug9151) {a.hash}
#    assert_nothing_raised(SystemStackError, bug9151) {b.hash}
#
#    h = hash_bracket()
#    h[[a,"hello"]] = 1
#    expect(1).to eql(h.size)
#    h[[b,"world"]] = 2
#    expect(2).to eql(h.size)
#
#    obj = Object.new
#    h = @cls[a => obj]
#    assert_same(obj, h[b])
#  end
#
#  def test_recursive_hash_value_array
#    h = hash_bracket()
#    h[[[1]]] = 1
#    expect(1).to eql(h.size)
#    h[[[2]]] = 1
#    expect(2).to eql(h.size)
#
#    a = []
#    a << a
#
#    h = hash_bracket()
#    h[[a, 1]] = 1
#    expect(1).to eql(h.size)
#    h[[a, 2]] = 2
#    expect(2).to eql(h.size)
#    h[[a, a]] = 3
#    expect(3).to eql(h.size)
#
#    obj = Object.new
#    h = @cls[a => obj]
#    assert_same(obj, h[[[a]]])
#  end
#
#  def test_recursive_hash_value_array_hash
#    h = hash_bracket()
#    rec = [h]
#    h[:x] = rec
#
#    obj = Object.new
#    h2 = {rec => obj}
#    [h, {x: rec}].each do |k|
#      k = [k]
#      assert_same(obj, h2[k], ->{k.inspect})
#    end
#  end
#
#  def test_recursive_hash_value_hash_array
#    h = hash_bracket()
#    rec = [h]
#    h[:x] = rec
#
#    obj = Object.new
#    h2 = {h => obj}
#    [rec, [h]].each do |k|
#      k = {x: k}
#      assert_same(obj, h2[k], ->{k.inspect})
#    end
#  end
#
#  def test_exception_in_rehash_memory_leak
#    return unless @cls == Hash
#
#    bug9187 = '[ruby-core:58728] [Bug #9187]'
#
#    prepare = <<-EOS
#    class Foo
#      def initialize
#        @raise = false
#      end
#
#      def hash
#        raise if @raise
#        @raise = true
#        return 0
#      end
#    end
#    h = {Foo.new => true}
#    EOS
#
#    code = <<-EOS
#    10_0000.times do
#      h.rehash rescue nil
#    end
#    GC.start
#    EOS
#
#    assert_no_memory_leak([], prepare, code, bug9187)
#  end
#
#  def test_wrapper_of_special_const
#    bug9381 = '[ruby-core:59638] [Bug #9381]'
#
#    wrapper = Class.new do
#      def initialize(obj)
#        @obj = obj
#      end
#
#      def hash
#        @obj.hash
#      end
#
#      def eql?(other)
#        @obj.eql?(other)
#      end
#    end
#
#    bad = [
#      5, true, false, nil,
#      0.0, 1.72723e-77,
#      :foo, "dsym_#{self.object_id.to_s(16)}_#{Time.now.to_i.to_s(16)}".to_sym,
#    ].select do |x|
#      hash = {x => bug9381}
#      hash[wrapper.new(x)] != bug9381
#    end
#    assert_empty(bad, bug9381)
#  end
#
#  def test_label_syntax
#    return unless @cls == Hash
#
#    feature4935 = '[ruby-core:37553] [Feature #4935]'
#    x = 'world'
#    hash = assert_nothing_raised(SyntaxError, feature4935) do
#      break eval(%q({foo: 1, "foo-bar": 2, "hello-#{x}": 3, 'hello-#{x}': 4, 'bar': {}}))
#    end
#    expect({:foo => 1, :'foo-bar' => 2, :'hello-world' => 3, :'hello-#{x}' => 4, :bar => {}}, hash).to eql(feature4935)
#    x = x
#  end
#
#  class TestSubHash < TestHash
#    class SubHash < Hash
#      def reject(*)
#        super
#      end
#    end
#
#    def setup
#      @cls = SubHash
#      super
#    end
#  end
end
