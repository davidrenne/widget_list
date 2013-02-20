require 'digest/md5'

class Object
  def md5key
    to_s
  end
end

class Array
  def md5key
    map(&:md5key).join
  end
end

class Hash
  def md5key
    sort.map(&:md5key).join
  end
end