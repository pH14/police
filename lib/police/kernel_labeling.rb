class Object
  @labels = Set.new

  def labels
    @labels ||= Set.new
    @labels
  end

  def label_with(label)
    return self if frozen? or nil?

    if is_a? TrueClass or is_a? FalseClass or is_a? NilClass
      return self
    end

    return self if has_label? label

    if not secure_context?
      self.secure_context = Police::DataFlow::SecureContextSingleton
    end

    @labels ||= Set.new
    @labels.add label

    self
  end

  def propagate_labels(other)
    @labels.each { |label| 
      label.propagate other } if labeled?
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
