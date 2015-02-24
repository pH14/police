class Object
  # attr_accessor :labels
  @labels = Set.new

  def labels
    @labels ||= Set.new
    @labels
  end

  def label_with(label)
    return self if frozen? or nil?

    if has_label? label and not secure_context?
      puts "Have a label but no secure context."#{}" I am #{self.no_label_to_s}"
    end

    return self if has_label? label

    # puts "Trying to label"

    if is_a? TrueClass or is_a? FalseClass or is_a? NilClass
      return self
    end

    if not secure_context?
      # puts "setting secure context"
      self.secure_context = Police::DataFlow::SecureContext.new
    end

    @labels ||= Set.new
    @labels << label

    # puts "Setting a label on #{self.no_label_to_s}"
    # puts "Setting a label"

    self
  end

  def propagate_labels(other)
    @labels.each { |label| label.propagate other } if labeled?
  end

  def has_label?(label)
    @labels ||= Set.new if not @labels
    @labels.include? label
  end

  def has_labels?(*labels_list)
    labels_list.all? { |l| has_label? l }
  end

  def labeled?
    return false if not @labels

    not @labels.empty?
  end

  # Can pass in :all to clear all labels
  def remove_label(label)
    if is_a? TrueClass or is_a? FalseClass or is_a? NilClass
      return self
    end

    return self if frozen?

    if label == :all
      @labels = Set.new
    else
      @labels.delete? label
    end

    self.secure_context = nil if not labeled?

    self
  end

  def no_label_to_s
    nolabel = dup
    nolabel.remove_label :all

    nolabel
  end
end
