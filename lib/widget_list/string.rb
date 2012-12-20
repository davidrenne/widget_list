class String

  #ruby returns nil when nothing is stripped
  def strip_or_self
    tmp = self.strip!
    if tmp.nil?
      self
    else
      tmp
    end
  end

  def split_it(char)
    tmp = self.split(char)
    if tmp.nil?
      [self]
    else
      tmp
    end
  end
=begin
  def fill(pieces={})
    WidgetList::Utils::fill(pieces,self)
  end
=end

=begin
  def [](*args)
    obj = self.dup
    unless obj.nil?
      if args.first.class.name == 'Integer'
        obj = []
      else
        obj = {}
      end
      obj[args.first]
    end
    obj
  end
=end

end