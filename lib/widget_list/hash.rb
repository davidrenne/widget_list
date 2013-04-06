class Hash

  def to_params
    params = ''
    stack = []

    each do |k, v|
      if v.is_a?(Hash)
        stack << [k,v]
      elsif v.is_a?(Array)
        stack << [k,Hash.from_array(v)]
      else
        params << "#{k}=#{v}&"
      end
    end

    stack.each do |parent, hash|
      hash.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          params << "#{parent}[#{k}]=#{v}&"
        end
      end
    end

    params.chop!
    params
  end

  def self.from_array(array = [])
    h = Hash.new
    array.size.times do |t|
      h[t] = array[t]
    end
    h
  end

  # Merges self with another hash, recursively.
  #
  # This code was lovingly stolen from some random gem:
  # http://gemjack.com/gems/tartan-0.1.1/classes/Hash.html
  #
  # Thanks to whoever made it.

  def deep_merge(hash)
    target = dup

    hash.keys.each do |key|
      if hash[key].is_a? Hash and self[key].is_a? Hash
        target[key] = target[key].deep_merge(hash[key])
        next
      end

      target[key] = hash[key]
    end

    target
  end


  # From: http://www.gemtacular.com/gemdocs/cerberus-0.2.2/doc/classes/Hash.html
  # File lib/cerberus/utils.rb, line 42

  def deep_merge!(second)
    second.each_pair do |k,v|
      if self[k].is_a?(Hash) and second[k].is_a?(Hash)
        self[k].deep_merge!(second[k])
      else
        self[k] = second[k]
      end
    end
  end


#-----------------

# cf. http://subtech.g.hatena.ne.jp/cho45/20061122
  def deep_merge2(other)
    deep_proc = Proc.new { |k, s, o|
      if s.kind_of?(Hash) && o.kind_of?(Hash)
        next s.merge(o, &deep_proc)
      end
      next o
    }
    merge(other, &deep_proc)
  end


  def deep_merge3(second)

    # From: http://www.ruby-forum.com/topic/142809
    # Author: Stefan Rusterholz

    merger = proc { |key,v1,v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(second, &merger)

  end


  def keep_merge(hash)
    target = dup
    hash.keys.each do |key|
      if hash[key].is_a? Hash and self[key].is_a? Hash
        target[key] = target[key].keep_merge(hash[key])
        next
      end
      #target[key] = hash[key]
      target.update(hash) { |key, *values| values.flatten.uniq }
    end
    target
  end

end