class ChangeAccessCache
  class CacheValue
    def initialize(check_key, lookup_key, result)
      @check_key = check_key
      @lookup_key = lookup_key
      @result= result
    end
  end
end
