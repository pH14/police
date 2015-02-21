require 'minitest/spec'
require 'minitest/autorun'

require 'test_helper'

describe Police do
  describe "Kernel Labeling" do
    let(:label1) { Police::DataFlow::Label.new "hello" }
    let(:label2) { Police::DataFlow::Label.new "world" }
    let(:label3) { Police::DataFlow::Label.new "!" }
    let(:person) { Person.new name: "Paul", age: 99, email: "pwh@csail.mit.edu" }

    it "sets single label" do
      person.name.labeled?.must_equal false

      person.name.label_with label1

      person.name.labeled?.must_equal true
      person.name.labels.size.must_equal 1
      person.name.labels.include?(label1).must_equal true
    end

    it "sets many labels" do
      person.name.labeled?.must_equal false

      person.name.label_with label1
      person.name.label_with label2
      person.name.label_with label3

      person.name.labeled?.must_equal true
      person.name.labels.size.must_equal 3

      person.name.has_labels?(label1, label2, label3).must_equal true
    end

    it "doesn't add labels it already has" do
      person.name.label_with label1
      person.name.label_with label2
      person.name.label_with label1

      person.name.labels.size.must_equal 2
      person.name.has_labels?(label2, label1).must_equal true
    end

    it "can remove labels" do
      person.name.label_with label1
      person.name.label_with label2

      person.name.labels.size.must_equal 2
      person.name.has_labels?(label1, label2).must_equal true

      person.name.remove_label label1
      person.name.labels.size.must_equal 1
      person.name.has_labels?(label2).must_equal true
      person.name.has_labels?(label1).must_equal false

      person.name.remove_label label2
      person.name.labels.size.must_equal 0
      person.name.has_labels?(label2).must_equal false
      person.name.has_labels?(label1).must_equal false
    end

    it "can remove all labels at once" do
      person.name.label_with label1
      person.name.label_with label2
      person.name.remove_label :all
      person.name.labels.size.must_equal 0
    end

    it "can assign labels to many elements" do
      person.name.label_with label1
      person.email.label_with label2

      person.name.labels.size.must_equal 1
      person.email.labels.size.must_equal 1

      person.name.has_label?(label1).must_equal true
      person.email.has_label?(label2).must_equal true
    end
  end

  describe "DataFlow with Security Contexts" do
    let(:label) { Police::DataFlow::Label.new "a label" }
    let(:label2) { Police::DataFlow::Label.new "a second label" }
    let(:person) { Person.new name: "Paul", age: 99, email: "pwh@csail.mit.edu" }
    let(:labeled_person) do
      p = Person.new name: "Paul", age: 99, email: "pwh@csail.mit.edu"
      p.name.label_with label
      p.email.label_with label2
      p
    end

    it "assigns a security context when labeling an object" do
      person.name.secure_context?.must_equal false
      person.name.label_with label
      person.name.secure_context?.must_equal true
    end

    it "removes the security context when removing the only label on an object" do
      labeled_person.name.secure_context?.must_equal true
      labeled_person.name.remove_label label
      labeled_person.name.secure_context?.must_equal false
    end

    it "removes the security context when removing the all labels individually on an object" do
      labeled_person.name.secure_context?.must_equal true
      labeled_person.name.label_with label2

      labeled_person.name.remove_label label
      labeled_person.name.secure_context?.must_equal true

      labeled_person.name.remove_label label2
      labeled_person.name.secure_context?.must_equal false
    end

    it "removes the security context when removing the all labels at once on an object" do
      labeled_person.name.secure_context?.must_equal true
      labeled_person.name.label_with label2

      labeled_person.name.remove_label :all

      labeled_person.name.labels.size.must_equal 0
      labeled_person.name.secure_context?.must_equal false
    end

    describe "propagates through String methods to new Strings" do
      it "through upcase" do
        x = labeled_person.name.upcase
        x.must_equal "PAUL"
        x.has_label?(label).must_equal true
        x.labels.size.must_equal 1
      end

      it "through downcase" do
        x = labeled_person.name.downcase
        x.must_equal "paul"
        x.has_label?(label).must_equal true
        x.labels.size.must_equal 1
      end

      it "through capitalize" do
        x = labeled_person.name.downcase!.capitalize
        x.must_equal "Paul"
        x.has_label?(label).must_equal true
        x.labels.size.must_equal 1
      end

      it "through tr_s" do
        x = labeled_person.name.tr_s 'l', 'r'
        x.must_equal "Paur"
        x.has_label?(label).must_equal true
        x.labels.size.must_equal 1
      end

      it "through byteslice" do
        x = labeled_person.name.byteslice(0)
        x.must_equal "P"
        x.has_label?(label).must_equal true
        x.labels.size.must_equal 1

        y = labeled_person.name.byteslice(0, 2)
        y.must_equal "Pa"
        y.has_label?(label).must_equal true
        y.labels.size.must_equal 1

        z = labeled_person.name.byteslice(0..1)
        z.must_equal "Pa"
        z.has_label?(label).must_equal true
        z.labels.size.must_equal 1
      end

      it "through split" do
        x = labeled_person.name.split(//)
        x.labeled?.must_equal false

        x.each do |letter|
          letter.has_label?(label).must_equal true
        end
      end

      # In RBX, this is more of a compiler/language test
      # rather than String method or operator, because the
      # generated bytecode normally calls a string building
      # method in the VM directly.
      it "propagates to new strings through interpolation" do
        y = "#{labeled_person.name}"
        y.must_equal labeled_person.name
        y.has_label?(label).must_equal true
        y.labels.size.must_equal 1
      end

      describe "with many labels" do
        it "through split" do
          labeled_person.name.label_with label2
          x = labeled_person.name.split(//)
          x.labeled?.must_equal false

          x.each do |letter|
            letter.has_label?(label).must_equal true
            letter.has_label?(label2).must_equal true
            letter.labels.size.must_equal 2
          end
        end
      end
    end

    describe "propagates through String operators to new Strings" do
      it "through + on the left" do
        x = labeled_person.name
        y = x + " Lastname"

        y.must_equal(person.name + " Lastname")
        y.has_label?(label).must_equal true
        y.labels.size.must_equal 1
      end

      it "through + on the right" do
        x = labeled_person.name
        y = "Firstname " + x

        y.must_equal("Firstname " + person.name)
        y.has_label?(label).must_equal true
        y.labels.size.must_equal 1
      end

      it "through *" do
        x = labeled_person.name
        y = x * 3

        y.must_equal(person.name * 3)
        y.has_label?(label).must_equal true
        y.labels.size.must_equal 1
      end

      it "through <<" do
        x = labeled_person.name
        y = x << "!"

        y.must_equal(person.name << "!")
        y.has_label?(label).must_equal true
        y.labels.size.must_equal 1
      end

      # TODO: This fails with named interpolation, ex. y = "%{name}" % { :name => labeled_person.name }
      it "through %" do
        y = "%s" % labeled_person.name
        y.must_equal labeled_person.name
        y.has_label?(label).must_equal true
        y.labels.size.must_equal 1
      end
    end
  end # DataFlow
end # Police
