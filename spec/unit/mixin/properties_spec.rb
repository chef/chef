require "support/shared/integration/integration_helper"
require "chef/mixin/properties"

module ChefMixinPropertiesSpec
  describe "Chef::Resource.property" do
    include IntegrationSupport

    context "with a base class A with properties a, ab, and ac" do
      class A
        include Chef::Mixin::Properties
        property :a, "a", default: "a"
        property :ab, %w{a b}, default: "a"
        property :ac, %w{a c}, default: "a"
      end

      context "and a module B with properties b, ab and bc" do
        module B
          include Chef::Mixin::Properties
          property :b, "b", default: "b"
          property :ab, default: "b"
          property :bc, %w{b c}, default: "c"
        end

        context "and a derived class C < A with properties c, ac and bc" do
          class C < A
            include B
            property :c, "c", default: "c"
            property :ac, default: "c"
            property :bc, default: "c"
          end

          it "A.properties has a, ab, and ac with types 'a', ['a', 'b'], and ['b', 'c']" do
            expect(A.properties.keys).to eq [ :a, :ab, :ac ]
            expect(A.properties[:a].validation_options[:is]).to eq "a"
            expect(A.properties[:ab].validation_options[:is]).to eq %w{a b}
            expect(A.properties[:ac].validation_options[:is]).to eq %w{a c}
          end
          it "B.properties has b, ab, and bc with types 'b', nil and ['b', 'c']" do
            expect(B.properties.keys).to eq [ :b, :ab, :bc ]
            expect(B.properties[:b].validation_options[:is]).to eq "b"
            expect(B.properties[:ab].validation_options[:is]).to be_nil
            expect(B.properties[:bc].validation_options[:is]).to eq %w{b c}
          end
          it "C.properties has a, b, c, ac and bc with merged types" do
            expect(C.properties.keys).to eq [ :a, :ab, :ac, :b, :bc, :c ]
            expect(C.properties[:a].validation_options[:is]).to eq "a"
            expect(C.properties[:b].validation_options[:is]).to eq "b"
            expect(C.properties[:c].validation_options[:is]).to eq "c"
            expect(C.properties[:ac].validation_options[:is]).to eq %w{a c}
            expect(C.properties[:bc].validation_options[:is]).to eq %w{b c}
          end
          it "C.properties has ab with a non-merged type (from B)" do
            expect(C.properties[:ab].validation_options[:is]).to be_nil
          end

          context "and an instance of C" do
            let(:c) { C.new }

            it "all properties can be retrieved and merged properties default to ab->b, ac->c, bc->c" do
              expect(c.a).to  eq("a")
              expect(c.b).to  eq("b")
              expect(c.c).to  eq("c")
              expect(c.ab).to eq("b")
              expect(c.ac).to eq("c")
              expect(c.bc).to eq("c")
            end
          end
        end
      end
    end
  end

  context "with an Inner module" do
    module Inner
      include Chef::Mixin::Properties
      property :inner
    end

    context "and an Outer module including it" do
      module Outer
        include Inner
        property :outer
      end

      context "and an Outerest class including that" do
        class Outerest
          include Outer
          property :outerest
        end

        it "Outerest.properties.validation_options[:is] inner, outer, outerest" do
          expect(Outerest.properties.keys).to eq [:inner, :outer, :outerest]
        end
      end
    end
  end
end
